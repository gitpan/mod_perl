
BEGIN { require "net/config.pl"; }
require LWP::UserAgent;

my $ua = new LWP::UserAgent;    # create a useragent to test
my $url = new URI::URL("http://$net::httpserver$net::perldir/api.pl");
my $request = new HTTP::Request('GET', $url);
my $response = $ua->request($request, undef, undef);
print $response->as_string;
#print $response->content;
