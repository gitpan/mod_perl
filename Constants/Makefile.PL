use ExtUtils::MakeMaker;
use Config;

$VERSION = "1.01";

for (<../../apache*/src>) {
    if (-e "$_/httpd.h") {
        print "Apache constants obtained from <$_/*.h>\n";
        $httpd_src=$_;
       last;
    }
}

$httpd_src ||= prompt "httpd source directory?", "/opt/src/apache/src"; 
unless (-e "$httpd_src/httpd.h") {
    die "Can't stat $httpd_src/httpd.h\n";
}

WriteMakefile(
    NAME	=> "Apache::Constants",
    VERSION => $VERSION,
    INC => "-I../src -I../src/modules/perl -I$httpd_src -I$httpd_src/regex",
);

