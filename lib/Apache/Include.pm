package Apache::Include;
use Apache::Constants ':common';
use Apache::Registry ();

$VERSION = "1.00";

sub handler {
    my($r, $uri) = @_;
    %ENV = $r->cgi_env;
    my($ouri,$fname) = ($r->uri, $r->filename);
    $r->uri($uri);
    $r->translate_name; 
    Apache::Registry::handler($r);
    $r->uri($ouri); $r->filename($fname); #reset
    OK;
}

1;

__END__

=head1 NAME

Apache::Include - Utilities for mod_perl/mod_include integration

=head1 SYNOPSIS

 <!--#perl sub="Apache::Include" arg="/perl/ssi.pl" -->


=head1 DESCRIPTION

The B<Apache::Include> module provides a handler, making it simple to
include Apache::Registry scripts with the mod_include perl directive.

Apache::Registry scripts can also be used in mod_include parsed
documents using 'virtual include', however, Apache::Include is faster.

=head1 SEE ALSO

perl(1), mod_perl(3), mod_include

=head1 AUTHOR

Doug MacEachern <dougm@osf.org>


