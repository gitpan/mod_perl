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

print "<b>Date: ", scalar localtime, "</b><br>\n";

print "%ENV: <br>\n", map { "$_ = $ENV{$_} <br>\n" } keys %ENV;


