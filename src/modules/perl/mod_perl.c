/* ====================================================================
 * Copyright (c) 1995,1996 The Apache Group.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer. 
 *
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in
 *    the documentation and/or other materials provided with the
 *    distribution.
 *
 * 3. All advertising materials mentioning features or use of this
 *    software must display the following acknowledgment:
 *    "This product includes software developed by the Apache Group
 *    for use in the Apache HTTP server project (http://www.apache.org/)."
 *
 * 4. The names "Apache Server" and "Apache Group" must not be used to
 *    endorse or promote products derived from this software without
 *    prior written permission.
 *
 * 5. Redistributions of any form whatsoever must retain the following
 *    acknowledgment:
 *    "This product includes software developed by the Apache Group
 *    for use in the Apache HTTP server project (http://www.apache.org/)."
 *
 * THIS SOFTWARE IS PROVIDED BY THE APACHE GROUP ``AS IS'' AND ANY
 * EXPRESSED OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE APACHE GROUP OR
 * ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 * ====================================================================
 *
 * This software consists of voluntary contributions made by many
 * individuals on behalf of the Apache Group and was originally based
 * on public domain software written at the National Center for
 * Supercomputing Applications, University of Illinois, Urbana-Champaign.
 * For more information on the Apache Group and the Apache HTTP server
 * project, please see <http://www.apache.org/>.
 *
 */

/* $Id: mod_perl.c,v 1.45 1997/03/23 18:50:37 dougm Exp $ */

/* 
 * And so it was decided the camel should be given magical multi-colored
 * feathers so it could fly and journey to once unknown worlds.
 * And so it was done...
 */

#include "mod_perl.h"

static IV mp_request_rec;
static int seqno = 0;
static int avoid_alloc_hack = 0;
static PerlInterpreter *perl = NULL;
#ifdef PERL_STACKED_HANDLERS
static HV *stacked_handlers = Nullhv;
#endif

static command_rec perl_cmds[] = {
    { "PerlTaintCheck", perl_cmd_tainting,
      NULL,
      RSRC_CONF, FLAG, "Turn on -T switch" },
    { "PerlWarn", perl_cmd_warn,
      NULL,
      RSRC_CONF, FLAG, "Turn on -w switch" },
    { "PerlScript", perl_cmd_script,
      NULL,
      RSRC_CONF, TAKE1, "A Perl script name" },
    { "PerlModule", perl_cmd_module,
      NULL,
      RSRC_CONF, ITERATE, "List of Perl modules" },
    { "PerlSetVar", perl_cmd_var,
      NULL,
      OR_ALL, TAKE2, "Perl config var and value" },
    { "PerlSendHeader", perl_cmd_sendheader,
      NULL,
      OR_ALL, FLAG, "Tell mod_perl to send basic_http_header" },
    { "PerlSetupEnv", perl_cmd_env,
      NULL,
      OR_ALL, FLAG, "Tell mod_perl to setup %ENV by default" },
    { "PerlHandler", perl_cmd_handler_handlers,
      NULL,
      OR_ALL, ITERATE, "the Perl handler routine name" },
#ifdef PERL_TRANS
    { PERL_TRANS_CMD_ENTRY },
#endif
#ifdef PERL_AUTHEN
    { PERL_AUTHEN_CMD_ENTRY },
#endif
#ifdef PERL_AUTHZ
    { PERL_AUTHZ_CMD_ENTRY },
#endif
#ifdef PERL_ACCESS
    { PERL_ACCESS_CMD_ENTRY },
#endif
#ifdef PERL_TYPE
    { PERL_TYPE_CMD_ENTRY },
#endif
#ifdef PERL_FIXUP
    { PERL_FIXUP_CMD_ENTRY },
#endif
#ifdef PERL_LOG
    { PERL_LOG_CMD_ENTRY },
#endif
#ifdef PERL_HEADER_PARSER
    { PERL_HEADER_PARSER_CMD_ENTRY },
#endif
    { NULL }
};

static handler_rec perl_handlers [] = {
    { PERL_APACHE_SSI_TYPE, perl_handler },
    { "perl-script", perl_handler },
    { NULL }
};

module perl_module = {
    STANDARD_MODULE_STUFF,
    perl_init,                 /* initializer */
    create_perl_dir_config,    /* create per-directory config structure */
    NULL,                      /* merge per-directory config structures */
    create_perl_server_config, /* create per-server config structure */
    NULL,                      /* merge per-server config structures */
    perl_cmds,                 /* command table */
    perl_handlers,             /* handlers */
    PERL_TRANS_HOOK,           /* translate_handler */
    PERL_AUTHEN_HOOK,          /* check_user_id */
    PERL_AUTHZ_HOOK,           /* check auth */
    PERL_ACCESS_HOOK,          /* check access */
    PERL_TYPE_HOOK,            /* type_checker */
    PERL_FIXUP_HOOK,           /* pre-run fixups */
    PERL_LOG_HOOK,          /* logger */
#if MODULE_MAGIC_NUMBER >= 19970103
    PERL_HEADER_PARSER_HOOK,   /* header parser */
#endif
};

#ifndef PERL_DO_ALLOC
#  ifdef APACHE_SSL
#    define PERL_DO_ALLOC 0
#  else
#    define PERL_DO_ALLOC 1
#  endif
#endif

void perl_init (server_rec *s, pool *p)
{
    char *argv[] = { "httpd", NULL, NULL, NULL, NULL };
    char *constants[] = { "Apache::Constants", "OK", "DECLINED", NULL };
    int status, i, argc=2, t=0, w=0;
    perl_server_config *cls;

    if(avoid_alloc_hack++ != PERL_DO_ALLOC) {
	CTRACE(stderr, "perl_init: skipping perl_alloc + perl_construct\n");
	return;
    }

    cls = get_module_config (s->module_config, &perl_module);   

#ifndef PERL_TRACE
    if (s->error_log)
	error_log2stderr(s);
#endif

    if (perl != NULL) {
	CTRACE(stderr, "destructing and freeing perl interpreter...ok\n");
	perl_destruct(perl);
	perl_free(perl);
    }

    CTRACE(stderr, "allocating perl interpreter...");
    if((perl = perl_alloc()) == NULL) {
	CTRACE(stderr, "not ok\n");
	perror("alloc");
	exit(1);
    }
    CTRACE(stderr, "ok\n");
  
    CTRACE(stderr, "constructing perl interpreter...ok\n");
    perl_construct(perl);
    perl_destruct_level = 0;

    /* fake-up what the shell usually gives perl */
    if((t = cls->PerlTaintCheck)) {
	argv[1] = "-T";
	argc++;
    }
    if((w = cls->PerlWarn)) {
	argv[1+t] = "-w";
	argc++;
    }

    argv[1+t+w] = cls->PerlScript;

    if (argv[1+t+w] == NULL) {
	argv[1+t+w] = "-e";
	argv[2+t+w] = "0";
	argc++;
    } 
    CTRACE(stderr, "parsing perl script: ");
    for(i=1; i<argc; i++)
	CTRACE(stderr, "'%s' ", argv[i]);
    CTRACE(stderr, "...");

    status = perl_parse(perl, xs_init, argc, argv, NULL);
    if (status != OK) {
	CTRACE(stderr,"not ok, status=%d\n", status);
	perror("parse");
	exit(1);
    }
    CTRACE(stderr, "ok\n");

    /* trick require now that TieHandle.pm is gone */
    hv_fetch(perl_get_hv("INC", TRUE), "Apache/TieHandle.pm", 19, 1);

    perl_clear_env;

    CTRACE(stderr, "running perl interpreter...");
    status = perl_run(perl);
    if (status != OK) {
	CTRACE(stderr,"not ok, status=%d\n", status);
	perror("run");
	exit(1);
    }
    CTRACE(stderr, "ok\n");

    for(i = 0; i < cls->NumPerlModules; i++) {
	if(perl_require_module(cls->PerlModules[i], s) != OK) {
	    fprintf(stderr, "Can't load Perl module `%s', exiting...\n", 
		    cls->PerlModules[i]);
	    exit(1);
	}
    }

    /* import Apache::Constants qw(OK DECLINED) */
    perl_call_argv("Exporter::import", G_DISCARD | G_EVAL, constants);
    if(perl_eval_ok(s) != OK) 
	perror("Apache::Constants->import failed");

#ifdef USE_SFIO
    sv_setiv(GvSV(gv_fetchpv("|", TRUE, SVt_PV)), 1); /* $|=1 */
#endif

    {
	GV *gv = gv_fetchpv("Apache::__T", GV_ADDMULTI, SVt_PV);
	if(cls->PerlTaintCheck) 
	    sv_setiv(GvSV(gv), 1);
	SvREADONLY_on(GvSV(gv));
    }
#ifdef PERL_STACKED_HANDLERS
    stacked_handlers = newHV();
#endif
}

void *create_perl_dir_config (pool *p, char *dirname)
{
    perl_dir_config *cld =
	(perl_dir_config *)palloc(p, sizeof (perl_dir_config));

    cld->vars = make_table(p, MAX_PERL_CONF_VARS); 
    cld->PerlHandler = NULL;
    cld->setup_env = 1;
    cld->sendheader = 0;
    PERL_AUTHEN_CREATE(cld);
    PERL_AUTHZ_CREATE(cld);
    PERL_ACCESS_CREATE(cld);
    PERL_TYPE_CREATE(cld);
    PERL_FIXUP_CREATE(cld);
    PERL_LOG_CREATE(cld);
    PERL_HEADER_PARSER_CREATE(cld);
    return (void *)cld;
}

void *create_perl_server_config (pool *p, server_rec *s)
{
    perl_server_config *cls =
	(perl_server_config *)palloc(p, sizeof (perl_server_config));

    cls->PerlModules = (char **)NULL; 
    cls->PerlModules = (char **)palloc(p, (MAX_PERL_MODS+1)*sizeof(char *));
    cls->PerlModules[0] = "Apache";
    cls->NumPerlModules = 1;
    cls->PerlScript = NULL;
    cls->PerlTaintCheck = 0;
    cls->PerlWarn = 0;
    PERL_TRANS_CREATE(cls);
    perl = NULL;

    return (void *)cls;
}

int perl_handler(request_rec *r)
{
    int status = OK;
    perl_dir_config *cld = get_module_config (r->per_dir_config,
					      &perl_module);   

    (void)perl_request_rec(r); 

    /* hookup STDIN & STDOUT to the client */
    perl_stdout2client(r);
    perl_stdin2client(r);

#ifndef PERL_TRACE
    /* hookup STDERR to the error_log */
    if (r->server->error_log)
	error_log2stderr(r->server);
#endif

    if(cld->sendheader) {
	CTRACE(stderr, "mod_perl sending basic_http_header...\n");
	basic_http_header(r);
    }
    if(cld->setup_env) 
	perl_setup_env(r);

    seqno++;
    PERL_CALLBACK_RETURN("PerlHandler", cld->PerlHandler);
}

#ifdef PERL_TRANS
int PERL_TRANS_HOOK(request_rec *r)
{
    int status = DECLINED;
    perl_server_config *cls = get_module_config (r->server->module_config,
						 &perl_module);   
    PERL_CALLBACK_RETURN("PerlTransHandler", cls->PerlTransHandler);
}
#endif

#ifdef PERL_AUTHEN
int PERL_AUTHEN_HOOK(request_rec *r)
{
    int status = DECLINED;
    perl_dir_config *cld = get_module_config (r->per_dir_config,
					      &perl_module);   
    PERL_CALLBACK_RETURN("PerlAuthenHandler", cld->PerlAuthenHandler);
}
#endif

#ifdef PERL_AUTHZ
int PERL_AUTHZ_HOOK(request_rec *r)
{
    int status = DECLINED;
    perl_dir_config *cld = get_module_config (r->per_dir_config,
					      &perl_module);   
    PERL_CALLBACK_RETURN("PerlAuthzHandler", cld->PerlAuthzHandler);
}
#endif

#ifdef PERL_ACCESS
int PERL_ACCESS_HOOK(request_rec *r)
{
    int status = DECLINED;
    perl_dir_config *cld = get_module_config (r->per_dir_config,
					      &perl_module);   
    PERL_CALLBACK_RETURN("PerlAccessHandler", cld->PerlAccessHandler);
}
#endif

#ifdef PERL_TYPE
int PERL_TYPE_HOOK(request_rec *r)
{
    int status = DECLINED;
    perl_dir_config *cld = get_module_config (r->per_dir_config,
					      &perl_module);   
    PERL_CALLBACK_RETURN("PerlTypeHandler", cld->PerlTypeHandler);
}
#endif

#ifdef PERL_FIXUP
int PERL_FIXUP_HOOK(request_rec *r)
{
    int status = DECLINED;
    perl_dir_config *cld = get_module_config (r->per_dir_config,
					      &perl_module);   
    PERL_CALLBACK_RETURN("PerlFixupHandler", cld->PerlFixupHandler);
}
#endif

#ifdef PERL_LOG
int PERL_LOG_HOOK(request_rec *r)
{
    int status = DECLINED;
    perl_dir_config *cld = get_module_config (r->per_dir_config,
					      &perl_module);   
    PERL_CALLBACK_RETURN("PerlLogHandler", cld->PerlLogHandler);
}
#endif

#ifdef PERL_HEADER_PARSER
int PERL_HEADER_PARSER_HOOK(request_rec *r)
{
    int status = DECLINED;
    perl_dir_config *cld = get_module_config (r->per_dir_config,
					      &perl_module);   
    PERL_CALLBACK_RETURN("PerlHeaderParserHandler", 
			 cld->PerlHeaderParserHandler);
}
#endif



#ifdef PERL_STACKED_HANDLERS
int mod_perl_push_handlers(SV *self, SV *hook, SV *sub, AV *handlers)
{
    char *key = SvPV(hook,na);
    int do_store=0;
    SV **svp;

    if(self && SvTRUE(sub)) {
	if(handlers == Nullav) {
	    svp = hv_fetch(stacked_handlers, key, SvCUR(hook), 0);
	    CTRACE(stderr, "fetching %s stack\n", key);
	    if(svp && SvTRUE(*svp) && SvROK(*svp)) {
		handlers = (AV*)SvRV(*svp);
	    }
	    else {
		CTRACE(stderr, "%s handlers stack undef, creating\n", key);
		handlers = (AV*)sv_2mortal((SV*)newAV());
	    }
	    do_store = 1;
	    CTRACE(stderr, "pushing CODE ref into `%s' handlers\n", key);
	}
	else
	    CTRACE(stderr, "pushing `%s' into `%s' handlers\n", SvPV(sub,na), key);

	SvREFCNT_inc((SV*)sub);
	av_push(handlers, sub);
	if(do_store)
	    hv_store(stacked_handlers, key, SvCUR(hook), 
		     (SV*)newRV((SV*)handlers), 0);
	return 1;
    }
    return 0;
}

int perl_run_stacked_handlers(char *hook, request_rec *r, AV *handlers)
{
    int count, status=DECLINED, do_clear=0;
    I32 i;
    SV *sub; 
    int hook_len = strlen(hook);
    SV **svp;

    if(handlers == Nullav) {
	svp = hv_fetch(stacked_handlers, hook, hook_len, 0);
	if(!svp || !SvTRUE(*svp) || !SvROK(*svp)) return DECLINED;
	handlers = (AV*)SvRV(*svp);
	do_clear = 1;
    }

    CTRACE(stderr, "%s av_len = %d\n", hook, (int)av_len(handlers));
    for(i=0; i<=av_len(handlers); i++) {
	dSP;
	ENTER;
	SAVETMPS;
	PUSHMARK(sp);
	XPUSHs((SV*)perl_bless_request_rec(r)); 
	PUTBACK;
    
	/* reset $$ */
	perl_set_pid;
	CTRACE(stderr, "calling &{%s->[%d]}\n", hook, (int)i);
	/* if a Perl*Handler is not a defined function name,
	 * default to the class implementor's handler() function
	 * attempt to load the class module if it is not already
	 */
	if(!(sub = *av_fetch(handlers, i, FALSE))) {
	    CTRACE(stderr, "sub not defined!\n");
	}

	if(SvTYPE(sub) == SVt_PV) {
	    char *imp = SvPV(sub,na);
	    if(!perl_get_cv(imp, FALSE) || 
	       !GvCV(gv_fetchmethod(NULL, imp)))
	       { 
		   if(!gv_stashpv(imp, FALSE)) {
		       perl_require_module(imp, r->server);
		   }
		   sv_catpv(sub, "::handler");
		   CTRACE(stderr, 
			  "perl_call: defaulting to %s::handler\n", imp);
	       }
	}

	/* use G_EVAL so we can trap errors */
	count = perl_call_sv(sub, G_EVAL | G_SCALAR);
    
	SPAGAIN;

	if(perl_eval_ok(r->server) != OK) {
	    if(do_clear)
		av_clear(handlers);	
	    return SERVER_ERROR;
	}
	if(count != 1) {
	    log_error("perl_call did not return a status arg, assuming OK",
		      r->server);
	    status = OK;
	}
	status = POPi;

	if((status == 1) || (status == 200) || (status > 600)) 
	    status = OK; 
      
	PUTBACK;
	FREETMPS;
	LEAVE;

	if((status != OK) && (status != DECLINED)) {
	    if(do_clear)
		av_clear(handlers);	
	    return status;
	}

    }
    perl_clear_env;
    if(do_clear)
	av_clear(handlers);	
    return status;
}

#define PERL_CMD_PUSH_HANDLERS(hook, cmd) \
{ \
    if(avoid_alloc_hack < PERL_DO_ALLOC) return NULL; \
    if(!cmd) cmd = newAV(); \
    CTRACE(stderr, "perl_cmd_push_handlers: @%s, '%s'\n", hook, arg); \
    mod_perl_push_handlers(&sv_yes, newSVpv(hook,0), newSVpv(arg,0), cmd); \
    return NULL; \
}

#else

int mod_perl_push_handlers(SV *self, SV *hook, SV *sub, AV *handlers)
{
    warn("Rebuild with -DPERL_STACKED_HANDLERS to $r->push_handlers");
    return 0;
}

int perl_call(char *imp, request_rec *r)
{
    int count, status;
    SV *sv = newSVpv(imp,0);

    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(sp);
    XPUSHs((SV*)perl_bless_request_rec(r)); 
    PUTBACK;
    
    /* reset $$ */
    perl_set_pid;

    /* if a Perl*Handler is not a defined function name,
     * default to the class implementor's handler() function
     * attempt to load the class module if it is not already
     */
    if(!perl_get_cv(imp, FALSE) || !GvCV(gv_fetchmethod(NULL, imp))) { 
	if(!gv_stashpv(imp, FALSE)) {
	    CTRACE(stderr, "%s symbol table not found, loading...\n", imp);
	    perl_require_module(imp, r->server);
	}
	sv_catpv(sv, "::handler");
	CTRACE(stderr, "perl_call: defaulting to %s::handler\n", imp);
    }

    /* use G_EVAL so we can trap errors */
    count = perl_call_sv(sv, G_EVAL | G_SCALAR);
    
    SPAGAIN;

    if(perl_eval_ok(r->server) != OK) 
	return SERVER_ERROR;
    
    if(count != 1) {
	log_error("perl_call did not return a status arg, assuming OK",
		  r->server);
	status = OK;
    }
    status = POPi;

    if((status == 1) || (status == 200) || (status > 600)) 
	status = OK; 
      
    PUTBACK;
    FREETMPS;
    LEAVE;

    perl_clear_env;

    return status;
}

#define PERL_CMD_PUSH_HANDLERS(hook, cmd) \
cmd = arg; \
return NULL

#endif

CHAR_P perl_cmd_header_parser_handlers (cmd_parms *parms, perl_dir_config *rec, char *arg)
{
    PERL_CMD_PUSH_HANDLERS("PerlHeaderParserHandler",
			   rec->PerlHeaderParserHandler);
}
CHAR_P perl_cmd_trans_handlers (cmd_parms *parms, void *dummy, char *arg)
{
    perl_server_config *cls = 
	get_module_config (parms->server->module_config, &perl_module);   
    PERL_CMD_PUSH_HANDLERS("PerlTransHandler", cls->PerlTransHandler);
}
CHAR_P perl_cmd_authen_handlers (cmd_parms *parms, perl_dir_config *rec, char *arg)
{
    PERL_CMD_PUSH_HANDLERS("PerlAuthenHandler", rec->PerlAuthenHandler);
}
CHAR_P perl_cmd_authz_handlers (cmd_parms *parms, perl_dir_config *rec, char *arg)
{
    PERL_CMD_PUSH_HANDLERS("PerlAuthzHandler", rec->PerlAuthzHandler);
}
CHAR_P perl_cmd_access_handlers (cmd_parms *parms, perl_dir_config *rec, char *arg)
{
    PERL_CMD_PUSH_HANDLERS("PerlAccessHandler", rec->PerlAccessHandler);
}
CHAR_P perl_cmd_type_handlers (cmd_parms *parms, perl_dir_config *rec, char *arg)
{
    PERL_CMD_PUSH_HANDLERS("PerlTypeHandler",  rec->PerlTypeHandler);
}
CHAR_P perl_cmd_fixup_handlers (cmd_parms *parms, perl_dir_config *rec, char *arg)
{
    PERL_CMD_PUSH_HANDLERS("PerlFixupHandler", rec->PerlFixupHandler);
}
CHAR_P perl_cmd_handler_handlers (cmd_parms *parms, perl_dir_config *rec, char *arg)
{
    PERL_CMD_PUSH_HANDLERS("PerlHandler", rec->PerlHandler);
}
CHAR_P perl_cmd_log_handlers (cmd_parms *parms, perl_dir_config *rec, char *arg)
{
    PERL_CMD_PUSH_HANDLERS("PerlLogHandler", rec->PerlLogHandler);
}

CHAR_P perl_cmd_module (cmd_parms *parms, void *dummy, char *arg)
{
    perl_server_config *cls = 
	get_module_config (parms->server->module_config, &perl_module);   

    CTRACE(stderr, "push_perl_modules: arg='%s'\n", arg);
    if (cls->NumPerlModules >= MAX_PERL_MODS) {
	CTRACE(stderr, "mod_perl: There's a limit of %d PerlModules, use a PerlScript to pull in as many as you want\n", MAX_PERL_MODS);
	exit(-1);
    }
	
    cls->PerlModules[cls->NumPerlModules++] = arg;
    return NULL;
}

CHAR_P perl_cmd_script (cmd_parms *parms, void *dummy, char *arg)
{
    perl_server_config *cls = 
	get_module_config (parms->server->module_config, &perl_module);   

    CTRACE(stderr, "perl_cmd_script: %s\n", arg);
    cls->PerlScript = arg;
    return NULL;
}

CHAR_P perl_cmd_tainting (cmd_parms *parms, void *dummy, int arg)
{
    perl_server_config *cls = 
	get_module_config (parms->server->module_config, &perl_module);   

    CTRACE(stderr, "perl_cmd_tainting: %d\n", arg);
    cls->PerlTaintCheck = arg;
    return NULL;
}

CHAR_P perl_cmd_warn (cmd_parms *parms, void *dummy, int arg)
{
    perl_server_config *cls = 
	get_module_config (parms->server->module_config, &perl_module);   

    CTRACE(stderr, "perl_cmd_warn: %d\n", arg);
    cls->PerlWarn = arg;
    return NULL;
}

CHAR_P perl_cmd_sendheader (cmd_parms *cmd, void *rec, int arg) {
    ((perl_dir_config *)rec)->sendheader = arg;
    return NULL;
}

CHAR_P perl_cmd_env (cmd_parms *cmd, void *rec, int arg) {
    ((perl_dir_config *)rec)->setup_env = arg;
    return NULL;
}

CHAR_P perl_cmd_var(cmd_parms *cmd, void *rec, char *key, char *val)
{
    table_set(((perl_dir_config *)rec)->vars, key, val);
    CTRACE(stderr, "perl_cmd_var: '%s' = '%s'\n", key, val);
    return NULL;
}

/* just so we can be -Wall clean, maybe better to re-work PERL_TRACE */
int mp_void_fprintf(FILE *fp, const char *fmt, ...)
{
    return 1;
}

request_rec *perl_request_rec(request_rec *r)
{
    /* This will depreciate */
    /* CTRACE(stderr, "perl_request_rec\n"); */
    if(r != NULL) {
	mp_request_rec = (IV)r;
	return NULL;
    }
    else
	return (request_rec *)mp_request_rec;
}

SV *perl_bless_request_rec(request_rec *r)
{
    SV *sv = sv_newmortal();
    sv_setref_pv(sv, "Apache", (void*)r);
    CTRACE(stderr, "blessing request_rec\n");
    return sv;
}

int perl_eval_ok(server_rec *s)
{
    SV *sv;
    sv = GvSV(gv_fetchpv("@", TRUE, SVt_PV));
    if(SvTRUE(sv)) {
	CTRACE(stderr, "perl_eval error: %s\n", SvPV(sv,na));
	log_error(SvPV(sv, na), s);
	return -1;
    }
    return 0;
}

int perl_require_module(char *mod, server_rec *s)
{
    SV *sv = sv_newmortal();
    SV *m = newSVpv(mod,0);
    CTRACE(stderr, "loading perl module '%s'...", mod); 
    sv_setpv(sv, "require ");
    sv_catsv(sv, m);
    perl_eval_sv(sv, G_DISCARD);
    if(perl_eval_ok(s) != OK) {
	CTRACE(stderr, "not ok\n");
	return -1;
    }
    CTRACE(stderr, "ok\n");
    return 0;
}

void perl_setup_env(request_rec *r)
{ 
    int klen;
    array_header *env_arr = table_elts (r->subprocess_env); 
    HV *cgienv = PerlEnvHV;
    CGIENVinit; 

    if (tz != NULL) 
	hv_store(cgienv, "TZ", 2, newSVpv(tz,0), 0);
    
    for (i = 0; i < env_arr->nelts; ++i) {
	if (!elts[i].key) continue;
	klen = strlen(elts[i].key);  
	hv_store(cgienv, elts[i].key, klen,
		 newSVpv(elts[i].val,0), 0);
	HV_SvTAINTED_on(cgienv, elts[i].key, klen);
    }
    CTRACE(stderr, "perl_setup_env...%d keys\n", i);
}

#ifdef USE_SFIO

typedef struct {
    Sfdisc_t     disc;   /* the sfio discipline structure */
    request_rec	*r;
} Apache_t;

static int sfapachewrite(f, buffer, n, disc)
    Sfio_t* f;      /* stream involved */
    char*           buffer;    /* buffer to read into */
    int             n;      /* number of bytes to send */
    Sfdisc_t*       disc;   /* discipline */        
{
    request_rec	*r = ((Apache_t*)disc)->r;
    /* CTRACE(stderr, "sfapachewrite: send %d bytes\n", n); */
    SENDN_TO_CLIENT;
    return n;
}

static int sfapacheread(f, buffer, bufsiz, disc)
    Sfio_t* f;      /* stream involved */
    char*           buffer;    /* buffer to read into */
    int             bufsiz;      /* number of bytes to read */
    Sfdisc_t*       disc;   /* discipline */        
{
    long nrd;
    request_rec	*r = ((Apache_t*)disc)->r;
    CTRACE(stderr, "sfapacheread: want %d bytes\n", bufsiz); 
    PERL_READ_FROM_CLIENT;
    return bufsiz;
}

Sfdisc_t * sfdcnewapache(request_rec *r)
{
    Apache_t*   disc;
    
    if(!(disc = (Apache_t*)malloc(sizeof(Apache_t))) )
	return (Sfdisc_t *)disc;
    CTRACE(stderr, "sfdcnewapache(r)\n");
    disc->disc.readf   = (Sfread_f)sfapacheread; 
    disc->disc.writef  = (Sfwrite_f)sfapachewrite;
    disc->disc.seekf   = (Sfseek_f)NULL;
    disc->disc.exceptf = (Sfexcept_f)NULL;
    disc->r = r;
    return (Sfdisc_t *)disc;
}
#endif

void perl_stdout2client(request_rec *r)
{
#ifdef USE_SFIO
    sfdisc(PerlIO_stdout(), SF_POPDISC);
    sfdisc(PerlIO_stdout(), sfdcnewapache(r));
#else
    GV *handle = gv_fetchpv("STDOUT", TRUE, SVt_PVIO);  

#if 0 
/* XXX so Perl*Handler's can re-tie before PerlHandler is run? 
 * then they'd also be reponsible for re-tie'ing to `Apache'
 * after all PerlHandlers are run, hmm must think.
 */
    MAGIC *mg;
    if (SvMAGICAL(handle) && (mg = mg_find((SV*)handle, 'q'))) {
	char *package = HvNAME(SvSTASH((SV*)SvRV(mg->mg_obj)));
	if(!strEQ(package, "Apache")) {
	    fprintf(stderr, "%s tied to %s\n", GvNAME(handle), package);
	    return;
	}
    }
#endif

    CTRACE(stderr, "tie *STDOUT => Apache\n");

    sv_magic((SV *)handle, 
	     (SV *)perl_bless_request_rec(r),
	     'q', Nullch, 0);
#endif
}

void perl_stdin2client(request_rec *r)
{
#ifdef USE_SFIO
    sfdisc(PerlIO_stdin(), SF_POPDISC);
    sfdisc(PerlIO_stdin(), sfdcnewapache(r));
    sfsetbuf(PerlIO_stdin(), NULL, 0);
#else
    CTRACE(stderr, "tie *STDIN => Apache\n");
    sv_magic((SV *)gv_fetchpv("STDIN", TRUE, SVt_PVIO), 
	     (SV *)perl_bless_request_rec(r),
	     'q', Nullch, 0);
#endif
}

int mod_perl_seqno(void)
{
    return seqno;
}

int perl_hook(char *name)
{
    switch (*name) {
	case 'A':
	    if (strEQ(name, "Authen")) 
#ifdef PERL_AUTHEN
		return 1;
#else
	return 0;    
#endif
	if (strEQ(name, "Authz"))
#ifdef PERL_AUTHZ
	    return 1;
#else
	return 0;    
#endif
	if (strEQ(name, "Access"))
#ifdef PERL_AUTHZ
	    return 1;
#else
	return 0;    
#endif
	break;
	case 'F':
	    if (strEQ(name, "Fixup")) 
#ifdef PERL_FIXUP
		return 1;
#else
	return 0;    
#endif
	break;
#if MODULE_MAGIC_NUMBER >= 19970103
	case 'H':
	    if (strEQ(name, "HeaderParser")) 
#ifdef PERL_HEADER_PARSER
		return 1;
#else
	return 0;    
#endif
	break;
#endif
	case 'L':
	    if (strEQ(name, "Log")) 
#ifdef PERL_LOG
		return 1;
#else
	return 0;    
#endif
	break;
	case 'T':
	    if (strEQ(name, "Trans")) 
#ifdef PERL_TRANS
		return 1;
#else
	return 0;    
#endif
        if (strEQ(name, "Type")) 
#ifdef PERL_TYPE
	    return 1;
#else
	return 0;    
#endif
	break;
    }
    return 0;
}

