#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#undef pregcomp
#ifdef __cplusplus
}
#endif

#include "httpd.h"
#include "http_config.h"
#include "http_protocol.h"
#include "http_log.h"
#include "http_main.h"
#include "http_core.h"

#ifdef PERL_TRACE
#define CTRACE fprintf
#else
#define CTRACE
#endif

/* Apache::SSI */
#define PERL_APACHE_SSI_TYPE "text/x-perl-server-parsed-html"
/* PerlSetVar */
#define MAX_PERL_CONF_VARS 10
/* must alloc for PerlModule ... */
#define MAX_PERL_MODS 10

#define PERL_CALLBACK_RETURN(h,name) \
  if(name != NULL) { \
    status = perl_call(name, r); \
    CTRACE(stderr, "perl_call %s handler '%s' returned: %d\n", h,name,status); \
  if((status == 1) || (status == 200)) \
    status = OK; \
  } \
  else \
    CTRACE(stderr, "mod_perl: declining to handle %s, no callback defined\n", h); \
  return status

#if MODULE_MAGIC_NUMBER >= 19961007
#define CHAR_P const char *
#else
#define CHAR_P char * 
#endif

    /* bleh */
#if MODULE_MAGIC_NUMBER > 19960526 
#define PERL_READ_SETUP \
       setup_client_block(r); \
       extra = 0; 
#else
#define PERL_READ_SETUP
#endif 

#if MODULE_MAGIC_NUMBER >= 19961007 
#define PERL_READ_CLIENT \
       if(should_client_block(r)) { \
	   nrd = get_client_block(r, buffer, bufsiz+extra); \
       } 
#else 
#define PERL_READ_CLIENT \
       nrd = read_client_block(r, buffer, bufsiz+extra); 
#endif       

#define PERL_READ_FROM_CLIENT \
       PERL_READ_SETUP; \
       PERL_READ_CLIENT

/* on/off switches for callback hooks during request stages */

#ifndef NO_PERL_TRANS
#define PERL_TRANS

#define PERL_TRANS_HOOK perl_translate

#define PERL_TRANS_CMD_ENTRY \
    "PerlTransHandler", set_perl_trans, \
    NULL, \
    RSRC_CONF, TAKE1, "the Perl Translation handler routine name"  

#define PERL_TRANS_CREATE(s) s->PerlTransHandler = NULL
#else
#define PERL_TRANS_HOOK NULL
#define PERL_TRANS_CMD_ENTRY NULL
#define PERL_TRANS_CREATE(s) 
#endif

#ifndef NO_PERL_AUTHEN
#define PERL_AUTHEN

#define PERL_AUTHEN_HOOK perl_authenticate

#define PERL_AUTHEN_CMD_ENTRY \
    "PerlAuthenHandler", set_string_slot, \
    (void*)XtOffsetOf(perl_dir_config, PerlAuthnHandler), \
    OR_ALL, TAKE1, "the Perl Authentication handler routine name"

#define PERL_AUTHEN_CREATE(s) s->PerlAuthnHandler = NULL
#else
#define PERL_AUTHEN_HOOK NULL
#define PERL_AUTHEN_CMD_ENTRY NULL
#define PERL_AUTHEN_CREATE(s)
#endif

#ifndef NO_PERL_AUTHZ
#define PERL_AUTHZ

#define PERL_AUTHZ_HOOK perl_authorize

#define PERL_AUTHZ_CMD_ENTRY \
    "PerlAuthzHandler", set_string_slot, \
    (void*)XtOffsetOf(perl_dir_config, PerlAuthzHandler), \
    OR_ALL, TAKE1, "the Perl Authorization handler routine name" 
#define PERL_AUTHZ_CREATE(s) s->PerlAuthzHandler = NULL
#else
#define PERL_AUTHZ_HOOK NULL
#define PERL_AUTHZ_CMD_ENTRY NULL
#define PERL_AUTHZ_CREATE(s)
#endif

#ifndef NO_PERL_ACCESS
#define PERL_ACCESS

#define PERL_ACCESS_HOOK perl_access

#define PERL_ACCESS_CMD_ENTRY \
    "PerlAccessHandler", set_string_slot, \
    (void*)XtOffsetOf(perl_dir_config, PerlAccessHandler), \
    OR_ALL, TAKE1, "the Perl Access handler routine name" 

#define PERL_ACCESS_CREATE(s) s->PerlAccessHandler = NULL
#else
#define PERL_ACCESS_HOOK NULL
#define PERL_ACCESS_CMD_ENTRY NULL
#define PERL_ACCESS_CREATE(s)
#endif

/* un-tested hooks */

#ifndef NO_PERL_TYPE
#define PERL_TYPE

#define PERL_TYPE_HOOK perl_type_checker

#define PERL_TYPE_CMD_ENTRY \
    "PerlTypeHandler", set_string_slot, \
    (void*)XtOffsetOf(perl_dir_config, PerlTypeHandler), \
    OR_ALL, TAKE1, "the Perl Type check handler routine name" 

#define PERL_TYPE_CREATE(s) s->PerlTypeHandler = NULL
#else
#define PERL_TYPE_HOOK NULL
#define PERL_TYPE_CMD_ENTRY NULL
#define PERL_TYPE_CREATE(s) 
#endif

#ifndef NO_PERL_FIXUP
#define PERL_FIXUP

#define PERL_FIXUP_HOOK perl_fixup

#define PERL_FIXUP_CMD_ENTRY \
    "PerlFixupHandler", set_string_slot, \
    (void*)XtOffsetOf(perl_dir_config, PerlFixupHandler), \
    OR_ALL, TAKE1, "the Perl Fixup handler routine name" 

#define PERL_FIXUP_CREATE(s) s->PerlFixupHandler = NULL
#else
#define PERL_FIXUP_HOOK NULL
#define PERL_FIXUP_CMD_ENTRY NULL
#define PERL_FIXUP_CREATE(s)
#endif

#ifndef NO_PERL_LOGGER
#define PERL_LOGGER

#define PERL_LOGGER_HOOK perl_logger

#define PERL_LOGGER_CMD_ENTRY \
    "PerlLogHandler", set_string_slot, \
    (void*)XtOffsetOf(perl_dir_config, PerlLogHandler), \
    OR_ALL, TAKE1, "the Perl Log handler routine name" 

#define PERL_LOGGER_CREATE(s) s->PerlLogHandler = NULL
#else
#define PERL_LOGGER_HOOK NULL
#define PERL_LOGGER_CMD_ENTRY NULL
#define PERL_LOGGER_CREATE(s) s->PerlLogHandler = NULL
#endif



typedef struct {
   char *PerlScript;
   char **PerlModules;
   char *PerlTransHandler;
   int  NumPerlModules;
} perl_server_config;

typedef struct {
   char *PerlHandler;
   char *PerlAuthnHandler;
   char *PerlAuthzHandler;
   char *PerlAccessHandler;
   char *PerlTypeHandler;
   char *PerlFixupHandler;
   char *PerlLogHandler;
   table *vars;
   int  sendheader;
   int setup_env;
} perl_dir_config;

extern module perl_module;

/* prototypes */

int perl_handler(request_rec *r);
void perl_init (server_rec *s, pool *p);
void *create_perl_dir_config (pool *p, char *dirname);
void *create_perl_server_config (pool *p, server_rec *s);
int perl_translate(request_rec *r);
int perl_authenticate(request_rec *r);
int perl_authorize(request_rec *r);
int perl_access(request_rec *r);
int perl_type_checker(request_rec *r);
int perl_fixup(request_rec *r);
int perl_logger(request_rec *r);
CHAR_P set_perl_script (cmd_parms *parms, void *dummy, char *arg);
CHAR_P push_perl_modules (cmd_parms *parms, void *dummy, char *arg);
CHAR_P set_perl_var(cmd_parms *cmd, void *rec, char *key, char *val);
CHAR_P perl_sendheader_on (cmd_parms *cmd, void *rec, int arg);
CHAR_P perl_set_env_on (cmd_parms *cmd, void *rec, int arg);
CHAR_P set_perl_trans (cmd_parms *parms, void *dummy, char *arg);
void xs_init _((void));
void perl_set_request_rec(request_rec *);
