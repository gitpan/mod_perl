use ExtUtils::MakeMaker;
use Config;
use FileHandle ();

$VERSION = "0.85_04";

print "WARNING: \$r->read is no longer an alias for \$r->read_client_block\n",
      "          see perldoc Apache for more information\n";
 
# Patch up the Makefiles we are going to use with Apache
system $^X, "-pi", "-e", "s!^PERL\\s*=.*!PERL=$Config{'perlpath'}!",
            <src/Makefile.tmpl*>, "src/modules/perl/Makefile";

# Automatic setup support
my(@adirs, %seen, %mft_map, %vers_map, $src_dir, $vers, $conf, $ans);
%vers_map = (
   '1.1.1' => "Makefile.tmpl",
   '1.2'   => "Makefile.tmpl-1.2",
   '1.1.1Ben-SSL' => "Makefile.tmpl-Ben-SSL",
);	     

foreach $src_dir (qw(../apache_1.1.1/src), <../apache_1.2*/src>,
		  <../apache*/src>, <../stronghold*/src>, <../src>, <src>) 
{
    next if $seen{$src_dir}++;
    next unless $vers = httpd_version($src_dir);
    unless($mft_map{$src_dir} = $vers_map{$vers}) {
	print STDERR "Apache version '$vers' unsupported\n";
	next;
    }
    print STDERR "$src_dir -> $vers_map{$vers}\n";
    push @adirs, $src_dir;
}

unless (@adirs) {
    print "Enter 'q' to stop search\n";
    while(1) {
	$src_dir = prompt "Please tell me where I can find your apache src", 
	                  "../apache_x.x/src";
	last if $src_dir eq "q";
	if(-d $src_dir) {
	    push(@adirs, $src_dir);
	    $mft_map{$src_dir} = $vers_map{httpd_version($src_dir)};
	    last;
	}
	else {
	    print "Can't stat $src_dir\n";
	}
    }
}

foreach $adir (@adirs) {
    $conf = "$adir/Configuration";
    if (-e $conf) {
	$ans = prompt "Configure mod_perl with $adir ?", "y";
	next unless $ans eq "y";
	system "cp", "$adir/Makefile.tmpl", "$adir/Makefile.tmpl.bak";
	system "cp", "src/$mft_map{$adir}", "$adir/Makefile.tmpl";
	print STDERR "cp src/$mft_map{$adir} $adir/Makefile.tmpl\n";
	$APACHE_SRC = $adir;
	
	mkdir "$adir/modules", 0755;
	mkdir "$adir/modules/perl", 0755;
	#ignore make's output here
	`(cd $adir/modules/perl; make clean > /dev/null)`;

	local(*MANI);
	open *MANI => "MANIFEST" or die "open MANIFEST $!";
	$adir =~ s,/src$,,;
	#only rm and cp files mod_perl ships with
	while(<MANI>) {
	    next unless m,^src/modules/perl/,; chomp;
	    #print "rm -f $adir/$_\n";
	    system "rm", "-f", "$adir/$_";
	    #print "cp $_ $adir/$_\n";
	    system "cp", $_, "$adir/$_";
	}
	close MANI;
	$adir .= "/src";
	
	open(CONF, $conf) || die "Can't open $conf: $!";
	while (<CONF>) {
	    $seen_modperl++ if /^Module\s+perl_module/i;
	}
	close(CONF);
	unless ($seen_modperl) {
	    print "Appending mod_perl to $conf\n";
	    open(CONF, ">>$conf") || die "Can't open $conf: $!";
	    print CONF <<EOT;

# Embed a perl interpreter
Module perl_module         modules/perl/libmodperl.a


EOT
            close(CONF);
       } else {
	   print "mod_perl already present in $conf\n";
       }
	system "(cd $adir; ./Configure)";
    }    		

    last if $APACHE_SRC;
}

WriteMakefile(
    NAME    => "mod_perl",
    VERSION => $VERSION,
    macro   => {
        APACHE_SRC => $APACHE_SRC,
	ARCHNAME => $Config{archname},
	PERL_VERSION => $]+0,
    },
    dist    => {
	COMPRESS=> 'gzip -9f', SUFFIX=>'gz', 
	DIST_DEFAULT => 'all tardist',
	POSTOP => 'mv $(DISTNAME)-*.tar.gz ../'
	},
    clean   => {
	FILES	=> "Apache.c *.o *~"
    }
);

sub MY::clean {
    my $self = shift;
    my $string = $self->MM::clean;
    return $string unless $APACHE_SRC;
    $string .= "\t-cd \$(APACHE_SRC) && \$(MAKE) clean\n";
    $string;
}

sub MY::top_targets {
    my $self = shift;
    my $string = $self->MM::top_targets;
    return $string unless $APACHE_SRC;
    $string =~ s/(pure_all\s+::\s+)(.*)/$1 apache_httpd $2/;
    $string .= <<'EOF';

apache_httpd: $(APACHE_SRC)/Configuration	
	(cd $(APACHE_SRC); $(MAKE);)

tar_Apache:
	(cd $(INSTALLSITELIB); \
	     $(TAR) -cf Apache.tar CGI/Switch.pm CGI/XA.pm Apache/ $(ARCHNAME)/auto/Apache; )
	$(MV) $(INSTALLSITELIB)/Apache.tar .

EOF

    $string;
}

sub MY::pasthru {
    return unless $APACHE_SRC;
    my $self = shift;
    chomp(my $str = $self->MM::pasthru);
    join $/, "$str\\", "\t".'APACHE_SRC="$(APACHE_SRC)"', "";   
}

sub MY::test {
    q(
TEST_VERBOSE=0

test:
	$(FULLPERL) t/TEST $(TEST_VERBOSE)

);
}

sub httpd_version {
    my($dir) = @_;
    my $fh = new FileHandle "$dir/httpd.h" or return;
    my($server, $version, $rest);
    my($fserver, $fversion, $frest);
    my($string, $extra, @vers);
    while(<$fh>) {
	next unless s/^#define\s+SERVER_VERSION\s+"(.*)\s*".*/$1/;
	chomp($string = $_);

	#print STDERR "Examining SERVER_VERSION '$string'...";
	#could be something like:
	#Stronghold-1.4b1-dev Ben-SSL/1.3 Apache/1.1.1 
	@vers = split /\s+/, $string;
	foreach (@vers) {
	    ($fserver,$fversion,$frest) =  
		m,^([^/]+)/(\d\.\d+\.?\d*)(.*),i;
	    if($fserver eq "Ben-SSL") {
		$extra = $fserver;
		print STDERR "I see $fserver/$fversion, ok\n";
		next;
	    }
	    #last if $server eq "Apache";
	}

	if($fserver eq "Apache") {
	    ($server, $version) = ($fserver, $fversion);
	}
	else {
	    #print STDERR "unrecognized.\n";
	    next;
	}

	if("$version$rest" eq "1.2-dev") {
	    print STDERR "Apache/1.2-dev not supported, upgrade to 1.2bX\n";
	    next;
	}

	print STDERR "Found $fserver '$fversion' in $dir/httpd.h\n";
    }
    $fh->close;
    #print STDERR "return $version$extra\n";
    return($version.$extra);
}

