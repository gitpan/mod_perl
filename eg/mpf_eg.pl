#example script for mod_perl_fast
#To load this file when the server starts -
#wherever you choose:
#AddType httpd/fast-perl .fpl

#add this to srm.conf:
#PerlScript /path/where/you/put/it/mfp_eg.pl

#in access.conf or .htaccess say:
#PerlResponse response
#and the subroutine named 'response' will be called for 
#each request when you ask for a 'file.fpl' in that directory
#the 'file.fpl' does not need to exist, just the directory

use Apache;

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

    my $host = $r->get_remote_host;
    if($host =~ m,bad\.com$,) {
	return 403; #forbidden
    }

    $r->content_type("text/html");
    $r->send_http_header;

    $r->write_client(
        hello(),
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
