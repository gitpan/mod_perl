use Apache ();
use strict;

my $tests = 21;
my $i;
my $r = Apache->request;
$r->content_type("text/plain");
$r->send_http_header;
$r->print("1..$tests\n");

sub test { 
    Apache->request->
	print(sprintf "%s", $_[1] ? "ok $_[0]\n" : "not ok $_[0]\n");
}

%ENV = $r->cgi_env;

test ++$i, $ENV{GATEWAY_INTERFACE};
test ++$i, $r->seqno;
test ++$i, $r->protocol;
#hostname
test ++$i, $r->status;
test ++$i, $r->status_line;
test ++$i, $r->method eq "GET";
#test ++$i, $r->method_number

my(%headers_in) = $r->headers_in;
test ++$i, keys %headers_in;
test ++$i, $r->header_in('UserAgent') || $r->header_in('User-Agent');
$r->header_in('X-Hello' => "goodbye");
test ++$i, $r->header_in("X-Hello") eq "goodbye";

$r->header_out('X-Camel-Message' => "I can fly"); 
test ++$i, $r->header_out("X-Camel-Message") eq "I can fly";
my(%headers_out) = $r->headers_out;
test ++$i, keys %headers_out;

my(%err_headers_out) = $r->headers_out;
test ++$i, keys %err_headers_out;
#test ++$i, $r->err_header_out("Content-Type");
$r->err_header_out('X-Die' => "uhoh"); 
#$r->err_headers_out('X-Die' => "uhoh"); #test compatible
test ++$i, $r->err_header_out("X-Die") eq "uhoh";

test ++$i, $r->content_type;
test ++$i, $r->handler;
#content_encoding
#content_language
#no_cache
#test ++$i, $r->uri;
#test ++$i, $r->filename;
#test ++$i, $r->path_info;
#test ++$i, $r->query_string;

#dir_config

my $c = $r->connection;
test ++$i, $c;
test ++$i, $c->remote_ip;
#Connection::remote_host
#Connection::remote_logname
#Connection::user
#Connection::auth_type

my $s = $r->server;
test ++$i, $s;
test ++$i, $s->server_admin;
test ++$i, $s->server_hostname;
test ++$i, $s->port;
