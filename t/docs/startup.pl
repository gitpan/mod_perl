
$ENV{GATEWAY_INTERFACE} =~ /^CGI-Perl/ or die "GATEWAY_INTERFACE not set!";

#will be redef'd during tests
sub PerlTransHandler::handler {-1}

#./blib/lib:./blib/arch
use ExtUtils::testlib;

#for testing PERL_HANDLER_METHODS
#see httpd.conf and t/docs/LoadClass.pm
use lib './t/docs';

sub MyClass::method ($$) {
    my($class, $r) = @_;  
    warn "$class->method called\n";
}

sub BaseClass::handler ($$) {
    my($class, $r) = @_;  
    warn "$class->handler called\n";
}

@MyClass::ISA = qw(BaseClass);
