package TestAPI::request_rec;

use strict;
use warnings;# FATAL => 'all';

use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest;

use Apache::RequestRec ();
use Apache::RequestUtil ();

use APR::Finfo ();

use Apache::Const -compile => qw(OK M_GET M_PUT);
use APR::Const    -compile => qw(FINFO_NORM);

#this test module is only for testing fields in the request_rec
#listed in apache_structures.map
#XXX: GloabalRequest test should be moved elsewhere
#     as should $| test

sub handler {
    my $r = shift;

    plan $r, tests => 45;

    #Apache->request($r); #PerlOptions +GlobalRequest takes care
    my $gr = Apache->request;

    ok $$gr == $$r;

    my $newr = Apache::RequestRec->new($r->connection, $r->pool);
    Apache->request($newr);
    $gr = Apache->request;

    ok $$gr == $$newr;

    Apache->request($r);

    ok $r->pool->isa('APR::Pool');

    ok $r->connection->isa('Apache::Connection');

    ok $r->server->isa('Apache::ServerRec');

    for (qw(next prev main)) {
        ok (! $r->$_()) || $r->$_()->isa('Apache::RequestRec');
    }

    ok !$r->assbackwards;

    ok !$r->proxyreq; # see also TestModules::proxy

    ok !$r->header_only;

    ok $r->protocol =~ /http/i;

    # HTTP 1.0
    ok t_cmp $r->proto_num, 1000, 't->proto_num';

    ok t_cmp $r->hostname, $r->get_server_name, '$r->hostname';

    ok $r->request_time;

    ok $r->status_line || 1;

    ok $r->status || 1;

    ok t_cmp $r->method, 'GET', '$r->method';

    ok t_cmp $r->method_number, Apache::M_GET, '$r->method_number';

    ok $r->headers_in;

    ok $r->headers_out;

    # tested in TestAPI::err_headers_out
    ok $r->err_headers_out;

    ok $r->subprocess_env;

    ok $r->notes;

    ok $r->content_type;

    ok $r->handler;

    ok $r->ap_auth_type || 1;

    ok $r->no_cache || 1;

    ok !$r->no_local_copy;

    {
        local $| = 0;
        ok t_cmp $r->print("# buffered\n"), 11, "buffered print";
        ok t_cmp $r->print(), 0, "buffered print";

        local $| = 1;
        my $string = "# not buffered\n";
        ok t_cmp $r->print(split //, $string), length($string),
            "unbuffered print";
    }

    # GET header components
    {
        my $args      = "my_args=3";
        my $path_info = "/my_path_info";
        my $base_uri  = "/TestAPI__request_rec";

        ok t_cmp $r->unparsed_uri, "$base_uri$path_info?$args";

        ok t_cmp $r->uri, "$base_uri$path_info", '$r->uri';

        ok t_cmp $r->path_info, $path_info, '$r->path_info';

        ok t_cmp $r->args, $args, '$r->args';

        ok t_cmp $r->the_request, "GET $base_uri$path_info?$args HTTP/1.0",
            '$r->the_request';

        ok $r->filename;

        my $location = '/' . Apache::TestRequest::module2path(__PACKAGE__);
        ok t_cmp $r->location, $location, '$r->location';
    }

    # bytes_sent
    {
        $r->rflush;
        my $sent = $r->bytes_sent;
        t_debug "sent so far: $sent bytes";
        # at least 100 chars were sent already
        ok $sent > 100;
    }

    # mtime
    {
        my $mtime = (stat __FILE__)[9];
        $r->mtime($mtime);
        ok t_cmp $r->mtime, $mtime, "mtime";
    }

    # finfo
    {
        my $finfo = APR::Finfo::stat(__FILE__, APR::FINFO_NORM, $r->pool);
        $r->finfo($finfo);
        # just one field test, all accessors are fully tested in
        # TestAPR::finfo
        ok t_cmp($r->finfo->fname,
                 __FILE__,
                 '$r->finfo');
    }

    # allowed
    {
        $r->allowed(1 << Apache::M_GET);

        ok $r->allowed & (1 << Apache::M_GET);
        ok ! ($r->allowed & (1 << Apache::M_PUT));

        $r->allowed($r->allowed | (1 << Apache::M_PUT));
        ok $r->allowed & (1 << Apache::M_PUT);
    }


    # tested in other tests
    # - input_filters:    TestAPI::in_out_filters
    # - output_filters:   TestAPI::in_out_filters
    # - per_dir_config:   in several other tests
    # - content_encoding: TestAPI::content_encoding
    # - user:             TestHooks::authz / TestHooks::authen

    # XXX: untested
    # - request_config
    # - content_languages
    # - allowed_xmethods
    # - allowed_methods

    Apache::OK;
}

1;
__END__
PerlOptions +GlobalRequest
