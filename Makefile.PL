use ExtUtils::MakeMaker;
use Config;

WriteMakefile(
    NAME	=> "mod_perl",
    VERSION => "0.83_09",
#    SKIP      => [qw(static dynamic)], #for now
#    'linkext' => {LINKTYPE => '' }, 	      
#    MAP_TARGET	=> "httpd",
#    OBJECT	=> "",
#    depend	=> {
#    },
   'dist'    => {
	COMPRESS=> 'gzip -9f', SUFFIX=>'gz', 
	DIST_DEFAULT => 'all tardist',
	POSTOP => 'mv $(DISTNAME)-*.tar.gz ../'
	},
    clean	=> {
	FILES	=> "Apache.c *.o *~"
    }
);

