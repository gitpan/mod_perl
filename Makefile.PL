use ExtUtils::MakeMaker;
use Config;

# Patch up the Makefiles we are going to use with Apache
system $^X, "-pi", "-e", "s!^PERL\\s*=.*!PERL=$Config{'perlpath'}!",
            "src/Makefile.tmpl", "src/modules/perl/Makefile";

WriteMakefile(
    NAME	=> "mod_perl",
    VERSION => "0.85",
#    SKIP      => [qw(static dynamic)], #for now
#    'linkext' => {LINKTYPE => '' }, 	      
#    MAP_TARGET	=> "httpd",
#    OBJECT	=> "",
#    depend	=> {
#    },
   'dist'    => {
	COMPRESS=> 'gzip -9f', SUFFIX=>'gz', 
	DIST_DEFAULT => 'all tardist',
	POSTOP => 'mv $(DISTNAME)-*.tar.gz /users/dougm/public_html/apache'
	},
    clean	=> {
	FILES	=> "Apache.c *.o *~"
    }
);

sub MY::test {
    q(
TEST_VERBOSE=0

test:
	$(FULLPERL) t/TEST $(TEST_VERBOSE)

);
}
