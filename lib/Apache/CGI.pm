package Apache::CGI;
use CGI::Apache ();
@ISA = qw(CGI::Apache);

warn "Do not use Apache::CGI!  use CGI::Switch instead!\n";

1;

__END__
