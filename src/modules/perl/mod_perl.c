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

/* $Id: mod_perl.c,v 1.40 1997/03/10 00:25:45 dougm Exp $ */

/* 
 * And so it was decided the camel should be given magical multi-colored
 * feathers so it could fly and journey to once unknown worlds.
 * And so it was done...
 */

#include "mod_perl.h"

static int avoid_alloc_hack = 0;

static PerlInterpreter *perl = NULL;

static command_rec perl_cmds[] = {
    { "PerlTaintCheck", set_perl_tainting,
      NULL,
      RSRC_CONF, FLAG, "Turn on -T switch" },
    { "PerlWarn", set_perl_warn,
      NULL,
      RSRC_CONF, FLAG, "Turn on -w switch" },
    { "PerlScript", set_perl_script,
      NULL,
      RSRC_CONF, TAKE1, "A Perl script name" },
    { "PerlModule", push_perl_modules,
      NULL,
      RSRC_CONF, ITERATE, "List of Perl modules" },
    { "PerlSetVar", set_perl_var,
      NULL,
      OR_ALL, TAKE2, "Perl config var and value" },
    { "PerlSendHeader", perl_sendheader_on,
      NULL,
      OR_ALL, FLAG, "Tell mod_perl to send basic_http_header" },
    { "PerlSetupEnv", perl_set_env_on,
      NULL,
      OR_ALL, FLAG, "Tell mod_perl to setup %ENV by default" },
    { "PerlHandler", set_string_slot,
      (void*)XtOffsetOf(perl_dir_config, PerlHandler),
      OR_ALL, TAKE1, "the Perl handler routine name" },
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
    if(t = cls->PerlTaintCheck) {
	argv[1] = "-T";
	argc++;
    }
    if(w = cls->PerlWarn) {
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

    for(i = 0; i < cls->NumPerlModules; i++) {
	if(perl_require_module(cls->PerlModules[i], s) != OK) {
	    fprintf(stderr, "Can't load Perl module `%s', exiting...\n", cls->PerlModules[i]);
	    exit(1);
	}
    }

    /* trick require now that TieHandle.pm is gone */
    hv_fetch(perl_get_hv("INC", TRUE), "Apache/TieHandle.pm", 19, 1);

    perl_clear_env();

    CTRACE(stderr, "running perl interpreter...");
    status = perl_run(perl);
    if (status != OK) {
	CTRACE(stderr,"not ok, status=%d\n", status);
	perror("run");
	exit(1);
    }
    CTRACE(stderr, "ok\n");

    /* import Apache::Constants qw(OK DECLINED) */
    perl_call_argv("Exporter::import", G_DISCARD | G_EVAL, constants);
    if(perl_eval_ok(s) != OK) 
	perror("Apache::Constants->import failed");

    {
	GV *gv = gv_fetchpv("Apache::__T", GV_ADDMULTI, SVt_PV);
	if(cls->PerlTaintCheck) 
	    sv_setiv(GvSV(gv), 1);
	SvREADONLY_on(GvSV(gv));
    }
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

    perl_set_request_rec(r); 

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

    PERL_CALLBACK_RETURN("handler", cld->PerlHandler);
}

#ifdef PERL_TRANS
int PERL_TRANS_HOOK(request_rec *r)
{
    int status = DECLINED;
    perl_server_config *cls = get_module_config (r->server->module_config,
						 &perl_module);   
    PERL_CALLBACK_RETURN("translate", cls->PerlTransHandler);
}
#endif

#ifdef PERL_AUTHEN
int PERL_AUTHEN_HOOK(request_rec *r)
{
    int status = DECLINED;
    perl_dir_config *cld = get_module_config (r->per_dir_config,
					      &perl_module);   
    PERL_CALLBACK_RETURN("authenticate", cld->PerlAuthnHandler);
}
#endif

#ifdef PERL_AUTHZ
int PERL_AUTHZ_HOOK(request_rec *r)
{
    int status = DECLINED;
    perl_dir_config *cld = get_module_config (r->per_dir_config,
					      &perl_module);   
    PERL_CALLBACK_RETURN("authorize", cld->PerlAuthzHandler);
}
#endif

#ifdef PERL_ACCESS
int PERL_ACCESS_HOOK(request_rec *r)
{
    int status = DECLINED;
    perl_dir_config *cld = get_module_config (r->per_dir_config,
					      &perl_module);   
    PERL_CALLBACK_RETURN("access", cld->PerlAccessHandler);
}
#endif

#ifdef PERL_TYPE
int PERL_TYPE_HOOK(request_rec *r)
{
    int status = DECLINED;
    perl_dir_config *cld = get_module_config (r->per_dir_config,
					      &perl_module);   
    PERL_CALLBACK_RETURN("type", cld->PerlTypeHandler);
}
#endif

#ifdef PERL_FIXUP
int PERL_FIXUP_HOOK(request_rec *r)
{
    int status = DECLINED;
    perl_dir_config *cld = get_module_config (r->per_dir_config,
					      &perl_module);   
    PERL_CALLBACK_RETURN("fixup", cld->PerlFixupHandler);
}
#endif

#ifdef PERL_LOG
int PERL_LOG_HOOK(request_rec *r)
{
    int status = DECLINED;
    perl_dir_config *cld = get_module_config (r->per_dir_config,
					      &perl_module);   
    PERL_CALLBACK_RETURN("logger", cld->PerlLogHandler);
}
#endif

#ifdef PERL_HEADER_PARSER
int PERL_HEADER_PARSER_HOOK(request_rec *r)
{
    int status = DECLINED;
    perl_dir_config *cld = get_module_config (r->per_dir_config,
					      &perl_module);   
    PERL_CALLBACK_RETURN("header_parser", cld->PerlHeaderParserHandler);
}
#endif

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
    perl_set_pid();

    /* if a Perl*Handler is not a defined function name,
     * default to the class implementor's handler() function
     * attempt to load the class module if it is not already
     */
    if(instr(imp, "::")) {
	if(!perl_get_cv(imp, FALSE) || !GvCV(gv_fetchmethod(NULL, imp))) { 
	    if(!gv_stashpv(imp, FALSE)) {
		CTRACE(stderr, "%s symbol table not found, loading...\n", imp);
		perl_require_module(imp, r->server);
	    }
	    sv_catpv(sv, "::handler");
	    CTRACE(stderr, "perl_call: defaulting to %s::handler\n", imp);
	}
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

    perl_clear_env();

    return status;
}

CHAR_P push_perl_modules (cmd_parms *parms, void *dummy, char *arg)
{
    perl_server_config *cls = 
	get_module_config (parms->server->module_config, &perl_module);   

    CTRACE(stderr, "push_perl_modules: arg='%s'\n", arg);
    if (cls->NumPerlModules >= MAX_PERL_MODS) {
	fprintf(stderr, "mod_perl: There's a limit of %d PerlModules, use a PerlScript to pull in as many as you want\n", MAX_PERL_MODS);
	exit(-1);
    }
	
    cls->PerlModules[cls->NumPerlModules++] = arg;
    return NULL;
}

#ifdef PERL_TRANS
CHAR_P set_perl_trans (cmd_parms *parms, void *dummy, char *arg)
{
    perl_server_config *cls = 
	get_module_config (parms->server->module_config, &perl_module);   

    CTRACE(stderr, "set_perl_trans: %s\n", arg);
    cls->PerlTransHandler = arg;
    return NULL;
}
#endif

CHAR_P set_perl_script (cmd_parms *parms, void *dummy, char *arg)
{
    perl_server_config *cls = 
	get_module_config (parms->server->module_config, &perl_module);   

    CTRACE(stderr, "set_perl_script: %s\n", arg);
    cls->PerlScript = arg;
    return NULL;
}

CHAR_P set_perl_tainting (cmd_parms *parms, void *dummy, int arg)
{
    perl_server_config *cls = 
	get_module_config (parms->server->module_config, &perl_module);   

    CTRACE(stderr, "set_perl_tainting: %d\n", arg);
    cls->PerlTaintCheck = arg;
    return NULL;
}

CHAR_P set_perl_warn (cmd_parms *parms, void *dummy, int arg)
{
    perl_server_config *cls = 
	get_module_config (parms->server->module_config, &perl_module);   

    CTRACE(stderr, "set_perl_warn: %d\n", arg);
    cls->PerlWarn = arg;
    return NULL;
}

CHAR_P perl_sendheader_on (cmd_parms *cmd, void *rec, int arg) {
    ((perl_dir_config *)rec)->sendheader = arg;
    return NULL;
}

CHAR_P perl_set_env_on (cmd_parms *cmd, void *rec, int arg) {
    ((perl_dir_config *)rec)->setup_env = arg;
    return NULL;
}

CHAR_P set_perl_var(cmd_parms *cmd, void *rec, char *key, char *val)
{
    table_set(((perl_dir_config *)rec)->vars, key, val);
    CTRACE(stderr, "set_perl_var: '%s' = '%s'\n", key, val);
    return NULL;
}
