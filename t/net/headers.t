
BEGIN { require "net/config.pl"; }

if($] < 5.003_02) {
    print "1..1\nok 1;\n";
    exit;
}
    
$ua = new LWP::UserAgent;    # create a useragent to test
$s = "http://$net::httpserver$net::perldir/io/perlio.pl";
print "1..3\n";

for (1..3) {
    test $_, fetch($ua, "$s?$_") == $_;
}

