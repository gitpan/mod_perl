/* ====================================================================
 * Copyright (c) 1995 The Apache Group.  All rights reserved.
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

/* $Id: mod_perl_fast.c,v 1.11 1996/05/09 19:38:29 dougm Exp $ */

#include <EXTERN.h>
#include <perl.h>

#include "httpd.h"
#include "http_config.h"
#include "http_protocol.h"
#include "http_log.h"
#include "http_main.h"

static int perl_trace = 0;
#define CTRACE if(perl_trace > 0) fprintf

typedef struct {
   char *PerlScript;
} perl_server_config;

typedef struct {
   char *PerlResponse;
} perl_dir_config;

static PerlInterpreter *perl = NULL;

void xs_init _((void));
void perl_set_request_rec(request_rec *);

module perl_fast_module;

void perl_init (server_rec *s, pool *p)
{
  char *argv[3];
  int status;
  perl_server_config *cls = get_module_config (s->module_config,
					       &perl_fast_module);   
  
  /* char *fname = server_root_relative (p, cls->PerlScript); */
  char *fname = cls->PerlScript;
  if (fname == NULL) {
    fprintf(stderr, "mod_perl_fast: Missing 'PerlScript' in srm.conf!\n");
    return;
    /* exit(1); */
  }

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
  CTRACE(stderr, "perl_init: perl_alloc OK\n");
  
  perl_construct(perl);
  CTRACE(stderr, "perl_init: perl_construct OK\n");

  argv[0] = argv[2] = NULL;
  argv[1] = fname;

  CTRACE(stderr, "perl_init: loading perl script: %s\n", fname);
  status = perl_parse(perl, xs_init, 2, argv, NULL);
  if (status != 0) {
     CTRACE(stderr,"httpd: perl_parse failed: %s. Status: %d\n",fname,status);
     perror("parse");
     exit(1);
  }
  CTRACE(stderr, "perl_init: perl_parse OK\n");

  /* perl_apache_bootstrap(); */
  perl_clear_env();
  status = perl_run(perl);
  if (status != 0) {
     CTRACE(stderr,"httpd: perl_run failed: %s. Status: %d\n",fname,status);
     perror("run");
     exit(1);
  }
  CTRACE(stderr, "perl_init: perl_run OK\n");

  error_log2stderr(s);
}

void *create_perl_dir_config (pool *p, char *dirname)
{
  perl_dir_config *cls =
    (perl_dir_config *)palloc(p, sizeof (perl_dir_config));

  cls->PerlResponse = NULL;
  return (void *)cls;
}

void *create_perl_server_config (pool *p, server_rec *s)
{
  perl_server_config *cls =
    (perl_server_config *)palloc(p, sizeof (perl_server_config));

  cls->PerlScript = NULL;
  perl = NULL;

  return (void *)cls;
}

int perl_fast_handler(request_rec *r)
{
  int status = OK;
  perl_dir_config *cld = get_module_config (r->per_dir_config,
					    &perl_fast_module);   

  perl_set_request_rec(r);
  status = perl_call(perl, cld->PerlResponse, r->server);

  if (status == 65535)  /* this is what we get by exit(-1) in perl */
    status = SERVER_ERROR;

  return status;
}

int perl_call(PerlInterpreter *perl, char *perlsub, server_rec *s)
{
    int count, status;
    SV *sv;
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(sp);
    PUTBACK;
                 /* use G_EVAL so we can trap errors */
    count = perl_call_pv(perlsub, G_EVAL | G_SCALAR);
    SPAGAIN;
    sv = GvSV(gv_fetchpv("@", TRUE, SVt_PV));
    if(SvTRUE(sv)) {
	log_error(SvPV(sv, na), s);
        return SERVER_ERROR;
    }

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

char *set_perl_script (cmd_parms *parms, void *dummy, char *arg)
{
  perl_server_config *cls = get_module_config (parms->server->module_config,
                                       &perl_fast_module);   

  CTRACE(stderr, "set_perl_script: arg='%s'\n", arg);
  cls->PerlScript = arg;
  return NULL;
}

command_rec perl_cmds [] = {
  { "PerlScript", set_perl_script,
    NULL,
    RSRC_CONF, TAKE1, "the Perl script name" },
  { "PerlResponse", set_string_slot, 
    (void*)XtOffsetOf(perl_dir_config, PerlResponse), 
    OR_ALL, TAKE1, "the Perl response routine name" },
  { NULL }
};

handler_rec perl_fast_handlers [] = {
   { "httpd/fast-perl", perl_fast_handler },
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
   NULL, 		        /* translate_handler */
   NULL,			/* check_user_id */
   NULL,   		        /* check auth */
   NULL, 		        /* check access */
   NULL,			/* type_checker */
   NULL,			/* pre-run fixups */
   NULL			        /* logger */
};

