package Apache;

#use vars qw($VERSION);

$VERSION = "1.00";

bootstrap Apache;

$VERSION;

__END__

=head1 NAME

Apache - Perl interface to the Apache server API

=head1 SYNOPSIS

   use Apache ();

   #using API
   $req = Apache->request;

   $host = $req->connection->remote_host;
   $user = $req->connection->user;

   $req->content_type("text/html");
   $req->send_http_header;  # actually start a reply

   $req->write_client (
        "Hey you from $host! <br>\n",
        "I bet your name is $user. <br>\n",
        "Yippe! <hr>\n",
   );

   ###################
   #or setup standard CGI   

   %ENV = Apache->request->cgi_env;
   
   #NOTE: this is broken right now
   print (
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

=head2 request()

Create a request object.
This is really a request_rec * in disguise.

 $req = Apache->request;


=head2 get_remote_host()

Lookup the client's hostname, return it if found.

 $remote_host = $req->get_remote_host();

=head2 content_type()

Get or set the content type being sent to the client.

   $type = $req->content_type;
   $req->content_type("text/plain");

=head2 content_encoding()

Get or set the content encoding.

   $enc = $req->content_encoding;
   $req->content_encoding("gzip");

=head2 content_language()

Get or set the content language.

   $lang = $req->content_language;
   $req->content_language("en");

=head2 status()

Get or set the reply status for the client request.

   $code = $req->status; 
   $req->status(200);    

=head2 status_line()

Get or set the response status line.

   $resp = $req->status_line;
   $req->status_line("HTTP/1.0 200 OK");

=head2 header_out()

Change the value of a response header, or create a new one.

   $req->header_out("WWW-Authenticate", "Basic");

=head2 err_header_out()

Change the value of an error response header, or create a new one.

   $req->err_headers_out("WWW-Authenticate", "Basic");

=head2 no_cache()

Boolean, on or off.

   $req->no_cache(1);

=head2 send_http_header()

Send the response line and headers to the client.

   $req->send_http_header;

=head2 read_client_block()

Read entity body sent by the client.

   %headers_in = $req->headers_in;
   $req->read_client_block($buf, $headers_in{'Content-length'});

=head2 write_client()

Send a list of data to the client.

   $req->write_client(@list_of_data);

=head2 print()

Friendly alias for write_client()

   $req->print(@list_of_data);

=head2 send_fd()

Send the contents of a file to the client.

   $req->send_fd(FILE_HANDLE);

=head2 log_reason()

The request failed, why??

   $req->log_reason("Because I felt like it", $req->filename);

=head2 log_error()

Uh, oh.

   $req->log_error("Some text that goes in the error_log");

=head2 cgi_env()

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
 	 	
=head2 headers_in()

Return a %hash of client request headers.

  %headers_in = $req->headers_in();

=head2 args()

Return the contents of the query string;
When called in a scalar context, the entire string is returned.
When called in a list context, a list of parsed key => value pairs
are returned.

  $query_string = $req->args;

  #split on '&' and '='
  %in = $req->args;

=head2 content()

Return the entity body as read from the client.
When called in a scalar context, the entire string is returned.
When called in a list context, a list of parsed key => value pairs
are returned.
Note that you can only ask for this once, 
as the entire body is read from the client.


 $content = $req->content;

  #split on '&' and '='
  %in = $req->content;

=head2 more request info

   $method = $req->method;         #GET, POST, etc.
   $protocol = $req->protocol;     #HTTP/1.x
   $uri = $req->uri;               #requested uri
   $script_file = $req->filename;  #the uri->filename translation
   $path_info = $req->path_info;   #path_info

=head2 connection()

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

=head2 server()

Return an object reference to the server info .
This is really a server_rec * in disguise.

 $srv = $req->server; 
 $server_admin = $srv->server_admin;
 $hostname = $srv->server_hostname;
 $port = $srv->port;


=head1 NOTES on mod_perl

The script can trigger errors by exit'ing with a HTTP status code (the perl
exit value is used as return value from the apache handler).

   exit 403;  # Forbidden

=head1 AUTHORS

Gisle Aas <aas@oslonett.no>
and
Doug MacEachern <dougm@osf.org> 




