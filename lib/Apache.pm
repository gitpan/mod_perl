package Apache;

use vars qw($VERSION);
use Apache::Constants ();

$VERSION = "1.07";

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
    $r->read($buff, $r->header_in("Content-length"));
    parse_args(wantarray, $buff);
}

sub args {
    my($r) = @_;
    parse_args(wantarray, $r->query_string);
}

sub read {
    my($r, $bufsiz) = @_[0,2];
    my($nrd, $buf);
    while($bufsiz) {
	$nrd = $r->read_client_block($buf, $bufsiz);
	if($nrd > 0) {
	    $bufsiz -= $nrd;
	    $_[1] .= $buf;
	    next if $bufsiz;
	    last;
	}
	else {
	    $_[1] = undef;
	}
    }
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
	    elsif($key eq "Location") {
		if($val =~ m,^/,) {
		    #/* This redirect needs to be a GET no 
                    #   matter what the original
		    # * method was.

		    $r->method("GET");
		    $r->method_number(0); #M_GET 
		    $r->internal_redirect_handler($val);
		    return OK;
		}
		else {
		    $r->header_out(Location => $val);
		    $r->status(302);
		    next;
		}
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

=head1 DESCRIPTION

This module provides a Perl interface the Apache API.  It's here
mainly for B<mod_perl>, but may be used for other Apache modules that
wish to embed a Perl interpreter.  We suggest that you also consult
the description of the Apache C API at http://www.apache.org/docs/.

=head1 THE REQUEST OBJECT

The request object holds all the information that the server needs to
service a request.  Apache B<Perl*Handler>s will be given a reference to the
request object as parameter and may choose update or use it in various
ways.  Most of the methods described below obtain information from or
updates the request object.
The perl version of the request object will be blessed into the B<Apache> 
package, it is really a C<request_rec *> in disguise.

=over 4

=item Apache->request

The Apache->request method will create a request object and return a
reference to it.  

=item $r->main

If the current request is a sub-request, this method returns a blessed 
reference to the main request structure.

=item $r->is_main

Returns true if the current request object is for the main request.

=back

=head1 CLIENT REQUEST PARAMETERS

First we will take a look at various methods that can be used to
retrieve the request parameters sent from the client.
In the following examples, B<$r> is a request object blessed into the 
B<Apache> class, obtained by a handler's first parameter or I<Apache-E<gt>request>

=over 4

=item $r->method( [$meth] )

The $r->method method will return the request method.  It will be a
string such as "GET", "HEAD" or "POST".
Passing an argument will set the method, mainly used for internal redirects.

=item $r->method_number( [$num] )

The $r->method_number method will return the request method number.
Each number corresponds to a string representation such as 
"GET", "HEAD" or "POST".
Passing an argument will set the method_number, mainly used for internal redirects and testing authorization restriction masks.

=item $r->proxyreq

Returns true if the request is proxy http.
Mainly used during the filename translation stage of the request, 
which may be handled by a C<PerlTransHandler>.

=item $r->protocol

The $r->protocol method will return a string identifying the protocol
that the client speaks.  Typical values will be "HTTP/1.0" or
"HTTP/1.1".

=item $r->uri( [$uri] )

The $r->uri method will return the requested URI, optionally changing
it with the first argument.

=item $r->filename( [$filename] )

The $r->filename method will return the result of the I<URI --E<gt>
filename> translation, optionally changing it with the first argument
if you happen to be doing the translation.

=item $r->path_info( [$path_info] )

The $r->path_info method will return what's left in the path after the
I<URI --E<gt> filename> translation, optionally changing it with the first 
argument if you happen to be doing the translation.

=item $r->args

The $r->args method will return the contents of the URI's I<query
string>.  When called in a scalar context, the entire string is
returned.  When called in a list context, a list of parsed I<key> =>
I<value> pairs are returned, i.e. it can be used like this:

  $query = $req->args;
  %in    = $req->args;

=item $r->headers_in

The $r->headers_in method will return a %hash of client request
headers.  This can be used to initialize a perl hash, or one could use
the $r->header_in() method (described below) to retrieve a specific
header value directly.

=item $r->header_in( $header_name )

Return the value of a client header.  Can be used like this:

  $ct = $req->header_in("Content-type");

=item $r->content

The $r->content method will return the entity body read from the
client, but only if the request content type is
C<application/x-www-form-urlencoded>.
When called in a scalar context, the entire string is
returned.  When called in a list context, a list of parsed I<key> =>
I<value> pairs are returned.  *NOTE*: you can only ask for this once,
as the entire body is read from the client.

=item $r->read_client_block($buf, $bytes_to_read)

Read from the entity body sent by the client.  Example of use:

  $r->read_client_block($buf, $r->header_in('Content-length'));

=item $r->read($buf, $bytes_to_read)



=item $r->get_remote_host

Lookup the client's DNS hostname.  Might return I<undef> if the
hostname is not known.

=back

More information about the client can be obtained from the
B<Apache::Connection> object, as described below.

=over 4

=item $c = $r->connection

The $r->connection method will return a reference to the request
connection object (blessed into the B<Apache::Connection> package).
This is really a C<conn_rec*> in disguise.  The following methods can
be used on the connection object:

$c->remote_host

$c->remote_ip

$c->remote_logname

$c->user; #Returns the remote username if authenticated.

$c->auth_type; #Returns the authentication scheme used, if any.

$c->close; #Calling this method will close down the connection to the
client

=back

=head1 SERVER CONFIGURATION INFORMATION

The following methods are used to obtain information from server
configuration and access control files.

=over 4

=item $r->dir_config( $key )

Returns the value of a per-directory variable specified by the 
C<PerlSetVar> directive.

 #<Location /foo/bar>
 #SetPerlVar  Key  Value
 #</Location>

 my $val = $r->dir_config('Key');

=item $r->requires

Returns an array reference of hash references, containing information
related to the B<require> directive.  This is normally used for access
control, see L<Apache::AuthzAge> for an example.

=item $r->allow_options

=item $r->is_perlaliased

The $r->allow_options and $r->is_perlaliased methods can be used for
checking if it's ok to run a perl script.  The B<Apache::Options>
module provide the constants to check against.

 if(!($r->allow_options & OPT_EXECCGI) && !$r->is_perlaliased) {
     $r->log_reason("Options ExecCGI is off in this directory", 
		    $filename);

=item $s = $r->server

Return a reference to the server info object (blessed into the
B<Apache::Server> package).  This is really a C<server_rec*> in
disguise.  The following methods can be used on the server object:

$s->server_admin; Returns the mail address of the person responsible
for this server.

$s->server_hostname; Returns the hostname used by this server.

$s->port;
Returns the port that this servers listens too.

=back

=head1 SETTING UP THE RESPONSE

The following methods are used to set up and return the response back
to the client.  This typically involves setting up $r->status(), the
various content attributes and optionally some additional
$r->out_headers() before calling $r->send_http_header() which will
actually send the headers to the client.  After this a typical
application will call the $r->write_client() method to send the response
content to the client.

=over 4

=item $r->basic_http_header

Send the response line (status) along with I<Server:> and I<Date:>
headers.

=item $r->send_http_header

Send the response line and all headers to the client.  (This method
will actually call $r->basic_http_header first).

This method will create headers from the $r->content_xxx() and
$r->no_cache() attributes (described below) and then append the
headers defined by $r->header_out (or $r->err_header_out if status
indicates an error).

=item $r->get_basic_auth_pw

If the current request is protected by Basic authentication, 
this method will return 0, otherwise -1.  
The second return value will be the decoded password sent by the client.

    ($ret, $sent_pw) = $r->get_basic_auth_pw;

=item $r->note_basic_auth_failure

Prior to requiring Basic authentication from the client, this method 
will set the outgoing HTTP headers asking the client to authenticate 
for the realm defined by the configuration directive C<AuthName>.

=item $r->handler( [$meth] )

Set the handler for a request.
Normally set by the configuration directive C<AddHandler>.
  
 $r->handler( "perl-script" );

=item $r->content_type( [$newval] )

Get or set the content type being sent to the client.  Content types
are strings like "text/plain", "text/html" or "image/gif".  This
corresponds to the "Content-Type" header in the HTTP protocol.  Example
of usage is:

   $previous_type = $r->content_type;
   $r->content_type("text/plain");

=item $r->content_encoding( [$newval] )

Get or set the content encoding.  Content encodings are string like
"gzip" or "compress".  This correspond to the "Content-Encoding"
header in the HTTP protocol.

=item $r->content_language( [$newval] )

Get or set the content language.  The content language corresponds to the
"Content-Language" HTTP header and is a string like "en" or "no".

=item $r->status( $integer )

Get or set the reply status for the client request.  The
B<Apache::Constants> module provide mnemonic names for the status codes.

=item $r->status_line( $string )

Get or set the response status line.  The status line is a string like
"HTTP/1.0 200 OK" and it will take precedence over the value specified
using the $r->status() described above.


=item $r->header_out( $header, $value )

Change the value of a response header, or create a new one.  You
should not define any "Content-XXX" headers by calling this method,
because these headers use their own specific methods.  Example of use:

   $req->header_out("WWW-Authenticate" => "Basic");

=item $r->err_header_out( $header, $value )

Change the value of an error response header, or create a new one.
These headers are used if the status indicates an error.

   $req->err_headers_out("Warning" => "Bad luck");

=item $r->no_cache( $boolean )

This is a flag that indicates that the data being returned is volatile
and the client should be told not to cache it.

=item $r->write_client( @list_of_data )

Send data to the client.  Unless you know what you are doing, you
should only call this method after you have called
$r->send_http_header.

=item $r->print()

Friendly alias for $r->write_client()

=item $r->send_fd( $filehandle )

Send the contents of a file to the client.  Can for instance be used
like this:

  open(FILE, $r->filename) || return 404;
  $r->send_fd(FILE);
  close(FILE);

=item $r->internal_redirect_handler( $newplace )

Redirect to a location in the server's namespace without 
telling the client. For instance:

  $r->internal_redirect_handler("/home/sweet/home.html");

=back

=head1 CGI SUPPORT

We also provide some methods that make it easier to support the CGI
type of interface.

=over 4

=item $r->cgi_env

Return a %hash that can be used to set up a standard CGI environment.
Typical usage would be:

  %ENV = $req->cgi_env

B<NOTE:> The $ENV{GATEWAY_INTERFACE} is set to C<'CGI-Perl/1.1'> so
you can say:

  if($ENV{GATEWAY_INTERFACE} =~ /^CGI-Perl/) {
      #do mod_perl stuff
  }
  else {
     #do normal CGI stuff
  }

When given a key => value pair, this will set an environment variable.

 $r->cgi_env(REMOTE_GROUP => "camels");

=item $r->send_cgi_header()

Take action on certain headers including I<Status:>, I<Location:> and
I<Content-type:> just as mod_cgi does, then calls
$r->send_http_header().  Example of use:

  $req->send_cgi_header("
  Location: /foo/bar
  Content-type: text/html 
  
  ");

=back

=head1 ERROR LOGGING

The following methods can be used to log errors. 

=over 4

=item $r->log_reason($message, $file)

The request failed, why??  Write a message to the server's errorlog.

   $r->log_reason("Because I felt like it", $r->filename);

=item $r->log_error($message)

Uh, oh.  Write a message to the server's errorlog.

  $r->log_error("Some text that goes in the error_log");

=back

=head1 UTILITY FUNCTIONS

=over 4

=item Apache::unescape_url($string)

Handy function for unescapes.

=back

=head1 SEE ALSO

perl(1),
Apache::Constants(3),
Apache::Registry(3),
Apache::CGI(3),
Apache::Debug(3),
Apache::Options(3)

=head1 AUTHORS

Gisle Aas <aas@sn.no> and Doug MacEachern <dougm@osf.org>

=cut

