package Apache::SIG;

use strict;
$Apache::SIG::VERSION = (qw$Revision: 1.10 $)[1];

sub set {
    $| = 1;
    $SIG{PIPE} = sub {
	my $ppid = getppid;
	my $s = ($ppid > 1) ? -2 : 0;
	warn "Client hit STOP or Netscrape bit it!\n";
	warn "Process $$ going to Apache::exit with status=$s\n";
        Apache::exit($s);
    };
}

1;

__END__
