use ExtUtils::MakeMaker;
use Config;

$VERSION = "1.01";

for (<../../apache*/src>) {
    print "Checking $_ for httpd.h\n";
    last if -e "$_/httpd.h", $httpd_src=$_;
    undef $httpd_src;
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

