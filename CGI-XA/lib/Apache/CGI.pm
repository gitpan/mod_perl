package Apache::CGI;
use Apache ();
use vars qw(@ISA $VERSION);

eval {require CGI::XA;};
if ($@) {
    require CGI;
    @ISA = qw(CGI); # maybe 
} else {
    @ISA = qw(CGI::XA);
}

$VERSION = (qw$Revision: 1.17 $)[1];

sub new {
    my($class) = shift;
    my($r) = Apache->request;
    %ENV = $r->cgi_env unless $ENV{GATEWAY_INTERFACE}; #PerlSetupEnv On 
    my $self = $class->SUPER::new(@_);
    $self->{'.req'} = $r;
    $self;
}

sub header {
    my $self = shift;
    my $r = $self->{'.req'};
    $r->basic_http_header;
    return $self->CGI::XA::header(@hdrs);
}		     

sub print {
    my($self) = shift;
    $self->{'.req'}->write_client(@_);
}

sub read_from_client {
    my($self, $fh, $buff, $len, $offset) = @_;
    my $r = $self->{'.req'} || Apache->request;
    return $r->read($$buff, $len, $offset);
}

sub new_MultipartBuffer {
    my $self = shift;
    my $new = Apache::MultipartBuffer->new($self, @_); 
    $new->{'.req'} = $self->{'.req'} || Apache->request;
    return $new;
}

sub exit {
    my($self, $s) = @_;
    $self->{'.req'}->connection->close;
    $self->{'.req'}->exit($s);
}

package Apache::MultipartBuffer;
@ISA = qw(CGI::XA::MultipartBuffer);

sub wouldBlock { undef }
*Apache::MultipartBuffer::read_from_client = \&Apache::CGI::read_from_client;

1;

__END__

=head1 NAME

Apache::CGI - Make things work with CGI.pm against Perl-Apache API

=head1 SYNOPSIS

 
 require Apache::CGI;

 my $q = new Apache::CGI;

 $q->print($q->header);

 #do things just like you do with CGI.pm

=head1 DESCRIPTION

When using the Perl-Apache API, your applications are faster, but the
enviroment is different than CGI.
This module attempts to set-up that environment as best it can.

=head1 SEE ALSO

perl(1), Apache(3), CGI(3)

=head1 AUTHOR

Doug MacEachern E<lt>dougm@osf.orgE<gt>, hacked over by Andreas König E<lt>a.koenig@mind.deE<gt>

=cut
