package Apache::Status;
use strict;

my(%status) = (
   inc => "Loaded Modules",
   rgysubs => "Compiled Registry Scripts",
   symdump => "Symbol Table Dump",
);

sub handler {
    my($r) = @_;
    require Apache::CGI;
    my $q = new Apache::CGI;
    my $qs = $r->args;
    my $sub = "status_$qs";
    $r->write_client($q->header, $q->start_html, $q->start_form);
    no strict 'refs';
    if(defined &$sub) {
	$r->write_client(@{ &{$sub}($r,$q) });
    }
    elsif (exists $Apache::Registry->{$qs}) { 
	$r->write_client(symdump($qs));
    }
    else {
	my $uri = $r->uri;
	my $start = scalar localtime $^T;
	$r->write_client(
            "Perl Status for process <b>$$</b>, running since $start<hr>\n",
 	    map { qq[<a href="$uri?$_">$status{$_}</a><br>\n] } keys %status
        );
    }

    1;
}

sub symdump {
    my($package) = @_;
    require Devel::Symdump;
    my $sob = Devel::Symdump->rnew($package);
    return $sob->as_HTML($package);
}

sub status_symdump { [symdump('main')] }

sub status_inc {
    my($r,$q) = @_;
    my(@retval, $module);
    local $_;
    foreach $module ($q->param("INC")) {
	delete $INC{$module};
    }
    $q->delete("INC");
    foreach (sort keys %INC) {
	push @retval, 
	"$_ <br>\n";
	#$q->checkbox(-name => "INC", -value => $_, -label => $_), "<br>";
    }
    push @retval, "<hr>"; #, $q->submit(-value => "Delete");
    \@retval;
}

sub status_rgysubs {
    my($r,$q) = @_;
    my(@retval);
    local $_;
    my $uri = $r->uri;
    push @retval, "<b>Click on package name to see it's symbol table</b><p>\n";
    foreach (sort keys %{$Apache::Registry}) {
	push @retval, 
	#$q->checkbox(-name => "RGY", 
	#	     -label => qq(<a href="$uri?$_">$_</a>)), 
	qq(<a href="$uri?$_">$_</a>\n),
	"<br>";
    }
    \@retval;
}

1;

__END__

=head1 NAME

Apache::Status - Embedded interpreter status information 

=head1 DESCRIPTION

The B<Apache::Status> module provides some information
about the status of the Perl interpreter embedded in the server.

Configure like so:

 <Location /perl-status>
 SetHandler  perl-script
 PerlHandler Apache::Status
 </Location>

=head1 PREREQUISITES

The I<Devel::Symdump> module must be installed:

 perl -MCPAN -e 'install "Devel::Symdump"'

Or fetch from:
http://www.perl.com/cgi-bin/cpan_mod?module=Devel::Symdump

=head1 SEE ALSO

perl(1), Apache(3), Devel::Symdump(3)

=head1 AUTHOR

Doug MacEachern <dougm@osf.org>


