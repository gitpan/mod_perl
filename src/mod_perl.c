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

/* This module embeds a perl interpreter within the Apache httpd. Files
 * classfied as "httpd/perl" are interpreted as a perl script by the
 * server.  The apache C API is directly available to the perl script
 * as through the perl_glue.xs routines.
 *
 * This should be much faster than what you can achieved with CGI
 * scripts and you also has more direct contol over the connection
 * back to the client.
 *
 * $Id: mod_perl.c,v 1.17 1996/09/06 21:29:41 dougm Exp $
 */

#include "httpd.h"
#include "http_config.h"
#include "http_protocol.h"
#include "http_log.h"
#include "http_main.h"

#include <EXTERN.h>
#include <perl.h>

void xs_init _((void));
void perl_set_request_rec(request_rec *);

int perl_handler(request_rec *r)
{

  char *argv[3];
  int status;
  STRLEN len;

  PerlInterpreter *perl = perl_alloc();
  argv[0] = argv[2] = NULL;
  argv[1] = r->filename;

  perl_construct(perl);
  perl_parse(perl, xs_init, 2, argv, NULL);
  
  /* hookup script's STDERR to the error_log */
  
  if (r->server->error_log)
    error_log2stderr(r->server);

  /* hookup script's STDIN and STDOUT to the client 
   * doing it this way we don't have to mess with server and client fd's
   */

  perl_stdout2client(r);
  perl_stdin2client(r);

  perl_set_request_rec(r);
  perl_clear_env();
  perl_run(perl);

  status = statusvalue;

/* these aren't doing quite what they are supposed to */
  perl_destruct(perl); 
  perl_free(perl);

  if (status == 65535)  /* this is what we get by exit(-1) in perl */
    status = DECLINED;

  return status;
}

handler_rec perl_handlers[] = {
{ "httpd/perl", perl_handler },
{ NULL }
};

module perl_module = {
   STANDARD_MODULE_STUFF,
   NULL,			/* initializer */
   NULL,			/* create per-directory config structure */
   NULL,			/* merge per-directory config structures */
   NULL,			/* create per-server config structure */
   NULL,			/* merge per-server config structures */
   NULL,			/* command table */
   perl_handlers,		/* handlers */
   NULL,			/* translate_handler */
   NULL,			/* check_user_id */
   NULL,			/* check auth */
   NULL,			/* check access */
   NULL,			/* type_checker */
   NULL,			/* pre-run fixups */
   NULL				/* logger */
};
