#Configuration directives specific to mod_perl
ServerRoot ./t
ServerName localhost
DocumentRoot /afs/ri/project/web/src/servers/mod_perl-0.95_03/t/docs

#mod_perl stuff
PerlScript ./t/docs/startup.pl

PerlTaintCheck On

Alias /perl/ ./t/net/perl/
Port  8529

<Perl>

$User  = getpwuid($>) || $>;
$Group = getgrgid($)) || $); 

$ServerAdmin = $User;

my(%handlers) = (
   "/perl"    => "",
   "/perl/io" => "",
   "/perl/perl-status" => "Apache::Status",
);

for (keys %handlers) {
    $Location{$_} = {
	PerlHandler => $handlers{$_} || "Apache::Registry",
	SetHandler  => "perl-script",
	Options     => "ExecCGI",
    };
}

$Location{"/perl/io"}->{PerlSendHeader} = "On";

for (qw(status info)) {
    $Location{"/server-$_"} = {
	SetHandler => "server-$_",
    };
}

@PerlModule = qw(Config Net::Ping);

$Location{"/~dougm/"} = {
    AuthUserFile => '/tmp/htpasswd',
    AuthType => 'Basic',
    AuthName => 'test',
    Limit => {
	METHODS => 'GET POST',
	require => 'user dougm',
    },
};

</Perl>

ErrorLog /tmp/mod_perl_error_log
PidFile  /tmp/mod_perl_httpd.pid
AccessConfig /dev/null
ResourceConfig /tmp/mod_perl_srm.conf
TypesConfig /dev/null
TransferLog /dev/null
ScoreBoardFile /dev/null

