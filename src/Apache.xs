/* -*-C-*- */
#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include "httpd.h"
#include "http_config.h"
#include "http_protocol.h"
#include "http_log.h"
#include "http_main.h"

/* $Id: Apache.xs,v 1.15 1996/05/18 16:59:48 dougm Exp $ */

typedef request_rec * Apache;
typedef conn_rec    * Apache__Connection;
typedef server_rec  * Apache__Server;

#define REMOTE_NAME (1)

/* this mess will go away */
#ifdef APACHE_1_0
#define REQUEST_IN  r->connection->request_in
#define REQUEST_OUT r->connection->client
#define SEND_TO_CLIENT rprintf(r, "%s", buffer);
#else
#define REQUEST_IN  fdopen(r->connection->client->fd_in, "r")
#define REQUEST_OUT fdopen(r->connection->client->fd, "w")
#define SEND_TO_CLIENT  bputs(buffer, r->connection->client)
#endif


/* eh, need a better way */
#ifdef HIDE_AUTH
#define SKIP_AUTH_HEADER if (!strcasecmp (key, "Authorization")) continue;
#else
#define SKIP_AUTH_HEADER
#endif

static int perl_trace = 0;
#define CTRACE if(perl_trace > 0) fprintf



void perl_set_request_rec(request_rec *r)
{
  /* Make a pointer to the request structure available as $Apache::Request */
  sv_setref_pv(sv_2mortal(perl_get_sv("Apache::Request", TRUE)), NULL, (void*)r);
}

void perl_apache_bootstrap()
{
  char *bootargs[] = { "Apache" };
  /* bootstrap ourselves, if we have no .pm file */
  if(!hv_exists(perl_get_hv("INC", FALSE), "Apache.pm", strlen("Apache.pm")))
    perl_call_argv("Apache::bootstrap", G_DISCARD, bootargs);
}

void perl_clear_env()
{
  /* flush %ENV */
  hv_clear(perl_get_hv("ENV", FALSE));
}

void
perl_require_module(m)
SV *m;
{
    SV* sv = sv_newmortal();
    sv_setpv(sv, "require ");
    sv_catsv(sv, m);
    perl_eval_sv(sv, G_DISCARD);
}

/* we don't use the Safe stuff yet, but it's here for those who are interested */
int perl_safe_wrap_file(PerlInterpreter *perl, char *fname, AV *permit, int permit_only)
{
  
  AV *av = (AV*)sv_2mortal((SV*)newAV());
  char *method;
  int ret;
  SV *cpt, *sv;
  I32 ax;

  perl_require_pv("Safe.pm");

  av_store(av, 0, newSVpv("Root",0));
  ret = mod_perl_call_method(perl, G_EVAL|G_SCALAR, newSVpv("Safe", 4), "new", av);
  CTRACE(stderr, "new Safe returned %d arg(s)\n", ret);
  cpt = (SV*)ST(0);

  method = permit_only ? "permit_only" : "permit";
  ret = mod_perl_call_method(perl, G_EVAL|G_SCALAR, cpt, method, permit); 
  CTRACE(stderr, "$cpt->%s\n returned %d arg(s)\n", method, ret);

  av_clear(av);
  av_push(av, newSVpv("*Apache::",9));
  ret = mod_perl_call_method(perl, G_EVAL|G_SCALAR, cpt, "share", av); 
  av_store(av, 0, newSVpv(fname,0));
  ret = mod_perl_call_method(perl, G_SCALAR, cpt, "rdo", av); 

  return ret;
}
 
int mod_perl_call_method(PerlInterpreter *perl, I32 flags, SV *ref, char *method, AV *av)
{
    int i, count;
    SV *sv;
    I32 ax;
    dSP;

    PUSHMARK(sp);
    XPUSHs(ref);
    i = av_len(av) + 1;
    while(i--) {
      sv = av_shift(av);
      CTRACE(stderr, "sv = '%s'\n", SvPV(sv,na));
      if(SvTRUE(sv))
	XPUSHs(sv_2mortal(sv));
    }
    
    PUTBACK;
    count = perl_call_method(method, flags);
    SPAGAIN;
    
    sp -= count ;
    ax = (sp - stack_base) + 1 ;

    sv = perl_get_sv("@", FALSE);
    if(SvTRUE(sv)) {
	CTRACE(stderr, SvPV(sv, na));
	return 0;
    }

    PUTBACK;
    return count;
}

/* these two are busted for now */
void
perl_stdout2client(request_rec *r)
{
    GV *tmpgv;

    tmpgv = gv_fetchpv("STDOUT",FALSE, SVt_PVIO);
    GvMULTI_on(tmpgv);
    IoOFP(GvIOp(tmpgv)) = IoIFP(GvIOp(tmpgv)) = REQUEST_OUT;
    setdefout(tmpgv);

}

void
perl_stdin2client(request_rec *r)
{
    GV *tmpgv;

    tmpgv = gv_fetchpv("STDIN",FALSE, SVt_PVIO);
    GvMULTI_on(tmpgv);
    IoIFP(GvIOp(tmpgv)) = REQUEST_IN;
}

/* should we? */
int
mod_perl_parse_args(char *a)
{
  dXSARGS;
  char *k, *v, *end;
  int i = 0;

  if(!a) {
    ST(i) = &sv_undef;
    return 1;
  }
 
  if((GIMME == G_SCALAR) || !strchr(a, '=')) {
    ST(i) = sv_2mortal((SV*)newSVpv(a, strlen(a)));
    return 1;
  }
  else {
    end = a;

    while (*end) {
      a = end;
      /* find next '&' character */
      while (*end && *end != '&')
	end++;

      if (*end)
	*end++ = '\0';

      /* split on '=' */
      k = a;
      v = a;
      while (*v && *v != '=')
	v++;
      if (*v)
	*v++ = '\0';

      /* Then we unescape the 'keyword' and the 'value'. */
      unescape_url(k);
      unescape_url(v);

      /* XXX: An unescaped %00 might have terminated the string before
       * we wanted, but there is not easy way to obtain the real unescaped
       * string length so we ignore this problem for now.
       */
      EXTEND(sp, 2);      
      ST(i++) = sv_2mortal((SV*)newSVpv(k, strlen(k)));
      ST(i++) = sv_2mortal((SV*)newSVpv(v, strlen(v)));
       
    }
  }
  PUTBACK;
  return(i);
}

MODULE = Apache  PACKAGE = Apache

PROTOTYPES: DISABLE

#functions from http_core.c

char *
get_remote_host(r)
    Apache	r

    CODE:
    RETVAL = (char *)get_remote_host(r->connection, r->per_dir_config, REMOTE_NAME);

    OUTPUT:
    RETVAL


#functions from http_protocol.c

void
send_http_header(r)
    Apache	r


# Beware that we have changes the order of the arguments for this
# function.

int
send_fd(r, f)
    Apache	r
    FILE *f

    CODE:
    RETVAL = send_fd(f, r);

long
read_client_block(r, buffer, bufsiz)
    Apache	r
    char    *buffer
    int      bufsiz

    OUTPUT:
    buffer

int
write_client(r, ...)
    Apache	r

    ALIAS:
    Apache::print = 1

    CODE:
    {    
    int i;
    char * buffer;

    for(i = 1; i <= items - 1; i++) {
	buffer = (char *)SvPV(ST(i), na);
        RETVAL += SEND_TO_CLIENT; 
    }
    }

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
cgi_env(r)
    Apache	r

    PPCODE:
{
    array_header *env_arr;
    table_entry *elts;
    int i;
    char *tz;

    add_common_vars(r);
    add_cgi_vars(r);
    env_arr = table_elts (r->subprocess_env);
    elts = (table_entry *)env_arr->elts;
    tz = getenv("TZ");
    table_set (env_arr, "PATH", DEFAULT_PATH);
    table_set (env_arr, "GATEWAY_INTERFACE", "CGI-Perl/1.1"); 

    if (tz!= NULL) {
	EXTEND(sp, 2);
	PUSHs(sv_2mortal((SV*)newSVpv("TZ", strlen("TZ"))));
	PUSHs(sv_2mortal((SV*)newSVpv(tz, strlen(tz))));
    }
    for (i = 0; i < env_arr->nelts; ++i) {
	if (!elts[i].key) continue;
	EXTEND(sp, 2);	   
	PUSHs(sv_2mortal((SV*)newSVpv(elts[i].key, strlen(elts[i].key))));
	PUSHs(sv_2mortal((SV*)newSVpv(elts[i].val, strlen(elts[i].val))));
    }
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
    {
    HV *stash;
   
    stash = gv_stashpv(packname, TRUE);
    ST(0) = sv_newmortal();
    ST(0) = sv_bless(perl_get_sv("Apache::Request", FALSE), stash);
    }

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
method(r)
    Apache	r

    CODE:
    RETVAL = r->method;

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

	SKIP_AUTH_HEADER;

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
path_info(r)
    Apache	r

    CODE:
    RETVAL = r->path_info;

    if(items > 1)
      r->path_info = pstrdup(r->pool, SvPV(ST(1), na));

    OUTPUT:
    RETVAL

char *
args(r)
    Apache	r

    CODE:
    {
    int ret;

    ret = mod_perl_parse_args(pstrdup(r->pool, r->args));
    XSRETURN(ret);
    }

#we added this one
char *
content(r)
    Apache	r

    CODE:
    {
    char *a, *ct, *lenp;
    long len, n;

    if (r->method_number == M_POST) {
	ct = table_get(r->headers_in, "Content-Type");
	if (ct && strEQ(ct, "application/x-www-form-urlencoded")) {
	    lenp = table_get(r->headers_in, "Content-Length");
	    len = lenp ? atoi(lenp) : 0;
	    if (len) {
		/* We read the data */
		a = (char*)palloc(r->pool, len+1);
		n = read_client_block(r, a, len);
		if (n != len) {
		    log_reason("Can't read request form content", r->filename, r);
                    #return BAD_REQUEST;
		}
		a[len] = '\0';

		/* Make this hint to the script so it does not try to read also */
		table_set(r->headers_in, "Content-Length", "0");
	    }
	}
    }
    XSRETURN(mod_perl_parse_args(a));
    }

  
#  /* Various other config info which may change with .htaccess files
#   * These are config vectors, with one void* pointer for each module
#   * (the thing pointed to being the module's business).
#   */
  
#  void *per_dir_config;		/* Options set in config files, etc. */
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



