use ExtUtils::MakeMaker;
use Config;

$VERSION = "1.01";

for (<../../apache*/src>) {
    if (-e "$_/httpd.h") {
	#print "Apache constants obtained from <$_/*.h>\n";
	$httpd_src=$_;
	last;
    }
}
    
$httpd_src ||= prompt "httpd source directory?", "/opt/src/apache/src"; 
unless (-e "$httpd_src/httpd.h") {
    die "Can't stat $httpd_src/httpd.h\n";
}

$httpd_src =~ s,^../,,; #fixup for pasthru

WriteMakefile(
    macro => {
	APACHE_SRC => $httpd_src, #PASTHRU might override this
    },
    NAME	=> "Apache::Constants",
    VERSION => $VERSION,
    INC => '-I../src -I../src/modules/perl -I../$(APACHE_SRC) -I../$(APACHE_SRC)/regex',
);

