package Apache::StatINC;

use strict;

$Apache::StatINC::VERSION = "1.00";

my %Stat = ();

sub handler {
    my($key,$file);

    while(($key,$file) = each %INC) {
	my $mtime = (stat $file)[9];

	if(exists $Stat{$file}) {
	    if($mtime > $Stat{$file}) {
		delete $INC{$key};
		local $^W = 0;
		require $key;
	    }
	}

	$Stat{$file} = $mtime;
    }

    return 1;
}

1;

__END__

=head1 NAME

Apache::StatINC - Reload %INC files when updated on disk

=head1 SYNOPSIS

  #httpd.conf or some such
   #can be any Perl*Handler
  PerlInitHandler Apache::StatINC

=head1 DESCRIPTION

When Perl pulls a file via C<require>, it stores the filename in the
global hash C<%INC>.  The next time Perl tries to C<require> the same
file, it sees the file in C<%INC> and does not reload from disk.  This
module's handler iterates over C<%INC> and reloads the file if it has
changed on disk. 

=head1 SEE ALSO

mod_perl(3)

=head1 AUTHOR

Doug MacEachern


