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
