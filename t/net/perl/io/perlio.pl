#!/user/local/bin/perl

#we're in Apache::Registry
#our perl is configured use sfio so we can 
#print() to STDOUT
#and
#read() from STDIN

#we've also set (per-directory config):
#PerlSendHeader On
#PerlSetupEnv   On

print "Content-type: text/html\n\n";
print "perlio test...\n";

my(@args);

if (@args = split(/\+/, $ENV{QUERY_STRING})) {
    print "ARGS: ",
    join(", ", map { $_ = qq{"$_"} } @args), "\n\n";
} else {
    print "No command line arguments passed to script\n\n";
}

my($key,$val);
while (($key,$val) = each %ENV) {
   print "$key=$val\n";
}


if ($ENV{CONTENT_LENGTH}) {
    $len = $ENV{CONTENT_LENGTH};
    read(STDIN, $content, $len);
    print "\nContent\n-------\n$content";
}
