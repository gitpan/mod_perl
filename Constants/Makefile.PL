use ExtUtils::MakeMaker;
use Config;

#for me
#$httpd_src = "/afs/ri/project/web/src/servers/apache-1.2-dev/src";
$VERSION = "1.00";

$httpd_src ||= prompt "httpd source directory?", "/opt/src/apache/src"; 
unless (-e "$httpd_src/httpd.h") {
    die "Can't stat $httpd_src/httpd.h\n";
}

WriteMakefile(
    NAME	=> "Apache::Constants",
    VERSION => $VERSION,
    INC => "-I../src -I$httpd_src",
);

