#!/usr/local/bin/perl -w
#
# Check POST via HTTP.
#

print "1..12\n";

BEGIN { require "net/config.pl"; }

require LWP::UserAgent;

$netloc = $net::httpserver;
$script = $net::perldir . "/test";

my $ua = new LWP::UserAgent;    # create a useragent to test

$url = new URI::URL("http://$netloc$script");

my $form = 'searchtype=Substring';

my $request = new HTTP::Request('POST', $url, undef, $form);
$request->header('Content-Type', 'application/x-www-form-urlencoded');

my $response = $ua->request($request, undef, undef);

my $str = $response->as_string;

print "$str\n";

test ++$i, ($response->is_success and $str =~ /^REQUEST_METHOD=POST$/m);
test ++$i, ($str =~ /^CONTENT_LENGTH=(\d+)$/m && $1 == length($form));

print "pounding a bit...\n";
for (1..10) {
    test ++$i, ($ua->request($request, undef, undef)->is_success);
}


# avoid -w warning
$dummy = $net::httpserver;
$dummy = $net::perldir;
