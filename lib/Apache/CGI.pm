package Apache::CGI;
require Apache;
use CGI ();

@ISA = qw(CGI);

#Things are not perfect yet...
#$CGI::DefaultClass = 'Apache::CGI';

BEGIN {
    undef &CGI::read_from_cmdline;
    *CGI::read_from_cmdline = sub {};
}

sub new {
    my($class) = shift;
    my $r = Apache->request;
    my $cgi = bless {
        '.req' => $r,
    }, $class;

    my($content,$meth);
    my $dispatch = {
        POST => 'read_post',
        GET  => 'read_query',
    };

    %ENV = $r->cgi_env; #set-up for CGI.pm

    if ($meth = $dispatch->{$r->method}) {
	$cgi->$meth();
    }
    return $cgi;
}

sub read_query {
    my($self) = @_;
    my $r = $self->{'.req'};
    my $content = $r->args();
    $self->parse_params($content);
}

sub read_post {
    my($self) = @_;

    my $r = $self->{'.req'};
    #my %headers = $r->headers_in;
    my $type = $ENV{CONTENT_TYPE};

    if ($type =~ m|^multipart|i) {
	my($boundary) = $type =~ /boundary=(\S+)/;
	$self->read_multipart($boundary, $ENV{CONTENT_LENGTH});
    } 
    else {
	my $content = $r->content();
	$self->parse_params($content);
    }
}

sub header {
    my $self = shift;
    my $r = $self->{'.req'};
    $r->basic_http_header;
    #return CGI->header(@hdrs);

    my %hdrs = @_;
    my @hdrs;

    $r->status_line(delete $hdrs{'-status'})
    	if defined $hdrs{'-status'};

    while(($key,$val) = splice(@_, 0, 2)) {
        next unless $hdrs{$key};
	push @hdrs, $key, $val;
    }	
    #return $self->SUPER::header(@hdrs);
    return CGI->header(@hdrs);
}		     

sub read_from_client {
    my($self, $fh, $buff, $len) = @_;
    my $r = $self->{'.req'} || Apache->request;
    $r->read_client_block($$buff, $len);	
}

sub binmode { undef }

sub new_MultipartBuffer {
    my $self = shift;
    my $new = MultipartBuffer::new((bless $self => 'Apache::MultipartBuffer'), @_); 
    $new->{'.req'} = $self->{'.req'};
    return $new;
}

sub AUTOLOAD {
    my($method) = (split('::',$AUTOLOAD))[-1];
    &{"CGI::$method"}(@_);
}

package Apache::MultipartBuffer;
@ISA = qw(MultipartBuffer Apache::CGI);

sub wouldBlock { undef }
#err, CGI.pm's AUTOLOAD is really busted
*Apache::MultipartBuffer::read_from_client = \&Apache::CGI::read_from_client;
*Apache::MultipartBuffer::eof = \&MultipartBuffer::eof;

sub AUTOLOAD {
    my($method) = (split('::',$AUTOLOAD))[-1];
    &{"MultipartBuffer\:\:$method"}(@_);
}

1;

__END__

=head1 NAME

Apache::CGI - Make things work with CGI.pm against Perl-Apache API

=head1 SYNOPSIS

 
 require Apache;
 require Apache::CGI;

 my $r = Apache->request;
 my $q = new Apache::CGI $r;

 $r->print($q->header);

 #do things just like you do with CGI.pm

=head1 DESCRIPTION

**NOTE**
If you are using a version of CGI.pm such as 2.19, comment out the SelfLoader stuff.
Once CGI.pm-2.22 is released we'll be in much better shape...
********

When using the Perl-Apache API, your applications are faster, but the
enviroment is different than CGI.
This module attempts to set-up that environment as best it can.

=head1 SEE ALSO

perl(1), Apache(3), CGI(3)

=cut
