#include "mod_perl.h"

static double
constant(name)
char *name;
{
    errno = 0;
    switch (*name) {
    case 'A':
	if (strEQ(name, "ACCESS_CONFIG_FILE"))
	if (strEQ(name, "AUTH_REQUIRED"))
#ifdef AUTH_REQUIRED
	    return AUTH_REQUIRED;
#else
	    goto not_there;
#endif
	break;
    case 'B':
	if (strEQ(name, "BAD_GATEWAY"))
#ifdef BAD_GATEWAY
	    return BAD_GATEWAY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "BAD_REQUEST"))
#ifdef BAD_REQUEST
	    return BAD_REQUEST;
#else
	    goto not_there;
#endif
	break;
    case 'C':
	break;
    case 'D':
	if (strEQ(name, "DECLINED"))
#ifdef DECLINED
	    return DECLINED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DOCUMENT_FOLLOWS"))
#ifdef DOCUMENT_FOLLOWS
	    return DOCUMENT_FOLLOWS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DYNAMIC_MODULE_LIMIT"))
#ifdef DYNAMIC_MODULE_LIMIT
	    return DYNAMIC_MODULE_LIMIT;
#else
	    goto not_there;
#endif
	break;
    case 'E':
	break;
    case 'F':
	if (strEQ(name, "FORBIDDEN"))
#ifdef FORBIDDEN
	    return FORBIDDEN;
#else
	    goto not_there;
#endif
	break;
    case 'G':
	break;
    case 'H':
       if (strEQ(name, "HTTP_ACCEPTED"))
#ifdef HTTP_ACCEPTED
           return HTTP_ACCEPTED;
#else
           goto not_there;
#endif
       if (strEQ(name, "HTTP_BAD_GATEWAY"))
#ifdef HTTP_BAD_GATEWAY
           return HTTP_BAD_GATEWAY;
#else
           goto not_there;
#endif
       if (strEQ(name, "HTTP_BAD_REQUEST"))
#ifdef HTTP_BAD_REQUEST
           return HTTP_BAD_REQUEST;
#else
           goto not_there;
#endif
       if (strEQ(name, "HTTP_CONFLICT"))
#ifdef HTTP_CONFLICT
           return HTTP_CONFLICT;
#else
           goto not_there;
#endif
       if (strEQ(name, "HTTP_CONTINUE"))
#ifdef HTTP_CONTINUE
           return HTTP_CONTINUE;
#else
           goto not_there;
#endif
       if (strEQ(name, "HTTP_CREATED"))
#ifdef HTTP_CREATED
           return HTTP_CREATED;
#else
           goto not_there;
#endif
       if (strEQ(name, "HTTP_FORBIDDEN"))
#ifdef HTTP_FORBIDDEN
           return HTTP_FORBIDDEN;
#else
           goto not_there;
#endif
       if (strEQ(name, "HTTP_GATEWAY_TIME_OUT"))
#ifdef HTTP_GATEWAY_TIME_OUT
           return HTTP_GATEWAY_TIME_OUT;
#else
           goto not_there;
#endif
       if (strEQ(name, "HTTP_GONE"))
#ifdef HTTP_GONE
           return HTTP_GONE;
#else
           goto not_there;
#endif
       if (strEQ(name, "HTTP_INTERNAL_SERVER_ERROR"))
#ifdef HTTP_INTERNAL_SERVER_ERROR
           return HTTP_INTERNAL_SERVER_ERROR;
#else
           goto not_there;
#endif
       if (strEQ(name, "HTTP_LENGTH_REQUIRED"))
#ifdef HTTP_LENGTH_REQUIRED
           return HTTP_LENGTH_REQUIRED;
#else
           goto not_there;
#endif
       if (strEQ(name, "HTTP_METHOD_NOT_ALLOWED"))
#ifdef HTTP_METHOD_NOT_ALLOWED
           return HTTP_METHOD_NOT_ALLOWED;
#else
           goto not_there;
#endif
       if (strEQ(name, "HTTP_MOVED_PERMANENTLY"))
#ifdef HTTP_MOVED_PERMANENTLY
           return HTTP_MOVED_PERMANENTLY;
#else
           goto not_there;
#endif
       if (strEQ(name, "HTTP_MOVED_TEMPORARILY"))
#ifdef HTTP_MOVED_TEMPORARILY
           return HTTP_MOVED_TEMPORARILY;
#else
           goto not_there;
#endif
       if (strEQ(name, "HTTP_MULTIPLE_CHOICES"))
#ifdef HTTP_MULTIPLE_CHOICES
           return HTTP_MULTIPLE_CHOICES;
#else
           goto not_there;
#endif
       if (strEQ(name, "HTTP_NON_AUTHORITATIVE"))
#ifdef HTTP_NON_AUTHORITATIVE
           return HTTP_NON_AUTHORITATIVE;
#else
           goto not_there;
#endif
       if (strEQ(name, "HTTP_NOT_ACCEPTABLE"))
#ifdef HTTP_NOT_ACCEPTABLE
           return HTTP_NOT_ACCEPTABLE;
#else
           goto not_there;
#endif
       if (strEQ(name, "HTTP_NOT_FOUND"))
#ifdef HTTP_NOT_FOUND
           return HTTP_NOT_FOUND;
#else
           goto not_there;
#endif
       if (strEQ(name, "HTTP_NOT_IMPLEMENTED"))
#ifdef HTTP_NOT_IMPLEMENTED
           return HTTP_NOT_IMPLEMENTED;
#else
           goto not_there;
#endif
       if (strEQ(name, "HTTP_NOT_MODIFIED"))
#ifdef HTTP_NOT_MODIFIED
           return HTTP_NOT_MODIFIED;
#else
           goto not_there;
#endif
       if (strEQ(name, "HTTP_NO_CONTENT"))
#ifdef HTTP_NO_CONTENT
           return HTTP_NO_CONTENT;
#else
           goto not_there;
#endif
       if (strEQ(name, "HTTP_OK"))
#ifdef HTTP_OK
           return HTTP_OK;
#else
           goto not_there;
#endif
       if (strEQ(name, "HTTP_PARTIAL_CONTENT"))
#ifdef HTTP_PARTIAL_CONTENT
           return HTTP_PARTIAL_CONTENT;
#else
           goto not_there;
#endif
       if (strEQ(name, "HTTP_PAYMENT_REQUIRED"))
#ifdef HTTP_PAYMENT_REQUIRED
           return HTTP_PAYMENT_REQUIRED;
#else
           goto not_there;
#endif
       if (strEQ(name, "HTTP_PRECONDITION_FAILED"))
#ifdef HTTP_PRECONDITION_FAILED
           return HTTP_PRECONDITION_FAILED;
#else
           goto not_there;
#endif
       if (strEQ(name, "HTTP_PROXY_AUTHENTICATION_REQUIRED"))
#ifdef HTTP_PROXY_AUTHENTICATION_REQUIRED
           return HTTP_PROXY_AUTHENTICATION_REQUIRED;
#else
           goto not_there;
#endif
       if (strEQ(name, "HTTP_REQUEST_ENTITY_TOO_LARGE"))
#ifdef HTTP_REQUEST_ENTITY_TOO_LARGE
           return HTTP_REQUEST_ENTITY_TOO_LARGE;
#else
           goto not_there;
#endif
       if (strEQ(name, "HTTP_REQUEST_TIME_OUT"))
#ifdef HTTP_REQUEST_TIME_OUT
           return HTTP_REQUEST_TIME_OUT;
#else
           goto not_there;
#endif
       if (strEQ(name, "HTTP_REQUEST_URI_TOO_LARGE"))
#ifdef HTTP_REQUEST_URI_TOO_LARGE
           return HTTP_REQUEST_URI_TOO_LARGE;
#else
           goto not_there;
#endif
       if (strEQ(name, "HTTP_RESET_CONTENT"))
#ifdef HTTP_RESET_CONTENT
           return HTTP_RESET_CONTENT;
#else
           goto not_there;
#endif
       if (strEQ(name, "HTTP_SEE_OTHER"))
#ifdef HTTP_SEE_OTHER
           return HTTP_SEE_OTHER;
#else
           goto not_there;
#endif
       if (strEQ(name, "HTTP_SERVICE_UNAVAILABLE"))
#ifdef HTTP_SERVICE_UNAVAILABLE
           return HTTP_SERVICE_UNAVAILABLE;
#else
           goto not_there;
#endif
       if (strEQ(name, "HTTP_SWITCHING_PROTOCOLS"))
#ifdef HTTP_SWITCHING_PROTOCOLS
           return HTTP_SWITCHING_PROTOCOLS;
#else
           goto not_there;
#endif
       if (strEQ(name, "HTTP_UNAUTHORIZED"))
#ifdef HTTP_UNAUTHORIZED
           return HTTP_UNAUTHORIZED;
#else
           goto not_there;
#endif
       if (strEQ(name, "HTTP_UNSUPPORTED_MEDIA_TYPE"))
#ifdef HTTP_UNSUPPORTED_MEDIA_TYPE
           return HTTP_UNSUPPORTED_MEDIA_TYPE;
#else
           goto not_there;
#endif
       if (strEQ(name, "HTTP_USE_PROXY"))
#ifdef HTTP_USE_PROXY
           return HTTP_USE_PROXY;
#else
           goto not_there;
#endif
       if (strEQ(name, "HTTP_VARIANT_ALSO_VARIES"))
#ifdef HTTP_VARIANT_ALSO_VARIES
           return HTTP_VARIANT_ALSO_VARIES;
#else
           goto not_there;
#endif
       if (strEQ(name, "HTTP_VERSION_NOT_SUPPORTED"))
#ifdef HTTP_VERSION_NOT_SUPPORTED
           return HTTP_VERSION_NOT_SUPPORTED;
#else
           goto not_there;
#endif
	if (strEQ(name, "HUGE_STRING_LEN"))
#ifdef HUGE_STRING_LEN
	    return HUGE_STRING_LEN;
#else
	    goto not_there;
#endif
	break;
    case 'I':
	break;
    case 'J':
	break;
    case 'K':
	break;
    case 'L':
	break;
    case 'M':
	if (strEQ(name, "MAX_HEADERS"))
#ifdef MAX_HEADERS
	    return MAX_HEADERS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MAX_STRING_LEN"))
#ifdef MAX_STRING_LEN
	    return MAX_STRING_LEN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "METHODS"))
#ifdef METHODS
	    return METHODS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "M_CONNECT"))
#ifdef M_CONNECT
	    return M_CONNECT;
#else
	    goto not_there;
#endif
        if (strEQ(name, "MODULE_MAGIC_NUMBER"))
#ifdef MODULE_MAGIC_NUMBER
            return MODULE_MAGIC_NUMBER;
#else
            goto not_there;
#endif
	if (strEQ(name, "M_DELETE"))
#ifdef M_DELETE
	    return M_DELETE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "M_GET"))
#ifdef M_GET
	    return M_GET;
#else
	    goto not_there;
#endif
	if (strEQ(name, "M_INVALID"))
#ifdef M_INVALID
	    return M_INVALID;
#else
	    goto not_there;
#endif
	if (strEQ(name, "M_POST"))
#ifdef M_POST
	    return M_POST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "M_PUT"))
#ifdef M_PUT
	    return M_PUT;
#else
	    goto not_there;
#endif
	break;
    case 'N':
	if (strEQ(name, "NOT_FOUND"))
#ifdef NOT_FOUND
	    return NOT_FOUND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NOT_IMPLEMENTED"))
#ifdef NOT_IMPLEMENTED
	    return NOT_IMPLEMENTED;
#else
	    goto not_there;
#endif
	break;
    case 'O':
	if (strEQ(name, "OK"))
#ifdef OK
	    return OK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "OPT_ALL"))
#ifdef OPT_ALL
	    return OPT_ALL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "OPT_EXECCGI"))
#ifdef OPT_EXECCGI
	    return OPT_EXECCGI;
#else
	    goto not_there;
#endif
	if (strEQ(name, "OPT_INCLUDES"))
#ifdef OPT_INCLUDES
	    return OPT_INCLUDES;
#else
	    goto not_there;
#endif
	if (strEQ(name, "OPT_INCNOEXEC"))
#ifdef OPT_INCNOEXEC
	    return OPT_INCNOEXEC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "OPT_INDEXES"))
#ifdef OPT_INDEXES
	    return OPT_INDEXES;
#else
	    goto not_there;
#endif
	if (strEQ(name, "OPT_MULTI"))
#ifdef OPT_MULTI
	    return OPT_MULTI;
#else
	    goto not_there;
#endif
	if (strEQ(name, "OPT_NONE"))
#ifdef OPT_NONE
	    return OPT_NONE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "OPT_SYM_LINKS"))
#ifdef OPT_SYM_LINKS
	    return OPT_SYM_LINKS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "OPT_SYM_OWNER"))
#ifdef OPT_SYM_OWNER
	    return OPT_SYM_OWNER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "OPT_UNSET"))
#ifdef OPT_UNSET
	    return OPT_UNSET;
#else
	    goto not_there;
#endif
	break;
    case 'P':
	break;
    case 'Q':
	break;
    case 'R':
	if (strEQ(name, "REDIRECT"))
#ifdef REDIRECT
	    return REDIRECT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RESPONSE_CODES"))
#ifdef RESPONSE_CODES
	    return RESPONSE_CODES;
#else
	    goto not_there;
#endif
	break;
    case 'S':
	if (strEQ(name, "SERVER_ERROR"))
#ifdef SERVER_ERROR
	    return SERVER_ERROR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SERVICE_UNAVAILABLE"))
#ifdef SERVICE_UNAVAILABLE
	    return SERVICE_UNAVAILABLE;
#else
	    goto not_there;
#endif
    case 'U':
	if (strEQ(name, "USE_LOCAL_COPY"))
#ifdef USE_LOCAL_COPY
	    return USE_LOCAL_COPY;
#else
	    goto not_there;
#endif
	break;
    case 'V':
	break;
    case 'W':
	break;
    case 'X':
	break;
    case 'Y':
	break;
    case 'Z':
	break;
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}



MODULE = Apache::Constants PACKAGE = Apache::Constants
 
PROTOTYPES: DISABLE
 
double
constant(name)
	char *		name

char *
SERVER_VERSION()
   CODE: 
   RETVAL = SERVER_VERSION;

   OUTPUT:
   RETVAL
