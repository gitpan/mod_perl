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

/* $Id: mod_perl_fast.c,v 1.23 1996/10/02 14:53:36 dougm Exp $ */

#include "mod_perl.h"

static int avoid_first_alloc_hack = 0;

static PerlInterpreter *perl = NULL;

void perl_init (server_rec *s, pool *p)
{
  char *argv[3], *mod;
  int status;
  I32 i;
  SV *module;
  perl_server_config *cls;
  char *fname; 

#ifndef APACHE_SSL  
  if(avoid_first_alloc_hack++ == 0)
    return;
#endif

  cls = get_module_config (s->module_config,
			    &perl_fast_module);   
  fname = cls->PerlScript;

  if (perl != NULL) {
    CTRACE(stderr, "perl_init: freeing perl interpreter\n");
    perl_destruct(perl);
    perl_free(perl);
  }

  if((perl = perl_alloc()) == NULL) {
     CTRACE(stderr,"httpd: could not allocate perl interpreter\n");
     perror("alloc");
     exit(1);
  }
  CTRACE(stderr, "perl_init: perl_alloc...ok\n");
  
  perl_construct(perl);
  CTRACE(stderr, "perl_init: perl_construct...ok\n");

  argv[0] = argv[2] = NULL;
  if (fname == NULL) {
    argv[1] = "-e";
    argv[2] = "0";
  } else {
    argv[1] = fname;
  }

  CTRACE(stderr, "perl_init: loading perl script: %s\n", argv[1]);
  status = perl_parse(perl, xs_init, 2, argv, NULL);
  if (status != 0) {
     CTRACE(stderr,"httpd: perl_parse failed: %s. Status: %d\n",argv[1],status);
     perror("parse");
     exit(1);
  }
  CTRACE(stderr, "perl_init: perl_parse...ok\n");

  for(i = 0; i < cls->NumPerlModules; i++) {
    mod = cls->PerlModules[i];
    module = newSVpv(mod,0);

    CTRACE(stderr, "Loading Perl module '%s'...", mod); 
    perl_require_module(module);
    if(perl_eval_ok(s) != 0) {
      fprintf(stderr, "Couldn't load Perl module '%s'\n", mod);
      perror("require");
      exit(1);
    }
    else
      CTRACE(stderr, "ok\n");
  }

  perl_clear_env();

  status = perl_run(perl);
  if (status != 0) {
     CTRACE(stderr,"httpd: perl_run failed: %s. Status: %d\n",fname,status);
     perror("run");
     exit(1);
  }
  CTRACE(stderr, "perl_init: perl_run...ok\n");

  if (s->error_log)
    error_log2stderr(s);
}

void *create_perl_dir_config (pool *p, char *dirname)
{
  perl_dir_config *cls =
    (perl_dir_config *)palloc(p, sizeof (perl_dir_config));
  cls->vars = make_table(p, MAX_PERL_CONF_VARS); 
  cls->PerlHandler = NULL;
  cls->PerlAuthenHandler = NULL;
  return (void *)cls;
}

void *create_perl_server_config (pool *p, server_rec *s)
{
  perl_server_config *cls =
    (perl_server_config *)palloc(p, sizeof (perl_server_config));

  cls->PerlModules = (char **)NULL; 
  cls->PerlModules = (char **)palloc(p, MAX_PERL_MODS*sizeof(char *));
  cls->NumPerlModules = 0;
  cls->PerlScript = NULL;
  cls->PerlTransHandler = NULL;
  perl = NULL;

  return (void *)cls;
}

int perl_fast_handler(request_rec *r)
{
  int status = OK;
  perl_dir_config *cld = get_module_config (r->per_dir_config,
					    &perl_fast_module);   

  perl_set_request_rec(r);

  /* hookup STDIN & STDOUT to the client */
  perl_stdout2client(r);
  perl_stdin2client(r);

  if(cld->sendheader)
    basic_http_header(r);
  if(cld->setup_env)
    perl_setup_env();

  if(cld->PerlHandler != NULL) {
    CTRACE(stderr, "calling PerlHandler '%s'\n", cld->PerlHandler);
    status = perl_call(cld->PerlHandler, r->server);
  }
  else {
    log_error("perl_call failed, must set a PerlHandler", r->server);
    return SERVER_ERROR;
  }

  CTRACE(stderr, "perl_call returned status: '%d'\n", status);
  PERL_RETURN_STATUS;
}

int perl_authenticate(request_rec *r)
{
  int status = DECLINED;
  perl_dir_config *cld = get_module_config (r->per_dir_config,
					    &perl_fast_module);   

  if (cld->PerlAuthenHandler != NULL) {
    perl_set_request_rec(r);
    CTRACE(stderr, "perl_authenticate handler: '&%s' \n", 
	 cld->PerlAuthenHandler);
    status = perl_call(cld->PerlAuthenHandler, r->server);
  }
  PERL_RETURN_STATUS;
}

int perl_translate(request_rec *r)
{
  int status = DECLINED;
  perl_server_config *cld = get_module_config (r->server->module_config,
					    &perl_fast_module);   
  if (cld->PerlTransHandler != NULL) {
    perl_set_request_rec(r);
    CTRACE(stderr, "perl_translate handler: '&%s' \n", 
	   cld->PerlTransHandler);
    status = perl_call(cld->PerlTransHandler, r->server);
  }
  PERL_RETURN_STATUS;
}

int perl_call(char *perlsub, server_rec *s)
{
    int count, status;
    SV *sv;

    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(sp);
    PUTBACK;
    
    /* agb. need to reset $$ */
    perl_set_pid();

    /* use G_EVAL so we can trap errors */
    count = perl_call_pv(perlsub, G_EVAL | G_SCALAR | G_NOARGS);
    
    SPAGAIN;

    if(perl_eval_ok(s) != 0) 
        return SERVER_ERROR;

    if(count != 1) {
	log_error("perl_call failed, must return a status arg", s);
        return SERVER_ERROR;
    }

    status = POPi;

    PUTBACK;
    FREETMPS;
    LEAVE;
    return status;
}

char *push_perl_modules (cmd_parms *parms, void *dummy, char *arg)
{
  perl_server_config *cls = get_module_config (parms->server->module_config,
                                       &perl_fast_module);   

  CTRACE(stderr, "push_perl_modules: arg='%s'\n", arg);
  cls->PerlModules[cls->NumPerlModules++] = arg;
  return NULL;
}

char *set_perl_trans (cmd_parms *parms, void *dummy, char *arg)
{
  perl_server_config *cls = get_module_config (parms->server->module_config,
                                       &perl_fast_module);   
  CTRACE(stderr, "set_perl_trans: %s\n", arg);
  cls->PerlTransHandler = arg;
  return NULL;
}

char *perl_sendheader_on (cmd_parms *cmd, void *rec, int arg) {
  ((perl_dir_config *)rec)->sendheader = arg;
  return NULL;
}

char *perl_set_env_on (cmd_parms *cmd, void *rec, int arg) {
  ((perl_dir_config *)rec)->setup_env = arg;
  return NULL;
}

char *set_perl_var(cmd_parms *cmd, void *rec, char *key, char *val)
{
  table_set(((perl_dir_config *)rec)->vars, key, val);
  CTRACE(stderr, "set_perl_var: '%s' = '%s'\n", key, val);
  return NULL;
}
  
command_rec perl_cmds [] = {
  { "PerlScript", set_string_slot,
    (void*)XtOffsetOf(perl_server_config, PerlScript), 
    RSRC_CONF, TAKE1, "A Perl script name" },
  { "PerlModule", push_perl_modules,
    NULL,
    RSRC_CONF, ITERATE, "List of Perl modules" },
  { "PerlHandler", set_string_slot, 
    (void*)XtOffsetOf(perl_dir_config, PerlHandler), 
    OR_ALL, TAKE1, "the Perl handler routine name" },
  { "PerlAuthenHandler", set_string_slot, 
    (void*)XtOffsetOf(perl_dir_config, PerlAuthenHandler), 
    OR_ALL, TAKE1, "the Perl Authentication handler routine name" },
  { "OrigPerlTransHandler", set_string_slot, 
    (void*)XtOffsetOf(perl_server_config, PerlTransHandler), 
    RSRC_CONF, TAKE1, "the Perl Translation handler routine name" },
  { "PerlTransHandler", set_perl_trans, 
    NULL,
    RSRC_CONF, TAKE1, "the Perl Translation handler routine name" },
  { "PerlSetVar", set_perl_var, 
    NULL,  
    OR_ALL, TAKE2, "Perl config var and value" },
  { "PerlSendHeader", perl_sendheader_on,
    NULL, 
    OR_ALL, FLAG, "Tell mod_perl_fast to send basic_http_header" },
  { "PerlSetupEnv", perl_set_env_on,
    NULL, 
    OR_ALL, FLAG, "Tell mod_perl_fast to setup %ENV by default" },
  { NULL }
};

handler_rec perl_fast_handlers [] = {
   { "httpd/fast-perl", perl_fast_handler },
   { PERL_APACHE_SSI_TYPE, perl_fast_handler },
   { "fast-perl", perl_fast_handler },
   { "perl-script", perl_fast_handler },
   { NULL }
};

module perl_fast_module = {
   STANDARD_MODULE_STUFF,
   perl_init,			/* initializer */
   create_perl_dir_config,	/* create per-directory config structure */
   NULL, 	                /* merge per-directory config structures */
   create_perl_server_config,	/* create per-server config structure */
   NULL,			/* merge per-server config structures */
   perl_cmds,			/* command table */
   perl_fast_handlers,		/* handlers */
   perl_translate, 		        /* translate_handler */
   perl_authenticate,		/* check_user_id */
   NULL,	                /* check auth */
   NULL, 		        /* check access */
   NULL,			/* type_checker */
   NULL,			/* pre-run fixups */
   NULL			        /* logger */
};

