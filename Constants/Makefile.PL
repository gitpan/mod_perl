use ExtUtils::MakeMaker;
use Config;

$mp_version = MM->parse_version("../Makefile.PL");

WriteMakefile(
    NAME	=> "Apache::Constants",
    VERSION_FROM => "Constants.pm",
    INC => '-I../src -I../src/modules/perl -I../$(APACHE_SRC) -I../$(APACHE_SRC)/regex -I$(APACHE_SRC) -I$(APACHE_SRC)/regex' .
	      qq{ -DSERVER_SUBVERSION=\\"mod_perl/$mp_version\\"},
);

