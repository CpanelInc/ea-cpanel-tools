#!/usr/local/cpanel/3rdparty/bin/perl

# cpanel - t/SOURCES-ea_install_profile.t         Copyright(c) 2016 cPanel, Inc.
#                                                           All rights Reserved.
# copyright@cpanel.net                                         http://cpanel.net
# This code is subject to the cPanel license. Unauthorized copying is prohibited

use strict;
use warnings;
use Test::More tests => 16 + 1;
use Test::NoWarnings;
use File::Temp ();
use File::Slurp 'write_file';
use Test::Trap;

use Cpanel::PackMan      ();
use Cpanel::PackMan::Sys ();
BEGIN { delete $Cpanel::PackMan::{'resolve_multi_op_ns'}; }

use FindBin;
BEGIN { require_ok("$FindBin::Bin/../SOURCES/ea_install_profile") }

my $resolve_multi_op    = 0;
my $resolve_multi_op_ns = 0;
my $multi_op            = 0;

my $dir     = File::Temp->newdir();
my $profile = "$dir/profile.$$.json";
write_file( "$dir/profile.$$.json", '{"pkgs":[1,2,3,"ea-im4reel"]}' );
my $pkgs_to_resolve;

# note: we do not local() these mocked methods
#       because we don't ever want to run them in this unit test
#       since they'd result in trying to make chnages on the system
note "test behavior when resolve_multi_op_ns() is not available (i.e. old code)";
no warnings 'redefine';
*Cpanel::PackMan::list             = sub { return "ea-im4reel" };
*Cpanel::PackMan::resolve_multi_op = sub { $pkgs_to_resolve = $_[1]; $resolve_multi_op++ };
*Cpanel::PackMan::multi_op         = sub { $multi_op++ };

die "Cpanel::PackMan::resolve_multi_op_ns() still exists!\n" if defined &Cpanel::PackMan::resolve_multi_op_ns;
trap { ea_install_profile::script( "--install", "$dir/profile.$$.json" ) };
my $stderr = $trap->stderr();
like( $stderr, qr/    \* Warning! ignored package: 1\. It is in the profile’s package list but does not exist on this server\./, "check warns about unknown packages 1" );
like( $stderr, qr/    \* Warning! ignored package: 2\. It is in the profile’s package list but does not exist on this server\./, "check warns about unknown packages 2" );
like( $stderr, qr/    \* Warning! ignored package: 3\. It is in the profile’s package list but does not exist on this server\./, "check warns about unknown packages 3" );
is_deeply( $pkgs_to_resolve, ['ea-im4reel'], "install strips out unknown packages" );
$pkgs_to_resolve = undef;    # just to be on the safe side

is( $resolve_multi_op, 1, 'resolve_multi_op() is called if resolve_multi_op_ns() is not available' );

note "test behavior when resolve_multi_op_ns() is available (i.e. new code)";
*Cpanel::PackMan::resolve_multi_op_ns = sub { $pkgs_to_resolve = $_[1]; $resolve_multi_op_ns++ };
trap { ea_install_profile::script( "--install", "$dir/profile.$$.json" ); };
$stderr = $trap->stderr();
like( $stderr, qr/    \* Warning! ignored package: 1\. It is in the profile’s package list but does not exist on this server\./, "install warns about unknown packages 1" );
like( $stderr, qr/    \* Warning! ignored package: 2\. It is in the profile’s package list but does not exist on this server\./, "install warns about unknown packages 2" );
like( $stderr, qr/    \* Warning! ignored package: 3\. It is in the profile’s package list but does not exist on this server\./, "install warns about unknown packages 3" );
is_deeply( $pkgs_to_resolve, ['ea-im4reel'], "install strips out unknown packages" );
$pkgs_to_resolve = undef;    # just to be on the safe side

is( $resolve_multi_op_ns, 1, 'resolve_multi_op_ns() called if it is available' );
is( $resolve_multi_op,    1, 'resolve_multi_op() not called if resolve_multi_op_ns() is available' );

$resolve_multi_op_ns = 0;
$resolve_multi_op    = 0;

# Test non-zero return code upon failure
my $rc;
trap { $rc = ea_install_profile::script( "--install", "$dir/this_file_does_not_exist" ) };
isnt( $rc, 0, "Non-zero return code upon error" );

my @pkgs;
my $fail_syscmd = 0;
my ( $class, $line_handler, $subcmd, $flag );
*Cpanel::PackMan::Sys::syscmd = sub {
    ( $class, $line_handler, $subcmd, $flag, @pkgs ) = @_;
    die "failed" if $fail_syscmd;
    return 1;
};
trap { ea_install_profile::script( "--firstinstall", "$dir/profile.$$.json" ); };
is_deeply( \@pkgs, ['ea-im4reel'], "--firstinstall passes the correct packages" );

Test::NoWarnings::had_no_warnings();
$fail_syscmd = 1;
trap { ea_install_profile::script( "--firstinstall", "$dir/profile.$$.json" ); };
like( join( " ", @{ $trap->warn() } ), qr/The system will fall back to doing a full install/, "If --firstinstall fails we fallback to the full version" );
Test::NoWarnings::clear_warnings();

# note "TODO: moar tests!";
