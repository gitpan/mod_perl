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

#define CORE_PRIVATE 
#include "mod_perl.h"

void mod_perl_dir_env(perl_dir_config *cld)
{
    if(cld->has_env) {
      table_entry *elts = (table_entry *)cld->env->elts;
	int i;
	HV *env = PerlEnvHV; 
	for (i = 0; i < cld->env->nelts; ++i) {
	    MP_TRACE(fprintf(stderr, "dir_env: %s=`%s'",
			     elts[i].key, elts[i].val));
	    hv_store(env, elts[i].key, strlen(elts[i].key), 
		     newSVpv(elts[i].val,0), FALSE); 
	}
	cld->has_env = 0; /* just doit once per-request */
    }
}

void *perl_merge_dir_config (pool *p, void *basev, void *addv)
{
    perl_dir_config *new = (perl_dir_config *)pcalloc (p, sizeof(perl_dir_config));
    perl_dir_config *base = (perl_dir_config *)basev;
    perl_dir_config *add = (perl_dir_config *)addv;

    new->vars = overlay_tables(p, add->vars, base->vars);
    new->env = overlay_tables(p, add->env, base->env);
    new->has_env = add->has_env ? add->has_env : base->has_env;
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
    cld->env  = make_table(p, MAX_PERL_CONF_VARS); 
    cld->has_env = 0;
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

    return (void *)cls;
}

#ifdef PERL_STACKED_HANDLERS

#define PERL_CMD_PUSH_HANDLERS(hook, cmd) \
{ \
    SV *svh, *sva; \
    svh = newSVpv(hook,0); sva = newSVpv(arg,0); \
    if(!cmd) { \
        cmd = newAV(); \
	MP_TRACE(fprintf(stderr, "init `%s' stack\n", hook)); \
    } \
    MP_TRACE(fprintf(stderr, "perl_cmd_push_handlers: @%s, '%s'\n", hook, arg)); \
    mod_perl_push_handlers(&sv_yes, svh, sva, cmd); \
    SvREFCNT_dec(svh); SvREFCNT_dec(sva); \
    return NULL; \
}

#else

#define PERL_CMD_PUSH_HANDLERS(hook, cmd) \
cmd = arg; \
return NULL

int mod_perl_push_handlers(SV *self, SV *hook, SV *sub, AV *handlers)
{
    warn("Rebuild with -DPERL_STACKED_HANDLERS to $r->push_handlers");
    return 0;
}

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

CHAR_P perl_cmd_init_handlers (cmd_parms *parms, perl_dir_config *rec, char *arg)
{
    PERL_CMD_PUSH_HANDLERS("PerlInitHandler", rec->PerlInitHandler);
}

CHAR_P perl_cmd_cleanup_handlers (cmd_parms *parms, perl_dir_config *rec, char *arg)
{
    PERL_CMD_PUSH_HANDLERS("PerlCleanupHandler", rec->PerlCleanupHandler);
}

CHAR_P perl_cmd_module (cmd_parms *parms, void *dummy, char *arg)
{
    perl_server_config *cls = 
	get_module_config (parms->server->module_config, &perl_module);   

    if(PERL_RUNNING()) 
	perl_require_module(arg, parms->server);
    else {
	MP_TRACE(fprintf(stderr, "push_perl_modules: arg='%s'\n", arg));
	if (cls->NumPerlModules >= MAX_PERL_MODS) {
	    MP_TRACE(fprintf(stderr, "mod_perl: There's a limit of %d PerlModules, use a PerlScript to pull in as many as you want\n", MAX_PERL_MODS));
	    exit(-1);
	}
	
	cls->PerlModules[cls->NumPerlModules++] = arg;
    }
    return NULL;
}

CHAR_P perl_cmd_script (cmd_parms *parms, void *dummy, char *arg)
{
    perl_server_config *cls = 
	get_module_config (parms->server->module_config, &perl_module);   

    MP_TRACE(fprintf(stderr, "perl_cmd_script: %s\n", arg));
    cls->PerlScript = arg;
    return NULL;
}

CHAR_P perl_cmd_tainting (cmd_parms *parms, void *dummy, int arg)
{
    perl_server_config *cls = 
	get_module_config (parms->server->module_config, &perl_module);   

    MP_TRACE(fprintf(stderr, "perl_cmd_tainting: %d\n", arg));
    cls->PerlTaintCheck = arg;
    return NULL;
}

CHAR_P perl_cmd_warn (cmd_parms *parms, void *dummy, int arg)
{
    perl_server_config *cls = 
	get_module_config (parms->server->module_config, &perl_module);   

    MP_TRACE(fprintf(stderr, "perl_cmd_warn: %d\n", arg));
    cls->PerlWarn = arg;
    return NULL;
}

CHAR_P perl_cmd_sendheader (cmd_parms *cmd, void *rec, int arg) {
    ((perl_dir_config *)rec)->sendheader = arg;
    return NULL;
}

CHAR_P perl_cmd_new_sendheader (cmd_parms *cmd, void *rec, int arg) {
    ((perl_dir_config *)rec)->new_sendheader = arg;
    (void)mod_perl_sent_header(&sv_undef, 1);
    return NULL;
}

CHAR_P perl_cmd_env (cmd_parms *cmd, void *rec, int arg) {
    ((perl_dir_config *)rec)->setup_env = arg;
    return NULL;
}

CHAR_P perl_cmd_var(cmd_parms *cmd, void *rec, char *key, char *val)
{
    table_set(((perl_dir_config *)rec)->vars, key, val);
    MP_TRACE(fprintf(stderr, "perl_cmd_var: '%s' = '%s'\n", key, val));
    return NULL;
}

CHAR_P perl_cmd_setenv(cmd_parms *cmd, void *rec, char *key, char *val)
{
    table_set(((perl_dir_config *)rec)->env, key, val);
    ((perl_dir_config *)rec)->has_env++;
    MP_TRACE(fprintf(stderr, "perl_cmd_setenv: '%s' = '%s'\n", key, val));
    return NULL;
}

#ifdef PERL_SECTIONS
/* some prototypes for -Wall sake */
const char *handle_command (cmd_parms *parms, void *config, const char *l);
const char *limit (cmd_parms *cmd, void *dummy, const char *arg);
void add_per_dir_conf (server_rec *s, void *dir_config);
void add_per_url_conf (server_rec *s, void *url_config);
void add_file_conf (core_dir_config *conf, void *url_config);

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
    if(PERL_RUNNING()) {
	sv_catpvn(sv, "\npackage ApacheReadConfig;\n{\n", 29);
	sv_catpvn(sv, "\n", 1);
    }
    while (!(cfg_getline (l, MAX_STRING_LEN, parms->infile))) {
	if(instr(l, "</Perl>"))
	    break;
	if(PERL_RUNNING()) {
	    sv_catpv(sv, l);
	    sv_catpvn(sv, "\n", 1);
	}
    }
    if(PERL_RUNNING())
	sv_catpvn(sv, "\n}\n", 3);
    return NULL;
}

#define dSEC \
    const char *key; \
    I32 klen; \
    SV *val

#define dSECiter_start \
    (void)hv_iterinit(hv); \
    while ((val = hv_iternextsv(hv, (char **) &key, &klen))) { \
	HV *tab; \
	if((tab = (HV *)SvRV(val))) { 

#define dSECiter_stop \
        } \
    }

void perl_section_hash_walk(cmd_parms *cmd, void *cfg, HV *hv)
{
    CHAR_P errmsg;
    char *tmpkey; 
    I32 tmpklen; 
    SV *tmpval;
    (void)hv_iterinit(hv); 
    while ((tmpval = hv_iternextsv(hv, &tmpkey, &tmpklen))) { 
	char line[MAX_STRING_LEN]; 
	char *value = NULL;
	if(SvROK(tmpval)) {
	    if(SvTYPE(SvRV(tmpval)) == SVt_PVAV) {
		value = perl_av2string((AV*)SvRV(tmpval)); 
	    }
	    else if(SvTYPE(SvRV(tmpval)) == SVt_PVHV) {
		HV *lim = (HV*)SvRV(tmpval);
		SV *methods = hv_delete(lim, "METHODS", 7, G_SCALAR);

		if(methods) {
		    MP_TRACE(fprintf(stderr, 
				     "Found Limit section for `%s'\n", 
				     SvPV(methods,na)));
		    limit(cmd, cfg, SvPV(methods,na));
		    perl_section_hash_walk(cmd, cfg, lim);
		    cmd->limited = -1;
		    continue;
		}
	    }
	}
	else
	    value = SvPV(tmpval,na); 

	sprintf(line, "%s %s", tmpkey, value);
	errmsg = handle_command(cmd, cfg, line); 
	MP_TRACE(fprintf(stderr, "%s (%s) Limit=%s\n", 
			 line, 
			 (errmsg ? errmsg : "OK"),
			 (cmd->limited > 0 ? "yes" : "no") ));
    }
} 

#define TRACE_SECTION(n,v) \
    MP_TRACE(fprintf(stderr, "perl_section: <%s %s>\n", n, v))

/* XXX, had to copy-n-paste much code from http_core.c for
 * perl_*sections, would be nice if the core config routines 
 * had a handful of callback hooks instead
 */

CHAR_P perl_virtualhost_section (cmd_parms *cmd, void *dummy, HV *hv)
{
    dSEC;
    server_rec *main_server = cmd->server, *s;
    pool *p = cmd->pool;
    char *arg;
    dSECiter_start

    arg = pstrdup(cmd->pool, getword_conf (cmd->pool, &key));
    s = init_virtual_host (p, arg, main_server);
    s->next = main_server->next;
    main_server->next = s;
    cmd->server = s;

    TRACE_SECTION("VirtualHost", arg);

    perl_section_hash_walk(cmd, s->lookup_defaults, tab);

    cmd->server = main_server;

    dSECiter_stop

    return NULL;
}

CHAR_P perl_urlsection (cmd_parms *cmd, void *dummy, HV *hv)
{
    dSEC;
    int old_overrides = cmd->override;
    char *old_path = cmd->path;

    dSECiter_start

    core_dir_config *conf;
    regex_t *r = NULL;

    void *new_url_conf = create_per_dir_config (cmd->pool);
    
    cmd->path = pstrdup(cmd->pool, getword_conf (cmd->pool, &key));
    cmd->override = OR_ALL|ACCESS_CONF;

    if (!strcmp(cmd->path, "~")) {
	cmd->path = getword_conf (cmd->pool, &key);
	r = pregcomp(cmd->pool, cmd->path, REG_EXTENDED);
    }

    TRACE_SECTION("Location", cmd->path);

    /* XXX, why must we??? */
    if(!hv_exists(tab, "Options", 7)) 
	hv_store(tab, "Options", 7, 
		 newSVpv("Indexes FollowSymLinks",22), 0);

    perl_section_hash_walk(cmd, new_url_conf, tab);

    conf = (core_dir_config *)get_module_config(
	new_url_conf, &core_module);
    if(!conf->opts)
	conf->opts = OPT_NONE;
    conf->d = pstrdup(cmd->pool, cmd->path);
    conf->d_is_matchexp = is_matchexp( conf->d );
    conf->r = r;

    add_per_url_conf (cmd->server, new_url_conf);
	    
    dSECiter_stop

    cmd->path = old_path;
    cmd->override = old_overrides;

    return NULL;
}

CHAR_P perl_dirsection (cmd_parms *cmd, void *dummy, HV *hv)
{
    dSEC;
    int old_overrides = cmd->override;
    char *old_path = cmd->path;

    dSECiter_start

    core_dir_config *conf;
    void *new_dir_conf = create_per_dir_config (cmd->pool);
    regex_t *r = NULL;

    cmd->path = pstrdup(cmd->pool, getword_conf (cmd->pool, &key));

#ifdef __EMX__
    /* Fix OS/2 HPFS filename case problem. */
    cmd->path = strlwr(cmd->path);
#endif    
    cmd->override = OR_ALL|ACCESS_CONF;

    if (!strcmp(cmd->path, "~")) {
	cmd->path = getword_conf (cmd->pool, &key);
	r = pregcomp(cmd->pool, cmd->path, REG_EXTENDED);
    }

    TRACE_SECTION("Directory", cmd->path);

    /* XXX, why must we??? */
    if(!hv_exists(tab, "Options", 7)) 
	hv_store(tab, "Options", 7, 
		 newSVpv("Indexes FollowSymLinks",22), 0);

    perl_section_hash_walk(cmd, new_dir_conf, tab);

    conf = (core_dir_config *)get_module_config(new_dir_conf, &core_module);
    conf->r = r;

    add_per_dir_conf (cmd->server, new_dir_conf);

    dSECiter_stop

    cmd->path = old_path;
    cmd->override = old_overrides;

    return NULL;
}

void perl_add_file_conf (server_rec *s, void *url_config)
{
    core_server_config *sconf = get_module_config (s->module_config,
						   &core_module);
    void **new_space = (void **) push_array (sconf->sec);
    
    *new_space = url_config;
}

CHAR_P perl_filesection (cmd_parms *cmd, void *dummy, HV *hv)
{
    dSEC;
    int old_overrides = cmd->override;
    char *old_path = cmd->path;

    dSECiter_start

    core_dir_config *conf;
    void *new_file_conf = create_per_dir_config (cmd->pool);
    regex_t *r = NULL;

    cmd->path = pstrdup(cmd->pool, getword_conf (cmd->pool, &key));
    /* Only if not an .htaccess file */
    if (cmd->path)
	cmd->override = OR_ALL|ACCESS_CONF;

    if (!strcmp(cmd->path, "~")) {
	cmd->path = getword_conf (cmd->pool, &key);
	if (old_path && cmd->path[0] != '/' && cmd->path[0] != '^')
	    cmd->path = pstrcat(cmd->pool, "^", old_path, cmd->path, NULL);
	r = pregcomp(cmd->pool, cmd->path, REG_EXTENDED);
    }
    else if (old_path && cmd->path[0] != '/')
	cmd->path = pstrcat(cmd->pool, old_path, cmd->path, NULL);

    TRACE_SECTION("Files", cmd->path);

    /* XXX, why must we??? */
    if(!hv_exists(tab, "Options", 7)) 
	hv_store(tab, "Options", 7, 
		 newSVpv("Indexes FollowSymLinks",22), 0);

    perl_section_hash_walk(cmd, new_file_conf, tab);

    conf = (core_dir_config *)get_module_config(new_file_conf, &core_module);
    if(!conf->opts)
	conf->opts = OPT_NONE;
    conf->d = pstrdup(cmd->pool, cmd->path);
    conf->d_is_matchexp = is_matchexp( conf->d );
    conf->r = r;

    perl_add_file_conf (cmd->server, new_file_conf);

    dSECiter_stop

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
    CHAR_P errmsg;
    SV *code = newSV(0), *val;
    HV *symtab;
    char *key;
    I32 klen;
    char line[MAX_STRING_LEN];

    errmsg = perl_srm_command_loop(cmd, code);

    if(!PERL_RUNNING()) {
	MP_TRACE(fprintf(stderr, "perl_section:, Perl not running, returning...\n"));
	SvREFCNT_dec(code);
	return NULL;
    }
    (void)gv_fetchpv("ApacheReadConfig::Location", GV_ADDMULTI, SVt_PVHV);
    (void)gv_fetchpv("ApacheReadConfig::VirtualHost", GV_ADDMULTI, SVt_PVHV);
    (void)gv_fetchpv("ApacheReadConfig::Directory", GV_ADDMULTI, SVt_PVHV);
    (void)gv_fetchpv("ApacheReadConfig::Files", GV_ADDMULTI, SVt_PVHV);

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
	int have_line = 0;

	if(SvTYPE(val) != SVt_PVGV) 
	    continue;

	if((sv = GvSV((GV*)val))) {
	    if(SvTRUE(sv)) {
		MP_TRACE(fprintf(stderr, "SVt_PV: %s\n", SvPV(sv,na)));
		sprintf(line, "%s %s", key, SvPV(sv,na));
		have_line++;
	    }
	}
	if((hv = GvHV((GV*)val))) {
	    if(strEQ(key, "Location")) 	
		perl_urlsection(cmd, dummy, hv);
	    else if(strEQ(key, "Directory")) 
		perl_dirsection(cmd, dummy, hv);
	    else if(strEQ(key, "VirtualHost")) 
		perl_virtualhost_section(cmd, dummy, hv);
	    else if(strEQ(key, "Files")) 
		perl_filesection(cmd, (core_dir_config *)dummy, hv);
	}
	else if((av = GvAV((GV*)val))) {	
	    sprintf(line, "%s %s", key, perl_av2string(av));
	    have_line++;
	}
	if(have_line) {
	    errmsg = handle_command(cmd, dummy, line);
	    MP_TRACE(fprintf(stderr, "handle_command (%s): %s\n", line, 
			     (errmsg ? errmsg : "OK")));
	    have_line = 0;
	}
    }
    SvREFCNT_dec(code);
    hv_undef(symtab);
    return NULL;
}

#endif /* PERL_SECTIONS */

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

