use strict;
use warnings;
use Test::More;
use File::pushd;

eval {
    my $dir = tempd;
    die("error\n");
};

my $err = $@;
is( $err, "error\n", "destroy did not clobber \$@\n" );

done_testing;
# COPYRIGHT
# vim: ts=4 sts=4 sw=4 et:
