package Apache::TieHandle;
require Apache;

use vars qw($VERSION);
#$Id: TieHandle.pm,v 1.2 1996/12/17 04:24:38 dougm Exp $ 
$VERSION = sprintf("%d.%02d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/);

sub TIEHANDLE {
    my($class, $r) = @_;
    $r ||= Apache->request;
    $r->basic_http_header(); #get things going
    bless { 
	r => $r,
    } => $class;
}

sub PRINT {
    my($self) = shift;
    $self->{r}->write_client(@_);
}

1;

__END__

=head1 NAME

Apache::TieHandle - tie stdio to Apache's i/o methods

=head1 SYNOPSIS

 use Apache::TieHandle ();

 tie *STDOUT => 'Apache::TieHash';

 print "Content-type: text/html\n\n" .
      "Ah, just like CGI\n";

=head1 DESCRIPTION

This module tie's stdio filehandles to Apache's i/o methods.

*** NOTE ***
There is no need to use this module unless your version of Perl
is <= 5.003
You must apply Sven Verdoolaege's patch 'pp_hot.patch' for it to work

=head1 AUTHOR

Well, Doug MacEachern wrote it, but it wouldn't be possible without
the efforts of Larry Wall and the fearless perl5-porters who 
implemented tie'd filehandles...



