use ExtUtils::MakeMaker;
use Config;

WriteMakefile(
    SKIP      => [qw(static dynamic)], #for now
    'linkext' => {LINKTYPE => '' }, 	      
    NAME	=> "mod_perl",
    VERSION => "0.60a4",
    MAP_TARGET	=> "httpd",
    OBJECT	=> "",
    depend	=> {
    },
   'dist'    => {
	COMPRESS=> 'gzip -9f', SUFFIX=>'gz', 
	POSTOP => 'mv $(DISTNAME)-*.tar.gz ../'
	},
    clean	=> {
	FILES	=> "Apache.c *.o *~"
    }
);

