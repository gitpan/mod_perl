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

/* $Id: mod_perl.c,v 1.51 1997/04/30 03:00:43 dougm Exp $ */

/* 
 * And so it was decided the camel should be given magical multi-colored
 * feathers so it could fly and journey to once unknown worlds.
 * And so it was done...
 */
#define CORE_PRIVATE 
#include "mod_perl.h"

static IV mp_request_rec;
static int seqno = 0;
static int avoid_alloc_hack = 0;
static int perl_is_running = 0;
static int sent_header = 1;
static int dir_cleanups = 0;
static int stack_cleanups = 0;
static int set_pid = 0;
static PerlInterpreter *perl = NULL;
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

#ifndef PERL_DO_ALLOC
#  ifdef APACHE_SSL
#    define PERL_DO_ALLOC 0
#  else
#    define PERL_DO_ALLOC 1
#  endif
#endif

#define PERL_RUNNING perl_is_running

/* XXX should split into perl_config.c */
#ifdef PERL_SECTIONS

char *perl_av2string(AV *av) 
{
    I32 i, len = av_len(av);
    SV *sv = newSV(0);

    for(i=0; i<=len; i++) {
	sv_catsv(sv, *av_fetch(av, i, FALSE));
	if(i != len)
	    sv_catpvn(sv, " ", 1);
    }
    return SvPV(sv,na);
}

CHAR_P perl_srm_command_loop(cmd_parms *parms, SV *sv)
{
    char l[MAX_STRING_LEN];
    if(PERL_RUNNING) {
	sv_catpvn(sv, "\npackage ApacheReadConfig;\n{\n", 29);
	sv_catpvn(sv, "\n", 1);
    }
    while (!(cfg_getline (l, MAX_STRING_LEN, parms->infile))) {
	if(instr(l, "</Perl>"))
	    break;
	
	if(PERL_RUNNING) {
	    sv_catpv(sv, l);
	    sv_catpvn(sv, "\n", 1);
	}
    }
    if(PERL_RUNNING)
	sv_catpvn(sv, "\n}\n", 3);
    return NULL;
}

CHAR_P perl_urlsection (cmd_parms *cmd, void *dummy, HV *hv)
{
    char *key;
    I32 klen;
    SV *val;
    CHAR_P errmsg;
    int old_overrides = cmd->override;
    char *old_path = cmd->path;

    (void)hv_iterinit(hv);
    while ((val = hv_iternextsv(hv, &key, &klen))) {
	HV *tab;
	if(tab = SvRV(val)) {
	    char *tmpkey;
	    I32 tmpklen;
	    SV *tmpval;

	    core_dir_config *conf;
	    regex_t *r = NULL;

	    void *new_url_conf = create_per_dir_config (cmd->pool);

	    cmd->path = pstrdup(cmd->pool, getword_conf (cmd->pool, &key));
	    cmd->override = OR_ALL|ACCESS_CONF;

	    if (!strcmp(cmd->path, "~")) {
		cmd->path = getword_conf (cmd->pool, &key);
		r = pregcomp(cmd->pool, cmd->path, REG_EXTENDED);
	    }

	    CTRACE(stderr, "perl_urlsection: <Location %s>\n", cmd->path);
	    /* XXX, why must we??? */
	    if(!hv_exists(tab, "Options", 7)) 
		hv_store(tab, "Options", 7, 
			 newSVpv("Indexes FollowSymLinks",22), 0);

	    (void)hv_iterinit(tab);
	    while ((tmpval = hv_iternextsv(tab, &tmpkey, &tmpklen))) {
		char line[MAX_STRING_LEN]; 
		sprintf(line, "%s %s", tmpkey, 
			( SvROK(tmpval) ?
			  perl_av2string((AV*)SvRV(tmpval)) :
			  SvPV(tmpval,na) ));
		errmsg = handle_command(cmd, new_url_conf, line);
		CTRACE(stderr, "%s (%s)\n", line, errmsg);
	    }
	    
	    conf = (core_dir_config *)get_module_config(
		new_url_conf, &core_module);
	    if(!conf->opts)
		conf->opts = OPT_NONE;
	    conf->d = pstrdup(cmd->pool, cmd->path);
	    conf->d_is_matchexp = is_matchexp( conf->d );
	    conf->r = r;

	    add_per_url_conf (cmd->server, new_url_conf);
	    
	}
    }   
    cmd->path = old_path;
    cmd->override = old_overrides;

    return NULL;
}

static const char perl_end_magic[] = "</Perl> outside of any <Perl> section";

CHAR_P perl_end_section (cmd_parms *cmd, void *dummy) {
    return perl_end_magic;
}

CHAR_P perl_section (cmd_parms *cmd, void *dummy, const char *arg)
{
    const char *errmsg;
    SV *code = newSV(0), *val;
    HV *symtab;
    char *key;
    I32 klen;
    char line[MAX_STRING_LEN];

    errmsg = perl_srm_command_loop(cmd, code);

    if(!PERL_RUNNING) 
	return NULL; 

    (void)gv_fetchpv("ApacheReadConfig::Location", GV_ADDMULTI, SVt_PVHV);

    perl_eval_sv(code, G_DISCARD);
    if(SvTRUE(GvSV(errgv))) {
       fprintf(stderr, "Apache::ReadConfig: %s\n", SvPV(GvSV(errgv),na));
       return NULL;
    }

    symtab = (HV*)gv_stashpv("ApacheReadConfig", FALSE);
    (void)hv_iterinit(symtab);
    while ((val = hv_iternextsv(symtab, &key, &klen))) {
	SV *sv;
	HV *hv;
	AV *av;

	if(SvTYPE(val) != SVt_PVGV) 
	    continue;

	if((sv = GvSV((GV*)val))) {
	    if(SvTRUE(sv)) {
		CTRACE(stderr, "SVt_PV: %s\n", SvPV(sv,na));
		sprintf(line, "%s %s", key, SvPV(sv,na));
	    }
	}
	if((hv = GvHV((GV*)val))) {
	    if(strEQ(key, "Location")) 	
		perl_urlsection(cmd, dummy, hv);
	}
	else if((av = GvAV((GV*)val))) 
	    sprintf(line, "%s %s", key, perl_av2string(av));
    }
    if(line) {
	errmsg = handle_command(cmd, dummy, line);
	CTRACE(stderr, "handle_command (%s): %s\n", line, errmsg);
    }
    SvREFCNT_dec(code);
    hv_undef(symtab);
    return NULL;
}

#endif /* PERL_SECTIONS */

void perl_startup (server_rec *s, pool *p)
{
    char *argv[] = { server_argv0, NULL, NULL, NULL, NULL };
    char *constants[] = { "Apache::Constants", "OK", "DECLINED", NULL };
    int status, i, argc=2, t=0, w=0;
    perl_server_config *cls;
#ifndef PERL_SECTIONS
    if(avoid_alloc_hack++ != PERL_DO_ALLOC) {
	CTRACE(stderr, "perl_startup: skipping perl_alloc + perl_construct\n");
	return;
    }
    perl_destruct_level = 0;
#else
    perl_destruct_level = 1;
#endif

    cls = get_module_config (s->module_config, &perl_module);   

#ifndef PERL_TRACE
    if (s->error_log)
	error_log2stderr(s);
#endif

    if (PERL_RUNNING) {
	CTRACE(stderr, "destructing and freeing perl interpreter...");
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

    perl_is_running++;
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

void *perl_merge_dir_config (pool *p, void *basev, void *addv)
{
    perl_dir_config *new = (perl_dir_config *)pcalloc (p, sizeof(perl_dir_config));
    perl_dir_config *base = (perl_dir_config *)basev;
    perl_dir_config *add = (perl_dir_config *)addv;

    new->vars = overlay_tables(p, add->vars, base->vars);
    new->setup_env = add->setup_env ? add->setup_env : base->setup_env;
    new->sendheader = add->sendheader ? add->sendheader : base->sendheader;
    new->new_sendheader = add->new_sendheader ? add->new_sendheader : base->new_sendheader;
    new->PerlHandler = add->PerlHandler ? add->PerlHandler : base->PerlHandler;

#ifdef PERL_ACCESS
    new->PerlAccessHandler = add->PerlAccessHandler ? 
        add->PerlAccessHandler : base->PerlAccessHandler;
#endif
#ifdef PERL_AUTHEN
    new->PerlAuthenHandler = add->PerlAuthenHandler ? 
        add->PerlAuthenHandler : base->PerlAuthenHandler;
#endif
#ifdef PERL_AUTHZ
    new->PerlAuthzHandler = add->PerlAuthzHandler ? 
        add->PerlAuthzHandler : base->PerlAuthzHandler;
#endif
#ifdef PERL_FIXUP
    new->PerlFixupHandler = add->PerlFixupHandler ? 
        add->PerlFixupHandler : base->PerlFixupHandler;
#endif
#ifdef PERL_CLEANUP
    new->PerlCleanupHandler = add->PerlCleanupHandler ? 
        add->PerlCleanupHandler : base->PerlCleanupHandler;
#endif
#ifdef PERL_HEADER_PARSER
    new->PerlHeaderParserHandler = add->PerlHeaderParserHandler ? 
        add->PerlHeaderParserHandler : base->PerlHeaderParserHandler;
#endif
#ifdef PERL_INIT
    new->PerlInitHandler = add->PerlInitHandler ? 
        add->PerlInitHandler : base->PerlInitHandler;
#endif
#ifdef PERL_LOG
    new->PerlLogHandler = add->PerlLogHandler ? 
        add->PerlLogHandler : base->PerlLogHandler;
#endif
#ifdef PERL_TYPE
    new->PerlTypeHandler = add->PerlTypeHandler ? 
        add->PerlTypeHandler : base->PerlTypeHandler;
#endif

    return new;
}

void *create_perl_dir_config (pool *p, char *dirname)
{
    perl_dir_config *cld =
	(perl_dir_config *)palloc(p, sizeof (perl_dir_config));

    cld->vars = make_table(p, MAX_PERL_CONF_VARS); 
    cld->PerlHandler = NULL;
    cld->setup_env = 1;
    cld->sendheader = 0;
    cld->new_sendheader = 0;
    PERL_AUTHEN_CREATE(cld);
    PERL_AUTHZ_CREATE(cld);
    PERL_ACCESS_CREATE(cld);
    PERL_TYPE_CREATE(cld);
    PERL_FIXUP_CREATE(cld);
    PERL_LOG_CREATE(cld);
    PERL_CLEANUP_CREATE(cld);
    PERL_HEADER_PARSER_CREATE(cld);
    PERL_INIT_CREATE(cld);
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

    IoFLAGS(GvIOp(defoutgv)) &= ~IOf_FLUSH; /* reset $| */
    /* hookup STDIN & STDOUT to the client */
    perl_stdout2client(r);
    perl_stdin2client(r);

#ifndef PERL_TRACE
    /* hookup STDERR to the error_log */
    if (r->server->error_log)
	error_log2stderr(r->server);
#endif

    /*don't do anything special unless PerlNewSendHeader*/ 
    sent_header = (cld->new_sendheader ? 0 : 1); 
    if(cld->sendheader) {
	CTRACE(stderr, "mod_perl sending basic_http_header...\n");
	basic_http_header(r);
    }
    if(cld->setup_env) 
	perl_setup_env(r);

    seqno++;
    register_cleanup(r->pool, NULL, perl_end_cleanup, NULL);
    PERL_CALLBACK_RETURN("PerlHandler", cld->PerlHandler);
    return status;
}

#ifdef PERL_TRANS
int PERL_TRANS_HOOK(request_rec *r)
{
    int status = DECLINED;
    perl_server_config *cls = get_module_config (r->server->module_config,
						 &perl_module);   
    PERL_CALLBACK_RETURN("PerlTransHandler", cls->PerlTransHandler);
    return status;
}
#endif

#ifdef PERL_AUTHEN
int PERL_AUTHEN_HOOK(request_rec *r)
{
    int status = DECLINED;
    perl_dir_config *cld = get_module_config (r->per_dir_config,
					      &perl_module);   
    PERL_CALLBACK_RETURN("PerlAuthenHandler", cld->PerlAuthenHandler);
    return status;
}
#endif

#ifdef PERL_AUTHZ
int PERL_AUTHZ_HOOK(request_rec *r)
{
    int status = DECLINED;
    perl_dir_config *cld = get_module_config (r->per_dir_config,
					      &perl_module);   
    PERL_CALLBACK_RETURN("PerlAuthzHandler", cld->PerlAuthzHandler);
    return status;
}
#endif

#ifdef PERL_ACCESS
int PERL_ACCESS_HOOK(request_rec *r)
{
    int status = DECLINED;
    perl_dir_config *cld = get_module_config (r->per_dir_config,
					      &perl_module);   
    PERL_CALLBACK_RETURN("PerlAccessHandler", cld->PerlAccessHandler);
    return status;
}
#endif

#ifdef PERL_TYPE
int PERL_TYPE_HOOK(request_rec *r)
{
    int status = DECLINED;
    perl_dir_config *cld = get_module_config (r->per_dir_config,
					      &perl_module);   
    PERL_CALLBACK_RETURN("PerlTypeHandler", cld->PerlTypeHandler);
    return status;
}
#endif

#ifdef PERL_FIXUP
int PERL_FIXUP_HOOK(request_rec *r)
{
    int status = DECLINED;
    perl_dir_config *cld = get_module_config (r->per_dir_config,
					      &perl_module);   
    PERL_CALLBACK_RETURN("PerlFixupHandler", cld->PerlFixupHandler);
    return status;
}
#endif

#ifdef PERL_LOG
int PERL_LOG_HOOK(request_rec *r)
{
    int status = DECLINED, rstatus;
    perl_dir_config *cld = get_module_config (r->per_dir_config,
					      &perl_module);   
    PERL_CALLBACK_RETURN("PerlLogHandler", cld->PerlLogHandler);
    rstatus = status;
    return rstatus;
}
#endif

void perl_end_cleanup(void *data)
{
    perl_clear_env;
    CTRACE(stderr, "perl_end_cleanup...ok\n");
}

void perl_cleanup_handler(void *data)
{
    request_rec *r = perl_request_rec(NULL);
    PERL_CMD_TYPE *cb = PERL_CMD_INIT;
    int status = DECLINED;

    if(data) {
	CTRACE(stderr, "running perl_cleanup_handler for dirs\n"); 
	dir_cleanups = 0;
	cb = ((perl_dir_config *)data)->PerlCleanupHandler;
    }
    else {
	CTRACE(stderr, "running perl_cleanup_handler for dynamic stack\n"); 
	stack_cleanups = 0;
    }
    PERL_CALLBACK_RETURN("PerlCleanupHandler", cb);
}

#ifdef PERL_HEADER_PARSER
int PERL_HEADER_PARSER_HOOK(request_rec *r)
{
    int status = DECLINED;
    perl_dir_config *cld = get_module_config (r->per_dir_config,
					      &perl_module);   

#ifdef PERL_INIT
    PERL_CALLBACK_RETURN("PerlInitHandler", 
			 cld->PerlInitHandler);
#endif
    PERL_CALLBACK_RETURN("PerlHeaderParserHandler", 
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
    CTRACE(stderr, "checking if `%s' is a method...%s\n", 
	   sub, (is_method ? "yes" : "no"));
    SvREFCNT_dec(sv);
    return is_method;
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
		handlers = newAV();
	    }
	    do_store = 1;
	}
	    
	if(SvROK(sub) && (SvTYPE(SvRV(sub)) == SVt_PVCV)) {
	    CTRACE(stderr, "pushing CODE ref into `%s' handlers\n", key);
	}
	else if(SvPOK(sub)) {
	    CTRACE(stderr, "pushing `%s' into `%s' handlers\n", 
		   SvPV(sub,na), key);
	}
	else {
	    warn("mod_perl_push_handlers: Not a subroutine name or CODE reference!");
	}

	SvREFCNT_inc((SV*)sub);
	av_push(handlers, sub);
	if(do_store) {
	    hv_store(stacked_handlers, key, SvCUR(hook), 
		     (SV*)newRV((SV*)handlers), 0);

	    if(strnEQ(key, "PerlCleanupHandler", 18)) {
		request_rec *r;
		if(sv_isa(self, "Apache")) {
		    IV tmp = SvIV((SV*)SvRV(self));
		    r = (Apache)tmp;
		}
		else
		    r = perl_request_rec(NULL);
		if(!stack_cleanups) {
		    register_cleanup(r->pool, NULL,
				     perl_cleanup_handler, NULL);
		    ++stack_cleanups;
		}
		CTRACE(stderr, "registering PerlCleanupHandler\n");
	    }
	}
	return 1;
    }
    return 0;
}

int perl_run_stacked_handlers(char *hook, request_rec *r, AV *handlers)
{
    int count, status=DECLINED, do_clear=0;
    I32 i;
    SV *sub, **svp; 
    int hook_len = strlen(hook);

    if(handlers == Nullav) {
	svp = hv_fetch(stacked_handlers, hook, hook_len, 0);
	if(!svp || !SvTRUE(*svp) || !SvROK(*svp)) {
	    CTRACE(stderr, "`%s' stack is empty\n", hook);
	    return DECLINED;
	}
	handlers = (AV*)SvRV(*svp);
	do_clear = 1;
    }

    CTRACE(stderr, "%s av_len = %d\n", hook, (int)av_len(handlers));
    for(i=0; i<=av_len(handlers); i++) {
#ifdef PERL_METHOD_HANDLERS
	int is_method=0;
#endif
	char *imp = NULL;
	SV *class = Nullsv;
	dSP;
    
	CTRACE(stderr, "calling &{%s->[%d]}\n", hook, (int)i);

	/* if a Perl*Handler is not a defined function name,
	 * default to the class implementor's handler() function
	 * attempt to load the class module if it is not already
	 */
	if(!(sub = *av_fetch(handlers, i, FALSE))) {
	    CTRACE(stderr, "sub not defined!\n");
	}
	else {
	    if(!SvTRUE(sub)) {
		CTRACE(stderr, "sub undef!  skipping callback...\n");
		continue;
	    }
	    status = perl_call_handler(sub, r);

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

#define PERL_CMD_PUSH_HANDLERS(hook, cmd) \
{ \
    if(!cmd) { \
        cmd = newAV(); \
	CTRACE(stderr, "init `%s' stack\n", hook); \
    } \
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

#define PERL_CMD_PUSH_HANDLERS(hook, cmd) \
cmd = arg; \
return NULL

#endif

/* XXX this still needs work, getting there... */
int perl_call_handler(SV *sv, request_rec *r)
{
    int count, status, is_method=0;
    dSP;
    HV *stash = Nullhv;
    SV *class = newSVsv(sv);
    CV *cv;
    char *method = "handler";
    int defined_sub = 0;

    if(SvTYPE(sv) == SVt_PV) {
	char *imp = SvPV(class,na);

#ifdef PERL_METHOD_HANDLERS
 	char *end_class = NULL;

	if (end_class = strstr(imp, "->")) {
	    end_class[0] = '\0';
	    class = newSVpv(imp, 0);
	    end_class[0] = ':';
	    end_class[1] = ':';
	    method = &end_class[2];
	    imp = method;
	    ++is_method;
	}

	if(class) stash = gv_stashpv(SvPV(class,na),FALSE);
	   
	CTRACE(stderr, "perl_call: class=`%s'\n", SvPV(class,na));
	CTRACE(stderr, "perl_call: imp=`%s'\n", imp);
	CTRACE(stderr, "perl_call: method=`%s'\n", method);
	CTRACE(stderr, "perl_call: stash=`%s'\n", stash?HvNAME(stash):"unknown");

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
	    CTRACE(stderr, 
		   "perl_call: trying method lookup on `%s' in class `%s'...", 
		   method, HvNAME(stash));
	    /* XXX Perl caches method lookups internally, 
	     * should we cache this lookup?
	     */
	    if(cv = GvCV(gv_fetchmethod(stash, method))) {
		CTRACE(stderr, "found\n");
		is_method = perl_handler_ismethod(stash, method);
	    }
	    else {
		CTRACE(stderr, "not found\n");
	    }
	}
#endif

	if(!stash && !defined_sub) {
	    CTRACE(stderr, "%s symbol table not found, loading...\n", imp);
	    if(perl_require_module(imp, r->server) == OK)
		stash = gv_stashpv(imp,FALSE);
#ifdef PERL_METHOD_HANDLERS
	    if(stash) /* check again */
		is_method = perl_handler_ismethod(stash, method);
#endif
	}
	
	if(!is_method && !defined_sub) {
	    if(!strnEQ(imp,"OK",2) && !strnEQ(imp,"DECLINED",8)) { /*XXX*/
		CTRACE(stderr, 
		       "perl_call: defaulting to %s::handler\n", imp);
		sv_catpv(sv, "::handler");
	    }
	}
#ifdef PERL_STACKED_HANDLERS
 	if(!is_method && defined_sub) { /* cache it */
	    CTRACE(stderr, "perl_call: caching sub `%s'\n", SvPV(sv,na));
	    SvREFCNT_dec(sv);
 	    sv = (SV*)newRV((SV*)cv); /* let newRV inc the refcnt */
	}
#endif
    }
    else {
	CTRACE(stderr, "perl_call: handler is a cached CV\n");
    }

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
    status = POPi;

    if((status == 1) || (status == 200) || (status > 600)) 
	status = OK; 
      
    PUTBACK;
    FREETMPS;
    LEAVE;

    return status;
}

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

CHAR_P perl_cmd_init_handlers (cmd_parms *parms, perl_dir_config *rec, char *arg)
{
    PERL_CMD_PUSH_HANDLERS("PerlInitHandler", rec->PerlInitHandler);
}

CHAR_P perl_cmd_cleanup_handlers (cmd_parms *parms, perl_dir_config *rec, char *arg)
{
    if(!dir_cleanups) {
	register_cleanup(parms->pool, (void*)rec, 
			 perl_cleanup_handler, NULL);
	++dir_cleanups;
    }
    PERL_CMD_PUSH_HANDLERS("PerlCleanupHandler", rec->PerlCleanupHandler);
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

CHAR_P perl_cmd_new_sendheader (cmd_parms *cmd, void *rec, int arg) {
    ((perl_dir_config *)rec)->new_sendheader = arg;
    sent_header = !arg;
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
	case 'C':
	    if (strEQ(name, "Cleanup")) 
#ifdef PERL_CLEANUP
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
#if MODULE_MAGIC_NUMBER >= 19970103
	case 'I':
	    if (strEQ(name, "Init")) 
#ifdef PERL_INIT
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
	case 'M':
	    if (strEQ(name, "MethodHandlers")) 
#ifdef PERL_METHOD_HANDLERS
		return 1;
#else
	return 0;    
#endif
	break;
	case 'S':
	    if (strEQ(name, "StackedHandlers")) 
#ifdef PERL_STACKED_HANDLERS
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

