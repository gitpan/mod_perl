use ExtUtils::MakeMaker;
use Config;

WriteMakefile(
    NAME	=> "Apache",
    VERSION_FROM => "Apache.pm",
    INC => '-I../src -I../src/modules/perl -I../$(APACHE_SRC) -I../$(APACHE_SRC)/regex -I$(APACHE_SRC)',
);

