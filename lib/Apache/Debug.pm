package Apache::Debug;

#from HTTP::Status
my %StatusCode = (
    100 => 'Continue',
    101 => 'Switching Protocols',
    200 => 'OK',
    201 => 'Created',
    202 => 'Accepted',
    203 => 'Non-Authoritative Information',
    204 => 'No Content',
    205 => 'Reset Content',
    206 => 'Partial Content',
    300 => 'Multiple Choices',
    301 => 'Moved Permanently',
    302 => 'Moved Temporarily',
    303 => 'See Other',
    304 => 'Not Modified',
    305 => 'Use Proxy',
    400 => 'Bad Request',
    401 => 'Unauthorized',
    402 => 'Payment Required',
    403 => 'Forbidden',
    404 => 'Not Found',
    405 => 'Method Not Allowed',
    406 => 'None Acceptable',
    407 => 'Proxy Authentication Required',
    408 => 'Request Timeout',
    409 => 'Conflict',
    410 => 'Gone',
    411 => 'Length Required',
    412 => 'Unless True',
    500 => 'Internal Server Error',
    501 => 'Not Implemented',
    502 => 'Bad Gateway',
    503 => 'Service Unavailable',
    504 => 'Gateway Timeout',
);

sub dump {
    my($r, $status) = (shift,shift);
    my $srv  = $r->server;
    my $conn = $r->connection;
    my %headers = $r->headers_in;
    my $host = $r->get_remote_host;

    $r->content_type("text/html");
    $r->header_out("Status",$status);
    $r->send_http_header;

    my $args = $r->args;
    my(%args,%in);
    my $title = "$status $StatusCode{$status}";
    $r->write_client(join("\n", "<html>",
			  "<head><title>$title</title></head>",
                          "<body>", "<h3>$title</h3>", @_, 
			  "<pre>", ($@ ? "$@\n" : "")));
    for (
	 qw(
	    method uri protocol path_info filename 
	    )
	 )
    {
	$r->write_client("$_ : ", $r->$_(), "\n");
    }
    for (
	 qw(
	    server_admin 
	    server_hostname port
	    )
	 ) 
    {
	$r->write_client("$_ : ", $srv->$_(), "\n");
    }
    for (
	 qw(
	    remote_host remote_ip
	    )
	 )
    {
	$r->write_client("$_ : ", $conn->$_(), "\n");
    }
    $r->write_client(
		     "\nscalar \$r->args:\n $args\n",
			 
		     "\n\$r->args:\n",		     
		     (map { "$_ = $args{$_}\n" } keys %args),
			 
		     "\n\$r->content:\n",		     
		     (map { "$_ = $in{$_}\n" } keys %in),
			 
		     "\n\$r->headers_in:\n",		     
		     (map { "$_ = $headers{$_}\n" } keys %headers),
		     );
    $r->write_client("</pre>\n</body></html>");
    return 0; #need to give a return status
}

1;

__END__

=head1 NAME

Apache::Debug - Utilities for debugging embedded perl code

=head1 SYNOPSIS

    require Apache::Debug;

    Apache::Debug::dump(Apache->request, 500, "Uh Oh!");

=head1 DESCRIPTION

This module sends what may be helpful debugging info to the client
rather that the error log.

