package Apache::CGI;
require CGI;

@ISA = qw(CGI);

sub new {
    my($class, $r) = @_;

    my $cgi = bless {
	'.req' => $r,
    }, $class;

    my($content,$meth);
    my $dispatch = {
	POST => 'content',
	GET  => 'args',
    };

    if ($meth = $dispatch->{$r->method}) {
	$content = $r->$meth();
	$cgi->parse_params($content);
    }

    %ENV = $r->cgi_env; #set-up for CGI.pm

    return $cgi;
}

sub header {
    my $self = shift;
    my $r = $self->{'.req'};
    return(
       $r->protocol,
       " ",
       $r->status_line || "200 OK",
       $CGI::CRLF,
       $self->SUPER::header(@_),
    );
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

 #do things just like you do with CGI.pm

=head1 DESCRIPTION

When using the Perl-Apache API, your application are faster, but the
enviroment is different than CGI.
This module attempt to set-up that environment as best it can.

=head1 SEE ALSO

perl(1), Apache(3), CGI(3)

=cut
