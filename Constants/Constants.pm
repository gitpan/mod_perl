package Apache::Constants;

use vars qw($VERSION @ISA @EXPORT);

$VERSION = "1.05";

use Carp ();
use Exporter ();
use DynaLoader ();
use strict;
use vars qw(@ISA %EXPORT_TAGS @EXPORT_OK @EXPORT);

@ISA = qw(Exporter DynaLoader);

%EXPORT_TAGS = (
   options => [qw(OPT_NONE OPT_INDEXES OPT_INCLUDES 
		  OPT_SYM_LINKS OPT_EXECCGI OPT_UNSET OPT_INCNOEXEC
		  OPT_SYM_OWNER OPT_MULTI OPT_ALL)],
   response_codes => [qw(
			 DOCUMENT_FOLLOWS
			 MOVED
			 REDIRECT
			 USE_LOCAL_COPY
			 BAD_REQUEST
			 AUTH_REQUIRED
			 FORBIDDEN
			 NOT_FOUND
			 HTTP_METHOD_NOT_ALLOWED 
			 HTTP_NOT_ACCEPTABLE 
			 HTTP_LENGTH_REQUIRED
			 HTTP_PRECONDITION_FAILED
			 SERVER_ERROR 
			 NOT_IMPLEMENTED
			 BAD_GATEWAY 
			 HTTP_SERVICE_UNAVAILABLE
			 HTTP_VARIANT_ALSO_VARIES)],
    common => [qw(OK DECLINED DONE NOT_FOUND FORBIDDEN AUTH_REQUIRED SERVER_ERROR)],
);

@EXPORT_OK = qw(
   MOVED
   HTTP_METHOD_NOT_ALLOWED 
   HTTP_NOT_ACCEPTABLE 
   HTTP_LENGTH_REQUIRED
   HTTP_PRECONDITION_FAILED
   HTTP_SERVICE_UNAVAILABLE
   HTTP_VARIANT_ALSO_VARIES
);
   
@EXPORT = qw(
   AUTH_REQUIRED
   BAD_GATEWAY
   BAD_REQUEST
   DECLINED
   DOCUMENT_FOLLOWS
   DONE
   FORBIDDEN
   M_CONNECT
   M_DELETE
   M_GET
   M_INVALID
   M_POST
   M_PUT
   NOT_FOUND
   NOT_IMPLEMENTED
   OK
   OPT_ALL
   OPT_EXECCGI
   OPT_INCLUDES
   OPT_INCNOEXEC
   OPT_INDEXES
   OPT_MULTI
   OPT_NONE
   OPT_SYM_LINKS
   OPT_SYM_OWNER
   OPT_UNSET
   REDIRECT
   RESPONSE_CODES
   SERVER_ERROR
   SERVER_VERSION
   SERVER_SUBVERSION
   USE_LOCAL_COPY
);

#hmm
sub MOVED () {301}
sub AUTH_REQUIRED () {401}

{
    my(%SEEN,@export,$key,$val);
    while(($key,$val) = each %EXPORT_TAGS) {
	push @export, grep {!$SEEN{$_}++} @$val;
    }
    push @export, grep {!$SEEN{$_}++} @EXPORT;
    eval { bootstrap Apache::Constants $VERSION; };
    if($@) {
	my $gw = $ENV{GATEWAY_INTERFACE} || '';
	die "$@\n" if substr($gw,0,8) eq 'CGI-Perl';
	warn "warning: can't `bootstrap Apache::Constants $VERSION' outside of httpd\n";
    }
    else {
	foreach $key (@export) {
	    next if defined &$key;
	    $val = constant($key);
	    eval "sub $key () { $val }";
	}
    }
}

1;

__END__

=head1 NAME

Apache::Constants - Constants defined in httpd.h

=head1 SYNOPSIS

    use Apache::Constants;
    use Apache::Constants ':common'; #OK,DECLINED,etc.

=head1 DESCRIPTION

Server constants used by apache modules are defined in
B<httpd.h>, this module gives Perl access to those constants.

=head1 AUTHORS

Gisle Aas <aas@sn.no>, Doug MacEachern <dougm@osf.org> and h2xs
