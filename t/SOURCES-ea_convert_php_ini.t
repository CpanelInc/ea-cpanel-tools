#!/usr/local/cpanel/3rdparty/bin/perl

# cpanel - t/SOURCES-ea_convert_php_ini.t         Copyright(c) 2016 cPanel, Inc.
#                                                           All rights Reserved.
# copyright@cpanel.net                                         http://cpanel.net
# This code is subject to the cPanel license. Unauthorized copying is prohibited

package t::SOURCES::ea_convert_php_ini;

use parent qw( Test::Class );
use strict;
use warnings;
use lib '/usr/local/cpanel/t/lib';
use FindBin;
use Data::Dumper;
use Test::NoWarnings;
use Test::More;
use Test::Trap;
use Test::File::Contents;
use Test::Filesys;
use Cpanel::TempFile ();

# A simple ini file with a variety of use cases that will be tested in test_parse()
my $TestParseIni = <<'ENDINI';
; comment in root node
extension = php_nodeA.so
extension = php_nodeB.so
php.key1 = "value1"
php.key1 = "value2"
[NOT_EMPTY_SECTION]
; comment in not_empty_section followed by blank line (that has spaces)
     
notempty.key1 =    Off
NOTEMPTY.key1 = On
notempty.key2 = Off
[empty_section-!@#$#13432rw#^**]
[section_after_empty_section]
sectionafter.key1 = #%%&^ 4#%W$54123 3432524erwe3232

ENDINI

# NOTE: The parser doesn't correctly grab the last empty line (no spaces either) at the end of a file
my $TestRenderIni = <<'ENDINI';
; comment in root node
[PHP]
extension = php_nodeA.so
extension = php_nodeB.so
php.key1 = "value2"
[NOT_EMPTY_SECTION]
; comment in not_empty_section followed by blank line (that has spaces)
     
notempty.key1 = On
notempty.key2 = Off
[empty_section-!@#$#13432rw#^**]
[section_after_empty_section]
sectionafter.key1 = #%%&^ 4#%W$54123 3432524erwe3232
ENDINI

# begin: Parse::PHP::Ini testing

sub init : Test( startup => 1 ) {
    note "Verify the modulino script compiles";
    require_ok("$FindBin::Bin/../SOURCES/ea_convert_php_ini");
    return 1;
}

# NOTE: This verifies the existence of the 4 major interfaces.  The
# remainder of them are geared for internal use and easier mocking.
# Though, consumers may use them, they're not guaranteed to exist
# or remain backwards compatible.
sub init_parse : Test(startup => 2 ) {
    note "Verify the Parse::PHP::Ini package is in the script";
    can_ok( 'Parse::PHP::Ini', qw( new parse merge render ) );
    my $p = trap { Parse::PHP::Ini->new() };
    $trap->return_isa_ok( 0, 'Parse::PHP::Ini', 'Correctly instantiated the Parse::PHP::Ini module and got the correct type' );
    return 1;
}

sub test_ini_parse : Test(48) {
    my $p = Parse::PHP::Ini->new();

    note "parse(): Failing to pass correct arguments";
    trap { $p->parse() };
    $trap->die_isa_ok( 'Cpanel::Exception', 'Died with correct exception type' );

    note "parse(): Verifying it can parse an ini file and vaguely return something sensible";
    my $ini = trap { $p->parse( str => \$TestParseIni ) };
    $trap->return_isa_ok( 0, 'Tree::DAG_Node', 'Received the correct type of data after parsing a string' );
    is( $ini->name(),              '!_ROOT_!', 'Received the root node in the ini DAG tree' );
    is( $ini->attribute()->{type}, 'section',  'The root node is a "section" type so it can be referenced internally' );
    ok( !$ini->mother(), 'The root node should always be at the top and never have parent nodes' );

    note "parse(): Verifying each section after parsing a test ini file";

    # TODO: verify the values in each of the 'type => section' daughter nodes
    my @section_tests = (
        {
            name      => 'filler',
            attr      => { type => 'filler', value => "; comment in root node\n" },
            daughters => [],
        },
        {
            name      => 'PHP',
            attr      => { type => 'section', value => 'php' },
            daughters => [
                {
                    name => 'extension',
                    attr => { type => 'setting', value => 'php_nodeA.so' },
                },
                {
                    name => 'extension',
                    attr => { type => 'setting', value => 'php_nodeB.so' },
                },
                {
                    name => 'php.key1',
                    attr => { type => 'setting', value => '"value2"' },
                },
            ],
        },
        {
            name      => 'NOT_EMPTY_SECTION',
            attr      => { type => 'section', value => 'not_empty_section' },
            daughters => [
                {
                    name => 'filler',
                    attr => { type => 'filler', value => "; comment in not_empty_section followed by blank line (that has spaces)\n     \n" },
                },
                {
                    name => 'notempty.key1',
                    attr => { type => 'setting', key => 'notempty.key1', value => 'On' },
                },
                {
                    name => 'notempty.key2',
                    attr => { type => 'setting', key => 'notempty.key2', value => 'Off' },
                },
            ],
        },
        {
            name      => 'empty_section-!@#$#13432rw#^**',
            attr      => { type => 'section', value => 'empty_section-!@#$#13432rw#^**' },
            daughters => [],
        },
        {
            name      => 'section_after_empty_section',
            attr      => { type => 'section', value => 'section_after_empty_section' },
            daughters => [
                {
                    name => 'sectionafter.key1',
                    attr => { type => 'setting', key => 'sectionafter.key1', value => '#%%&^ 4#%W$54123 3432524erwe3232' },
                },
            ],
        }
    );

    my @sections = $ini->daughters();
    is( scalar @sections, scalar @section_tests, 'Found the correct number of sections (which should include the autogenerated components)' );

    for ( my $i = 0; $i < scalar @section_tests; $i++ ) {
        my $test   = $section_tests[$i];
        my $actual = $sections[$i];

        # NOTE: Skipping line numbers since it's really only for debugging
        is( $actual->name(), $test->{name}, "Section $i has correct name" );
        my $attr = $actual->attribute();
        is( $attr->{type},  $test->{attr}->{type},  "Section $i has correct node type" );
        is( $attr->{value}, $test->{attr}->{value}, "Section $i has correct node value" );

        my @daughters = $actual->daughters();
        is( scalar @daughters, scalar @{ $test->{daughters} }, "Section $i had correct number of filler and settings" );

        for ( my $j = 0; $j < scalar @{ $test->{daughters} }; $j++ ) {
            my $test_subnode   = $test->{daughters}->[$j];
            my $actual_subnode = $daughters[$j];

            is( $actual_subnode->name(), $test_subnode->{name}, "Section $i (subnode $j) has correct name" );
            my $actual_attr = $actual_subnode->attribute();
            is( $actual_attr->{type},  $test_subnode->{attr}->{type},  "Section $i (subnode $j) has correct node type" );
            is( $actual_attr->{value}, $test_subnode->{attr}->{value}, "Section $i (subnode $j) has correct node value" );
        }
    }

    # NOTE: Skipping file-based parsing for now

    return 1;
}

sub test_ini_render : Test( 4 ) {
    my $p = Parse::PHP::Ini->new();

    note "render(): Failing to pass correct arguments";
    trap { $p->render() };
    $trap->die_isa_ok( 'Cpanel::Exception', 'Died with correct exception type after passing no arguments' );
    trap { $p->render( {} ) };
    $trap->die_isa_ok( 'Cpanel::Exception', 'Died with correct exception when passing invalid argument' );

    note "render(): Render a previously parsed ini";
    my $ini = $p->parse( str => \$TestParseIni );    # we test parse() elsewhere, no need to repeat those tests here
    my $txtref = trap { $p->render($ini) };
    $trap->return_isa_ok( 0, 'SCALAR', 'Rendering an ini Tree::DAG_Node returns a scalar reference to the text' );
    is( $$txtref, $TestRenderIni, 'Correct rendering of a parsed ini file' );

    return 1;
}

my $TestLeftIni = << 'INI';
; left comment in root node
extension = leftA.so
extension = leftB.so
option_both.key1 = Off
option_both.dupkey2 = Off
[section_left]
section_left.key = Off
[section_both]
section_both.leftkey = Off
section_both.bothkey = Off
INI

my $TestRightIni = << 'INI';
; right comment in root node
extension = rightC.so
[php]
option_both.key3 = On

option_both.dupkey2 = On
[section_right]
section_right.key = On
[section_both]

section_both.rightkey = On
section_both.bothkey = On
INI

# NOTE: We're not merging filler (e.g. comments and spaces) from the
# right, into the left
my $TestMergeRightIntoLeft = << 'INI';
; left comment in root node
[PHP]
extension = leftA.so
extension = leftB.so
option_both.key1 = Off
option_both.dupkey2 = On
extension = rightC.so
option_both.key3 = On
[section_left]
section_left.key = Off
[section_both]
section_both.leftkey = Off
section_both.bothkey = On
section_both.rightkey = On
[section_right]
section_right.key = On
INI

my $TestMergeLeftIntoRight = << 'INI';
; right comment in root node
[PHP]
extension = rightC.so
option_both.key3 = On

option_both.dupkey2 = Off
extension = leftA.so
extension = leftB.so
option_both.key1 = Off
[section_right]
section_right.key = On
[section_both]

section_both.rightkey = On
section_both.bothkey = Off
section_both.leftkey = Off
[section_left]
section_left.key = Off
INI

my $TestMergeRightIntoLeftExclude = << 'INI';
; left comment in root node
[PHP]
extension = leftA.so
extension = leftB.so
option_both.key1 = Off
option_both.dupkey2 = On
option_both.key3 = On
[section_left]
section_left.key = Off
[section_both]
section_both.leftkey = Off
section_both.bothkey = Off
section_both.rightkey = On
[section_right]
section_right.key = On
INI

sub test_ini_merge : Test(7) {
    note "merge(): Failing to pass correct arguments";
    my $p     = Parse::PHP::Ini->new();
    my $left  = $p->parse( str => \$TestLeftIni );
    my $right = $p->parse( str => \$TestRightIni );
    trap { $p->merge() };
    $trap->die_isa_ok( 'Cpanel::Exception', 'Died when passing no arguments' );
    trap { $p->merge($left) };
    $trap->die_isa_ok( 'Cpanel::Exception', 'Died when passing only 1 argument' );
    trap { $p->merge( $left, {} ) };
    $trap->die_isa_ok( 'Cpanel::Exception', 'Died when passing 2 arguments, but 1 was an invalid type' );

    note "merge(): Verify we can merge 2 ini files together";
    my $merge_rl = trap { $p->merge( $left, $right ) };
    $trap->return_isa_ok( 0, 'Tree::DAG_Node', 'Returns correct data type (right into left)' );
    my $txtref = $p->render($merge_rl);
    is( $$txtref, $TestMergeRightIntoLeft, 'Merged the ini files correctly (right into left)' );

    my $merge_lr = trap { $p->merge( $right, $left ) };
    $trap->return_isa_ok( 0, 'Tree::DAG_Node', 'Returns correct data type (left into right)' );
    $txtref = $p->render($merge_lr);
    is( $$txtref, $TestMergeLeftIntoRight, 'Merged the ini files correctly (left into right)' );

    return 1;
}

sub test_ini_merge_exclude : Test(2) {
    note "exclude_settings(): Verify that we can merge trees, but exclude settings from the right merge tree";

    my $p     = Parse::PHP::Ini->new();
    my $left  = $p->parse( str => \$TestLeftIni );
    my $right = $p->parse( str => \$TestRightIni );

    my $merge = trap { $p->merge( $left, $right, exclude => [ { key => qr/^extension$/ }, { key => qr/\.bothkey$/, value => qr/^\s*on\s*$/i } ] ) };
    $trap->return_isa_ok( 0, 'Tree::DAG_Node', 'Returns correct data type when excluding settings while merging (right into left)' );

    my $txtref = $p->render($merge);
    is( $$txtref, $TestMergeRightIntoLeftExclude, 'Merged and filter ini files correctly (right into left)' );

    return 1;
}

# end: Parse::PHP::Ini testing

# begin: ea_convert_php_ini_file testing
sub init_config : Test( startup => 1 ) {
    note "Verify the ea_convert_php_ini_file package is in the script";
    can_ok( 'ea_convert_php_ini_file', 'main' );
    return 1;
}

sub test_config_guess_scl_package : Test(4) {
    note "guess_scl_package(): Ensure this validates the PHP package existence, or uses system default";

    my $path    = 'php.ini';
    my $default = 'default_php';
    my $hint    = 'hint_php';
    my %conf;

    no warnings qw( redefine once );
    local *Cpanel::ProgLang::Conf::new                     = sub { return bless( {}, 'fake_proglang::conf' ) };
    local *fake_proglang::conf::get_conf                   = sub { return \%conf };
    local *fake_proglang::conf::get_system_default_package = sub { return $conf{default} };

    use warnings qw( redefine once );
    trap { ea_convert_php_ini_file::guess_scl_package($path) };
    $trap->die_like( qr/Cpanel::Exception::FeatureNotEnabled/, 'Detects when PHP packages not installed' );

    my $package;
    %conf = ( $hint => 1 );
    $package = trap { ea_convert_php_ini_file::guess_scl_package( $path, $hint ) };
    $trap->return_is( 0, $hint, 'Found the "hint" package supplied by user' );

    %conf = ( default => $default );
    $package = trap { ea_convert_php_ini_file::guess_scl_package( $path, $hint ) };
    $trap->return_is( 0, $default, 'Did not find the "hint" package, so it returned the default' );

    $package = trap { ea_convert_php_ini_file::guess_scl_package($path) };
    $trap->return_is( 0, $default, 'Returned system default when no "hint" package supplied' );

    return 1;
}

sub test_config_get_php_ini : Test(5) {
    note "get_php_ini(): Verify parsing of file-based php ini configurations";

    my $tmp    = Cpanel::TempFile->new();
    my $tmpdir = $tmp->dir();

    Test::Filesys::make_structure(
        $tmpdir,
        {
            happy_path => { 'php.ini' => "extension = happy.so\n" },
            symlink_path => { 'actual.ini' => "extension = sym.so\n", 'sym.ini' => Test::Filesys::Symlink->new( undef, undef, 'actual.ini' ) },
            missing_path => {},
        }
    );

    my $ini = trap { ea_convert_php_ini_file::get_php_ini("$tmpdir/happy_path/php.ini") };
    $trap->return_isa_ok( 0, 'Tree::DAG_Node', 'Correctly parsed a normal ini file' );

    $ini = trap { ea_convert_php_ini_file::get_php_ini("$tmpdir/symlink_path/sym.ini") };
    $trap->return_nok( 0, 'Does not return a Tree::DAG_Node when trying to access an ini via symlink' );
    like( $trap->stderr, qr/Skipping/, 'Application emitted a warning when trying to access an ini via symlink' );

    $ini = trap { ea_convert_php_ini_file::get_php_ini("$tmpdir/missing_path/nothere.ini") };
    $trap->return_nok( 0, 'Does not return a Tree::DAG_Node when trying to parse a missing file' );
    like( $trap->stderr, qr/Skipping/, 'Application emitted a warning when trying to access a missing file' );

    return 1;
}

sub test_config_get_phpd_ini : Test(13) {
    note "get_phpd_ini(): Verify we can parse a directory of ini files";

    my $tmp    = Cpanel::TempFile->new();
    my $tmpdir = $tmp->dir();

    Test::Filesys::make_structure(
        $tmpdir,
        {
            happy_path => {
                'one.ini' => "[one]\n", 'two.ini' => "[two]\n", 'three.ini' => "[three]\n",
            },
            empty_dir => {},
            sym_dir   => {
                'one.ini' => "[one]\n", 'two.ini' => "[two]\n", 'sym.ini' => Test::Filesys::Symlink->new( undef, undef, "$tmpdir/happy_path/three.ini" ),
            },
            skip_dir => {
                'notini.file' => "[notini]\n", 'local.ini' => "[local]\n",
            },
        }
    );

    my $parser = Parse::PHP::Ini->new();

    trap { ea_convert_php_ini_file::get_phpd_ini("$tmpdir/missing_dir") };
    $trap->die_isa_ok( 'Cpanel::Exception', 'Died when trying to parse a directory that does not exist' );

    my $ini = trap { ea_convert_php_ini_file::get_phpd_ini("$tmpdir/happy_path") };
    $trap->return_isa_ok( 0, 'Tree::DAG_Node', 'Correctly returns a Tree::DAG_Node parse tree during in happy path' );
    for my $sec (qw( one two three )) {
        my $node = $parser->get_matching_section( $ini, $sec );
        ok( $node, "Found the '[$sec]' ini section in resulting happy_path parse tree" );
    }

    $ini = trap { ea_convert_php_ini_file::get_phpd_ini("$tmpdir/empty_dir") };
    $trap->return_isa_ok( 0, 'Tree::DAG_Node', 'Correctly returns a Tree::DAG_Node parse tree with ini dir is empty' );
    is( scalar $ini->daughters(), 0, 'Parse tree contains no entries when directory is empty' );

    $ini = trap { ea_convert_php_ini_file::get_phpd_ini("$tmpdir/sym_dir") };
    $trap->return_isa_ok( 0, 'Tree::DAG_Node', 'Correctly returns a Tree::DAG_Node parse tree with an ini dir contain files and symlinks' );
    for my $sec (qw( one two )) {
        my $node = $parser->get_matching_section( $ini, $sec );
        ok( $node, "Found the '[$sec]' ini section when dir also contains symlinks" );
    }
    ok( !$parser->get_matching_section( $ini, 'three' ), 'Parse tree does not contain the section the "[three]" section because it was a symlink' );

    $ini = trap { ea_convert_php_ini_file::get_phpd_ini("$tmpdir/skip_dir") };
    $trap->return_isa_ok( 0, 'Tree::DAG_Node', 'Correctly returns a Tree::DAG_Node when no usable ini files found' );
    is( scalar $ini->daughters(), 0, 'Parse tree properly skipped local.ini and files that do not end ini .ini' );

    return 1;
}

sub test_config_converted_php_ini : Test(5) {
    note "get_converted_php_ini(): Verifying we can merge ini files together";

    my $tmp     = Cpanel::TempFile->new();
    my $tmpdir  = $tmp->dir();
    my $package = "pkg$$";

    no warnings qw( redefine once );
    local *ea_convert_php_ini_file::get_scl_rootpath = sub { return "$tmpdir/$package/root" };
    %ea_convert_php_ini_file::SysIniCache = ();       # ensure we don't cache anything
    %ea_convert_php_ini_file::Cfg = ( force => 1 );

    use warnings qw( redefine once );

    # NOTE: This structure is set up to exercise as much of the overwriting/merging as possible
    Test::Filesys::make_structure(
        $tmpdir,
        {
            $package => {
                root => {
                    etc => {
                        'php.ini' => "extension = php.so\nkey.system = On\nkey.shared = system-set",
                        'php.d'   => {
                            'one.ini'   => "extension = one.so\nzomg.wtf = lol",
                            'two.ini'   => "extension = two.so\n",
                            'local.ini' => "extension = local.so\nkey.local = On\nkey.shared = local-set\n",
                        },
                    },
                },
            },
            'php.ini' => "extension = user.so\nkey.shared = user-set\nkey.user = On\n",
        },
    );

    my $orig = "$tmpdir/php.ini";
    my $ini = trap { ea_convert_php_ini_file::get_converted_php_ini( $orig, $package ) };
    $trap->return_isa_ok( 0, 'Tree::DAG_Node', 'Received the correct return type after attempting an EA3 to EA4 ini conversion' );

    note "write_php_ini(): Not only verify we merged ini files, but also in the correct order";

    my $new = "$tmpdir/new.ini";
    ok( !-s $new, 'File we are going to merge to does not exist before test' );
    my $ret = trap { ea_convert_php_ini_file::write_php_ini( $ini, $new ) };
    $trap->return_ok( 0, 'Returned the correct value after writing the merged ini file to disk' );

    my $txt = << 'TXT';
[PHP]
extension = one.so
zomg.wtf = lol
extension = two.so
extension = php.so
key.system = On
key.shared = user-set
extension = local.so
key.local = On
key.user = On
TXT

    ok( -s $new, 'The newly created file containing merged php ini values exists' );
    file_contents_eq_or_diff( $new, $txt, 'Successfully merged all files in the correct order' );

    return 1;
}

# end: ea_convert_php_ini_file testing

# begin: ea_convert_php_ini_system testing

package t::SOURCES::Pseudo::WebServer::Userdata;

use strict;
use warnings;
sub new { my %args = @_; return bless( \%args, shift ) }
sub id { my $self = shift; return ( $self->{user}, $$ ) }

package t::SOURCES::Pseudo::ProgLang::Conf;

use strict;
use warnings;
our %Conf;
sub new { return bless( {}, shift ) }
sub get_conf { return \%Conf }

package t::SOURCES::ea_convert_php_ini_system;

use strict;
use warnings;
use parent qw( Test::Class );
use lib '/usr/local/cpanel/t/lib';
use Mock::Cpanel::Logger ();
use FindBin;
use Data::Dumper;
use Test::NoWarnings;
use Test::More;
use Test::Trap;
use Test::MockObject;
use Test::Filesys;
use Test::File::Contents;
use Cpanel::TempFile ();

sub init : Test( startup => 1 ) {
    no warnings qw( redefine );
    *Cpanel::Logger::find_progname = sub { return __PACKAGE__ };

    use warnings qw( redefine );
    note "Verify the modulino script compiles";
    require_ok("$FindBin::Bin/../SOURCES/ea_convert_php_ini");

    return 1;
}

sub test_script : Test(2) {
    note "main(): Verifying primary script interface";

    no warnings qw( redefine once );
    local *Cpanel::Version::Compare::compare         = sub { return 0 };
    local *ea_convert_php_ini_system::process_args   = sub { return 1 };
    local *ea_convert_php_ini_system::sane_or_bail   = sub { return 1 };
    local *ea_convert_php_ini_system::convert_system = sub { return 1 };
    %ea_convert_php_ini_system::Cfg = ( action => 'sys' );

    use warnings qw( redefine once );
    can_ok( 'ea_convert_php_ini_system', 'main' );
    trap { ea_convert_php_ini_system::main() };
    $trap->exit_is( 0, 'Uses correct exit code to indicate success' );

    return 1;
}

sub test_config_cpanelversion : Test(3) {
    note "Verify execution on correct cpanel systems";

    no warnings qw( redefine );
    local $Cpanel::Version::Tiny::VERSION = '11.54.0';

    use warnings qw( redefine );
    trap { ea_convert_php_ini_system::main() };
    $trap->exit_is( 1, "Exited with failure code so users can capture using standard shell \$?" );
    like( $trap->stderr, qr/You should only run/, 'Should not run on cPanel 11.54 or older' );

    # NOTE: This will die because it validates input args after cpanel version check,
    #       but i'm not providing any, not even an array ref.  so the underlying
    #       GetOptionsFromArray call fails
    $Cpanel::Version::Tiny::VERSION = '11.56.0';
    trap { ea_convert_php_ini_system::main() };
    $trap->die_like( qr/GetOptionsFromArray/, 'Allowed to run on cPanel 11.56 and newer' );

    return 1;
}

sub test_process_args : Test(11) {
    note "process_args(): Validate correct argument parsing";

    no warnings qw( redefine once );    # once because of %Cfg var
    local *Cpanel::ProgLang::Conf::new = sub { return t::SOURCES::Pseudo::ProgLang::Conf->new() };

    use warnings qw( redefine );
    trap { ea_convert_php_ini_system::process_args() };
    $trap->did_die("Died because we didn't pass argv");

    trap { ea_convert_php_ini_system::process_args( [qw( --action foo )] ) };
    $trap->exit_is( 1, 'Exits when supplying an unknown action type' );
    like( $trap->stderr, qr/valid action/, 'Correct error message emitted when supplying an invalid action' );

    trap { ea_convert_php_ini_system::process_args( [qw( --action ini )] ) };
    $trap->exit_is( 1, 'Exits when supplying disabled ini action' );
    like( $trap->stderr, qr/Only supports/i, 'Correct error message emitted when using a disabled action' );

    trap { ea_convert_php_ini_system::process_args( [qw( --action sys --unknown )] ) };
    $trap->exit_is( 1, 'fake error' );
    like( $trap->stderr, qr/argument isn't a valid/, 'Correct error message emitted when supplying unknown argument to valid action' );

    # NOTE: Skipping required argument test since the 'sys' action doesn't currently have any
    #       required arguments.  When we implement the 'ini' action, this will need to be added.

    my $r = trap { ea_convert_php_ini_system::process_args( [qw( --action sys )] ) };
    $trap->return_ok( 0, "Lived after wanting default arguments with 'sys' action" );
    my %actual = ( action => 'sys', dryrun => 0, verbose => 1, user => [], hint => undef, state => {} );
    is_deeply( \%ea_convert_php_ini_system::Cfg, \%actual, "Default values stored after passing no additional args" );

    %t::SOURCES::Pseudo::ProgLang::Conf::Conf = ( lol => 1 );
    $r = trap { ea_convert_php_ini_system::process_args( [qw( --action sys --dryrun --quiet --user joe --user bob )] ) };
    $trap->return_ok( 0, "Lived after customizing all arguments with 'sys' action" );
    %actual = ( action => 'sys', dryrun => 1, verbose => 0, user => [qw( joe bob )], state => { lol => 1 }, hint => undef );
    is_deeply( \%ea_convert_php_ini_system::Cfg, \%actual, "Accepted all passed in command-line args" );

    return 1;
}

sub test_sane_or_bail : Test(5) {
    my ( $manual, $root );

    note "sane_or_bail(): Ensuring we bail out to prevent bad stuff";

    no warnings qw( redefine once );
    local *ea_convert_php_ini_system::is_manual = sub { return $manual };
    local *ea_convert_php_ini_system::is_root   = sub { return $root };

    use warnings qw( redefine once );
    $manual = 1;
    $root   = 1;
    trap { ea_convert_php_ini_system::sane_or_bail() };
    $trap->die_like( qr/EA3/, "Died when trying to manually run this outside of migration script" );

    $manual = 0;
    $root   = 0;
    trap { ea_convert_php_ini_system::sane_or_bail() };
    $trap->die_like( qr/must be root/, "Died when trying to run this as a non-root user" );

    no warnings qw( once );
    $manual                         = 0;
    $root                           = 1;
    %ea_convert_php_ini_system::Cfg = ();
    trap { ea_convert_php_ini_system::sane_or_bail() };
    $trap->die_like( qr/configured/, "Died when the system default php version wasn't set" );

    $manual                         = 0;
    $root                           = 1;
    %ea_convert_php_ini_system::Cfg = ( state => { default => 'awesome-perl', 'awesome-perl' => 'badhandler' } );
    trap { ea_convert_php_ini_system::sane_or_bail() };
    $trap->die_like( qr/instead of suphp/, 'Dies when the the system default PHP is assigned to something other than suphp' );

    $manual                         = 0;
    $root                           = 1;
    %ea_convert_php_ini_system::Cfg = ( state => { default => 'omgzphp', 'omgzphp' => 'suphp' } );
    my $r = trap { ea_convert_php_ini_system::sane_or_bail() };
    $trap->return_is( 0, 1, 'Validation returns success when default php version is assigned to suphp' );

    return 1;
}

sub test_convert_system : Test(4) {
    my @users;
    my @executed;

    note "convert_system(): Validate that we try to convert ini files for every users on the system";

    no warnings qw( redefine once );
    local *Cpanel::Config::userdata::load_user_list           = sub { return \@users };
    local *Cpanel::WebServer::Userdata::new                   = sub { return t::SOURCES::Pseudo::WebServer::Userdata->new(@_) };
    local *Cpanel::AccessIds::ReducedPrivileges::call_as_user = sub { my ( $sub, @id ) = @_; push @executed, $id[0] if @id };

    use warnings qw( redefine );
    @executed                       = ();
    %ea_convert_php_ini_system::Cfg = ( user => [] );
    @users                          = qw( nobody root );
    trap { ea_convert_php_ini_system::convert_system() };
    is( scalar @executed, 0, "Didn't try to convert php.ini files for the 'nobody' and 'root' users" );

    @executed                       = ();
    %ea_convert_php_ini_system::Cfg = ( user => [qw( bob )] );
    @users                          = qw( joe );
    trap { ea_convert_php_ini_system::convert_system() };
    is( scalar @executed, 0, "Didn't convert php.ini files found on system, but left unspecified via command-line" );

    @executed                       = ();
    %ea_convert_php_ini_system::Cfg = ( user => [qw( bob )] );
    @users                          = qw( bob joe );
    trap { ea_convert_php_ini_system::convert_system() };
    is_deeply( \@executed, [qw( bob )], "Only converted php.ini files for users specified via command-line" );

    @executed                       = ();
    %ea_convert_php_ini_system::Cfg = ( user => [] );
    @users                          = qw( bob joe );
    trap { ea_convert_php_ini_system::convert_system() };
    is_deeply( \@executed, [qw( bob joe )], "Converted php.ini files for all users on the system" );

    return 1;
}

sub test_get_safe_path : Test(11) {
    note "get_safe_path(): Validate safe path retrieval";

    my $tmp = Cpanel::TempFile->new();
    my $dir = $tmp->dir();

    # create various test scenarios
    Test::Filesys::make_structure(
        $dir,
        {
            'notinhome.txt' => 'a file not in the home dir',
            homedir         => {
                'regular.file'     => 'regular contents',                                                            # great success path
                'file with space'  => 'regular file as well',
                'abs_notsafe.file' => Test::Filesys::Symlink->new( undef, undef, "$dir/otherdir/other.file" ),       # points to file outside of basedir using absoluate path symlink
                'rel_notsafe.file' => Test::Filesys::Symlink->new( undef, undef, '../otherdir/other.file' ),         # points to file outside of basedir using relative symlink
                'bad-link1.file'   => Test::Filesys::Symlink->new( undef, undef, "$dir/homedir/dne$$.file" ),        # bad symlink
                'bad-link2.file'   => Test::Filesys::Symlink->new( undef, undef, "$dir/homedir/bad-link1.file" ),    # symlink points to bad symlink
                'nonregular.file'  => Test::Filesys::Symlink->new( undef, undef, 'character.file' ),                 # points to a non-regular file
                subdir             => {
                    'missing_link.file' => Test::Filesys::Symlink->new( undef, undef, "$dir/homedir/dne.file" ),        # missing dest file
                    'good_link.file'    => Test::Filesys::Symlink->new( undef, undef, "$dir/homedir/regular.file" ),    # symlink to file in basedir
                    'relative.file'     => Test::Filesys::Symlink->new( undef, undef, "../regular.file" ),              # relative symlink to good file
                },
                circular => {
                    link1 => Test::Filesys::Symlink->new( undef, undef, 'link2' ),
                    link2 => Test::Filesys::Symlink->new( undef, undef, 'link3' ),
                    link3 => Test::Filesys::Symlink->new( undef, undef, 'link1' ),
                },
            },
            otherdir => {
                'other.file' => 'other contents',
            },
        }
    );

    # Test::Filesys::make_structure doesn't support creation of character devices
    system("mknod $dir/homedir/character.file c 1 3");    # /dev/null major/minor

    my @tests = (
        { path => "$dir/homedir/regular.file",             basedir => "$dir/homedir", msg => 'Regular file is in basedir',                          ret => "$dir/homedir/regular.file" },
        { path => "$dir/homedir/abs_notsafe.file",         basedir => "$dir/homedir", msg => 'Symlink points to file outside of basedir',           ret => undef },
        { path => "$dir/homedir/bad-link2.file",           basedir => "$dir/homedir", msg => 'Symlink points to a bad symlink',                     ret => undef },
        { path => "$dir/homedir/nonregular.file",          basedir => "$dir/homedir", msg => 'Symlink points to a non-regular file',                ret => undef },
        { path => "$dir/homedir/subdir/missing_link.file", basedir => "$dir/homedir", msg => 'Symlink points to a missing file',                    ret => undef },
        { path => "$dir/homedir/subdir/good_link.file",    basedir => "$dir/homedir", msg => 'Symlink uses absolute path to point to regular file', ret => "$dir/homedir/regular.file" },
        { path => "$dir/homedir/subdir/relative.file",     basedir => "$dir/homedir", msg => 'Symlink uses relative path to point to regular file', ret => "$dir/homedir/regular.file" },
        { path => "$dir/homedir/circular/link1",           basedir => "$dir/homedir", msg => 'Circular symlink detected',                           ret => undef },
        { path => "$dir/homedir/../notinhome.txt",         basedir => "$dir/homedir", msg => "Recognizes directory traversal using ..",             ret => undef },
        { path => "$dir/homedir/./regular.file",           basedir => "$dir/homedir", msg => "Recognizes local path using \$dir/./file",            ret => "$dir/homedir/regular.file" },
        { path => "$dir/homedir/file with space",          basedir => "$dir/homedir", msg => "Recognizes a filename with spaces",                   ret => "$dir/homedir/file with space" },
    );

    for my $t (@tests) {
        my $path = ea_convert_php_ini_system::get_safe_path( $t->{path}, $t->{basedir} );
        is( $path, $t->{ret}, $t->{msg} );
    }

    return 1;
}

sub test_is_within : Test(5) {
    note "is_within(): Ensure it can properly determine when one path/directory is within another";

    my @tests = (
        { path => '/a/b/c/file.txt', basedir => '/a',        within => 1 },
        { path => '/a/b/file.txt',   basedir => '/a/b',      within => 1 },
        { path => '/x/y/file.txt',   basedir => '/a/b',      within => 0 },
        { path => '/a/file.txt',     basedir => '/',         within => 1 },
        { path => '/a/b/c/file.txt', basedir => '/a/b/c/d/', within => 0 }
    );

    for my $t (@tests) {
        my $w = ea_convert_php_ini_system::is_within( $t->{path}, $t->{basedir} );
        my $msg = $t->{within} ? 'IS' : 'IS NOT';
        is( $w, $t->{within}, "$t->{path} path $msg within the $t->{basedir} base directory" );
    }

    return 1;
}

sub test_get_suphp_configpath : Test(7) {
    my $tmp = Cpanel::TempFile->new();
    my $dir = $tmp->dir();

    note "get_suphp_configpath(): Validate parsing of .htaccess file for suPHP_Config directive";

    Test::Filesys::make_structure(
        $dir,
        {
            success => {
                'found'          => qq{\nsuPHP_ConfigPath "/some/success/found/path"},
                'lowercasefound' => qq{\nsuphp_configpath '/some/success/lowercasefound/path'\n\n#stuff},
                'noquotesfound'  => qq{\n#test\notherdirective /some/path\nsuphp_configpath /some/success/noquotesfound/path\n},
                'extraslash'     => qq{\n#test\notherdirective /some/path\nsuphp_configpath /some/success/extraslash/path//\n},
            },
            fails => {
                'baddir'      => qq{\nsuphp_configpath\n},
                'unsupported' => qq{\nsuphp_configpath \\\n/some/unsupported/path\n},
                'missingdir'  => qq{\nsome_other_dir\n\n},
            }
        }
    );

    for my $success (qw( found lowercasefound noquotesfound extraslash )) {
        my $path = ea_convert_php_ini_system::get_suphp_configpath("$dir/success/$success");
        is( $path, "/some/success/$success/path/php.ini", "Found a suphp_configpath directive within an .htaccess file (file:$success)" );
    }

    for my $fail (qw( baddir unsupported missingdir )) {
        my $path = ea_convert_php_ini_system::get_suphp_configpath("$dir/fails/$fail");
        ok( !$path, "Didn't find a valid/supported suphp_configpath directive within an .htaccess file (file:$fail)" );
    }

    return 1;
}

sub test_convert_user : Test(18) {
    my $user = "tmpbob$$";
    my @info;
    my @converted;

    note "convert_user(): Validating that this converts ini files for all domains owned by a user";

    no warnings qw( redefine once );
    local *Cpanel::ProgLang::Conf::new                = sub { return t::SOURCES::Pseudo::ProgLang::Conf->new() };
    local *Cpanel::WebServer::get_vhost_lang_packages = sub { return \@info };
    local *ea_convert_php_ini_system::convert_ini     = sub { my @in = @_; push @converted, \@in; return 1 };
    local %ea_convert_php_ini_system::Cfg = ( verbose => 1 );

    use warnings qw( redefine once );
    my $tmp = Cpanel::TempFile->new();
    my $dir = $tmp->dir();

    Test::Filesys::make_structure(
        $dir,
        {
            nohtaccess => {
                $user => { public_html => {} },
            },
            nocfgpath => {
                $user => {
                    '.htaccess' => "# a comment\n# but no suphp directives\n",
                    public_html => {
                        '.htaccess' => "# another htaccess without\na suphpconfig path directive\n",
                    },
                },
            },
            invaliddir => {
                $user => {
                    '.htaccess' => "suPHPConfig_Path    \n",
                    public_html => {
                        '.htaccess' => "\n a comment before invalid dir\nsuPHPConfig_path_lol $dir/invaliddir/$user\n",
                    },
                },
            },
            validdir_missingini => {
                $user => {
                    '.htaccess' => "suPHP_ConfigPath $dir/validdir_missingini/$user/\n",
                    public_html => {
                        '.htaccess' => "\ncomment\nsuphp_configpath \"$dir/validdir_missingini/$user/public_html\"\n",
                    },
                },
            },
            validdir => {
                $user => {
                    '.htaccess' => "suphp_configpath $dir/validdir/$user\n",
                    'php.ini'   => "$dir/validdir/$user content",
                    public_html => {
                        '.htaccess' => "\na comment before valid dir\nsUpHp_CoNfIgPaTh '$dir/validdir/$user/public_html'\n",
                        'php.ini'   => "$dir/validdir/$user/public_html content",
                    },
                },
            },
        }
    );

    my $r = trap { ea_convert_php_ini_system::convert_user($user) };
    $trap->return_is( 0, -1, "Received error return value when the home directory isn't defined" );
    like( $trap->stderr, qr/home directory/, "Warning emitted to stderr when home directory isn't defined" );
    is_deeply( \@converted, [], "Validated that no attempts to convert an ini file when home directory isn't defined" );

    my @tests = (
        {
            info => [ { homedir => "$dir/nohtaccess/$user", main_domain => 1, documentroot => "$dir/nohtaccess/$user/public_html", vhost => "vhost$user.loc" } ],
            ret => 0,
            retmsg       => "Detected when no htaccess file is present in user directory",
            stdout       => qr/suPHP_ConfigPath directive is not defined/,
            stdoutmsg    => "Received notification about no suphpconfig_path directive when htaccess file is missing",
            converted    => [],
            convertedmsg => "Validated that no attempts to convert an ini file occurred when htaccess file is missing"
        },
        {
            info => [ { homedir => "$dir/nocfgpath/$user", main_domain => 1, documentroot => "$dir/nocfgpath/$user/public_html", vhost => "vhost$user.loc" } ],
            ret => 0,
            retmsg       => "Detected when htaccess file exists, but suphpconfig_path directive is missing",
            stdout       => qr/suPHP_ConfigPath directive is not defined/,
            stdoutmsg    => "Received notification about no suphpconfig_path directive when htaccess file exists",
            converted    => [],
            convertedmsg => "Validated that no attempts to convert an ini file occurred when the suphpconfig_path wasn't defined in htaccess files",
        },
        {
            info => [ { homedir => "$dir/invaliddir/$user", main_domain => 1, documentroot => "$dir/invaliddir/$user/public_html", vhost => "vhost$user.loc" } ],
            ret => 0,
            retmsg       => "Detected when htaccess file exists, but suphpconfig_path directive is missing",
            stdout       => qr/suPHP_ConfigPath directive is not defined/,
            stdoutmsg    => "Received notification about no suphpconfig_path directive when htaccess file exists",
            converted    => [],
            convertedmsg => "Validated that no attempts to convert an ini file occurred when valid suphpconfig_path directives weren't found"
        },
        {
            info => [ { homedir => "$dir/validdir_missingini/$user", main_domain => 1, documentroot => "$dir/validdir_missingini/$user/public_html", vhost => "vhost$user.loc" } ],
            ret => 0,
            retmsg       => "Detected when suphpconfig_path directive defined, but the ini file doesn't exist",
            stdout       => qr/does not exist/,
            stdoutmsg    => "Received notification about a missing or empty ini file",
            converted    => [],
            convertedmsg => "Validated that no attempts to convert an ini file occurred when ini files are missing",
        },
        {
            info => [ { homedir => "$dir/validdir/$user", main_domain => 1, documentroot => "$dir/validdir/$user/public_html", vhost => "vhost$user.loc" } ],
            ret => 2,
            retmsg       => "Detected both suphpconfig_path directives",
            stdout       => qr//,                                                                                                 # typically we'd get output, but we're mocking the convert_ini() sub
            stdoutmsg    => "Output indicates the user's ini files were converted",
            converted    => [ [ $user, "$dir/validdir/$user/php.ini" ], [ $user, "$dir/validdir/$user/public_html/php.ini" ] ],
            convertedmsg => "Validated the correct ini files were converted",
        },
    );

    for my $t (@tests) {
        @converted = ();
        @info      = @{ $t->{info} },
          my $r = trap { ea_convert_php_ini_system::convert_user($user) },
          $trap->return_is( 0, $t->{ret}, $t->{retmsg} );
        like( $trap->stdout, $t->{stdout}, $t->{stdoutmsg} );
        is_deeply( \@converted, $t->{converted}, $t->{convertedmsg} );
    }

    return 1;
}

sub test_convert_ini : Test(21) {
    note "convert_ini(): Validating that we perform correct order of backup and/or recover during ini conversion";

    my $user = "tmpbob$$";
    my $tmp  = Cpanel::TempFile->new();
    my $dir  = $tmp->dir();

    Test::Filesys::make_structure(
        $dir,
        {
            'notempty.ini' => "stuff$$",
            'empty.ini'    => '',
        }
    );

    my $r;
    my ( $rename_ret,  @rename );
    my ( $convert_ret, @convert );

    no warnings qw( redefine once );
    local *ea_convert_php_ini_system::do_rename  = sub { @rename  = @_; return $rename_ret };
    local *ea_convert_php_ini_system::do_convert = sub { @convert = @_; return $convert_ret };
    %ea_convert_php_ini_system::Cfg = ( verbose => 1 );

    use warnings qw( redefine once );
    ( $convert_ret, $rename_ret ) = ( 1, 1 );
    Mock::Cpanel::Logger::clear_all();
    $r = trap { ea_convert_php_ini_system::convert_ini( $user, "$dir/notempty.ini" ) };
    $trap->return_ok( 0, "Lived, and return truthy value after successful ini conversion" );
    my $messages = Mock::Cpanel::Logger::get_messages('info');
    is( $messages->[0]->{level}, 'info', 'Successfully converting a PHP ini file emits a logger message of type "info"' );
    like( $messages->[0]->{message}, qr/Converted\s+/, 'Successfully converting a PHP ini file emits the correct message to stdout' );
    is_deeply( \@rename,  [ "$dir/notempty.ini",         "$dir/notempty.ini.ea3.bak" ], "Used the correct filename when renaming an ini file" );
    is_deeply( \@convert, [ "$dir/notempty.ini.ea3.bak", "$dir/notempty.ini" ],         "Correctly using renamed file for conversion so new one doesn't exist" );

    @rename = @convert = ();
    ( $convert_ret, $rename_ret ) = ( 1, 0 );
    $r = trap { ea_convert_php_ini_system::convert_ini( $user, "$dir/notempty.ini" ) };
    $trap->return_nok( 0, "Lived, and return false value when initial ini file backup fails" );
    like( $trap->stderr, qr/Unable to backup/i, "Received warning message when backup fails" );
    is_deeply( \@rename, [ "$dir/notempty.ini", "$dir/notempty.ini.ea3.bak" ], "Used the correct filenames when failing to backup an ini file" );
    is_deeply( \@convert, [], "Never called conversion when the initial backup fails" );

    @rename = @convert = ();
    ( $convert_ret, $rename_ret ) = ( 0, 1 );
    $r = trap { ea_convert_php_ini_system::convert_ini( $user, "$dir/notempty.ini" ) };
    $trap->return_nok( 0, "Lived, and return false value when convert of ini failed" );
    like( $trap->stderr, qr/Failed to convert/i, "Received warning message when conversion fails" );
    is_deeply( \@rename,  [ "$dir/notempty.ini.ea3.bak", "$dir/notempty.ini" ], "Used correct filenames when putting a file back into place after failed conversion" );
    is_deeply( \@convert, [ "$dir/notempty.ini.ea3.bak", "$dir/notempty.ini" ], "Correctly using renamed file for a failed ini conversion" );

    @rename = @convert = ();
    ( $convert_ret, $rename_ret ) = ( 1, 1 );
    $r = trap { ea_convert_php_ini_system::convert_ini( $user, "$dir/empty.ini" ) };
    $trap->return_ok( 0, "Lived, and return truthy value when file exists, but is empty" );
    like( $trap->stdout, qr/empty/i, "Received correct message when file exists, but is empty" );
    is_deeply( \@rename,  [], "Never attempted to rename an empty file" );
    is_deeply( \@convert, [], "Never attempted to convert an empty file" );

    @rename = @convert = ();
    ( $convert_ret, $rename_ret ) = ( 1, 1 );
    $r = trap { ea_convert_php_ini_system::convert_ini( $user, "$dir/missing.ini" ) };
    $trap->return_ok( 0, "Lived, and return truthy value when file is missing" );
    like( $trap->stdout, qr/missing/i, "Received correct message when file is missing" );
    is_deeply( \@rename,  [], "Never attempted to rename a missing file" );
    is_deeply( \@convert, [], "Never attempted to convert a missing file" );

    return 1;
}

sub test_do_convert : Test(6) {
    my ( $err, %args, $r );
    my ( $new, $old ) = ( "php$$.new.ini", "php$$.old.ini" );

    note "do_convert(): Verify conversion of a single ini file";

    no warnings qw( redefine once );
    local *ea_convert_php_ini_file::main = sub {
        %args = @_;
        die "$err" if $err;
        return 1;
    };

    use warnings qw( redefine );
    %args                           = ();
    %ea_convert_php_ini_system::Cfg = ( dryrun => 0, hint => 'ea-roflcopters', state => { default => 'ea-roflcopters' } );
    $err                            = undef;
    $r                              = ea_convert_php_ini_system::do_convert( $old, $new );
    is( $r, 1, 'Recognized when no errors occurred while converting an ini file' );
    is_deeply( \%args, { force => 0, in => $old, out => $new, hint => 'ea-roflcopters', state => { default => 'ea-roflcopters' } }, 'Proper arguments passed when requesting a successful ini conversion' );

    %args                           = ();
    %ea_convert_php_ini_system::Cfg = ( dryrun => 0, hint => 'ea-roflcopters', state => { default => 'ea-roflcopters' } );
    $err                            = "bad stuff happened";
    $r                              = ea_convert_php_ini_system::do_convert( $old, $new );
    is( $r, 0, 'Recognized when an error occurred while converting an ini file' );
    is_deeply( \%args, { force => 0, in => $old, out => $new, hint => 'ea-roflcopters', state => { default => 'ea-roflcopters' } }, 'Proper arguments passed when requesting a failed ini conversion' );

    %args                           = ();
    %ea_convert_php_ini_system::Cfg = ( dryrun => 1 );
    $err                            = undef;
    $r                              = ea_convert_php_ini_system::do_convert( $old, $new );
    is( $r, 1, 'When dryrun is enabled, we get a successful return value' );
    is_deeply( \%args, {}, 'Validated that ini conversion is not performed with dryrun enabled' );

    return 1;
}

sub test_do_rename : Test(9) {
    note "do_rename(): Ensure we rename files and adhere to dryrun";

    my $tmp = Cpanel::TempFile->new();
    my $dir = $tmp->dir();
    my $r;

    Test::Filesys::make_structure(
        $dir,
        {
            'good.file' => "good stuff",
            'dry.run',  => "dry stuff",
        }
    );

    no warnings qw( once );
    %ea_convert_php_ini_system::Cfg = ( dryrun => 0 );
    $r = trap { ea_convert_php_ini_system::do_rename( "$dir/good.file", "$dir/good.file.new" ) };
    $trap->return_is( 0, 1, "Lives, and returns truthy value when successfully renaming an ini file" );
    file_contents_eq_or_diff( "$dir/good.file.new", "good stuff", "Renamed file has correct contents" );
    ok( !-e "$dir/good.file", "Original file no longer exists after successful rename" );

    %ea_convert_php_ini_system::Cfg = ( dryrun => 0 );
    $r = trap { ea_convert_php_ini_system::do_rename( "$dir/missing.file", "$dir/missing.file.new" ) };
    $trap->return_is( 0, 0, "Lives, and returns false value when failing to rename an ini file" );
    ok( !-e "$dir/missing.file",     "Rename indeed fails because the original file is missing" );
    ok( !-e "$dir/missing.file.new", "And the renamed file doesn't exist since the original one doesn't" );

    %ea_convert_php_ini_system::Cfg = ( dryrun => 1 );
    $r = trap { ea_convert_php_ini_system::do_rename( "$dir/dry.run", "$dir/dry.run.new" ) };
    $trap->return_is( 0, 1, "Lives, and truthy value when renaming a file with dryrun enabled" );
    file_contents_eq_or_diff( "$dir/dry.run", "dry stuff", "Original file doesn't appear to be renamed" );
    ok( !-e "$dir/dry.run.new", "Dryrun prevent the renaming of the original file" );

    return 1;
}

# end: ea_convert_php_ini_system testing

unless (caller) {
    my $test = __PACKAGE__->new();
    plan tests => $test->expected_tests(+1);
    $test->runtests();
}

1;

__END__
