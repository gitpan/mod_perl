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

#include "httpd.h"
#include "http_config.h"
#include "http_protocol.h"
#include "http_log.h"
#include "http_main.h"
#include "http_core.h"

#ifdef PERL_TRACE
#define CTRACE fprintf
#else
#define CTRACE
#endif

/* Apache::SSI */
#define PERL_APACHE_SSI_TYPE "text/x-perl-server-parsed-html"
/* PerlSetVar */
#define MAX_PERL_CONF_VARS 10
/* must alloc for PerlModule ... */
#define MAX_PERL_MODS 10

#define PERL_RETURN_STATUS \
  if((status == 1) || (status == 200)) \
    status = OK; \
  return status

module perl_fast_module;

void xs_init _((void));
void perl_set_request_rec(request_rec *);

typedef struct {
   char *PerlScript;
   char **PerlModules;
   char *PerlTransHandler;
   int  NumPerlModules;
} perl_server_config;

typedef struct {
   char *PerlHandler;
   char *PerlAuthenHandler;
   table *vars;
   int  sendheader;
   int setup_env;
} perl_dir_config;

