package Apache::CGI;
use CGI::Apache ();
@ISA = qw(CGI::Apache);

warn "Do not use Apache::CGI!  use CGI::Switch instead!\n";

package CGI::Apache;

1;

__END__
