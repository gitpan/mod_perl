use CGI::Switch;
use strict;

my $r = CGI::Switch->new;
warn "Running cgi.pl with $CGI::VERSION";
warn $r;

my($param) = $r->param('PARAM');
my($httpupload) = $r->param('HTTPUPLOAD');

$r->print( $r->header(-type => "text/plain") );
$r->print( "ok $param\n" ) if $param;

my($content);
if ($httpupload) {
    no strict;
    local $/;
    $content = <$httpupload>;
    $r->print( "ok $content\n" );
}
