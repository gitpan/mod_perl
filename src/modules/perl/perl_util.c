#include "mod_perl.h"

static HV *mod_perl_endhv = Nullhv;
static CV *no_warn = Nullcv;
static int set_ids = 0;

void perl_util_cleanup(void)
{
    hv_undef(mod_perl_endhv);
    SvREFCNT_dec((SV*)mod_perl_endhv);
    mod_perl_endhv = Nullhv;

    SvREFCNT_dec((SV*)no_warn);
    no_warn = Nullcv;

    set_ids = 0;
}

/* execute END blocks */

void perl_run_blocks(I32 oldscope, AV *list)
{
    STRLEN len;
    I32 i;

    for(i=0; i<=AvFILL(list); i++) {
	CV *cv = (CV*)*av_fetch(list, i, FALSE);
	SV* atsv = GvSV(errgv);

	PUSHMARK(stack_sp);
	perl_call_sv((SV*)cv, G_EVAL|G_DISCARD);
	(void)SvPV(atsv, len);
	if (len) {
	    if (list == beginav)
		sv_catpv(atsv, "BEGIN failed--compilation aborted");
	    else
		sv_catpv(atsv, "END failed--cleanup aborted");
	    while (scopestack_ix > oldscope)
		LEAVE;
	}
    }
}

void mod_perl_clear_rgy_endav(request_rec *r, SV *sv)
{
    STRLEN klen;
    char *key;

    if(!mod_perl_endhv) return;

    key = SvPV(sv,klen);
    if(hv_exists(mod_perl_endhv, key, klen)) {
	SV *entry = *hv_fetch(mod_perl_endhv, key, klen, FALSE);
	AV *av;
	if(!SvTRUE(entry) && !SvROK(entry)) {
	    MP_TRACE(fprintf(stderr, "endav is empty for %s\n", r->uri));
	    return;
	}
	av = (AV*)SvRV(entry);
	av_clear(av);
	SvREFCNT_dec((SV*)av);
	(void)hv_delete(mod_perl_endhv, key, klen, G_DISCARD);
	MP_TRACE(fprintf(stderr, 
			 "clearing END blocks for package `%s' (uri=%s)\n",
			 key, r->uri)); 
    }
}

void perl_run_rgy_endav(char *s) 
{
    SV *rgystash = perl_get_sv("Apache::Registry::curstash", TRUE);
    AV *rgyendav = Nullav;
    STRLEN klen;
    char *key = SvPV(rgystash,klen);

    if(!klen) {
	MP_TRACE(fprintf(stderr, 
        "Apache::Registry::curstash not set, can't run END blocks for %s\n",
			 s));
	return;
    }

    if(mod_perl_endhv == Nullhv)
	mod_perl_endhv = newHV();
    else if(hv_exists(mod_perl_endhv, key, klen)) {
	SV *entry = *hv_fetch(mod_perl_endhv, key, klen, FALSE);
	if(SvTRUE(entry) && SvROK(entry)) 
	    rgyendav = (AV*)SvRV(entry);
    }

    if(endav) {
	I32 i;
	if(rgyendav == Nullav)
	    rgyendav = newAV();

	if(AvFILL(rgyendav) > -1)
	    av_clear(rgyendav);
	else
	    av_extend(rgyendav, AvFILL(endav));

	for(i=0; i<=AvFILL(endav); i++) {
	    SV **svp = av_fetch(endav, i, FALSE);
	    av_store(rgyendav, i, (SV*)newRV((SV*)*svp));
	}
    }

    MP_TRACE(fprintf(stderr, 
	     "running %d END blocks for %s\n", AvFILL(rgyendav)+1, s));
    if((endav = rgyendav)) 
	perl_run_blocks(scopestack_ix, endav);
    if(rgyendav)
	hv_store(mod_perl_endhv, key, klen, (SV*)newRV((SV*)rgyendav), FALSE);
    
    sv_setpv(rgystash,"");
}

void perl_run_endav(char *s)
{
    if(endav) {
	save_hptr(&curstash);
	curstash = defstash;
	MP_TRACE(fprintf(stderr, "running %d END blocks for %s\n", 
			 AvFILL(endav)+1, s));
	call_list(scopestack_ix, endav);
    }
}

static I32
errgv_empty_set(IV ix, SV* sv)
{ 
    sv_setpv(sv, "");
    return TRUE;
}

void perl_call_halt()
{
    struct ufuncs umg;

    umg.uf_val = errgv_empty_set;
    umg.uf_set = errgv_empty_set;
    umg.uf_index = (IV)0;
                                                                  
    sv_magic(GvSV(errgv), Nullsv, 'U', (char*) &umg, sizeof(umg));

    ENTER;
    SAVESPTR(diehook);
    diehook = Nullsv; 
    croak("");
    LEAVE;

    sv_unmagic(GvSV(errgv), 'U');
}

CV *empty_anon_sub(void)
{
    return newSUB(start_subparse(FALSE, 0),
                  newSVOP(OP_CONST, 0, newSVpv("__ANON__",8)),
                  Nullop,
                  block_end(block_start(TRUE), newOP(OP_STUB,0)));
}
   
void newCONSTSUB(HV *stash, char *name, SV *sv)
{
    line_t oldline = curcop->cop_line;
    curcop->cop_line = copline;

    ENTER;
    SAVEI32(hints);
    hints &= ~HINT_BLOCK_SCOPE;

    if(stash) {
	save_hptr(&curstash);
	save_hptr(&curcop->cop_stash);
	curstash = curcop->cop_stash = stash;
    }

    /* prevent prototype mismatch warnings */
    if(!no_warn) no_warn = empty_anon_sub();
    SAVESPTR(warnhook);
    warnhook = (SV*)no_warn;

    (void)newSUB(start_subparse(FALSE, 0),
	   newSVOP(OP_CONST, 0, newSVpv(name,0)),
	   newSVOP(OP_CONST, 0, &sv_no),	
	   newSTATEOP(0, Nullch, newSVOP(OP_CONST, 0, sv)));

    LEAVE;
    curcop->cop_line = oldline;
}

int perl_require_module(char *mod, server_rec *s)
{
    SV *sv = sv_newmortal();
    sv_setpvn(sv, "require ", 8);
    MP_TRACE(fprintf(stderr, "loading perl module '%s'...", mod)); 
    sv_catpv(sv, mod);
    perl_eval_sv(sv, G_DISCARD);
    if(perl_eval_ok(s) != OK) {
	MP_TRACE(fprintf(stderr, "not ok\n"));
	return -1;
    }
    MP_TRACE(fprintf(stderr, "ok\n"));
    return 0;
}

void perl_clear_env(void)
{
    char *key; 
    I32 klen; 
    SV *val;
    HV *hv = (HV*)GvHV(envgv);

    sv_unmagic((SV*)hv, 'E');
    (void)hv_iterinit(hv); 
    while ((val = hv_iternextsv(hv, (char **) &key, &klen))) { 
	if((*key == 'G') && strEQ(key, "GATEWAY_INTERFACE"))
	    continue;
	if((*key == 'T') && strnEQ(key, "TZ", 2))
	    continue;
	(void)hv_delete(hv, key, klen, G_DISCARD);
    }
    sv_magic((SV*)hv, (SV*)envgv, 'E', Nullch, 0);
}

void mod_perl_init_ids(void)  /* $$, $>, $), etc */
{
    if(set_ids++) return;
    sv_setiv(GvSV(gv_fetchpv("$", TRUE, SVt_PV)), (I32)getpid());
#ifndef WIN32
    uid  = (int)getuid(); 
    euid = (int)geteuid(); 
    gid  = (int)getgid(); 
    egid = (int)getegid(); 
    MP_TRACE(fprintf(stderr, 
		     "perl_init_ids: uid=%d, euid=%d, gid=%d, egid=%d\n",
		     uid, euid, gid, egid));
#endif
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

#ifndef PERLLIB_SEP
#define PERLLIB_SEP ':'
#endif

void perl_incpush(char *p)
{
    if(!p) return;

    while(p && *p) {
	SV *libdir = newSV(0);
	char *s;

	while(*p == PERLLIB_SEP) p++;

	if((s = strchr(p, PERLLIB_SEP)) != Nullch) {
	    sv_setpvn(libdir, p, (STRLEN)(s - p));
	    p = s + 1;
	}
	else {
	    sv_setpv(libdir, p);
	    p = Nullch;
	}
	av_push(GvAV(incgv), libdir);
    }
}
