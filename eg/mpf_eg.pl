#example script for mod_perl_fast
#To load this file when the server starts -
#wherever you choose:
#AddType httpd/fast-perl .fpl

#add this to srm.conf:
#PerlScript /path/where/you/put/it/mpf_eg.pl

#in access.conf or .htaccess say:
#PerlResponse response
#and the subroutine named 'response' will be called for 
#each request when you ask for a 'file.fpl' in that directory
#the 'file.fpl' does not need to exist, just the directory

require Apache;

#load perl modules of your choice here
#this code is interpreted *once* when the server starts
#require CGI;
#require LWP;
#use HTTP::Status;
#require Penguin;

#here's where you can open a database connection when
#httpd starts up

#use DBI;
#my($host,$db,$table,$driver) = ("", "test", "Users", "mSQL");
#my $dbh = DBI->connect($host, $db, "", $driver);

sub response {
    my $r    = Apache->request;
    my $srv  = $r->server;
    my $conn = $r->connection;

    my %headers = $r->headers_in;
    my $host = $r->get_remote_host;

    $r->content_type("text/html");
    $r->send_http_header;

    $r->write_client(<<FORM);
<FORM METHOD="POST"  ENCTYPE=application/x-www-form-urlencoded >
What's your name? <INPUT TYPE="text" NAME="name" VALUE="dfasdf">
<P>What's the combination?<P>
<INPUT TYPE="checkbox" NAME="words" VALUE="eenie">eenie 
<INPUT TYPE="checkbox" NAME="words" VALUE="meenie">meenie 
<INPUT TYPE="checkbox" NAME="words" VALUE="minie" CHECKED>minie 
<INPUT TYPE="checkbox" NAME="words" VALUE="moe">moe 
<P>What's your favorite color? <SELECT NAME="color">
<OPTION SELECTED VALUE="red">red
<OPTION  VALUE="green">green
<OPTION  VALUE="blue">blue
<OPTION  VALUE="chartreuse">chartreuse
</SELECT>

<P><INPUT TYPE="reset"><INPUT TYPE="submit"NAME="submit" VALUE="OK"></FORM>

FORM
    my $args = $r->args;
    my(%args,%in);

    if($r->method eq "POST") {
	#my $buff;
	#my $nrd = $r->read_client_block($buff, $headers{"Content-length"});
	#$r->print("read_client_block ->[ $r ][ $nrd ] $buff\n");
	%in = $r->content;
    }
    %args = $r->args;

    $r->write_client(
        hello(),

       "\nscalar \$r->args:\n $args\n",
     
       "\n\$r->args:\n",		     
       (map { "$_ = $args{$_}\n" } keys %args),

       "\n\$r->content:\n",		     
       (map { "$_ = $in{$_}\n" } keys %in),

       "\n\$r->headers_in:\n",		     
       (map { "$_ = $headers{$_}\n" } keys %headers),

        #"\nargs: ", $args,		     
        "\nmethod : ", $r->method,
        "\nuri : ", $r->uri,
        "\nprotocol : ", $r->protocol,
        "\npath_info : ", $r->path_info,	 
        "\nfilename: ", $r->filename,	

	"\nserver_admin: ", $srv->server_admin,		 
	"\nserver_hostname: ", $srv->server_hostname,		 
	"\nport: ", $srv->port,

	"\nremote_host: ", $conn->remote_host,
	"\nremote_ip: ", $conn->remote_ip,	 
	"\n",
    );
    

    return 0; #need to give a return status
}

#any other subroutines you want can be here too.
sub hello {
    return "<h1>hi there speedy!</h1><pre>\n";
}

1;








