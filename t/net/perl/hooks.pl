use Apache ();
my $tests = 0;
use Cwd;
my $pwd = cwd;
Apache->untaint($pwd);
my $ht_access  = "$pwd/t/docs/.htaccess";
my $hooks_file = "$pwd/t/docs/hooks.txt";

unlink $ht_access;
unlink $hooks_file;

local *FH;
if(Apache::perl_hook("Authen")) {
    open FH, ">$ht_access";
    print FH <<EOF;
AuthType Basic
AuthName mod_perl tests

<Limit GET>
require valid-user
</Limit>

EOF
    close FH;
}

my $r = Apache->request;
$r->content_type("text/html");
$r->send_http_header;
my($hook, $package, $retval);

for (qw(Access Authen Authz Fixup HeaderParser Log Type Trans)) {
    next unless Apache::perl_hook($_);
    $tests++; 
    $retval = -1; #we want to decline Trans, but ok for Authen, etc.
    $hook = "Perl${_}Handler";
    $package = "Apache::$hook";
    unless ($_ eq "Trans") { #must be in server configs
	$retval = 0;
	open FH, ">>$ht_access" or warn "can't open $ht_access" and next;
	print FH "$hook $package\:\:handler\n";
	close FH;
    }

    undef &{"$package\:\:handler"}; #avoid warnings
    eval <<"PACKAGE";
package $package;

sub $package\:\:handler {
    my(\$r) = \@_;
    return -1 unless \$r->is_main;
    open FH, ">>$hooks_file" or die "can't open $hooks_file";
    \$r->log_error("$hook ok\n");
    print FH "$hook ok\n";
    close FH;
    return $retval;
}	

PACKAGE

    $r->print($@) if $@;
}

$r->print($tests);



