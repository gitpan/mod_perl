#!/user/local/bin/perl

#**** NOTE: Lincoln has made adjustments for us in CGI.pm-2.22a5
# Once he makes a final release things will look something like so....

my $q;
if($ENV{GATEWAY_INTERFACE}) { #not setup until new Apache::CGI; 
    require CGI;
    $q = new CGI;
}
else {
    require Apache::CGI;
    $q = new Apache::CGI;
}

$q->print(
   $q->header,	
   "Can you tell if I've been run under CGI or Apache::Registry?",
);


