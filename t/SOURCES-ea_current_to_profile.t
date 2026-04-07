#!/usr/local/cpanel/3rdparty/bin/perl

# cpanel - t/SOURCES-ea_current_to_profile.t      Copyright(c) 2026 cPanel, Inc.
#                                                           All rights Reserved.
# copyright@cpanel.net                                         http://cpanel.net
# This code is subject to the cPanel license. Unauthorized copying is prohibited

use strict;
use warnings;
use Test::More;
use Test::Deep;
use Test::MockModule qw/strict/;
use Test::Trap;
use File::Temp ();
use FindBin;

use Cpanel::PackMan       ();
use Cpanel::Config::Httpd ();
use Cpanel::JSON          ();

BEGIN { require_ok("$FindBin::Bin/../SOURCES/ea_current_to_profile") }

###########################
## _load_pkg_renames tests
###########################

note "test _load_pkg_renames with a valid JSON file";
{
    my $dir = File::Temp->newdir();
    my $json_file = "$dir/target-os-pkg-renames.json";

    Cpanel::JSON::DumpFile(
        $json_file,
        {
            'CentOS_9' => {
                'ea-ruby27-mod_passenger' => 'ea-apache24-mod-passenger',
                'ea-old-pkg'              => 'ea-new-pkg',
            },
            'CentOS_8' => {
                'ea-legacy-pkg' => 'ea-modern-pkg',
            },
        }
    );

    local $ea_cpanel_tools::ea_current_to_profile::pkg_renames_file = $json_file;

    my ( $renames, $ignore_deps ) = ea_cpanel_tools::ea_current_to_profile::_load_pkg_renames("CentOS_9");
    is_deeply(
        $renames,
        {
            'ea-ruby27-mod-passenger' => 'ea-apache24-mod-passenger',
            'ea-old-pkg'              => 'ea-new-pkg',
        },
        "_load_pkg_renames returns normalized renames for CentOS_9"
    );
    is_deeply( $ignore_deps, {}, "_load_pkg_renames returns empty ignore_deps when none defined" );

    ( $renames, $ignore_deps ) = ea_cpanel_tools::ea_current_to_profile::_load_pkg_renames("CentOS_8");
    is_deeply(
        $renames,
        { 'ea-legacy-pkg' => 'ea-modern-pkg' },
        "_load_pkg_renames returns renames for CentOS_8"
    );
}

note "test _load_pkg_renames with a target OS that has no renames";
{
    my $dir = File::Temp->newdir();
    my $json_file = "$dir/target-os-pkg-renames.json";

    Cpanel::JSON::DumpFile(
        $json_file,
        {
            'CentOS_9' => {
                'ea-ruby27-mod_passenger' => 'ea-apache24-mod-passenger',
            },
        }
    );

    local $ea_cpanel_tools::ea_current_to_profile::pkg_renames_file = $json_file;

    my ( $renames, $ignore_deps ) = ea_cpanel_tools::ea_current_to_profile::_load_pkg_renames("CentOS_7");
    is_deeply( $renames, {}, "_load_pkg_renames returns empty hash for OS with no renames" );
    is_deeply( $ignore_deps, {}, "_load_pkg_renames returns empty ignore_deps for OS with no renames" );
}

note "test _load_pkg_renames when file does not exist";
{
    local $ea_cpanel_tools::ea_current_to_profile::pkg_renames_file = "/nonexistent/path/renames.json";

    my ( $renames, $ignore_deps ) = ea_cpanel_tools::ea_current_to_profile::_load_pkg_renames("CentOS_9");
    is_deeply( $renames, {}, "_load_pkg_renames returns empty hash when file does not exist" );
    is_deeply( $ignore_deps, {}, "_load_pkg_renames returns empty ignore_deps when file does not exist" );
}

note "test _load_pkg_renames normalizes underscores to dashes";
{
    my $dir = File::Temp->newdir();
    my $json_file = "$dir/target-os-pkg-renames.json";

    Cpanel::JSON::DumpFile(
        $json_file,
        {
            'CentOS_9' => {
                'ea-ruby27-mod_passenger' => 'ea-apache24-mod-passenger',
            },
        }
    );

    local $ea_cpanel_tools::ea_current_to_profile::pkg_renames_file = $json_file;

    my ($renames) = ea_cpanel_tools::ea_current_to_profile::_load_pkg_renames("CentOS_9");
    ok( exists $renames->{'ea-ruby27-mod-passenger'}, "underscore keys are normalized to dashes" );
    is( $renames->{'ea-ruby27-mod-passenger'}, 'ea-apache24-mod-passenger', "values are also normalized" );
}

note "test _normalize_pkg";
{
    is( ea_cpanel_tools::ea_current_to_profile::_normalize_pkg("ea-ruby27-mod_passenger"), "ea-ruby27-mod-passenger", "_normalize_pkg converts underscores to dashes" );
    is( ea_cpanel_tools::ea_current_to_profile::_normalize_pkg("ea-apache24-mod-passenger"), "ea-apache24-mod-passenger", "_normalize_pkg leaves dashes alone" );
    is( ea_cpanel_tools::ea_current_to_profile::_normalize_pkg("ea-no-changes"), "ea-no-changes", "_normalize_pkg with no underscores is a no-op" );
}

#################################
## _load_pkg_renames ignore_deps
#################################

note "test _load_pkg_renames with ignore_deps (hash format)";
{
    my $dir = File::Temp->newdir();
    my $json_file = "$dir/target-os-pkg-renames.json";

    Cpanel::JSON::DumpFile(
        $json_file,
        {
            'CentOS_9' => {
                'ea-ruby27-mod_passenger' => {
                    to          => 'ea-apache24-mod-passenger',
                    ignore_deps => [ 'ea-ruby27-ruby', '/^ea-ruby27-rubygems/' ],
                },
                'ea-simple-rename' => 'ea-new-simple',
            },
        }
    );

    local $ea_cpanel_tools::ea_current_to_profile::pkg_renames_file = $json_file;

    my ( $renames, $ignore_deps ) = ea_cpanel_tools::ea_current_to_profile::_load_pkg_renames("CentOS_9");
    is_deeply(
        $renames,
        {
            'ea-ruby27-mod-passenger' => 'ea-apache24-mod-passenger',
            'ea-simple-rename'        => 'ea-new-simple',
        },
        "_load_pkg_renames returns renames from both string and hash entries"
    );
    is_deeply(
        $ignore_deps,
        {
            'ea-ruby27-mod-passenger' => [ 'ea-ruby27-ruby', '/^ea-ruby27-rubygems/' ],
        },
        "_load_pkg_renames returns ignore_deps for hash entries only"
    );
    ok( !exists $ignore_deps->{'ea-simple-rename'}, "simple string entries have no ignore_deps" );
}

############################
## _pkg_matches_ignore tests
############################

note "test _pkg_matches_ignore with literal match";
{
    my @patterns = ( 'ea-ruby27-ruby', 'ea-ruby27-rubygems' );
    ok( ea_cpanel_tools::ea_current_to_profile::_pkg_matches_ignore( 'ea-ruby27-ruby', \@patterns ), "literal match works" );
    ok( ea_cpanel_tools::ea_current_to_profile::_pkg_matches_ignore( 'ea-ruby27-rubygems', \@patterns ), "second literal match works" );
    ok( !ea_cpanel_tools::ea_current_to_profile::_pkg_matches_ignore( 'ea-ruby27-other', \@patterns ), "non-matching literal returns false" );
}

note "test _pkg_matches_ignore with regex match";
{
    my @patterns = ( '/^ea-ruby27-ruby/' );
    ok( ea_cpanel_tools::ea_current_to_profile::_pkg_matches_ignore( 'ea-ruby27-ruby', \@patterns ), "regex matches exact" );
    ok( ea_cpanel_tools::ea_current_to_profile::_pkg_matches_ignore( 'ea-ruby27-rubygems', \@patterns ), "regex matches prefix" );
    ok( ea_cpanel_tools::ea_current_to_profile::_pkg_matches_ignore( 'ea-ruby27-ruby-doc', \@patterns ), "regex matches with suffix" );
    ok( !ea_cpanel_tools::ea_current_to_profile::_pkg_matches_ignore( 'ea-ruby27-mod-passenger', \@patterns ), "regex does not match unrelated" );
}

note "test _pkg_matches_ignore with mixed patterns";
{
    my @patterns = ( 'ea-exact-match', '/^ea-ruby27-ruby/' );
    ok( ea_cpanel_tools::ea_current_to_profile::_pkg_matches_ignore( 'ea-exact-match', \@patterns ), "literal in mixed list matches" );
    ok( ea_cpanel_tools::ea_current_to_profile::_pkg_matches_ignore( 'ea-ruby27-rubygems', \@patterns ), "regex in mixed list matches" );
    ok( !ea_cpanel_tools::ea_current_to_profile::_pkg_matches_ignore( 'ea-unrelated', \@patterns ), "non-matching in mixed list returns false" );
}

note "test _pkg_matches_ignore normalizes literal patterns";
{
    my @patterns = ( 'ea-ruby27-mod_passenger-doc' );
    ok( ea_cpanel_tools::ea_current_to_profile::_pkg_matches_ignore( 'ea-ruby27-mod-passenger-doc', \@patterns ), "underscore in pattern normalized to match dash in pkg" );
}

# -----------------------------------------------------------------------
# Integration test setup
# -----------------------------------------------------------------------

my $tmp      = File::Temp->newdir();
my $prof_dir = "$tmp/profiles";
mkdir $prof_dir;

my $metainfo_file = "$tmp/ea4-metainfo.json";
Cpanel::JSON::DumpFile(
    $metainfo_file,
    { obs_project_aliases => { 'AlmaLinux_9' => 'CentOS_9' } }
);

{
    no warnings 'once'; ## no critic qw(ProhibitNoWarnings)
    $ea_cpanel_tools::ea_current_to_profile::ea4_metainfo_file = $metainfo_file;
    $ea_cpanel_tools::ea_current_to_profile::ea4_profiles_dir  = $prof_dir;
}

my $mock_httpd   = Test::MockModule->new('Cpanel::Config::Httpd');
my $mock_packman = Test::MockModule->new('Cpanel::PackMan');

$mock_httpd->redefine( is_ea4 => sub { 1 } );

my %base_manifest = (
    'EA4'              => { 'CentOS_9' => [ 'ea-apache24-mod-deflate', 'ea-apache24-mod-passenger' ] },
    'EA4-experimental' => { 'CentOS_9' => [] },
    'EA4-production'   => { 'CentOS_9' => [] },
);

# -----------------------------------------------------------------------
# Integration test 1: rename is active
#   System has ea-ruby27-mod_passenger (underscore in real pkg name).
#   Manifest has ea-apache24-mod-passenger.
#   Expected: old name replaced by new name; ea-ruby27-gems dropped.
# -----------------------------------------------------------------------

note "Integration: rename ea-ruby27-mod_passenger -> ea-apache24-mod-passenger";

my ( $rc1, $out1 ) = _run_script(
    \%base_manifest,
    [ 'ea-ruby27-mod_passenger', 'ea-ruby27-gems', 'ea-apache24-mod-deflate' ],
);

is( $rc1, 0, "script exits 0 when rename is active" );

my $profile1 = Cpanel::JSON::LoadFile($out1);
my $pkgs1    = $profile1->{pkgs};
ok( ( grep { $_ eq 'ea-apache24-mod-passenger' } @{$pkgs1} ), "renamed pkg ea-apache24-mod-passenger is in output" );
ok( !( grep { $_ =~ /ea-ruby27-mod/ } @{$pkgs1} ),            "old pkg ea-ruby27-mod-passenger is not in output" );
ok( !( grep { $_ eq 'ea-ruby27-gems' } @{$pkgs1} ),            "obsolete dep ea-ruby27-gems is dropped from output" );
ok( ( grep { $_ eq 'ea-apache24-mod-deflate' } @{$pkgs1} ),   "unrelated pkg ea-apache24-mod-deflate is kept" );

# Verify the metadata tracks the rename and ignored dep
is_deeply(
    $profile1->{os_upgrade}{renamed_pkgs},
    { 'ea-ruby27-mod-passenger' => 'ea-apache24-mod-passenger' },
    "renamed_pkgs metadata records the rename"
);
ok( exists $profile1->{os_upgrade}{ignored_deps}{'ea-ruby27-gems'}, "ignored_deps metadata records the dropped dep" );

# -----------------------------------------------------------------------
# Integration test 2: rename is inactive (new pkg absent from manifest)
#   ea-ruby27-mod_passenger should be treated as unavailable on target OS
#   (removed), NOT substituted.
# -----------------------------------------------------------------------

note "Integration: no rename when new pkg is absent from manifest";

my %no_passenger_manifest = (
    'EA4'              => { 'CentOS_9' => ['ea-apache24-mod-deflate'] },
    'EA4-experimental' => { 'CentOS_9' => [] },
    'EA4-production'   => { 'CentOS_9' => [] },
);

my ( $rc2, $out2 ) = _run_script(
    \%no_passenger_manifest,
    [ 'ea-ruby27-mod_passenger', 'ea-apache24-mod-deflate' ],
);

is( $rc2, 0, "script exits 0 when rename is inactive" );

my $pkgs2 = Cpanel::JSON::LoadFile($out2)->{pkgs};
ok( !( grep { $_ =~ /passenger/ } @{$pkgs2} ),              "no passenger pkg in output when rename is inactive" );
ok( ( grep { $_ eq 'ea-apache24-mod-deflate' } @{$pkgs2} ), "unrelated pkg ea-apache24-mod-deflate is kept when rename inactive" );

done_testing();

# -----------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------

my $_counter = 0;

sub _run_script {
    my ( $manifest_href, $installed_ref ) = @_;

    my $mf = "$tmp/manifest-" . $_counter++ . ".json";
    Cpanel::JSON::DumpFile( $mf, $manifest_href );

    # Create a JSON renames file matching the real config
    my $renames_file = "$tmp/renames-$_counter.json";
    Cpanel::JSON::DumpFile(
        $renames_file,
        {
            'CentOS_9' => {
                'ea-ruby27-mod_passenger' => {
                    to          => 'ea-apache24-mod-passenger',
                    ignore_deps => ['/^ea-ruby27/'],
                },
            },
        }
    );

    no warnings 'once'; ## no critic qw(ProhibitNoWarnings)
    local $ea_cpanel_tools::ea_current_to_profile::manifest_file    = $mf;
    local $ea_cpanel_tools::ea_current_to_profile::pkg_renames_file = $renames_file;

    $mock_packman->redefine( list => sub { return @{$installed_ref} } );

    my $out = "$prof_dir/out-" . $_counter . ".json";
    my $rc;
    trap { $rc = ea_cpanel_tools::ea_current_to_profile::script( "--target-os=AlmaLinux_9", "--output=$out" ) };
    return ( $rc, $out );
}
