package mod_perl;
use 5.004;
use strict;

BEGIN {
    $mod_perl::VERSION = "1.03";
    $ENV{MOD_PERL} = $mod_perl::VERSION;
    $ENV{GATEWAY_INTERFACE} = "CGI-Perl/1.1";
}

sub subversion {
    print qq( SERVER_SUBVERSION=\\"mod_perl/$mod_perl::VERSION\\" );
}

sub import {
    my $class = shift;

    #so we can say EXTRA_CFLAGS = `perl -Mmod_perl -e subversion`
    if($^X !~ /(httpd|apache.exe)$/i and $0 eq "-e") {
	*main::subversion = \&subversion;
	return;
    }

    return unless @_;

    if($_[0] =~ /^\d/) {
	$class->UNIVERSAL::VERSION(shift);
    }

    for my $hook (@_) {
	require Apache;
	unless (Apache::perl_hook($hook)) {
	    (my $flag = $hook) =~ s/([A-Z])/_$1/g;
	    $flag = uc $flag;
	    die "`$hook' not enabled, rebuild mod_perl with PERL$flag=1\n";
	}
    }
}

1;

__END__
