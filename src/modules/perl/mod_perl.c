/* ====================================================================
 * Copyright (c) 1995-1997 The Apache Group.  All rights reserved.
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

/* $Id: mod_perl.c,v 1.55 1997/05/19 22:25:31 dougm Exp $ */

/* 
 * And so it was decided the camel should be given magical multi-colored
 * feathers so it could fly and journey to once unknown worlds.
 * And so it was done...
 */

#define CORE_PRIVATE 
#include "mod_perl.h"

static IV mp_request_rec;
static int seqno = 0;
static int perl_is_running = 0;
static int sent_header = 1;
static int registered_cleanups = 0;
static int set_pid = 0;
static PerlInterpreter *perl = NULL;
static AV *orig_inc = Nullav;
static AV *cleanup_av = Nullav;
#ifdef PERL_STACKED_HANDLERS
static HV *stacked_handlers = Nullhv;
#endif

static command_rec perl_cmds[] = {
#ifdef PERL_SECTIONS
    { "<Perl>", perl_section, NULL, RSRC_CONF, RAW_ARGS, "Perl code" },
    { "</Perl>", perl_end_section, NULL, ACCESS_CONF, NO_ARGS, NULL },
#endif
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
    { "PerlSetEnv", perl_cmd_setenv,
      NULL,
      OR_ALL, TAKE2, "Perl %ENV key and value" },
    { "PerlSendHeader", perl_cmd_sendheader,
      NULL,
      OR_ALL, FLAG, "Tell mod_perl to send basic_http_header" },
    { "PerlNewSendHeader", perl_cmd_new_sendheader,
      NULL,
      OR_ALL, FLAG, "Tell mod_perl to parse and send HTTP headers" },
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
#ifdef PERL_CLEANUP
    { PERL_CLEANUP_CMD_ENTRY },
#endif
#ifdef PERL_INIT
    { PERL_INIT_CMD_ENTRY },
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
    perl_startup,                 /* initializer */
    create_perl_dir_config,    /* create per-directory config structure */
    perl_merge_dir_config,     /* merge per-directory config structures */
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

#if defined(STRONGHOLD) && !defined(APACHE_SSL)
#define APACHE_SSL
#endif

#ifndef PERL_DO_ALLOC
#  ifdef APACHE_SSL
#    define PERL_DO_ALLOC 0
#  else
#    define PERL_DO_ALLOC 1
#  endif
#endif

int PERL_RUNNING (void) 
{
    MP_TRACE(fprintf(stderr, "PERL_RUNNING=%d\n", perl_is_running));
    return (perl_is_running);
}

void perl_startup (server_rec *s, pool *p)
{
    char *argv[] = { NULL, NULL, NULL, NULL, NULL };
    char *constants[] = { "Apache::Constants", "OK", "DECLINED", NULL };
    int status, i, argc=2, t=0, w=0;
    perl_server_config *cls;

    argv[0] = server_argv0;
#ifndef PERL_SECTIONS
    perl_destruct_level = 0;
#else
    perl_destruct_level = 1;
#endif

    if(perl_is_running++) {
	if(perl_is_running > 2) {
#if 0 /* XXX restarts are _tricky_, it'll work right someday, maybe */
	    fprintf(stderr, "mod_perl_restart: \n");
	    if (perl_destruct_level > 0) {
		MP_TRACE(fprintf(stderr, 
			 "destructing and freeing perl interpreter...ok\n"));
		perl_destruct(perl);
		perl_free(perl);
	    }
	    else
		return;
#else
	    MP_TRACE(fprintf(stderr, "perl_startup: perl aleady running...ok\n"));
	    return;
#endif

	}
	else {
	    MP_TRACE(fprintf(stderr, "perl_startup: perl aleady running...ok\n"));
	    return;
	}
    }
    cls = get_module_config (s->module_config, &perl_module);   

#ifndef PERL_TRACE
    if (s->error_log)
	error_log2stderr(s);
#endif

    MP_TRACE(fprintf(stderr, "allocating perl interpreter..."));
    if((perl = perl_alloc()) == NULL) {
	MP_TRACE(fprintf(stderr, "not ok\n"));
	perror("alloc");
	exit(1);
    }
    MP_TRACE(fprintf(stderr, "ok\n"));
  
    MP_TRACE(fprintf(stderr, "constructing perl interpreter...ok\n"));
    perl_construct(perl);

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
    MP_TRACE(fprintf(stderr, "parsing perl script: "));
    for(i=1; i<argc; i++)
	MP_TRACE(fprintf(stderr, "'%s' ", argv[i]));
    MP_TRACE(fprintf(stderr, "..."));

    status = perl_parse(perl, xs_init, argc, argv, NULL);
    if (status != OK) {
	MP_TRACE(fprintf(stderr,"not ok, status=%d\n", status));
	perror("parse");
	exit(1);
    }
    MP_TRACE(fprintf(stderr, "ok\n"));

    /* trick require now that TieHandle.pm is gone */
    hv_fetch(perl_get_hv("INC", TRUE), "Apache/TieHandle.pm", 19, 1);

    perl_clear_env;

    MP_TRACE(fprintf(stderr, "running perl interpreter..."));
    status = perl_run(perl);
    if (status != OK) {
	MP_TRACE(fprintf(stderr,"not ok, status=%d\n", status));
	perror("run");
	exit(1);
    }
    MP_TRACE(fprintf(stderr, "ok\n"));

    hv_store(PerlEnvHV, "GATEWAY_INTERFACE", 17, 
	     newSVpv(PERL_GATEWAY_INTERFACE,0), 0);

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

    orig_inc = av_copy_array(GvAV(incgv));

    {
	GV *gv = gv_fetchpv("Apache::__T", GV_ADDMULTI, SVt_PV);
	if(cls->PerlTaintCheck) 
	    sv_setiv(GvSV(gv), 1);
	SvREADONLY_on(GvSV(gv));
    }
#ifdef PERL_STACKED_HANDLERS
    if(!stacked_handlers)
	stacked_handlers = newHV();
#endif 
}

int mod_perl_sent_header(SV *self, int val)
{
    if(val) sent_header = val;
    return sent_header;
}

int perl_handler(request_rec *r)
{
    int status = OK;
    perl_dir_config *cld = get_module_config (r->per_dir_config,
					      &perl_module);   

    (void)perl_request_rec(r); 

#ifdef USE_SFIO
    IoFLAGS(GvIOp(defoutgv)) |= IOf_FLUSH; /* $|=1 */
#else
    IoFLAGS(GvIOp(defoutgv)) &= ~IOf_FLUSH; /* $|=0 */
#endif

    /* hookup STDIN & STDOUT to the client */
    perl_stdout2client(r);
    perl_stdin2client(r);

#ifndef PERL_TRACE
    /* hookup STDERR to the error_log */
    if (r->server->error_log)
	error_log2stderr(r->server);
#endif

    seqno++;
    register_cleanup(r->pool, NULL, mod_perl_end_cleanup, NULL);

    /*don't do anything special unless PerlNewSendHeader*/ 
    sent_header = (cld->new_sendheader ? 0 : 1); 
    if(cld->sendheader) {
	MP_TRACE(fprintf(stderr, "mod_perl sending basic_http_header...\n"));
	basic_http_header(r);
    }
    if(cld->setup_env) 
	perl_setup_env(r);

    mod_perl_dir_env(cld);
    PERL_CALLBACK("PerlHandler", cld->PerlHandler);
    return status;
}

#ifdef PERL_TRANS
int PERL_TRANS_HOOK(request_rec *r)
{
    int status = DECLINED;
    perl_server_config *cls = get_module_config (r->server->module_config,
						 &perl_module);   
    PERL_CALLBACK("PerlTransHandler", cls->PerlTransHandler);
    return status;
}
#endif

#ifdef PERL_AUTHEN
int PERL_AUTHEN_HOOK(request_rec *r)
{
    int status = DECLINED;
    perl_dir_config *cld = get_module_config (r->per_dir_config,
					      &perl_module);   
    mod_perl_dir_env(cld);
    PERL_CALLBACK("PerlAuthenHandler", cld->PerlAuthenHandler);
    return status;
}
#endif

#ifdef PERL_AUTHZ
int PERL_AUTHZ_HOOK(request_rec *r)
{
    int status = DECLINED;
    perl_dir_config *cld = get_module_config (r->per_dir_config,
					      &perl_module);   
    mod_perl_dir_env(cld);
    PERL_CALLBACK("PerlAuthzHandler", cld->PerlAuthzHandler);
    return status;
}
#endif

#ifdef PERL_ACCESS
int PERL_ACCESS_HOOK(request_rec *r)
{
    int status = DECLINED;
    perl_dir_config *cld = get_module_config (r->per_dir_config,
					      &perl_module);   
    mod_perl_dir_env(cld);
    PERL_CALLBACK("PerlAccessHandler", cld->PerlAccessHandler);
    return status;
}
#endif

#ifdef PERL_TYPE
int PERL_TYPE_HOOK(request_rec *r)
{
    int status = DECLINED;
    perl_dir_config *cld = get_module_config (r->per_dir_config,
					      &perl_module);   
    mod_perl_dir_env(cld);
    PERL_CALLBACK("PerlTypeHandler", cld->PerlTypeHandler);
    return status;
}
#endif

#ifdef PERL_FIXUP
int PERL_FIXUP_HOOK(request_rec *r)
{
    int status = DECLINED;
    perl_dir_config *cld = get_module_config (r->per_dir_config,
					      &perl_module);   
    mod_perl_dir_env(cld);
    PERL_CALLBACK("PerlFixupHandler", cld->PerlFixupHandler);
    return status;
}
#endif

#ifdef PERL_LOG
int PERL_LOG_HOOK(request_rec *r)
{
    int status = DECLINED, rstatus;
    perl_dir_config *cld = get_module_config (r->per_dir_config,
					      &perl_module);   
    mod_perl_dir_env(cld);
    PERL_CALLBACK("PerlLogHandler", cld->PerlLogHandler);
    rstatus = status;
#ifdef PERL_CLEANUP
    PERL_CALLBACK("PerlCleanupHandler", cld->PerlCleanupHandler);
#endif
    return rstatus;
}
#endif

void mod_perl_end_cleanup(void *data)
{
    perl_clear_env;
    av_undef(GvAV(incgv));
    GvAV(incgv) = Nullav;
    GvAV(incgv) = av_copy_array(orig_inc);
    MP_TRACE(fprintf(stderr, "perl_end_cleanup...ok\n"));
}

void mod_perl_cleanup_handler(void *data)
{
    request_rec *r = perl_request_rec(NULL);
    SV *cv;
    I32 i;

    MP_TRACE(fprintf(stderr, "running registered cleanup handlers...\n")); 
    for(i=0; i<=av_len(cleanup_av); i++) { 
	cv = *av_fetch(cleanup_av, i, 0);
	perl_call_handler(cv, (request_rec *)r, Nullav);
    }
    registered_cleanups = 0;
    av_clear(cleanup_av);
}

#ifdef PERL_HEADER_PARSER
int PERL_HEADER_PARSER_HOOK(request_rec *r)
{
    int status = DECLINED;
    perl_dir_config *cld = get_module_config (r->per_dir_config,
					      &perl_module);   
    mod_perl_dir_env(cld);
#ifdef PERL_INIT
    PERL_CALLBACK("PerlInitHandler", 
			 cld->PerlInitHandler);
#endif
    PERL_CALLBACK("PerlHeaderParserHandler", 
			 cld->PerlHeaderParserHandler);
    return status;
}
#endif

#ifdef PERL_METHOD_HANDLERS
int perl_handler_ismethod(HV *class, char *sub)
{
    CV *cv;
    HV *stash;
    GV *gv;
    SV *sv;
    int is_method=0;

    if(!sub) return 0;
    sv = newSVpv(sub,0);
    if(!(cv = sv_2cv(sv, &stash, &gv, FALSE)))
	cv = GvCV(gv_fetchmethod(class, sub));

    if (cv && SvPOK(cv)) 
	is_method = strnEQ(SvPVX(cv), "$$", 2);
    MP_TRACE(fprintf(stderr, "checking if `%s' is a method...%s\n", 
	   sub, (is_method ? "yes" : "no")));
    SvREFCNT_dec(sv);
    return is_method;
}
#endif

void mod_perl_register_cleanup(request_rec *r, SV *sv)
{
    if(!registered_cleanups) {
	(void)perl_request_rec(r); 
	register_cleanup(r->pool, (void*)r,
			 mod_perl_cleanup_handler, NULL);
	++registered_cleanups;
	if(cleanup_av == Nullav) cleanup_av = newAV();
    }
    MP_TRACE(fprintf(stderr, "registering PerlCleanupHandler\n"));
    
    av_push(cleanup_av, SvREFCNT_inc(sv));
}

#ifdef PERL_STACKED_HANDLERS

int mod_perl_push_handlers(SV *self, SV *hook, SV *sub, AV *handlers)
{
    char *key = SvPV(hook,na);
    int do_store=0;
    SV **svp;

    if(self && SvTRUE(sub)) {
	if(handlers == Nullav) {
	    svp = hv_fetch(stacked_handlers, key, SvCUR(hook), 0);
	    MP_TRACE(fprintf(stderr, "fetching %s stack\n", key));
	    if(svp && SvTRUE(*svp) && SvROK(*svp)) {
		handlers = (AV*)SvRV(*svp);
	    }
	    else {
		MP_TRACE(fprintf(stderr, "%s handlers stack undef, creating\n", key));
		handlers = newAV();
	    }
	    do_store = 1;
	}
	    
	if(SvROK(sub) && (SvTYPE(SvRV(sub)) == SVt_PVCV)) {
	    MP_TRACE(fprintf(stderr, "pushing CODE ref into `%s' handlers\n", key));
	}
	else if(SvPOK(sub)) {
	    MP_TRACE(fprintf(stderr, "pushing `%s' into `%s' handlers\n", 
		   SvPV(sub,na), key));
	}
	else {
	    warn("mod_perl_push_handlers: Not a subroutine name or CODE reference!");
	}

	av_push(handlers, SvREFCNT_inc(sub));
	if(do_store) 
	    hv_store(stacked_handlers, key, SvCUR(hook), 
		     (SV*)newRV((SV*)handlers), 0);
	return 1;
    }
    return 0;
}

int perl_run_stacked_handlers(char *hook, request_rec *r, AV *handlers)
{
    int status=DECLINED, do_clear=0;
    I32 i;
    SV *sub, **svp; 
    int hook_len = strlen(hook);

    if(handlers == Nullav) {
	svp = hv_fetch(stacked_handlers, hook, hook_len, 0);
	if(!svp || !SvTRUE(*svp) || !SvROK(*svp)) {
	    MP_TRACE(fprintf(stderr, "`%s' push_handlers() stack is empty\n", hook));
	    return DECLINED;
	}
	handlers = (AV*)SvRV(*svp);
	do_clear = 1;
    }

    for(i=0; i<=av_len(handlers); i++) {
	MP_TRACE(fprintf(stderr, "calling &{%s->[%d]}\n", hook, (int)i));

	if(!(sub = *av_fetch(handlers, i, FALSE))) {
	    MP_TRACE(fprintf(stderr, "sub not defined!\n"));
	}
	else {
	    if(!SvTRUE(sub)) {
		MP_TRACE(fprintf(stderr, "sub undef!  skipping callback...\n"));
		continue;
	    }
	    status = perl_call_handler(sub, r, Nullav);

	    if((status != OK) && (status != DECLINED)) {
		if(do_clear)
		    av_clear(handlers);	
		return status;
	    }
	}
    }
    if(do_clear)
	av_clear(handlers);	
    return status;
}

#endif /* PERL_STACKED_HANDLERS */

/* XXX this still needs work, getting there... */
int perl_call_handler(SV *sv, request_rec *r, AV *args)
{
    int count, status, is_method=0;
    dSP;
    HV *stash = Nullhv;
    SV *class = newSVsv(sv);
    CV *cv = Nullcv;
    char *method = "handler";
    int defined_sub = 0, anon = 0;

    if(SvTYPE(sv) == SVt_PV) {
	char *imp = SvPV(class,na);

	if((anon = strnEQ(imp,"sub ",4))) {
#ifdef HAVE_PERL_5__4
	    sv = perl_eval_pv(imp, FALSE);
	    MP_TRACE(fprintf(stderr, "perl_call: caching CV pointer to `__ANON__'\n"));
	    defined_sub++;
	    goto callback; /* XXX, I swear I've never used goto before! */
#else
	    warn("Need Perl version 5.003_98+ to use anonymous subs!\n");
	    return SERVER_ERROR;
#endif
	}


#ifdef PERL_METHOD_HANDLERS
	{
	    char *end_class = NULL;

	    if ((end_class = strstr(imp, "->"))) {
		end_class[0] = '\0';
		class = newSVpv(imp, 0);
		end_class[0] = ':';
		end_class[1] = ':';
		method = &end_class[2];
		imp = method;
		++is_method;
	    }
	}

	if(class) stash = gv_stashpv(SvPV(class,na),FALSE);
	   
	MP_TRACE(fprintf(stderr, "perl_call: class=`%s'\n", SvPV(class,na)));
	MP_TRACE(fprintf(stderr, "perl_call: imp=`%s'\n", imp));
	MP_TRACE(fprintf(stderr, "perl_call: method=`%s'\n", method));
	MP_TRACE(fprintf(stderr, "perl_call: stash=`%s'\n", 
			 stash ? HvNAME(stash) : "unknown"));

#endif


    /* if a Perl*Handler is not a defined function name,
     * default to the class implementor's handler() function
     * attempt to load the class module if it is not already
     */
	if(!imp) imp = SvPV(sv,na);
	if(!stash) stash = gv_stashpv(imp,FALSE);
	if(!is_method)
	    defined_sub = (cv = perl_get_cv(imp, FALSE)) ? TRUE : FALSE;
#ifdef PERL_METHOD_HANDLERS
	if(!defined_sub && stash) {
	    MP_TRACE(fprintf(stderr, 
		   "perl_call: trying method lookup on `%s' in class `%s'...", 
		   method, HvNAME(stash)));
	    /* XXX Perl caches method lookups internally, 
	     * should we cache this lookup?
	     */
	    if((cv = GvCV(gv_fetchmethod(stash, method)))) {
		MP_TRACE(fprintf(stderr, "found\n"));
		is_method = perl_handler_ismethod(stash, method);
	    }
	    else {
		MP_TRACE(fprintf(stderr, "not found\n"));
	    }
	}
#endif

	if(!stash && !defined_sub) {
	    MP_TRACE(fprintf(stderr, "%s symbol table not found, loading...\n", imp));
	    if(perl_require_module(imp, r->server) == OK)
		stash = gv_stashpv(imp,FALSE);
#ifdef PERL_METHOD_HANDLERS
	    if(stash) /* check again */
		is_method = perl_handler_ismethod(stash, method);
#endif
	}
	
	if(!is_method && !defined_sub) {
	    if(!strnEQ(imp,"OK",2) && !strnEQ(imp,"DECLINED",8)) { /*XXX*/
		MP_TRACE(fprintf(stderr, 
		       "perl_call: defaulting to %s::handler\n", imp));
		sv_catpv(sv, "::handler");
	    }
	}
#ifdef PERL_STACKED_HANDLERS
 	if(!is_method && defined_sub) { /* cache it */
	    MP_TRACE(fprintf(stderr, 
			     "perl_call: caching CV pointer to `%s'\n", 
			     (anon ? "__ANON__" : SvPV(sv,na))));
	    SvREFCNT_dec(sv);
 	    sv = (SV*)newRV((SV*)cv); /* let newRV inc the refcnt */
	}
#endif
    }
    else {
	MP_TRACE(fprintf(stderr, "perl_call: handler is a cached CV\n"));
    }

callback:
    ENTER;
    SAVETMPS;
    PUSHMARK(sp);
#ifdef PERL_METHOD_HANDLERS
    if(is_method)
	XPUSHs(sv_2mortal(class));
    else
	SvREFCNT_dec(class);
#else
    SvREFCNT_dec(class);
#endif

    XPUSHs((SV*)perl_bless_request_rec(r)); 
    {
	I32 i, len = (args ? av_len(args) : 0);
	
	if(args) {
	    EXTEND(sp, len);
	    for(i=0; i<=len; i++)
		PUSHs(sv_2mortal(*av_fetch(args, i, FALSE)));
	}
    }
    PUTBACK;
    
    /* reset $$ */
    perl_set_pid;

    /* use G_EVAL so we can trap errors */
#ifdef PERL_METHOD_HANDLERS
    if(is_method)
	count = perl_call_method(method, G_EVAL | G_SCALAR);
    else
#endif
	count = perl_call_sv(sv, G_EVAL | G_SCALAR);
    
    SPAGAIN;

    if(perl_eval_ok(r->server) != OK) 
	return SERVER_ERROR;
    
    if(count != 1) {
	log_error("perl_call did not return a status arg, assuming OK",
		  r->server);
	status = OK;
    }
    else {
	status = POPi;
	if((status == 1) || (status == 200) || (status > 600)) 
	    status = OK; 
    }
    PUTBACK;
    FREETMPS;
    LEAVE;

    return status;
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
    MP_TRACE(fprintf(stderr, "blessing request_rec\n"));
    return sv;
}

int perl_eval_ok(server_rec *s)
{
    SV *sv;
    sv = GvSV(gv_fetchpv("@", TRUE, SVt_PV));
    if(SvTRUE(sv)) {
	MP_TRACE(fprintf(stderr, "perl_eval error: %s\n", SvPV(sv,na)));
	log_error(SvPV(sv, na), s);
	return -1;
    }
    return 0;
}

int perl_require_module(char *mod, server_rec *s)
{
    SV *sv = sv_newmortal();
    SV *m = newSVpv(mod,0);
    MP_TRACE(fprintf(stderr, "loading perl module '%s'...", mod)); 
    sv_setpv(sv, "require ");
    sv_catsv(sv, m);
    perl_eval_sv(sv, G_DISCARD);
    if(perl_eval_ok(s) != OK) {
	MP_TRACE(fprintf(stderr, "not ok\n"));
	return -1;
    }
    MP_TRACE(fprintf(stderr, "ok\n"));
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
	if (strnEQ("Authorization", elts[i].key, 13)) continue;
	if (!elts[i].key) continue;
	klen = strlen(elts[i].key);  
	hv_store(cgienv, elts[i].key, klen,
		 newSVpv(elts[i].val,0), 0);
	HV_SvTAINTED_on(cgienv, elts[i].key, klen);
    }
    MP_TRACE(fprintf(stderr, "perl_setup_env...%d keys\n", i));
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
    /* feed buffer to Apache->print */
    CV *cv = GvCV(gv_fetchpv("Apache::print", FALSE, SVt_PVCV));
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(sp);
    XPUSHs(perl_bless_request_rec(((Apache_t*)disc)->r));
    XPUSHs(sv_2mortal(newSVpv(buffer,n)));
    PUTBACK;
    (void)(*CvXSUB(cv))(cv); 
    FREETMPS;
    LEAVE;
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
    MP_TRACE(fprintf(stderr, "sfapacheread: want %d bytes\n", bufsiz)); 
    PERL_READ_FROM_CLIENT;
    return bufsiz;
}

Sfdisc_t * sfdcnewapache(request_rec *r)
{
    Apache_t*   disc;
    
    if(!(disc = (Apache_t*)malloc(sizeof(Apache_t))) )
	return (Sfdisc_t *)disc;
    MP_TRACE(fprintf(stderr, "sfdcnewapache(r)\n"));
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

    MP_TRACE(fprintf(stderr, "tie *STDOUT => Apache\n"));

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
    MP_TRACE(fprintf(stderr, "tie *STDIN => Apache\n"));
    sv_magic((SV *)gv_fetchpv("STDIN", TRUE, SVt_PVIO), 
	     (SV *)perl_bless_request_rec(r),
	     'q', Nullch, 0);
#endif
}

int mod_perl_seqno(void)
{
    return seqno;
}

