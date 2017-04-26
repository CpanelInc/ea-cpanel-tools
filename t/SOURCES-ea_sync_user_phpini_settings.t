#!/usr/local/cpanel/3rdparty/bin/perl

# cpanel - t/SOURCES-ea_sync_user_phpini_settings.t  Copyright 2017 cPanel, Inc.
#                                                           All rights Reserved.
# copyright@cpanel.net                                         http://cpanel.net
# This code is subject to the cPanel license. Unauthorized copying is prohibited

use strict;
use warnings;
use Test::More tests => 65 + 1;
use Test::NoWarnings;
use File::Temp ();
use File::Slurp 'write_file';
use Test::Trap;

use Cpanel::PwCache                  ();
use Cpanel::Config::Httpd            ();
use Cpanel::PHP::Config              ();
use Cpanel::Version                  ();
use Cpanel::ProgLang::Supported::php ();

use FindBin;
BEGIN { require_ok("$FindBin::Bin/../SOURCES/ea_sync_user_phpini_settings") }

note "run() logic, arg handling";
{
    my @_process_user_args;
    our @php_versions             = qw(ea-php42 ea-php86);
    our $get_short_release_number = 62;
    no warnings "redefine";
    local *ea_sync_user_phpini_settings::_process_user = sub { push @_process_user_args, \@_ };
    local *Cpanel::PwCache::getpwnam = sub { $_[0] =~ m/^validu/ ? [] : undef };
    local *Cpanel::PHP::Config::get_php_version_info = sub { return { versions => \@php_versions, default => "ea-php99" } };
    local *Cpanel::Version::get_short_release_number = sub { return $get_short_release_number };
    use warnings "redefine";

    # --help
    trap { ea_sync_user_phpini_settings::run("--help"); };
    is_deeply( \@_process_user_args, [], "--help flag: no users are processed" );
    $trap->exit_is( 0, '--help exits clean' );
    $trap->stdout_like( qr/Usage/, "--help does help" );

    # pre-62
    {
        local $get_short_release_number = 61;
        trap { ea_sync_user_phpini_settings::run("--user=validu"); };
        is_deeply( \@_process_user_args, [], "pre v62: no users are processed" );
        $trap->exit_is( 0, 'pre v62 exits clean' );
        $trap->stdout_unlike( qr/Usage/, "pre v62 does not do help" );
        $trap->stdout_like( qr/Nothing to do \(only applies to v62 and newer\)\n/, "pre v62 has explantion" );

    }
    #### un happy paths do help and exit ##
    # non ea4
    trap {
        no warnings "redefine";
        local *Cpanel::Config::Httpd::is_ea4 = sub { return };
        ea_sync_user_phpini_settings::run();
    };
    is_deeply( \@_process_user_args, [], "non-ea4: no users are processed" );
    $trap->die_like( qr/This script only operates when you are under EasyApache 4\n/, "non-ea4: does help" );
    $trap->stdout_unlike( qr/Usage/, "non-ea4: does not do help" );

    # no PHPs installed
    {
        local @php_versions = ();
        trap { ea_sync_user_phpini_settings::run("--user=validu") };
        is_deeply( \@_process_user_args, [], "no PHPs: no users are processed" );
        $trap->die_like( qr/There are no PHP packages installed via ea4\n/, "no PHPs: explains the problem" );
        $trap->stdout_unlike( qr/Usage/, "no PHPs: does not do help" );
    }

    # no --user=<USER>
    trap { ea_sync_user_phpini_settings::run(); };
    is_deeply( \@_process_user_args, [], "no --user flag: no users are processed" );
    $trap->exit_isnt( 0, 'no --user flag: exits unclean' );
    $trap->stderr_is( "", "no --user flag: does not explain the problem (the help does that)" );
    $trap->stdout_like( qr/Usage/, "no --user flag: does help" );

    # --user
    trap { ea_sync_user_phpini_settings::run( "--user=validu", "--user" ); };
    is_deeply( \@_process_user_args, [], "no value --user flag: no users are processed" );
    $trap->exit_isnt( 0, 'no value --user flag: exits unclean' );
    $trap->stderr_like( qr/--user requires a value \(--user=<USER>\)\n/, "no value --user flag: does explain the problem" );
    $trap->stdout_like( qr/Usage/, "no value --user flag: does help" );

    # --user=
    trap { ea_sync_user_phpini_settings::run( "--user=validu", "--user=" ); };
    is_deeply( \@_process_user_args, [], "--user= flag: no users are processed" );
    $trap->exit_isnt( 0, '--user= flag: exits unclean' );
    $trap->stderr_like( qr/--user requires a value \(--user=<USER>\)\n/, "--user= flag: does explain the problem" );
    $trap->stdout_like( qr/Usage/, "--user= flag: does help" );

    # --user=<BADUSER>
    trap { ea_sync_user_phpini_settings::run( "--user=validu", "--user=baduser" ); };
    is_deeply( \@_process_user_args, [], "--user=<BADUSER> flag: no users are processed" );
    $trap->exit_isnt( 0, '--user=<BADUSER> flag : exits unclean' );
    $trap->stderr_like( qr/“baduser” is not a user on this system\n/, "--user=<BADUSER> flag: does explain the problem" );
    $trap->stdout_like( qr/Usage/, "--user=<BADUSER> flag: does help" );

    # --user=<USER> --user=<SAMEUSER>
    trap { ea_sync_user_phpini_settings::run( "--user=validu", "--user=validu2", "--user=validu" ); };
    is_deeply( \@_process_user_args, [], "duplicate value --user flags: no users are processed" );
    $trap->exit_isnt( 0, 'duplicate value --user flags: : exits unclean' );
    $trap->stderr_like( qr/Each <USER> must be unique!/, "duplicate value --user flags:: does explain the problem" );
    $trap->stdout_like( qr/Usage/, "duplicate value --user flags:: does help" );

    # --uzer=<VALIDUSER>
    trap { ea_sync_user_phpini_settings::run( "--user=validu", "--uzer=validu2" ); };
    is_deeply( \@_process_user_args, [], "unknown flags: no users are processed" );
    $trap->exit_isnt( 0, 'unknown flags: exits unclean' );
    $trap->stderr_like( qr/Unknown argument 'uzer' at/, "unknown flags: does explain the problem" );
    $trap->stdout_like( qr/Usage/, "unknown flags: does help" );

    #### happy paths process users ##
    my $return = 99;

    # --user=A
    trap { $return = ea_sync_user_phpini_settings::run("--user=validu"); return $return; };
    is_deeply( \@_process_user_args, [ ['validu'] ], "one --user=<VALIDUSER>: that user is processed" );

    # because return_is(0, "one --user=<VALIDUSER>: would exit clean") is broken
    $trap->did_return( 0, "one --user=<VALIDUSER>: returns" );
    is( $return, 0, "one --user=<VALIDUSER>: would exit clean" );
    $trap->stdout_unlike( qr/Usage/, "one --user=<VALIDUSER>: does not do help" );
    @_process_user_args = ();
    $return             = 99;

    # --user=A --user=B --user=C
    trap { $return = ea_sync_user_phpini_settings::run( "--user=validu2", "--user=validu", "--user=validu3" ); return $return };
    is_deeply( \@_process_user_args, [ ['validu2'], ['validu'], ['validu3'] ], "multiple --user=<VALIDUSER>: those users are processed in the order given" );

    # because $trap->return_is( 0, "multiple --user=<VALIDUSER>: would exit clean" ) is broken
    $trap->did_return( 0, "one --user=<VALIDUSER>: returns" );
    is( $return, 0, "one --user=<VALIDUSER>: would exit clean" );
    $trap->stdout_unlike( qr/Usage/, "multiple --user=<VALIDUSER>: does not do help" );
    @_process_user_args = ();
    $return             = 99;

}

note "User processing";
{
    my $dir             = File::Temp->newdir();
    my %user_php_config = (
        "derp.com" => { documentroot => "$dir/public_html", phpversion => "ea-php42" },
    );
    no warnings "redefine";
    local *Cpanel::PwCache::getpwnam = sub { return ( $_[0], undef, undef, undef, undef, undef, undef, $dir ) };
    local *Cpanel::PHP::Config::get_php_version_info             = sub { return { versions => [qw(ea-php42 ea-php86)], default => "ea-php99" } };
    local *Cpanel::PHP::Config::get_php_config_for_users         = sub { \%user_php_config };
    local *Cpanel::Version::get_short_release_number             = sub { 62 };
    local *Cpanel::AccessIds::do_as_user                         = sub { my ( $u, $c ) = @_; $c->() };
    local *Cpanel::ProgLang::Supported::php::get_ini             = sub { return bless( {}, 'Cpanel::ProgLang::Supported::php::Ini' ) };
    local *Cpanel::ProgLang::Supported::php::Ini::set_directives = sub { };
    use warnings "redefine";

    # user with no php.ini
    trap { _call_process_user("noini"); };
    $trap->did_return("Processing user w/out php.ini: does not exit");
    $trap->stdout_like( qr/\tNo php\.ini files found\.\n/, "Processing user w/out php.ini: informs caller that there was no php.ini to process" );

    # user w/ php.ini and public_html/php.ini public_html/ohhai/php.ini
    write_file( "$dir/php.ini",        "memory_limit = 128M" );
    write_file( "$dir/arbitrary.file", "oh hai" );
    symlink( "$dir/arbitrary.file",   "$dir/arbitrary.sym" );
    symlink( "$dir/nonexistent.file", "$dir/broken.sym" );
    mkdir("$dir/public_html");
    write_file( "$dir/public_html/realphp.ini", "memory_limit = 129M" );
    symlink( "$dir/public_html/realphp.ini", "$dir/public_html/php.ini" );
    mkdir("$dir/public_html/ohhai");
    write_file( "$dir/public_html/ohhai/php.ini", "memory_limit = 130M" );
    mkdir("$dir/arbitrary.dir");
    write_file( "$dir/arbitrary.dir/some.file", "oh hai" );
    trap { _call_process_user("multi"); };
    $trap->did_return("Processing user with multiple php.ini (directly in ~ and various depths): does not exit");
    $trap->stdout_like( qr{\tProcessing \Q$dir\E/php\.ini …},                    "php.ini directly in ~ is processed" );
    $trap->stdout_like( qr{\tProcessing \Q$dir\E/public_html/ohhai/php\.ini …},  "php.ini in subdir is processed" );
    $trap->stdout_like( qr{\tProcessing \Q$dir\E/public_html/php\.ini …},        "php.ini that is a symlink to a file os processed" );
    $trap->stdout_like( qr/\tSuccessfully processed php\.ini files: 3/,            "user summary contains count of successfully processed files" );
    $trap->stdout_like( qr/\tphp\.ini files that had errors during processing: 0/, "user summary contains count of unsuccessfully processed files" );

    # when one fails the other still happens
    {
        # Simulate arbitrary set_directives() exceptions like IO issues or  symlinks that are broken or targeted to a directory
        no warnings "redefine";
        local *Cpanel::ProgLang::Supported::php::Ini::set_directives = sub { shift; my %args = @_; die "derp $args{path}\n"; };
        trap { _call_process_user("onebroke"); };
        $trap->did_return("Processing user with multiple php.ini (directly in ~ and various depths): does not exit");
        $trap->stderr_like( qr{ERROR: derp php\.ini},                   "w/ failure php.ini directly in ~ is processed" );
        $trap->stderr_like( qr{ERROR: derp public_html/ohhai/php\.ini}, "w/ failure php.ini in subdir is processed" );
        $trap->stderr_like( qr{ERROR: derp public_html/php\.ini},       "w/ failure php.ini that is a symlink to a file os processed" );
        $trap->stdout_like( qr/\tSuccessfully processed php\.ini files: 0/,            "w/ failure user summary contains count of successfully processed files" );
        $trap->stdout_like( qr/\tphp\.ini files that had errors during processing: 3/, "w/ failure user summary contains count of unsuccessfully processed files" );
    }

    {
        # errors from iterator
        no warnings "redefine";
        local *Path::Iter::get_iterator = sub {
            my ( $dir, $opts ) = @_;
            push @{ $opts->{errors} },
              { function => "func1", args => [], error => "42: meep" },
              { function => "func2", args => [ 1, 2, 3 ], error => "47: derp" };
            return sub { };
        };
        trap { _call_process_user("fsissues"); };
        $trap->did_return("errors from iterator: does not exit");
        $trap->stdout_like( qr/\tNo php\.ini files found\./, "errors from iterator: Summary still happens" );
        $trap->stderr_like( qr/\tThe following errors occured while traversing “$dir” \(some php\.ini files may not have been processed\):/, "errors from iterator: has overall description" );
        $trap->stderr_like( qr/\t\tfunc1\(\) – 42: meep/,                                                                                      "errors from iterator: shows all errors (1)" );
        $trap->stderr_like( qr/\t\tfunc2\(1, 2, 3\) – 47: derp/,                                                                               "errors from iterator: shows all errors (2)" );
    }
}

sub _call_process_user {
    my ($user) = @_;
    my $starting_dir = Cwd::cwd();
    ea_sync_user_phpini_settings::_process_user($user);
    chdir($starting_dir) or die "Could not chdir back to $starting_dir: $!\n";
    return;
}
