#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
/* perl hides it's symbols in libperl when these macros are expanded to Perl_foo
 * but some cause conflict when expanded in other headers files
 */
#undef pregcomp
#undef setregid
#undef setreuid
#undef sync
#undef my_memcmp

#include "httpd.h"
#include "http_config.h"
#include "http_protocol.h"
#include "http_log.h"
#include "http_main.h"
#include "http_core.h"
#include "http_request.h"
#include "util_script.h"

typedef request_rec * Apache;
typedef conn_rec    * Apache__Connection;
typedef server_rec  * Apache__Server;

#define iniHV(hv) hv = (HV*)sv_2mortal((SV*)newHV())
#define iniAV(av) av = (AV*)sv_2mortal((SV*)newAV())

#define PerlEnvHV GvHV(gv_fetchpv("ENV", FALSE, SVt_PVHV))

#ifndef SvTAINTED_on
#define SvTAINTED_on(sv) if (tainting) sv_magic(sv, Nullsv, 't', Nullch, 0)
#endif

#define HV_SvTAINTED_on(hv,key,klen) \
    SvTAINTED_on(*hv_fetch(hv, key, klen, 0)) 

/* flush %ENV */
#define perl_clear_env \
      hv_clear(PerlEnvHV)

#define perl_set_pid \
      sv_setiv(GvSV(gv_fetchpv("$", TRUE, SVt_PV)), (I32)getpid())

#ifdef PERL_TRACE
#define CTRACE fprintf
#else
#define CTRACE mp_void_fprintf
#endif

#define PERL_GATEWAY_INTERFACE "CGI-Perl/1.1"
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
} \
else { \
    CTRACE(stderr, "mod_perl: declining to handle %s, no callback defined\n", h); \
} \
return status

#if MODULE_MAGIC_NUMBER >= 19961007
#define CHAR_P const char *
#define PERL_EXIT_CLEANUP multi_log_transaction(r);
#else
#define CHAR_P char * 
#define PERL_EXIT_CLEANUP common_log_transaction(r);
#endif

/* bleh */
#if MODULE_MAGIC_NUMBER >= 19961125 
#define PERL_READ_SETUP setup_client_block(r, REQUEST_CHUNKED_ERROR); 
#else
#define PERL_READ_SETUP
#endif 

#if MODULE_MAGIC_NUMBER >= 19961125 
#define PERL_READ_CLIENT \
if(should_client_block(r)) { \
    nrd = get_client_block(r, buffer, bufsiz); \
} 
#else 
#define PERL_READ_CLIENT \
nrd = read_client_block(r, buffer, bufsiz); 
#endif       

#define PERL_READ_FROM_CLIENT \
PERL_READ_SETUP; \
PERL_READ_CLIENT

#if MODULE_MAGIC_NUMBER >= 19961211
#define SENDN_TO_CLIENT rwrite(buffer, n, r) 

#else

/* this was private in http_protocol.c */
#define SET_BYTES_SENT(r) \
  do { if (r->sent_bodyct) \
	  bgetopt (r->connection->client, BO_BYTECT, &r->bytes_sent); \
  } while (0)

#define SENDN_TO_CLIENT \
    bwrite(r->connection->client, buffer, n); \
    SET_BYTES_SENT(r)
#endif

#define PUSHelt(key,val,klen) \
{ \
    SV *psv = (SV*)newSVpv(val, 0); \
    SvTAINTED_on(psv); \
    XPUSHs(sv_2mortal((SV*)newSVpv(key, klen))); \
    XPUSHs(sv_2mortal((SV*)psv)); \
}

#define CGIENVinit \
       int i; \
       char *tz = NULL; \
       table_entry *elts = NULL; \
       if(table_get(env_arr,"GATEWAY_INTERFACE") != PERL_GATEWAY_INTERFACE) { \
           add_common_vars(r); \
           add_cgi_vars(r); \
           elts = (table_entry *)env_arr->elts; \
           tz = getenv("TZ"); \
           table_set (env_arr, "PATH", DEFAULT_PATH); \
           table_set (env_arr, "GATEWAY_INTERFACE", PERL_GATEWAY_INTERFACE); \
       }

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

#ifndef NO_PERL_LOG
#define PERL_LOG

#define PERL_LOG_HOOK perl_logger

#define PERL_LOG_CMD_ENTRY \
"PerlLogHandler", set_string_slot, \
    (void*)XtOffsetOf(perl_dir_config, PerlLogHandler), \
    OR_ALL, TAKE1, "the Perl Log handler routine name" 

#define PERL_LOG_CREATE(s) s->PerlLogHandler = NULL
#else
#define PERL_LOG_HOOK NULL
#define PERL_LOG_CMD_ENTRY NULL
#define PERL_LOG_CREATE(s) s->PerlLogHandler = NULL
#endif

#ifndef NO_PERL_HEADER_PARSER
#define PERL_HEADER_PARSER

#define PERL_HEADER_PARSER_HOOK perl_header_parser

#define PERL_HEADER_PARSER_CMD_ENTRY \
"PerlHeaderParserHandler", set_string_slot, \
    (void*)XtOffsetOf(perl_dir_config, PerlHeaderParserHandler), \
    OR_ALL, TAKE1, "the Perl Header Parser handler routine name" 

#define PERL_HEADER_PARSER_CREATE(s) s->PerlHeaderParserHandler = NULL
#else
#define PERL_HEADER_PARSER_HOOK NULL
#define PERL_HEADER_PARSER_CMD_ENTRY NULL
#define PERL_HEADER_PARSER_CREATE(s) s->PerlHeaderParserHandler = NULL
#endif

typedef struct {
    char *PerlScript;
    char **PerlModules;
    char *PerlTransHandler;
    int  NumPerlModules;
    int  PerlTaintCheck;
    int  PerlWarn;
} perl_server_config;

typedef struct {
    char *PerlHandler;
    char *PerlAuthnHandler;
    char *PerlAuthzHandler;
    char *PerlAccessHandler;
    char *PerlTypeHandler;
    char *PerlFixupHandler;
    char *PerlLogHandler;
    char *PerlHeaderParserHandler;
    table *vars;
    int  sendheader;
    int setup_env;
} perl_dir_config;

extern module perl_module;

/* a couple for -Wall sanity sake */
int multi_log_transaction(request_rec *r);
int basic_http_header(request_rec *r);
/* prototypes */
int perl_call(char *imp, request_rec *r);
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
int perl_header_parser(request_rec *r);
CHAR_P set_perl_script (cmd_parms *parms, void *dummy, char *arg);
CHAR_P push_perl_modules (cmd_parms *parms, void *dummy, char *arg);
CHAR_P set_perl_var(cmd_parms *cmd, void *rec, char *key, char *val);
CHAR_P perl_sendheader_on (cmd_parms *cmd, void *rec, int arg);
CHAR_P set_perl_tainting (cmd_parms *parms, void *dummy, int arg);
CHAR_P set_perl_warn (cmd_parms *parms, void *dummy, int arg);
CHAR_P perl_set_env_on (cmd_parms *cmd, void *rec, int arg);
CHAR_P set_perl_trans (cmd_parms *parms, void *dummy, char *arg);
#ifdef APACHE_SSL
void xs_init (void);
#else
void xs_init _((void));
#endif
int mod_perl_seqno(void);
int perl_hook(char *name);
request_rec *perl_request_rec(request_rec *);
void perl_stdin2client(request_rec *);
void perl_stdout2client(request_rec *); 
int perl_require_module(char *, server_rec *);
int  perl_eval_ok(server_rec *);
void perl_setup_env(request_rec *r);
SV  *perl_bless_request_rec(request_rec *); 
void perl_set_request_rec(request_rec *); 
int mp_void_fprintf(FILE *, const char *, ...);

