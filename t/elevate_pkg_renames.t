#!/usr/local/cpanel/3rdparty/bin/perl

# cpanel - t/elevate_pkg_renames.t                 Copyright(c) 2026 cPanel, Inc.
#                                                           All rights Reserved.
# copyright@cpanel.net                                         http://cpanel.net
# This code is subject to the cPanel license. Unauthorized copying is prohibited

use strict;
use warnings;
use Test::More;
use Test::Trap;
use File::Temp ();
use FindBin;

BEGIN { require_ok("$FindBin::Bin/../elevate_pkg_renames") }

my $dir = File::Temp->newdir();
my $json_file = "$dir/target-os-pkg-renames.json";
local $elevate_pkg_renames::json_file = $json_file;

###############
## list empty
###############

note "list with no file";
trap { elevate_pkg_renames::run('list') };
is( $trap->stdout(), "No package renames defined.\n", "list with no file prints empty message" );
is( $trap->exit(),   undef,                           "list does not exit" );

###############
## add
###############

note "add a mapping";
trap { elevate_pkg_renames::run( 'add', '--os=CentOS_9', '--from=ea-old-pkg', '--to=ea-new-pkg' ) };
like( $trap->stdout(), qr/Added: CentOS_9: ea-old-pkg -> ea-new-pkg/, "add prints confirmation" );
ok( -f $json_file, "JSON file was created" );

note "add duplicate fails";
trap { elevate_pkg_renames::run( 'add', '--os=CentOS_9', '--from=ea-old-pkg', '--to=ea-new-pkg' ) };
like( $trap->die(), qr/Mapping already exists/, "add duplicate dies with appropriate message" );

note "add to a different OS";
trap { elevate_pkg_renames::run( 'add', '--os=CentOS_8', '--from=ea-legacy', '--to=ea-modern' ) };
like( $trap->stdout(), qr/Added: CentOS_8: ea-legacy -> ea-modern/, "add to different OS works" );

note "add missing required opts";
trap { elevate_pkg_renames::run( 'add', '--os=CentOS_9', '--from=ea-foo' ) };
like( $trap->die(), qr/'add' requires --to=VALUE/, "add without --to dies" );

###############
## list
###############

note "list all";
trap { elevate_pkg_renames::run('list') };
my $out = $trap->stdout();
like( $out, qr/CentOS_8:/, "list shows CentOS_8 section" );
like( $out, qr/CentOS_9:/, "list shows CentOS_9 section" );
like( $out, qr/ea-old-pkg -> ea-new-pkg/, "list shows the CentOS_9 mapping" );
like( $out, qr/ea-legacy -> ea-modern/, "list shows the CentOS_8 mapping" );

note "list filtered by OS";
trap { elevate_pkg_renames::run( 'list', '--os=CentOS_9' ) };
$out = $trap->stdout();
like( $out, qr/CentOS_9:/, "filtered list shows target OS" );
unlike( $out, qr/CentOS_8:/, "filtered list hides other OS" );

note "list filtered by nonexistent OS";
trap { elevate_pkg_renames::run( 'list', '--os=CentOS_7' ) };
like( $trap->stdout(), qr/No renames defined for CentOS_7/, "filtered list for missing OS shows message" );

###############
## edit
###############

note "edit existing mapping";
trap { elevate_pkg_renames::run( 'edit', '--os=CentOS_9', '--from=ea-old-pkg', '--to=ea-newer-pkg' ) };
like( $trap->stdout(), qr/Updated:.*ea-new-pkg \(was\) => ea-newer-pkg \(now\)/, "edit prints old and new values" );

note "verify edit took effect";
trap { elevate_pkg_renames::run( 'list', '--os=CentOS_9' ) };
like( $trap->stdout(), qr/ea-old-pkg -> ea-newer-pkg/, "list confirms edit" );

note "edit nonexistent mapping fails";
trap { elevate_pkg_renames::run( 'edit', '--os=CentOS_9', '--from=ea-nonexistent', '--to=ea-whatever' ) };
like( $trap->die(), qr/No mapping found.*Use 'add'/s, "edit nonexistent dies with helpful message" );

###############
## remove
###############

note "remove existing mapping";
trap { elevate_pkg_renames::run( 'remove', '--os=CentOS_9', '--from=ea-old-pkg' ) };
like( $trap->stdout(), qr/Removed: CentOS_9: ea-old-pkg -> ea-newer-pkg/, "remove prints confirmation" );

note "verify remove cleaned up empty OS section";
trap { elevate_pkg_renames::run('list') };
$out = $trap->stdout();
unlike( $out, qr/CentOS_9:/, "CentOS_9 section removed when empty" );
like( $out, qr/CentOS_8:/, "CentOS_8 section still present" );

note "remove nonexistent mapping fails";
trap { elevate_pkg_renames::run( 'remove', '--os=CentOS_9', '--from=ea-old-pkg' ) };
like( $trap->die(), qr/No mapping found/, "remove nonexistent dies" );

###############
## usage / help
###############

note "no command shows usage";
trap { elevate_pkg_renames::run() };
like( $trap->stdout(), qr/Usage:/, "no command prints usage" );
is( $trap->leaveby(), 'return', "no command returns normally" );

note "unknown command shows usage and returns non-zero";
my $rc;
trap { $rc = elevate_pkg_renames::run('bogus') };
like( $trap->stdout(), qr/Usage:/, "unknown command prints usage" );
is( $rc, 1, "unknown command returns 1" );

note "--help shows usage";
trap { elevate_pkg_renames::run( 'add', '--help' ) };
like( $trap->stdout(), qr/Usage:/, "--help prints usage" );

note "unknown argument dies";
trap { elevate_pkg_renames::run( 'list', 'garbage' ) };
like( $trap->die(), qr/Unknown argument/, "unknown argument dies" );

###############
## add with --ignore-deps
###############

note "add a mapping with --ignore-deps";
trap { elevate_pkg_renames::run( 'add', '--os=CentOS_9', '--from=ea-rename-pkg', '--to=ea-renamed-pkg', '--ignore-deps=ea-dep1,/^ea-dep2/' ) };
like( $trap->stdout(), qr/Added: CentOS_9: ea-rename-pkg -> ea-renamed-pkg/, "add with --ignore-deps prints confirmation" );

note "list shows ignore_deps";
trap { elevate_pkg_renames::run( 'list', '--os=CentOS_9' ) };
$out = $trap->stdout();
like( $out, qr/ea-rename-pkg -> ea-renamed-pkg/, "list shows the rename" );
like( $out, qr/ignore: ea-dep1/, "list shows literal ignore dep" );
like( $out, qr{ignore: /\^ea-dep2/}, "list shows regex ignore dep" );

###############
## add-ignore
###############

note "add-ignore to existing rename";
trap { elevate_pkg_renames::run( 'add-ignore', '--os=CentOS_8', '--from=ea-legacy', '--dep=ea-legacy-lib' ) };
like( $trap->stdout(), qr/Added ignore dep: CentOS_8: ea-legacy: ea-legacy-lib/, "add-ignore prints confirmation" );

note "add-ignore another pattern";
trap { elevate_pkg_renames::run( 'add-ignore', '--os=CentOS_8', '--from=ea-legacy', '--dep=/^ea-legacy-ruby/' ) };
like( $trap->stdout(), qr{Added ignore dep: CentOS_8: ea-legacy: /\^ea-legacy-ruby/}, "add-ignore regex prints confirmation" );

note "list shows added ignore_deps";
trap { elevate_pkg_renames::run( 'list', '--os=CentOS_8' ) };
$out = $trap->stdout();
like( $out, qr/ea-legacy -> ea-modern/, "list shows rename" );
like( $out, qr/ignore: ea-legacy-lib/, "list shows first ignore dep" );
like( $out, qr{ignore: /\^ea-legacy-ruby/}, "list shows second ignore dep" );

note "add-ignore duplicate fails";
trap { elevate_pkg_renames::run( 'add-ignore', '--os=CentOS_8', '--from=ea-legacy', '--dep=ea-legacy-lib' ) };
like( $trap->die(), qr/Ignore pattern already exists/, "add-ignore duplicate dies" );

note "add-ignore to nonexistent rename fails";
trap { elevate_pkg_renames::run( 'add-ignore', '--os=CentOS_8', '--from=ea-nonexistent', '--dep=ea-foo' ) };
like( $trap->die(), qr/No mapping found/, "add-ignore nonexistent dies" );

note "add-ignore missing --dep fails";
trap { elevate_pkg_renames::run( 'add-ignore', '--os=CentOS_8', '--from=ea-legacy' ) };
like( $trap->die(), qr/'add-ignore' requires --dep=VALUE/, "add-ignore without --dep dies" );

###############
## remove-ignore
###############

note "remove-ignore existing pattern";
trap { elevate_pkg_renames::run( 'remove-ignore', '--os=CentOS_8', '--from=ea-legacy', '--dep=ea-legacy-lib' ) };
like( $trap->stdout(), qr/Removed ignore dep: CentOS_8: ea-legacy: ea-legacy-lib/, "remove-ignore prints confirmation" );

note "verify remove-ignore cleaned up";
trap { elevate_pkg_renames::run( 'list', '--os=CentOS_8' ) };
$out = $trap->stdout();
unlike( $out, qr/ignore: ea-legacy-lib/, "removed ignore dep no longer shown" );
like( $out, qr{ignore: /\^ea-legacy-ruby/}, "other ignore dep still present" );

note "remove-ignore last pattern collapses to simple string";
trap { elevate_pkg_renames::run( 'remove-ignore', '--os=CentOS_8', '--from=ea-legacy', '--dep=/^ea-legacy-ruby/' ) };
like( $trap->stdout(), qr/Removed ignore dep/, "remove last ignore dep works" );

trap { elevate_pkg_renames::run( 'list', '--os=CentOS_8' ) };
$out = $trap->stdout();
unlike( $out, qr/ignore:/, "no ignore_deps shown after removing all" );
like( $out, qr/ea-legacy -> ea-modern/, "rename still present" );

note "remove-ignore nonexistent pattern fails";
trap { elevate_pkg_renames::run( 'remove-ignore', '--os=CentOS_8', '--from=ea-legacy', '--dep=ea-nonexistent' ) };
like( $trap->die(), qr/No ignore_deps defined/, "remove-ignore from collapsed simple rename dies" );

note "remove-ignore from rename with no ignore_deps fails";
trap { elevate_pkg_renames::run( 'remove-ignore', '--os=CentOS_8', '--from=ea-legacy', '--dep=ea-foo' ) };
like( $trap->die(), qr/No ignore_deps defined/, "remove-ignore from simple rename dies" );

###############
## edit preserves ignore_deps
###############

note "add ignore_deps to a rename, then edit the rename target";
trap { elevate_pkg_renames::run( 'add-ignore', '--os=CentOS_8', '--from=ea-legacy', '--dep=ea-legacy-lib' ) };
trap { elevate_pkg_renames::run( 'edit', '--os=CentOS_8', '--from=ea-legacy', '--to=ea-modern-v2' ) };
like( $trap->stdout(), qr/Updated:.*ea-modern \(was\) => ea-modern-v2 \(now\)/, "edit prints old and new values" );

trap { elevate_pkg_renames::run( 'list', '--os=CentOS_8' ) };
$out = $trap->stdout();
like( $out, qr/ea-legacy -> ea-modern-v2/, "edit updated rename target" );
like( $out, qr/ignore: ea-legacy-lib/, "edit preserved existing ignore_deps" );

note "edit with --ignore-deps replaces the list";
trap { elevate_pkg_renames::run( 'edit', '--os=CentOS_8', '--from=ea-legacy', '--to=ea-modern-v3', '--ignore-deps=ea-replaced-dep' ) };
trap { elevate_pkg_renames::run( 'list', '--os=CentOS_8' ) };
$out = $trap->stdout();
like( $out, qr/ea-legacy -> ea-modern-v3/, "edit updated target again" );
like( $out, qr/ignore: ea-replaced-dep/, "edit replaced ignore_deps" );
unlike( $out, qr/ignore: ea-legacy-lib/, "old ignore_deps gone" );

done_testing();
