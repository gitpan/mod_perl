#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* perl hides it's symbols in libperl when these macros are 
 * expanded to Perl_foo
 * but some cause conflict when expanded in other headers files
 */
#undef pregexec
#undef pregfree
#undef pregcomp
#undef setregid
#undef setreuid
#undef sync
#undef my_memcmp
#undef RETURN

#include "httpd.h"
#include "http_config.h"
#include "http_protocol.h"
#include "http_log.h"
#include "http_main.h"
#include "http_core.h"
#include "http_request.h"
#include "util_script.h"
#include "http_conf_globals.h"

typedef request_rec * Apache;
typedef conn_rec    * Apache__Connection;
typedef server_rec  * Apache__Server;

#define iniHV(hv) hv = (HV*)sv_2mortal((SV*)newHV())
#define iniAV(av) av = (AV*)sv_2mortal((SV*)newAV())

#define av_copy_array(av) av_make(av_len(av)+1, AvARRAY(av))  

#define PerlEnvHV GvHV(gv_fetchpv("ENV", FALSE, SVt_PVHV))

#ifndef newRV_noinc
#define newRV_noinc(sv)	((Sv = newRV(sv)), --SvREFCNT(SvRV(Sv)), Sv)
#endif

#ifndef SvTAINTED_on
#define SvTAINTED_on(sv) if (tainting) sv_magic(sv, Nullsv, 't', Nullch, 0)
#endif

#define HV_SvTAINTED_on(hv,key,klen) \
    SvTAINTED_on(*hv_fetch(hv, key, klen, 0)) 

#define perl_set_pid \
      if(!set_pid++) sv_setiv(GvSV(gv_fetchpv("$", TRUE, SVt_PV)), (I32)getpid())

#ifdef PERL_TRACE
#define MP_TRACE(a) a 
#else
#define MP_TRACE(a)
#endif

#define PERL_GATEWAY_INTERFACE "CGI-Perl/1.1"
/* Apache::SSI */
#define PERL_APACHE_SSI_TYPE "text/x-perl-server-parsed-html"
/* PerlSetVar */
#define MAX_PERL_CONF_VARS 10
/* must alloc for PerlModule ... */
#define MAX_PERL_MODS 10

#ifndef NO_PERL_STACKED_HANDLERS
#define PERL_STACKED_HANDLERS
#endif
#ifndef NO_PERL_METHOD_HANDLERS
#define PERL_METHOD_HANDLERS
#endif
#ifndef NO_PERL_SECTIONS
#define PERL_SECTIONS
#endif

#ifdef PERL_STACKED_HANDLERS
#define PERL_TAKE ITERATE
#define PERL_CMD_INIT  Nullav
#define PERL_CMD_TYPE  AV

#define mod_perl_can_stack_handlers(sv) (SvTRUE(sv) && 1)

#define PERL_CALLBACK(h,name) \
acquire_mutex(mod_perl_mutex); \
perl_set_pid; \
status = perl_run_stacked_handlers(h, r, Nullav); \
if((status != OK) && (status != DECLINED)) { \
    MP_TRACE(fprintf(stderr, "%s handlers returned %d\n", h, status)); \
} \
else if(name != Nullav) { \
    MP_TRACE(fprintf(stderr, "running server configured stacked handlers...\n")); \
    status = perl_run_stacked_handlers(h, r, name); \
} \
release_mutex(mod_perl_mutex); \
MP_TRACE(fprintf(stderr, "%s handlers returned %d\n", h, status))


#else

#define PERL_TAKE TAKE1
#define PERL_CMD_INIT  NULL
#define PERL_CMD_TYPE  char

#define mod_perl_can_stack_handlers(sv) (SvTRUE(sv) && 0)

#define PERL_CALLBACK(h,name) \
if(name != NULL) { \
    SV *sv; \
    acquire_mutex(mod_perl_mutex); \
    sv = newSVpv(name,0); \
    status = perl_call_handler(sv, r, Nullav); \
    SvREFCNT_dec(sv); \
    release_mutex(mod_perl_mutex); \
    MP_TRACE(fprintf(stderr, "perl_call %s '%s' returned: %d\n", h,name,status)); \
} \
else { \
    MP_TRACE(fprintf(stderr, "mod_perl: declining to handle %s, no callback defined\n", h)); \
}

#endif

#define PERL_EXIT_CLEANUP log_transaction(r);

#if MODULE_MAGIC_NUMBER >= 19961007
#define CHAR_P const char *
#else
#define CHAR_P char * 
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

#ifdef MULTITHREAD
extern void *mod_perl_mutex;
#else
extern void *mod_perl_dummy_mutex;
#endif

#ifndef MULTITHREAD_H
typedef void mutex;
#define MULTI_OK (0)
#define create_mutex(name)	((mutex *)mod_perl_dummy_mutex)
#define acquire_mutex(mutex_id)	((int)MULTI_OK)
#define release_mutex(mutex_id)	((int)MULTI_OK)

#endif

/* on/off switches for callback hooks during request stages */

#ifndef NO_PERL_TRANS
#define PERL_TRANS

#define PERL_TRANS_HOOK perl_translate

#define PERL_TRANS_CMD_ENTRY \
"PerlTransHandler", perl_cmd_trans_handlers, \
    NULL,	 \
    RSRC_CONF, PERL_TAKE, "the Perl Translation handler routine name"  

#define PERL_TRANS_CREATE(s) s->PerlTransHandler = PERL_CMD_INIT
#else
#define PERL_TRANS_HOOK NULL
#define PERL_TRANS_CMD_ENTRY NULL
#define PERL_TRANS_CREATE(s) 
#endif

#ifndef NO_PERL_AUTHEN
#define PERL_AUTHEN

#define PERL_AUTHEN_HOOK perl_authenticate

#define PERL_AUTHEN_CMD_ENTRY \
"PerlAuthenHandler", perl_cmd_authen_handlers, \
    NULL, \
    OR_ALL, PERL_TAKE, "the Perl Authentication handler routine name"

#define PERL_AUTHEN_CREATE(s) s->PerlAuthenHandler = PERL_CMD_INIT
#else
#define PERL_AUTHEN_HOOK NULL
#define PERL_AUTHEN_CMD_ENTRY NULL
#define PERL_AUTHEN_CREATE(s)
#endif

#ifndef NO_PERL_AUTHZ
#define PERL_AUTHZ

#define PERL_AUTHZ_HOOK perl_authorize

#define PERL_AUTHZ_CMD_ENTRY \
"PerlAuthzHandler", perl_cmd_authz_handlers, \
    NULL, \
    OR_ALL, PERL_TAKE, "the Perl Authorization handler routine name" 
#define PERL_AUTHZ_CREATE(s) s->PerlAuthzHandler = PERL_CMD_INIT
#else
#define PERL_AUTHZ_HOOK NULL
#define PERL_AUTHZ_CMD_ENTRY NULL
#define PERL_AUTHZ_CREATE(s)
#endif

#ifndef NO_PERL_ACCESS
#define PERL_ACCESS

#define PERL_ACCESS_HOOK perl_access

#define PERL_ACCESS_CMD_ENTRY \
"PerlAccessHandler", perl_cmd_access_handlers, \
    NULL, \
    OR_ALL, PERL_TAKE, "the Perl Access handler routine name" 

#define PERL_ACCESS_CREATE(s) s->PerlAccessHandler = PERL_CMD_INIT
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
"PerlTypeHandler", perl_cmd_type_handlers, \
    NULL, \
    OR_ALL, PERL_TAKE, "the Perl Type check handler routine name" 

#define PERL_TYPE_CREATE(s) s->PerlTypeHandler = PERL_CMD_INIT
#else
#define PERL_TYPE_HOOK NULL
#define PERL_TYPE_CMD_ENTRY NULL
#define PERL_TYPE_CREATE(s) 
#endif

#ifndef NO_PERL_FIXUP
#define PERL_FIXUP

#define PERL_FIXUP_HOOK perl_fixup

#define PERL_FIXUP_CMD_ENTRY \
"PerlFixupHandler", perl_cmd_fixup_handlers, \
    NULL, \
    OR_ALL, PERL_TAKE, "the Perl Fixup handler routine name" 

#define PERL_FIXUP_CREATE(s) s->PerlFixupHandler = PERL_CMD_INIT
#else
#define PERL_FIXUP_HOOK NULL
#define PERL_FIXUP_CMD_ENTRY NULL
#define PERL_FIXUP_CREATE(s)
#endif

#ifndef NO_PERL_LOG
#define PERL_LOG

#define PERL_LOG_HOOK perl_logger

#define PERL_LOG_CMD_ENTRY \
"PerlLogHandler", perl_cmd_log_handlers, \
    NULL, \
    OR_ALL, PERL_TAKE, "the Perl Log handler routine name" 

#define PERL_LOG_CREATE(s) s->PerlLogHandler = PERL_CMD_INIT
#else
#define PERL_LOG_HOOK NULL
#define PERL_LOG_CMD_ENTRY NULL
#define PERL_LOG_CREATE(s) 
#endif

#ifndef NO_PERL_CLEANUP
#define PERL_CLEANUP

#define PERL_CLEANUP_HOOK perl_cleanup

#define PERL_CLEANUP_CMD_ENTRY \
"PerlCleanupHandler", perl_cmd_cleanup_handlers, \
    NULL, \
    OR_ALL, PERL_TAKE, "the Perl Cleanup handler routine name" 

#define PERL_CLEANUP_CREATE(s) s->PerlCleanupHandler = PERL_CMD_INIT
#else
#define PERL_CLEANUP_HOOK NULL
#define PERL_CLEANUP_CMD_ENTRY NULL
#define PERL_CLEANUP_CREATE(s)
#endif

#ifndef NO_PERL_INIT
#define PERL_INIT

#define PERL_INIT_HOOK perl_init

#define PERL_INIT_CMD_ENTRY \
"PerlInitHandler", perl_cmd_init_handlers, \
    NULL, \
    OR_ALL, PERL_TAKE, "the Perl Init handler routine name" 

#define PERL_INIT_CREATE(s) s->PerlInitHandler = PERL_CMD_INIT
#else
#define PERL_INIT_HOOK NULL
#define PERL_INIT_CMD_ENTRY NULL
#define PERL_INIT_CREATE(s) 
#endif

#ifndef NO_PERL_HEADER_PARSER
#define PERL_HEADER_PARSER

#define PERL_HEADER_PARSER_HOOK perl_header_parser

#define PERL_HEADER_PARSER_CMD_ENTRY \
"PerlHeaderParserHandler", perl_cmd_header_parser_handlers, \
    NULL, \
    OR_ALL, PERL_TAKE, "the Perl Header Parser handler routine name" 

#define PERL_HEADER_PARSER_CREATE(s) s->PerlHeaderParserHandler = PERL_CMD_INIT
#else
#define PERL_HEADER_PARSER_HOOK NULL
#define PERL_HEADER_PARSER_CMD_ENTRY NULL
#define PERL_HEADER_PARSER_CREATE(s)
#endif

typedef struct {
    char *PerlScript;
    char **PerlModules;
    int  NumPerlModules;
    int  PerlTaintCheck;
    PERL_CMD_TYPE   *PerlTransHandler;
    int  PerlWarn;
} perl_server_config;

typedef struct {
    PERL_CMD_TYPE *PerlHandler;
    PERL_CMD_TYPE *PerlAuthenHandler;
    PERL_CMD_TYPE *PerlAuthzHandler;
    PERL_CMD_TYPE *PerlAccessHandler;
    PERL_CMD_TYPE *PerlTypeHandler;
    PERL_CMD_TYPE *PerlFixupHandler;
    PERL_CMD_TYPE *PerlLogHandler;
    PERL_CMD_TYPE *PerlCleanupHandler;
    PERL_CMD_TYPE *PerlHeaderParserHandler;
    PERL_CMD_TYPE *PerlInitHandler;
    table *env;
    int has_env;
    table *vars;
    int  sendheader;
    int  new_sendheader;
    int setup_env;
} perl_dir_config;

extern module perl_module;

/* a couple for -Wall sanity sake */
int multi_log_transaction(request_rec *r);
int basic_http_header(request_rec *r);
/* prototypes */
int perl_handler_ismethod(HV *class, char *sub);
int perl_call_handler(SV *sv, request_rec *r, AV *args);
int mod_perl_push_handlers(SV *self, SV *hook, SV *sub, AV *handlers);
int perl_run_stacked_handlers(char *hook, request_rec *r, AV *handlers);
int perl_handler(request_rec *r);
void perl_startup(server_rec *s, pool *p);
void *perl_merge_dir_config(pool *p, void *basev, void *addv);
void *create_perl_dir_config(pool *p, char *dirname);
void *create_perl_server_config(pool *p, server_rec *s);
int perl_translate(request_rec *r);
int perl_authenticate(request_rec *r);
int perl_authorize(request_rec *r);
int perl_access(request_rec *r);
int perl_type_checker(request_rec *r);
int perl_fixup(request_rec *r);
int perl_logger(request_rec *r);
int perl_header_parser(request_rec *r);
CHAR_P perl_end_section (cmd_parms *cmd, void *dummy);
CHAR_P perl_section (cmd_parms *cmd, void *dummy, CHAR_P arg);
CHAR_P perl_urlsection (cmd_parms *cmd, void *dummy, HV *hv);
CHAR_P perl_cmd_script (cmd_parms *parms, void *dummy, char *arg);
CHAR_P perl_cmd_module (cmd_parms *parms, void *dummy, char *arg);
CHAR_P perl_cmd_var(cmd_parms *cmd, void *rec, char *key, char *val);
CHAR_P perl_cmd_setenv(cmd_parms *cmd, void *rec, char *key, char *val);
CHAR_P perl_cmd_sendheader (cmd_parms *cmd, void *rec, int arg);
CHAR_P perl_cmd_new_sendheader (cmd_parms *cmd, void *rec, int arg);
CHAR_P perl_cmd_tainting (cmd_parms *parms, void *dummy, int arg);
CHAR_P perl_cmd_warn (cmd_parms *parms, void *dummy, int arg);
CHAR_P perl_cmd_env (cmd_parms *cmd, void *rec, int arg);
void mod_perl_dir_env(perl_dir_config *cld);
CHAR_P perl_cmd_init_handlers (cmd_parms *parms, perl_dir_config *rec, char *arg);
CHAR_P perl_cmd_cleanup_handlers (cmd_parms *parms, perl_dir_config *rec, char *arg);
CHAR_P perl_cmd_header_parser_handlers (cmd_parms *parms, perl_dir_config *rec, char *arg);
CHAR_P perl_cmd_trans_handlers (cmd_parms *parms, void *dumm, char *arg);
CHAR_P perl_cmd_authen_handlers (cmd_parms *parms, perl_dir_config *rec, char *arg);
CHAR_P perl_cmd_authz_handlers (cmd_parms *parms, perl_dir_config *rec, char *arg);
CHAR_P perl_cmd_access_handlers (cmd_parms *parms, perl_dir_config *rec, char *arg);
CHAR_P perl_cmd_type_handlers (cmd_parms *parms, perl_dir_config *rec, char *arg);
CHAR_P perl_cmd_fixup_handlers (cmd_parms *parms, perl_dir_config *rec, char *arg);
CHAR_P perl_cmd_handler_handlers (cmd_parms *parms, perl_dir_config *rec, char *arg);
CHAR_P perl_cmd_log_handlers (cmd_parms *parms, perl_dir_config *rec, char *arg);

#ifdef APACHE_SSL
void xs_init (void);
#else
void xs_init _((void));
#endif
int mod_perl_sent_header(SV *self, int val);
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
void mod_perl_cleanup_handler(void *data);
void mod_perl_end_cleanup(void *data);
void mod_perl_register_cleanup(request_rec *r, SV *sv);
int PERL_RUNNING(void);
