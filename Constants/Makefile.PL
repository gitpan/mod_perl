use ExtUtils::MakeMaker;
use Config;

$VERSION = "1.01";

WriteMakefile(
    NAME	=> "Apache::Constants",
    VERSION => $VERSION,
    INC => '-I../src -I../src/modules/perl -I../$(APACHE_SRC) -I../$(APACHE_SRC)/regex -I$(APACHE_SRC) -I$(APACHE_SRC)/regex',
);

