use ExtUtils::MakeMaker;
use Config;
use FileHandle ();

$VERSION = "0.85_03";

print "WARNING: \$r->read is no longer an alias for \$r->read_client_block\n",
      "          see perldoc Apache for more information\n";
 
# Patch up the Makefiles we are going to use with Apache
system $^X, "-pi", "-e", "s!^PERL\\s*=.*!PERL=$Config{'perlpath'}!",
            <src/Makefile.tmpl*>, "src/modules/perl/Makefile";

# Automatic setup support
my(@adirs, %seen, %mft_map, %vers_map, $src_dir, $vers, $conf, $ans);
@vers_map{'1.1.1', '1.2'} = qw(Makefile.tmpl Makefile.tmpl-1.2);

foreach $src_dir (qw(../apache_1.1.1/src), <../apache_1.2*/src>,
		  <../apache_*/src>, <../stronghold*/src>, <../src>, <src>) 
{
    next if $seen{$src_dir}++;
    next unless $vers = httpd_version($src_dir);
    unless($mft_map{$src_dir} = $vers_map{$vers}) {
	print STDERR "Apache version '$vers' unsupported\n";
	next;
    }
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
	$APACHE_SRC = $adir;
	
	mkdir "$adir/modules", 0755;
	print "rm -rf $adir/modules/perl\n";
	system "rm", "-rf", "$adir/modules/perl";
	print "cp -r src/modules/perl $adir/modules\n";
	system "cp", "-r", "src/modules/perl", "$adir/modules";
	
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
    my($server, $version, $rest, $string);
    while(<$fh>) {
	next unless s/^#define\s+SERVER_VERSION\s+"(.*)\s*".*/$1/;
	chomp($string = $_);

	#print STDERR "Examining SERVER_VERSION '$string'...";
	#could be something like:
	#Stronghold-1.4b1-dev Ben-SSL/1.3 Apache/1.1.1 
	foreach (split /\s+/, $string) {
	    ($server,$version,$rest) =  
		m,^([^/]+)/(\d\.\d+\.?\d*)(.*),i;
	    last if lc($server) eq "apache";
	}

	if(lc $server eq "apache") {
	    #print STDERR "ok\n";
	}
	else {
	    #print STDERR "unrecognized.\n";
	    next;
	}

	if("$version$rest" eq "1.2-dev") {
	    print STDERR "Apache/1.2-dev not supported, upgrade to 1.2bX\n";
	    next;
	}

	print STDERR "Found $server '$version' in $dir/httpd.h\n";
	last;
    }
    $fh->close;
    return($version);
}
