package Apache::Constants;

use vars qw($VERSION @ISA @EXPORT);

$VERSION = "1.00";

use Carp ();
use Exporter ();
use DynaLoader ();

@ISA = qw(Exporter DynaLoader);

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


