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

#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#undef pregcomp
#ifdef __cplusplus
}
#endif
#include "mod_perl.h"

/* $Id: Apache.xs,v 1.35 1996/11/27 16:59:45 dougm Exp $ */

typedef request_rec * Apache;
typedef conn_rec    * Apache__Connection;
typedef server_rec  * Apache__Server;

/* this was private in http_protocol.c */

#define SET_BYTES_SENT(r) \
  do { if (r->sent_bodyct) \
	  bgetopt (r->connection->client, BO_BYTECT, &r->bytes_sent); \
  } while (0)

#define SENDN_TO_CLIENT \
    bwrite(r->connection->client, buffer, n); \
    SET_BYTES_SENT(r)

#define iniHV(hv) hv = (HV*)sv_2mortal((SV*)newHV())
#define iniAV(av) av = (AV*)sv_2mortal((SV*)newAV())

static IV perl_apache_request_rec;

void perl_set_request_rec(request_rec *r)
{
  /* This will depreciate */
  perl_apache_request_rec = (IV)r;
  CTRACE(stderr, "perl_set_request_rec\n");
}

SV *perl_bless_request_rec(request_rec *r)
{
    SV *sv = sv_newmortal();
    char *package = "Apache";
    sv_setref_pv(sv, package, (void*)r);
    CTRACE(stderr, "blessing request_rec\n");
    return sv;
}

void perl_setup_env()
{ /* XXX yuck, rework this later */
  SV *sv = newSV(0);
  sv_setpv(sv, "%ENV = Apache->request->cgi_env();"); 
  perl_eval_sv(sv, G_DISCARD);
}

void perl_clear_env()
{
  /* flush %ENV */
  hv_clear(perl_get_hv("ENV", FALSE));
}

void perl_set_pid()
{
  GV *tmpgv;
  if (tmpgv = gv_fetchpv("$", TRUE, SVt_PV))  /*" unconfuse emacs */
    sv_setiv(GvSV(tmpgv), (I32)getpid());
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

void perl_require_module(mod)
char *mod;
{
    SV *sv = sv_newmortal();
    SV *m = newSVpv(mod,0);
    sv_setpv(sv, "require ");
    sv_catsv(sv, m);
    perl_eval_sv(sv, G_DISCARD);
}

#ifdef USE_SFIO

typedef struct {
   Sfdisc_t     disc;   /* the sfio discipline structure */
   request_rec	*r;
} Apache_t;

static int
sfapachewrite(f, buffer, n, disc)
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

static int
sfapacheread(f, buffer, bufsiz, disc)
Sfio_t* f;      /* stream involved */
char*           buffer;    /* buffer to read into */
int             bufsiz;      /* number of bytes to read */
Sfdisc_t*       disc;   /* discipline */        
{
    long nrd;
    int extra = 0;
    request_rec	*r = ((Apache_t*)disc)->r;
    /* CTRACE(stderr, "sfapacheread: want %d bytes\n", bufsiz); */
    PERL_READ_FROM_CLIENT;
    return bufsiz;
}

Sfdisc_t *
sfdcnewapache(request_rec *r)
{
    Apache_t*   disc;
  
    if(!(disc = (Apache_t*)malloc(sizeof(Apache_t))) )
      return (Sfdisc_t *)disc;
    CTRACE(stderr, "sfdcnewapache(r)\n");
    disc->disc.readf = sfapacheread; 
    disc->disc.writef = sfapachewrite;
    disc->disc.seekf = (Sfseek_f)NULL;
    disc->disc.exceptf = (Sfexcept_f)NULL;
    disc->r = r;
    return (Sfdisc_t *)disc;
}
#endif

/* need Perl 5.003_02+, linked with sfio */
void
perl_stdout2client(request_rec *r)
{
#ifdef USE_SFIO
    sfdisc(PerlIO_stdout(), SF_POPDISC);
    sfdisc(PerlIO_stdout(), sfdcnewapache(r));
#else
    CTRACE(stderr, "tie *STDOUT => Apache\n");
    sv_magic((SV *)gv_fetchpv("STDOUT", TRUE, SVt_PVIO), 
	     (SV *)perl_bless_request_rec(r),
	     'q', Nullch, 0);
#endif
}

void
perl_stdin2client(request_rec *r)
{
#ifdef USE_SFIO
    sfdisc(PerlIO_stdin(), SF_POPDISC);
    sfdisc(PerlIO_stdin(), sfdcnewapache(r));
    sfsetbuf(PerlIO_stdin(), NULL, 0);
#else
/* XXX patch pp_sys.c ?
    CTRACE(stderr, "tie *STDIN => Apache (doesn't work yet)\n");
    sv_magic((SV *)gv_fetchpv("STDIN", TRUE, SVt_PVIO), 
	     (SV *)perl_bless_request_rec(r),
	     'q', Nullch, 0);
*/
#endif
}

MODULE = Apache  PACKAGE = Apache

PROTOTYPES: DISABLE

void
exit(r, ...)
Apache r

    CODE:
    {
    int sts = 0;
    
    if(items > 1)
        sts = (int)SvIV(ST(1));

    /* make sure we log the transaction, etc. */
    PERL_EXIT_CLEANUP;
    exit(sts);
    }
     
char *
unescape_url(string)
    char *	string

   CODE:
   {
   unescape_url(string);
   RETVAL = string;
   }

   OUTPUT:
   RETVAL
   
#functions from http_core.c

void
requires(r)
Apache     r

    CODE:
    {
    AV *av;
    HV *hv;
    register int x;
    int m = r->method_number;
    char *t;
    array_header *reqs_arr = requires (r);
    require_line *reqs;

    if (!reqs_arr)
	ST(0) = &sv_undef;
    else {
	reqs = (require_line *)reqs_arr->elts;
	iniAV(av);
        for(x=0; x < reqs_arr->nelts; x++) {
	    /* XXX should we do this or let PerlAuthzHandler? */
	    if (! (reqs[x].method_mask & (1 << m))) continue;
	    t = reqs[x].requirement;
	    iniHV(hv);
	    hv_store(hv, "method_mask", 11, 
		     newSViv((IV)reqs[x].method_mask), 0);
	    hv_store(hv, "requirement", 11, 
		     newSVpv(reqs[x].requirement,0), 0);
	    av_push(av, newRV((SV*)hv));
	    /* SvREFCNT_dec(hv); *//* XXX since newRV() incremented it? */
	}
	ST(0) = newRV((SV*)av); 
	SvREFCNT_dec(av); 
    }
    }

int 
allow_options(r)
    Apache	r

int
is_perlaliased(r)
    Apache	r

    CODE:
    {
    char *t;

    t = table_get (r->notes, "alias-forced-type");
    RETVAL = (t && (!strcmp (t, "perl-script")));
    }

    OUTPUT:
    RETVAL
 

char *
get_remote_host(r)
    Apache	r

    CODE:
    RETVAL = (char *)get_remote_host(r->connection, r->per_dir_config, REMOTE_NAME);

    OUTPUT:
    RETVAL


#functions from http_protocol.c

void
note_basic_auth_failure(r)
	Apache r

void
get_basic_auth_pw(r)
    Apache r

    PPCODE:
    {
    char *sent_pw = NULL;
    int ret;
    ret = get_basic_auth_pw(r, &sent_pw);
    XPUSHs(sv_2mortal((SV*)newSViv(ret)));
    if(ret == OK)
	XPUSHs(sv_2mortal((SV*)newSVpv(sent_pw, 0)));
    else
	XPUSHs(&sv_undef);
    }

void
send_http_header(r)
    Apache	r

void
basic_http_header(r)
    Apache	r

# Beware that we have changes the order of the arguments for this
# function.

int
send_fd(r, f)
    Apache	r
    FILE *f

    CODE:
    RETVAL = send_fd(f, r);

void
read_client_block(r, buffer, bufsiz)
    Apache	r
    char    *buffer
    int      bufsiz

    PPCODE:
     {
       long nrd;
       int extra = 0;
       buffer = (char*)palloc(r->pool, bufsiz);
       PERL_READ_FROM_CLIENT;
       if ( nrd > 0 ) {
	 XPUSHs(newSViv((long)nrd));
	 sv_setpvn((SV*)ST(1), buffer, bufsiz);
       } 
       else {
	 ST(1) = &sv_undef;
       }
     }

int
write_client(r, ...)
    Apache	r

    ALIAS:
    Apache::print = 1
    Apache::PRINT = 2

    CODE:
    {    
    int i;
    char * buffer;
    STRLEN n;

    for(i = 1; i <= items - 1; i++) {
	buffer = SvPV(ST(i), n);
	RETVAL += SENDN_TO_CLIENT;
    }
    }

    
#functions from http_request.c
void
internal_redirect_handler(r, location)
    Apache	r
    char *      location

    CODE:
    internal_redirect_handler(location, r);

#functions from http_log.c
# Beware, we have changed the order of the arguments for the log_reason()
# funtion.

void
log_reason(r, reason, filename)
    Apache	r
    char *	reason
    char *	filename

    CODE:
    log_reason(reason, filename, r);

void
log_error(r, mess)
    Apache	r
    char *	mess

    CODE:
    log_error(mess, r->server);

#methods for creating a CGI environment
void
cgi_env(r, ...)
    Apache	r

    PPCODE:
   {

   array_header *env_arr = table_elts (r->subprocess_env);
   char *key;

   if(items > 1) {
       key = SvPV(ST(1),na);
       if(items > 2) 
	   table_set(env_arr, key, SvPV(ST(2),na));
   }
   if(GIMME == G_ARRAY) {
       int i;
       char *tz;
       table_entry *elts;
       add_common_vars(r);
       add_cgi_vars(r);
       elts = (table_entry *)env_arr->elts;
       tz = getenv("TZ");
       table_set (env_arr, "PATH", DEFAULT_PATH);
       table_set (env_arr, "GATEWAY_INTERFACE", "CGI-Perl/1.1"); 
       
       if (tz!= NULL) {
	   EXTEND(sp, 2);
	   PUSHs(sv_2mortal((SV*)newSVpv("TZ", 2)));
	   PUSHs(sv_2mortal((SV*)newSVpv(tz, strlen(tz))));
       }
       for (i = 0; i < env_arr->nelts; ++i) {
	   if (!elts[i].key) continue;
	   EXTEND(sp, 2);	   
	   PUSHs(sv_2mortal((SV*)newSVpv(elts[i].key, strlen(elts[i].key))));
	   PUSHs(sv_2mortal((SV*)newSVpv(elts[i].val, strlen(elts[i].val))));
       }
   }
   else if(key) 
       XPUSHs(sv_2mortal((SV*)newSVpv(table_get(env_arr, key), 0)));

   }
   

void
client_to_stdout(r)
    Apache	r

    CODE:
    perl_stdout2client(r);

void
client_to_stdin(r)
    Apache	r

    CODE:
    perl_stdin2client(r);

#see httpd.h
#struct request_rec {

void
request(packname = "Apache")
    char * packname
	
    CODE:
    ST(0) = perl_bless_request_rec((request_rec *)perl_apache_request_rec);	   
#  pool *pool;
#  conn_rec *connection;
#  server_rec *server;

void
connection(r)
    Apache	r
	
    CODE:
    {
    char *packname = "Apache::Connection";
    HV *stash;
   
    stash = gv_stashpv(packname, TRUE);
    ST(0) = sv_newmortal();
    sv_setref_pv(ST(0), packname, (void*)r->connection);
    }

void
server(r)
    Apache	r
	
    CODE:
    {
    char *packname = "Apache::Server";
    HV *stash;
   
    stash = gv_stashpv(packname, TRUE);
    ST(0) = sv_newmortal();
    sv_setref_pv(ST(0), packname, (void*)r->server);
    }

#  request_rec *next;		/* If we wind up getting redirected,
#				 * pointer to the request we redirected to.
#				 */
#  request_rec *prev;		/* If this is an internal redirect,
#				 * pointer to where we redirected *from*.
#				 */
  
#  request_rec *main;		/* If this is a sub_request (see request.h) 
#				 * pointer back to the main request.
#				 */

# ...
#  /* Info about the request itself... we begin with stuff that only
#   * protocol.c should ever touch...
#   */
  
#  char *the_request;		/* First line of request, so we can log it */
#  int assbackwards;		/* HTTP/0.9, "simple" request */
#  int proxyreq;                 /* A proxy request */
#  int header_only;		/* HEAD request, as opposed to GET */

#  char *protocol;		/* Protocol, as given to us, or HTTP/0.9 */
#  char *hostname;		/* Host, as set by full URI or Host: */
#  int hostlen;			/* Length of http://host:port in full URI */

#  char *status_line;		/* Status line, if set by script */
#  int status;			/* In any case */

void
main(r)
    Apache   r

    CODE:
    if(r->main != NULL)
 	ST(0) = perl_bless_request_rec((request_rec *)r->main);
    else
        ST(0) = &sv_undef;

int 
is_main(r)
    Apache   r

    CODE:
    if(r->main != NULL) RETVAL = 0;
    else RETVAL = 1;
       
    OUTPUT:
    RETVAL

int
proxyreq(r)
    Apache   r

    CODE:
    RETVAL = r->proxyreq;

    OUTPUT:
    RETVAL

char *
protocol(r)
    Apache	r

    CODE:
    RETVAL = r->protocol;

    OUTPUT:
    RETVAL

char *
hostname(r)
    Apache	r

    CODE:
    RETVAL = r->hostname;

    OUTPUT:
    RETVAL

int
status(r, ...)
    Apache	r

    CODE:
    RETVAL = r->status;

    if(items > 1)
        r->status = (int)SvIV(ST(1));

    OUTPUT:
    RETVAL

char *
status_line(r, ...)
    Apache	r

    CODE:
    RETVAL = (char *)r->status_line;

    if(items > 1)
        r->status_line = pstrdup(r->pool, (char *)SvPV(ST(1), na));

    OUTPUT:
    RETVAL
  
#  /* Request method, two ways; also, protocol, etc..  Outside of protocol.c,
#   * look, but don't touch.
#   */
  
#  char *method;			/* GET, HEAD, POST, etc. */
#  int method_number;		/* M_GET, M_POST, etc. */

#  int sent_bodyct;		/* byte count in stream is for body */

char *
method(r, ...)
    Apache	r

    CODE:
    RETVAL = r->method;

    if(items > 1)
        r->method = pstrdup(r->pool, (char *)SvPV(ST(1), na));

    OUTPUT:
    RETVAL

int
method_number(r, ...)
    Apache	r

    CODE:
    RETVAL = r->method_number;

    if(items > 1)
        r->method_number = (int)SvIV(ST(1));

    OUTPUT:
    RETVAL

#    /* MIME header environments, in and out.  Also, an array containing
#   * environment variables to be passed to subprocesses, so people can
#   * write modules to add to that environment.
#   *
#   * The difference between headers_out and err_headers_out is that the
#   * latter are printed even on error, and persist across internal redirects
#   * (so the headers printed for ErrorDocument handlers will have them).
#   *
#   * The 'notes' table is for notes from one module to another, with no
#   * other set purpose in mind...
#   */
  
#  table *headers_in;
#  table *headers_out;
#  table *err_headers_out;
#  table *subprocess_env;
#  table *notes;

#  char *content_type;		/* Break these out --- we dispatch on 'em */
#  char *handler;		/* What we *really* dispatch on           */

#  char *content_encoding;
#  char *content_language;
  
#  int no_cache;

char *
header_in(r,key)
    Apache	r
    char *key

    CODE:
    RETVAL = table_get(r->headers_in, key);

    OUTPUT:
    RETVAL

void
headers_in(r)
    Apache	r

    PPCODE:
    {
    int i;
    char *key, *val;

    array_header *hdrs_arr = table_elts (r->headers_in);
    table_entry  *hdrs = (table_entry *)hdrs_arr->elts;

    for (i = 0; i < hdrs_arr->nelts; ++i) {
	key = hdrs[i].key;
	if (!key) continue;
	val = hdrs[i].val;

	EXTEND(sp, 2);	   
	PUSHs(sv_2mortal((SV*)newSVpv(key, strlen(key))));
	PUSHs(sv_2mortal((SV*)newSVpv(val, strlen(val))));
    }
    }

char *
header_out(r, key, ...)
    Apache	r
    char *key

    CODE:
    RETVAL = table_get(r->headers_out, key);

    if(items > 2) 
      table_set(r->headers_out, key, SvPV(ST(2), na));

    OUTPUT:
    RETVAL
    
void
err_headers_out(r, key, val)
    Apache	r
    char *key
    char *val

    CODE:
    table_set(r->err_headers_out, key, val);

char *
content_type(r, ...)
    Apache	r

    CODE:
    RETVAL = r->content_type;

    if(items > 1)
        r->content_type = pstrdup(r->pool, SvPV(ST(1), na));
  
    OUTPUT:
    RETVAL

char *
handler(r, ...)
    Apache	r

    CODE:
    RETVAL = r->handler;

    if(items > 1)
        r->handler = pstrdup(r->pool, SvPV(ST(1), na));
  
    OUTPUT:
    RETVAL

char *
content_encoding(r, ...)
    Apache	r

    CODE:
    RETVAL = r->content_encoding;

    if(items > 1)
      r->content_encoding = pstrdup(r->pool, SvPV(ST(1), na));

    OUTPUT:
    RETVAL

char *
content_language(r, ...)
    Apache	r

    CODE:
    RETVAL = r->content_language;

    if(items > 1)
      r->content_language = pstrdup(r->pool, SvPV(ST(1), na));

    OUTPUT:
    RETVAL

int
no_cache(r, ...)
    Apache	r

    CODE: 
    RETVAL = r->no_cache;

    if(items > 1)
        r->no_cache = (int)SvIV(ST(1));

    OUTPUT:
    RETVAL

#  /* What object is being requested (either directly, or via include
#   * or content-negotiation mapping).
#   */

#  char *uri;                    /* complete URI for a proxy req, or
#                                   URL path for a non-proxy req */
#  char *filename;
#  char *path_info;
#  char *args;			/* QUERY_ARGS, if any */
#  struct stat finfo;		/* ST_MODE set to zero if no such file */

char *
uri(r, ...)
    Apache	r

    CODE:
    RETVAL = r->uri;

    if(items > 1)
      r->uri = pstrdup(r->pool, SvPV(ST(1), na));

    OUTPUT:
    RETVAL

char *
filename(r, ...)
    Apache	r

    CODE:
    RETVAL = r->filename;

    if(items > 1)
      r->filename = pstrdup(r->pool, SvPV(ST(1), na));

    OUTPUT:
    RETVAL

char *
path_info(r, ...)
    Apache	r

    CODE:
    RETVAL = r->path_info;

    if(items > 1)
      r->path_info = pstrdup(r->pool, SvPV(ST(1), na));

    OUTPUT:
    RETVAL

char *
query_string(r)
    Apache	r

    CODE: 
    RETVAL = r->args;

    OUTPUT:
    RETVAL

#  /* Various other config info which may change with .htaccess files
#   * These are config vectors, with one void* pointer for each module
#   * (the thing pointed to being the module's business).
#   */
  
#  void *per_dir_config;		/* Options set in config files, etc. */

char *
dir_config(r, key)
   Apache  r
   char *key

   CODE:
   {
   perl_dir_config *c;
   c = get_module_config(r->per_dir_config, &perl_module);
   RETVAL = table_get(c->vars, key);
   }

   OUTPUT:
   RETVAL

   
#  void *request_config;		/* Notes on *this* request */

#/*
# * a linked list of the configuration directives in the .htaccess files
# * accessed by this request.
# * N.B. always add to the head of the list, _never_ to the end.
# * that way, a sub request's list can (temporarily) point to a parent's list
# */
#  const struct htaccess_result *htaccess;
#};

#/* Things which are per connection
# */

#struct conn_rec {
  
MODULE = Apache  PACKAGE = Apache::Connection

PROTOTYPES: DISABLE

void
close(conn)
    Apache::Connection	conn

    CODE:
    bclose(conn->client);

#  pool *pool;
#  server_rec *server;
  
#  /* Information about the connection itself */
  
#  BUFF *client;			/* Connetion to the guy */
#  int aborted;			/* Are we still talking? */
  
#  /* Who is the client? */
  
#  struct sockaddr_in local_addr; /* local address */
#  struct sockaddr_in remote_addr;/* remote address */
#  char *remote_ip;		/* Client's IP address */
#  char *remote_host;		/* Client's DNS name, if known.
#                                 * NULL if DNS hasn't been checked,
#                                 * "" if it has and no address was found.
#                                 * N.B. Only access this though
#				 * get_remote_host() */

char *
remote_ip(conn)
    Apache::Connection	conn

    CODE:
    RETVAL = conn->remote_ip;

    OUTPUT:
    RETVAL

char *
remote_host(conn)
    Apache::Connection	conn

    CODE:
    RETVAL = conn->remote_host;

    OUTPUT:
    RETVAL

#  char *remote_logname;		/* Only ever set if doing_rfc931
#                                 * N.B. Only access this through
#				 * get_remote_logname() */
#    char *user;			/* If an authentication check was made,
#				 * this gets set to the user name.  We assume
#				 * that there's only one user per connection(!)
#				 */
#  char *auth_type;		/* Ditto. */

char *
remote_logname(conn)
    Apache::Connection	conn

    CODE:
    RETVAL = conn->remote_logname;

    OUTPUT:
    RETVAL

char *
user(conn)
    Apache::Connection	conn

    CODE:
    RETVAL = conn->user;

    OUTPUT:
    RETVAL

char *
auth_type(conn)
    Apache::Connection	conn

    CODE:
    RETVAL = conn->auth_type;

    OUTPUT:
    RETVAL

#  int keepalive;		/* Are we using HTTP Keep-Alive? */
#  int keptalive;		/* Did we use HTTP Keep-Alive? */
#  int keepalives;		/* How many times have we used it? */
#};

#/* Per-vhost config... */

#struct server_rec {

MODULE = Apache  PACKAGE = Apache::Server

PROTOTYPES: DISABLE

#  server_rec *next;
  
#  /* Full locations of server config info */
  
#  char *srm_confname;
#  char *access_confname;
  
#  /* Contact information */
  
#  char *server_admin;
#  char *server_hostname;
#  short port;                    /* for redirects, etc. */

char *
server_admin(server)
    Apache::Server	server

    CODE:
    RETVAL = server->server_admin;

    OUTPUT:
    RETVAL

char *
server_hostname(server)
    Apache::Server	server

    CODE:
    RETVAL = server->server_hostname;

    OUTPUT:
    RETVAL

short
port(server)
    Apache::Server	server

    CODE:
    RETVAL = server->port;

    OUTPUT:
    RETVAL
  
#  /* Log files --- note that transfer log is now in the modules... */
  
#  char *error_fname;
#  FILE *error_log;
  
#  /* Module-specific configuration for server, and defaults... */

#  int is_virtual;               /* true if this is the virtual server */
#  void *module_config;		/* Config vector containing pointers to
#				 * modules' per-server config structures.
#				 */
#  void *lookup_defaults;	/* MIME type info, etc., before we start
#				 * checking per-directory info.
#				 */
#  /* Transaction handling */

#  struct in_addr host_addr;	/* The bound address, for this server */
#  short host_port;              /* The bound port, for this server */
#  int timeout;			/* Timeout, in seconds, before we give up */
#  int keep_alive_timeout;	/* Seconds we'll wait for another request */
#  int keep_alive;		/* Maximum requests per connection */

#  char *names;			/* Wildcarded names for HostAlias servers */
#  char *virthost;		/* The name given in <VirtualHost> */



