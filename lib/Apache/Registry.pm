package Apache::Registry;
use Apache ();
use Apache::Debug ();
use Apache::Constants qw(:common &OPT_EXECCGI);
use FileHandle ();

use vars qw($VERSION);
#$Id: Registry.pm,v 1.18 1996/12/05 02:47:50 dougm Exp $
$VERSION = sprintf("%d.%02d", q$Revision: 1.18 $ =~ /(\d+)\.(\d+)/);

$Apache::Registry::Debug ||= 0;
# 1 => log recompile in errorlog
# 2 => Apache::Debug::dump in case of $@
# 4 => trace pedantically

sub handler {
    my($r) = @_; #Apache->request;
    my $filename = $r->filename;

    if (-r $filename && -s _) {
	if (!($r->allow_options & OPT_EXECCGI) && (!$r->is_perlaliased)) {
	    $r->log_reason("Options ExecCGI is off in this directory", 
			   $filename);
	    return FORBIDDEN;
	}
	if (-d _) {
	    $r->log_reason("attempt to invoke directory as script", $filename);
	    return FORBIDDEN;
	}
	unless (-x _) {
	    $r->log_reason("file permissions deny server execution", 
			   $filename);
	    return FORBIDDEN;
	}

	my $mtime = -M _;

	# turn into a package name
	$r->log_error("Apache::Registry::handler checking out script_name")
	    if $Debug & 4;
	my $script_name = 
	    substr($r->uri, 0, length($r->uri)-length($r->path_info));

	# Escape everything into valid perl identifiers
	$script_name =~ s/([^A-Za-z0-9\/])/sprintf("_%2x",unpack("C",$1))/eg;
	# second pass only for words starting with a digit
	$script_name =~ s|/(\d)|sprintf("/_%2x",unpack("C",$1))|eg;

	# Dress it up as a real package name
	$script_name =~ s|/|::|g;
	my $package = "Apache::ROOT$script_name";
       $r->log_error("Apache::Registry::handler determined package as $package") 
	   if $Debug & 4;

	if (
	    defined $Apache::Registry->{$package}{mtime}
	    &&
	    $Apache::Registry->{$package}{mtime} <= $mtime
	   ){
	    # we have compiled this subroutine already, nothing left to do
	} else {
           $r->log_error("Apache::Registry::handler reading $filename")
	       if $Debug & 4;
	    my $fh = new FileHandle $filename;
	    local($/);
	    undef $/;
	    my $sub = <$fh>;
	    $fh->close;
	    undef $fh;
	    # compile this subroutine into the uniq package name
            $r->log_error("Apache::Registry::handler eval-ing") if $Debug & 4;
            my $eval = qq{package $package; sub handler { $sub; }};
            {
                # hide our variables within this block
                my($r,$filename,$script_name,$mtime,$package,$sub);
                eval $eval;
            }
	    if ($@) {
		$r->log_error($@);
		return SERVER_ERROR unless $Debug & 2;
		return Apache::Debug::dump($r, SERVER_ERROR);
	    }
            $r->log_error(qq{Compiled package \"$package\" for process $$})
	       if $Debug & 1;
	    $Apache::Registry->{$package}{mtime} = $mtime;
	}

	eval {$package->handler;};
	if ($@) {
	    $r->log_error($@);
	    return SERVER_ERROR unless $Debug & 2;
	    return Apache::Debug::dump($r, SERVER_ERROR);
	}
	return $r->status;
    } else {
	return NOT_FOUND unless $Debug & 2;
	return Apache::Debug::dump($r, NOT_FOUND);
    }
}

my(%status) = (
   inc => "Loaded Modules",
   rgysubs => "Compiled Registry Scripts",
   symdump => "Symbol Table Dump",
);

sub status {
    my($r) = @_;
    require Apache::CGI;
    my $q = new Apache::CGI;
    my $qs = $r->args;
    my $sub = "status_$qs";
    no strict 'subs';
    $r->write_client($q->header, $q->start_html, $q->start_form);
    if(defined &$sub) {
	$r->write_client(@{ &{$sub}($r,$q) });
    }
    elsif (exists $Apache::Registry->{$qs}) { 
	$r->write_client(symdump($qs));
    }
    else {
	my $uri = $r->uri;
	my $start = scalar localtime($^T);
	$r->write_client(
            "Perl Status for process <b>$$</b>, running since $start",	 
 	    "<h3>Menu</h3>\n",
 	    map { qq[<a href="$uri?$_">$status{$_}</a><br>\n] } keys %status
        );
    }

    1;
}

sub symdump {
    my($package) = @_;
    require Devel::Symdump;
    my $sob = Devel::Symdump->rnew($package);

    my($type, @syms, @retval);
    push @retval, "<h2>Symbol table dump of package '$package'</h2>\n<pre>";
    for $type ( qw{
	       packages
	       scalars arrays hashes
	       functions filehandles dirhandles 
	     })
    {
	push @retval, "<hr><h3>$type:</h3>", join("\n", $sob->$type())
    }
    join '', @retval, "</pre>";
}

sub status_symdump { [symdump('main')] }

sub status_inc {
    my($r,$q) = @_;
    my(@retval, $module);
    local $_;
    foreach $module ($q->param("INC")) {
	delete $INC{$module};
    }
    $q->delete("INC");
    foreach (sort keys %INC) {
	push @retval, $q->checkbox(-name => "INC", -value => $_, -label => $_), "<br>";
    }
    push @retval, $q->submit(-value => "Delete");
    \@retval;
}

sub status_rgysubs {
    my($r,$q) = @_;
    my(@retval);
    local $_;
    my $uri = $r->uri;
    foreach (sort keys %{$Apache::Registry}) {
	push @retval, 
	$q->checkbox(-name => "RGY", 
		     -label => qq(<a href="$uri?$_">$_</a>)), 
	"<br>";
    }
    \@retval;
}

1;

__END__

=head1 NAME

Apache::Registry - Run (mostly) unaltered CGI scripts through mod_perl

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

