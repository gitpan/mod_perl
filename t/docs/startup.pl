BEGIN {
    #./blib/lib:./blib/arch
    use ExtUtils::testlib;

    use lib './t/docs';
    require "blib.pl" if -e "./t/docs/blib.pl";
}

#use Apache::Debug level => 4;

#for testing perl mod_include's

$Access::Cnt = 0;
sub main::pid { print $$ }
sub main::access { print ++$Access::Cnt }

$ENV{GATEWAY_INTERFACE} =~ /^CGI-Perl/ or die "GATEWAY_INTERFACE not set!";

#will be redef'd during tests
sub PerlTransHandler::handler {-1}

#for testing PERL_HANDLER_METHODS
#see httpd.conf and t/docs/LoadClass.pm

sub MyClass::method ($$) {
    my($class, $r) = @_;  
    warn "$class->method called\n";
}

sub BaseClass::handler ($$) {
    my($class, $r) = @_;  
    warn "$class->handler called\n";
}

@MyClass::ISA = qw(BaseClass);

#testing child_init hook

sub My::child_init {
    my $r = shift;
    my $sa = $r->server->server_admin;
    warn "child_init for process $$, report any problems to $sa\n";
}
