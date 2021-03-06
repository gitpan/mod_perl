package TestModperl::readline;

use strict;
use warnings FATAL => 'all';

use Apache2::RequestIO ();
use Apache2::compat (); #XXX

use Apache::Test;

use Apache2::Const -compile => 'OK';

sub handler {
    my $r = shift;

    untie *STDIN;
    tie *STDIN, $r;

    while (defined(my $line = <STDIN>)) {
        $r->puts($line);
    }

    untie *STDIN;

    Apache2::Const::OK;
}

1;
