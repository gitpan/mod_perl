#include "mod_perl.h"

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

API_EXPORT(void) perl_stdout2client(request_rec *r)
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
    sv_unmagic((SV*)handle, 'q');
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
    GV *handle = gv_fetchpv("STDIN", TRUE, SVt_PVIO);  
    MP_TRACE(fprintf(stderr, "tie *STDIN => Apache\n"));
    sv_unmagic((SV*)handle, 'q');
    sv_magic((SV *)handle,
	     (SV *)perl_bless_request_rec(r),
	     'q', Nullch, 0);
#endif
}
