
use Apache::test;

if($] < 5.003_02) {
    print "1..1\nok 1;\n";
    exit;
}
    
$ua = new LWP::UserAgent;    # create a useragent to test
$s = "http://$net::httpserver$net::perldir/io/perlio.pl";
print "1..5\n";
my $i = 0;

for (1..4) {
    test $_, fetch($ua, "$s?$_") == $_;
}

my $str = join "\n", ("A".."D"), "";

test 5, fetch($ua, "$s?5") eq $str;
