package Apache::Constants;

use vars qw($VERSION @ISA @EXPORT);

$VERSION = "1.01";

use Carp ();
use Exporter ();
use DynaLoader ();

@ISA = qw(Exporter DynaLoader);

%EXPORT_TAGS = (
   options => [qw(OPT_NONE OPT_INDEXES OPT_INCLUDES 
		  OPT_SYMLINKS OPT_EXECCGI OPT_UNSET OPT_INCNOEXEC
		  OPT_SYM_OWNER OPT_MULTI OPT_ALL)],
   response_codes => [qw(
			 DOCUMENT_FOLLOWS
			 PARTIAL_CONTENT 
			 MULTIPLE_CHOICES
			 MOVED
			 REDIRECT
			 USE_LOCAL_COPY
			 BAD_REQUEST
			 AUTH_REQUIRED
			 FORBIDDEN
			 NOT_FOUND
			 METHOD_NOT_ALLOWED 
			 NOT_ACCEPTABLE 
			 LENGTH_REQUIRED
			 PRECONDITION_FAILED
			 SERVER_ERROR 
			 NOT_IMPLEMENTED
			 BAD_GATEWAY 
			 HTTP_SERVICE_UNAVAILABLE
			 VARIANT_ALSO_VARIES)],
    common => [qw(OK DECLINED NOT_FOUND FORBIDDEN AUTH_REQUIRED SERVER_ERROR)],
);

@EXPORT = qw(
   AUTH_REQUIRED
   BAD_GATEWAY
   BAD_REQUEST
   DECLINED
   DOCUMENT_FOLLOWS
   DYNAMIC_MODULE_LIMIT
   FORBIDDEN
   HUGE_STRING_LEN
   MAX_HEADERS
   MAX_STRING_LEN
   METHODS
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
   SERVICE_UNAVAILABLE
   SERVER_VERSION
   USE_LOCAL_COPY
);
 
sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    my $val = constant($constname);
    if ($! != 0) {
	Carp::croak("Your vendor has not defined Apache macro $constname");
    }
    eval "sub $AUTOLOAD () { $val }";
    goto &$AUTOLOAD;
 }
 
bootstrap Apache::Constants $VERSION;

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
