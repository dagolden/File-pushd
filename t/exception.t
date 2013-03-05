#! perl

use Test::More tests => 2;

use File::Spec::Functions qw( curdir );

BEGIN { use_ok( 'File::pushd' ); }

eval {

     my $dir = tempd;

     die( "error\n" );


};

my $err = $@;

is( $err, "error\n", "destroy did not clobber \$@\n" );

