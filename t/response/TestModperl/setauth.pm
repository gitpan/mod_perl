package TestModperl::setauth;

use strict;
use warnings FATAL => 'all';

use Apache::Access ();

use Apache::Test;
use Apache::TestUtil;

use Apache::Const -compile => 'OK';

sub handler {
    my $r = shift;

    plan $r, tests => 2;

    ok t_cmp($r->auth_type(), undef, 'auth_type');

    t_server_log_error_is_expected();
    $r->get_basic_auth_pw();

    ok t_cmp($r->auth_type(), 'Basic', 'default auth_type');

    Apache::OK;
}

1;
