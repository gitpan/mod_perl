package Apache::Registry;
require Apache;
require Apache::Debug;
use Apache::Options qw(&OPT_EXECCGI);
require FileHandle;

use vars qw($VERSION);
#$Id: Registry.pm,v 1.12 1996/07/26 19:11:08 dougm Exp $
$VERSION = sprintf("%d.%02d", q$Revision: 1.12 $ =~ /(\d+)\.(\d+)/);

#should really just use for developing.
$Apache::Registry::Debug ||= 0;

sub handler {
    my $r = Apache->request;
    my $filename = $r->filename;

    if (-r $filename && -s _) {
	if (!($r->allow_options & OPT_EXECCGI) && (!$r->is_perlaliased)) {
	    $r->log_reason("Options ExecCGI is off in this directory", 
			   $filename);
	    return 403; #FORBIDDEN;
	}
	if (-d _) {
	    $r->log_reason("attempt to invoke directory as script", $filename);
	    return 403; #FORBIDDEN;
	}
	unless (-x _) {
	    $r->log_reason("file permissions deny server execution", 
			   $filename);
	    return 403; #FORBIDDEN;
	}

	my $mtime = -M _;

	# turn into a package name
	my $uri = $r->uri;

	# Escape everything into valid perl identifiers
	$uri =~ s/([^A-Za-z0-9\/])/sprintf("_%2x",unpack("C",$1))/eg;

	# Dress it up as a real package name
	$uri =~ s|/|::|g;
	my $package = "Apache::ROOT$uri";

	my $eval;
	if (
	    defined $Apache::Registry->{$package}{mtime}
	    &&
	    $Apache::Registry->{$package}{mtime} <= $mtime
	   ){
	    # we have compiled this subroutine already, nothing left to do
	} else {
	    my $fh = new FileHandle $filename;
	    local($/);
	    undef $/;
	    my $sub = <$fh>;
	    $fh->close;

	    # compile this subroutine into the uniq package name
	    $eval = qq{package $package;\n};
	    $eval .= qq{sub handler {
		$sub;
		return 0;
	    }\n1;\n};
	    eval $eval;
	    if ($@) {
		$r->log_error($@);
		return 500 unless $Debug;
		return Apache::Debug::dump($r, 500);
	    }
	    $Apache::Registry->{$package}{mtime} = $mtime;
	}

	eval {$package->handler;};
	if ($@) {
	    $r->log_error($@);
	    return 500 unless $Debug;
	    return Apache::Debug::dump($r, 500);
	}
	return 200;
    } else {
	return 404 unless $Debug;
	return Apache::Debug::dump($r, 404);
    }
}

1;

__END__

=head1 NAME

Apache::Registry - Run (mostly) unaltered CGI scripts through mod_perl_fast

=head1 SYNOPSIS

 #in srm.conf

 PerlAlias /perl/ /perl/apache/scripts/ #optional
 PerlModule Apache::Registry 
 
 AddHandler perl-script .fpl
 
 #in access.conf
 <Directory /perl/apache/scripts>
 PerlHandler Apache::Regsistry::handler
 ...
 </Directory>


=head1 DESCRIPTION

URIs in the form of:
 http://www.host.com/perl/file.fpl

Will be compiled as the body of a perl subroutine and executed.
Each server process or 'child' will compile the subroutine once 
and store it in memory until the file is updated on the disk.

The file looks much like a "normal" script, but it is compiled or 'evaled'
into a subroutine.

Here's an example:

 my $r = Apache->request;
 $r->content_type("text/html");
 $r->send_http_header;
 $r->print("Hi There!");

Apache::Registry::handler will preform the same checks as mod_cgi
before running the script.

=head1 SEE ALSO

perl(1), Apache(3)

=head1 AUTHORS

Andreas Koenig <andreas.koenig@franz.ww.tu-berlin.de> and 
Doug MacEachern <dougm@osf.org>
