#!/usr/local/cpanel/3rdparty/bin/perl

# cpanel - t/SOURCES-ea_install_profile.t         Copyright(c) 2016 cPanel, Inc.
#                                                           All rights Reserved.
# copyright@cpanel.net                                         http://cpanel.net
# This code is subject to the cPanel license. Unauthorized copying is prohibited

use strict;
use warnings;
use Test::More tests => 4 + 1;
use Test::NoWarnings;
use File::Temp ();
use File::Slurp 'write_file';
use Capture::Tiny 'capture';

use Cpanel::PackMan ();
BEGIN { delete $Cpanel::PackMan::{'resolve_multi_op_ns'}; }

use FindBin;
BEGIN { require_ok("$FindBin::Bin/../SOURCES/ea_install_profile") }

my $resolve_multi_op    = 0;
my $resolve_multi_op_ns = 0;
my $multi_op            = 0;

my $dir     = File::Temp->newdir();
my $profile = "$dir/profile.$$.json";
write_file( "$dir/profile.$$.json", '{"pkgs":[1,2,3]}' );

# note: we do not local() these mocked methods
#       because we don't ever want to run them in this unit test
#       since they'd result in trying to make chnages on the system
note "test behavior when resolve_multi_op_ns() is not available (i.e. old code)";
no warnings 'redefine';
*Cpanel::PackMan::resolve_multi_op = sub { $resolve_multi_op++ };
*Cpanel::PackMan::multi_op         = sub { $multi_op++ };

die "Cpanel::PackMan::resolve_multi_op_ns() still exists!\n" if defined &Cpanel::PackMan::resolve_multi_op_ns;
capture { ea_install_profile::script( "--install", "$dir/profile.$$.json" ) };
is( $resolve_multi_op, 1, 'resolve_multi_op() is called if resolve_multi_op_ns() is not available' );

note "test behavior when resolve_multi_op_ns() is available (i.e. new code)";
*Cpanel::PackMan::resolve_multi_op_ns = sub { $resolve_multi_op_ns++ };
capture { ea_install_profile::script( "--install", "$dir/profile.$$.json" ); };

is( $resolve_multi_op_ns, 1, 'resolve_multi_op_ns() called if it is available' );
is( $resolve_multi_op,    1, 'resolve_multi_op() not called if resolve_multi_op_ns() is available' );

# note "TODO: moar tests!";
