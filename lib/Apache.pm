package Apache;

use vars qw($VERSION);

$VERSION = "1.03";

bootstrap Apache $VERSION;

sub parse_args {
    my($wantarray,$string) = @_;
    if($wantarray) {
	return map { Apache::unescape_url($_) } split /[=&]/, $string;
    }
    $string;
}

sub content {
    my($r) = @_;
    my $ct = $r->header_in("Content-type");
    return unless $ct eq "application/x-www-form-urlencoded";
    my $buff;
    $r->read_client_block($buff, $r->header_in("Content-length"));
    parse_args(wantarray, $buff);
}

sub args {
    my($r) = @_;
    parse_args(wantarray, $r->query_string);
}

sub send_cgi_header {
    my($r, $headers) = @_;
    my $dlm = "\015?\012"; #a bit borrowed from LWP::UserAgent
    my(@headerlines) = split /$dlm/, $headers;
    my($key, $val);

    foreach (@headerlines) {
	if (/^(\S+?):\s*(.*)$/) {
	    ($key, $val) = ($1, $2);
	    last unless $key;
	    if($key eq "Status") {
		$r->status_line($val);
		next;
	    }
	    elsif($key eq "Location" and $val =~ m,^/,) {
	   #/* This redirect needs to be a GET no matter what the original
	   # * method was.
	   # */
		$r->method("GET");
		$r->method_number(0); #M_GET 
		$r->internal_redirect_handler($val);
		return 0;
	    }
	    elsif($key eq "Content-type") {
		$r->content_type($val);
		next;
	    }
	    else {
		$r->header_out($key,$val);
		next;
	    }
	} else {
	    warn "Illegal header '$_'";
	}
    }
    $r->send_http_header;
}

1;

__END__

=head1 NAME

Apache - Perl interface to the Apache server API

=head1 SYNOPSIS

   require Apache;

   #using API
   $req = Apache->request;

   $host = $req->get_remote_host;
   $user = $req->connection->user;

   $req->content_type("text/html");
   $req->send_http_header;  # actually start a reply

   $req->write_client (
        "Hey you from $host! <br>\n",
        "I bet your name is $user. <br>\n",
        "Yippe! <hr>\n",
   );

   ###################
   #or setup a CGI environment  
   $r = Apache->request;
   %ENV = $r->cgi_env;
   
   #Apache's i/o is not stream oriented
   #so you cannot print() to your script's STDOUT
   #and you cannont read() from STDIN (yet)
   $r->print (
	  "Content-type: text/html\n\n",
          "Hey you from $ENV{REMOTE_HOST}! <br>\n",
          "I bet your name is $ENV{REMOTE_USER}. <br>\n",
 	  "Yippe! <hr>\n",
   );

=head1 DESCRIPTION

This module provides a Perl interface the Apache API.
It's here mainly for 
B<mod_perl>, but may be used for other Apache modules that
wish to embed a Perl interpreter.

=head1 METHODS

=item request()

Create a request object.
This is really a request_rec * in disguise.

 $req = Apache->request;


=item get_remote_host()

Lookup the client's hostname, return it if found.

 $remote_host = $req->get_remote_host();

=item content_type()

Get or set the content type being sent to the client.

   $type = $req->content_type;
   $req->content_type("text/plain");

=item content_encoding()

Get or set the content encoding.

   $enc = $req->content_encoding;
   $req->content_encoding("gzip");

=item content_language()

Get or set the content language.

   $lang = $req->content_language;
   $req->content_language("en");

=item status()

Get or set the reply status for the client request.

   $code = $req->status; 
   $req->status(200);    

=item status_line()

Get or set the response status line.

   $resp = $req->status_line;
   $req->status_line("HTTP/1.0 200 OK");

=item header_out()

Change the value of a response header, or create a new one.

   $req->header_out("WWW-Authenticate", "Basic");

=item err_header_out()

Change the value of an error response header, or create a new one.

   $req->err_headers_out("WWW-Authenticate", "Basic");

=item no_cache()

Boolean, on or off.

   $req->no_cache(1);

=item basic_http_header()

Send the response line along with 'Server' and 'Date' headers.
  
=item send_http_header()

Send the response line and all headers to the client.
(Calls basic_http_header)

   $req->send_http_header;

=item internal_redirect_handler()

Redirect to a location in the server's namespace without 
telling the client.

   $req->internal_redirect_handler("/home/sweet/home.html");

=item read_client_block()

Read entity body sent by the client.

   %headers_in = $req->headers_in;
   $req->read_client_block($buf, $headers_in{'Content-length'});

=item read()

Friendly alias for read_client_block()

   $req->read($buf, $headers_in{'Content-length'});

=item write_client()

Send a list of data to the client.

   $req->write_client(@list_of_data);

=item print()

Friendly alias for write_client()

   $req->print(@list_of_data);

=item send_fd()

Send the contents of a file to the client.

   $req->send_fd(FILE_HANDLE);

=item log_reason()

The request failed, why??

   $req->log_reason("Because I felt like it", $req->filename);

=item log_error()

Uh, oh.

   $req->log_error("Some text that goes in the error_log");

=item cgi_env()

Setup a standard CGI environment.

  %ENV = $req->cgi_env();

NOTE: 
'GATEWAY_INTERFACE' is set to 'CGI-Perl/1.1' so you can say:

  if($ENV{GATEWAY_INTERFACE} =~ /^CGI-Perl/) {
      #do mod_perl stuff
  }
  else {
     #do normal CGI stuff
  }
 	 	
=item send_cgi_header()

Take action on certain headers including 'Status', 'Location' and
'Content-type' just as mod_cgi does, then calls send_http_header().

    $req->send_cgi_header(<<EOF);
 Location: /foo/bar
 Content-type: text/html 

 EOF


=item headers_in()

Return a %hash of client request headers.

  %headers_in = $req->headers_in();

=item header_in()

Return the value of a client header.

    $ct = $req->header_in("Content-type");


=item args()

Return the contents of the query string;
When called in a scalar context, the entire string is returned.
When called in a list context, a list of parsed key => value pairs
are returned.

  $query_string = $req->args;

  #split on '&' and '='
  %in = $req->args;

=item content()

Return the entity body as read from the client.
When called in a scalar context, the entire string is returned.
When called in a list context, a list of parsed key => value pairs
are returned.
*NOTE*: you can only ask for this once, 
as the entire body is read from the client.


 $content = $req->content;

  #split on '&' and '='
  %in = $req->content;

=item unescape_url()

Handy function for unescapes.

  Apache::unescape_url($string);

=item allow_options(), is_perlaliased() 

Methods for checking if it's ok to run a perl script. 

 if(!($r->allow_options & OPT_EXECCGI) && !$r->is_perlaliased) {
     $r->log_reason("Options ExecCGI is off in this directory", 
		    $filename);

=item more request info

   $method = $req->method;         #GET, POST, etc.
   $protocol = $req->protocol;     #HTTP/1.x
   $uri = $req->uri;               #requested uri
   $script_file = $req->filename;  #the uri->filename translation
   $path_info = $req->path_info;   #path_info

=item connection()

Return an object reference to the request connection.
This is really a conn_rec * in disguise.

 $conn = $req->connection; 
 $remote_host = $conn->remote_host;
 $remote_ip = $conn->remote_ip;
 $remote_logname = $conn->remote_logname;
 
 #The remote username if authenticated.
 $remote_user = $conn->user;

 #The authentication scheme used, if any.
 $auth_type = $conn->auth_type;

 #close connection to the client
 $conn->close;
 
=item server()

Return an object reference to the server info.
This is really a server_rec * in disguise.

 $srv = $req->server; 
 $server_admin = $srv->server_admin;
 $hostname = $srv->server_hostname;
 $port = $srv->port;


=head1 SEE ALSO

 perl(1), Apache::Registry(3), Apache::CGI(3), Apache::Debug(3), Apache::Options(3)

=head1 AUTHORS

Gisle Aas <aas@oslonett.no>
and
Doug MacEachern <dougm@osf.org> 




