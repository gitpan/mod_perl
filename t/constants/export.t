# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)
BEGIN {
    use Config;
    if($Config{dlsrc} eq "dl_none.xs" 
       or
       not -e "Constants/Constants.xs"
       ) {
	print "1..1\nok 1\n";
	print "dynamic Apache::Constants not built, skipping tests\n";
	exit;
    }
}

use Apache::Constants;

$version = SERVER_VERSION; 

if($version =~ /1\.1\.\d/) {
    print "1..1\nok 1\n";
    print "skipping tests against $version\n";
    exit(0);
}

my(%SEEN);
while(($key,$val) = each %Apache::Constants::EXPORT_TAGS) {
    print "importing tag $key\n";
    Apache::Constants->import(":$key");
    push @export, grep {!$SEEN{$_}++} @$val;
}

push @export, grep {!$SEEN{$_}++} @Apache::Constants::EXPORT;

$tests = (1 + @export); 
print "1..$tests\n"; 
#$loaded = 1;
print "ok 1\n";
$ix = 2;

my($sym);

for $sym (sort @export) {
    my $val = &$sym;
    print defined $val ? "" : "not ", "ok $ix ($sym: $val)\n";
    $ix++;
}

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

