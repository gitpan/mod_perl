#these three are passed to perl_parse(), 
#which happens before <Perl> sections are processed
#optionally, they can be inside <Perl>, however for testing we want
#warnings and taint checks on while processing <Perl>
#besides that, we rely on the PerlScript below to set @INC to our blib

PerlScript docs/startup.pl
#-Tw
PerlTaintCheck On
PerlWarn On

PerlSetVar KeyForPerlSetVar OK

<Perl>
#!perl
#line 16 httpd.conf

use IO::Handle ();
use Cwd qw(fastcwd);
my $dir = join "/", fastcwd, "t";
my $Is_Win32 = ($^O eq "MSWin32");

sub prompt ($;$) {
    my($mess,$def) = @_;
    print "$mess [$def]";
    STDIN->untaint;
    chomp(my $ans = <STDIN>);
    $ans || $def;
}

$ServerRoot = $dir;

$User  = $Is_Win32 ? "nobody" : (getpwuid($>) || $>);
$Group = $Is_Win32 ? "nogroup" : (getgrgid($)) || $)); 

if($User eq "root") {
    my $other = (getpwnam('nobody'))[0];
    $User = $other if $other;
} 
if($User eq "root") {
    print "Cannot run tests as User `$User'\n";
    $User  = prompt "Which User?", "nobody";
    $Group = prompt "Which Group?", $Group; 
}
print "Will run tests as User: '$User' Group: '$Group'\n";

$Port = 8529;
$ServerName = "localhost";
$DocumentRoot = "$dir/docs";

push @AddType, ["text/x-server-parsed-html" => ".shtml"];

for (qw(/perl/ /cgi-bin/)) {
    push @Alias, [$_ => "$dir/net/perl/"];
}

my @mod_perl = (
    SetHandler  => "perl-script",
    PerlHandler => "Apache::Registry",
    Options     => "ExecCGI",
);

$Location{"/perl"} = { 
    @mod_perl,
    PerlSetEnv => [KeyForPerlSetEnv => "OK"],
#    PerlSetVar => [KeyForPerlSetVar => "OK"],
};

$Location{"/cgi-bin"} = {
    SetHandler => "cgi-script",
    Options    => "ExecCGI",
};

$Location{"/perl/io"} = {
    @mod_perl,
    PerlSendHeader => "On",
    PerlSetupEnv   => "On",
};

$Location{"/perl/perl-status"} = {
    SetHandler  => "perl-script",
    PerlHandler => "Apache::Status",
};

for (qw(status info)) {
    $Location{"/server-$_"} = {
	SetHandler => "server-$_",
    };
}

$ErrorLog = "/tmp/mod_perl_error_log";
$PidFile  = "/tmp/mod_perl_httpd.pid";
$ResourceConfig = "/tmp/mod_perl_srm.conf";

$AccessConfig = $TypesConfig = $TransferLog = $ScoreBoardFile = "/dev/null";

$LockFile = "/tmp/mod_perl.lock";

#push @PerlChildInitHandler, "My::child_init";
#push @PerlChildExitHandler, "My::child_exit";

</Perl>
