package TestAPR::threadmutex;

use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestUtil;

use Apache2::Const -compile => 'OK';

use TestAPRlib::threadmutex;

sub handler {
    my $r = shift;

    my $tests = TestAPRlib::threadmutex::num_of_tests();
    plan $r, tests => $tests, need_threads;

    TestAPRlib::threadmutex::test();

    Apache2::Const::OK;
}

1;
