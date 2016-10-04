use strict;
use warnings;
use Test::More 0.96;
use File::pushd;

my @warnings;

$SIG{__WARN__} = sub {
    push @warnings, $_[0];
};

{
    no warnings 'void';

    @warnings = ();
    pushd; # Calling in void context
    is_deeply(\@warnings, [], 'no warning if "void" category disabled');
    @warnings = ();
    tempd; # Calling in void context
    is_deeply(\@warnings, [], 'no warning if "void" category disabled');

    @warnings = ();
}

{
    no warnings;
    use warnings 'void';

    @warnings = ();
    pushd; # Calling in void context
    is_deeply(\@warnings, ['Useless use of File::pushd::pushd in void context at '.__FILE__.' line '.(__LINE__-1).".\n"], 'warning if "void" category enabled');

    @warnings = ();
    tempd; # Calling in void context
    is_deeply(\@warnings, ['Useless use of File::pushd::tempd in void context at '.__FILE__.' line '.(__LINE__-1).".\n"], 'warning if "void" category enabled');

    @warnings = ();
}


done_testing;
