BEGIN { require "net/config.pl"; }  

use LWP::Simple;

print get "http://$net::httpserver$net::perldir/constants.pl";
