use File::Copy qw(cp);


#version 1.5 that ships with 5.003 is broken!
*cp = sub { system "cp @_"; } if($File::Copy::VERSION < 2.0);

use ExtUtils::testlib;
BEGIN { require "net/config.pl"; }
require LWP::UserAgent;

#first one queries httpd for enabled hooks, 
#generating a hook::handler() for each and writing t/docs/.htaccess
#next request invokes each handler, each appending to t/docs/hooks.txt
my $stacked_test = -d "../docs/stacked" or -d "./docs/stacked";
if($stacked_test) {
    push @urls, qw(/stacked/test.html) ;
    for (qw(.. .)) {
	cp "$_/docs/LoadClass.pm", "../$_/blib/lib" if -e "$_/docs/LoadClass.pm";
    }
}    

@urls = ("$net::perldir/hooks.pl", "/test.html");

my $ua = new LWP::UserAgent;    # create a useragent to test

my($request,$response,$str,$hook_tests,$loc,%Seen);
$hook_tests = 0;

foreach $loc (@urls) {
    $url = new URI::URL("http://$net::httpserver$loc");

    $request = new HTTP::Request('GET', $url);

    print "GET $url\n\n";

    $response = $ua->request($request, undef, undef);

    $str = $response->as_string;

    print "$str\n";

    die "$str\n" unless $response->is_success;
    $hook_tests = $response->content if $response->content =~ /^\d+$/;
}

unless ($hook_tests > 0) { #no callbacks enabled, fine.
    print "1..1\nok 1\n";
    print "no callbacks defined, skipping tests...\n";
    exit;
}

print "1..$hook_tests\n";
$i = 1;
foreach (split /\n/, `cat docs/hooks.txt`) {
    next if $Seen{$_}++;
    print "ok $i\n"; $i++;
}

unlink "docs/.htaccess";
