#!/user/local/bin/perl
use strict;
use CGI::Switch ();
my $q = new CGI::Switch;

$q->print(
   $q->header,	
   $q->start_html(),	  
   "Can you tell if I've been run under CGI or Apache::Registry?<p>",
   $q->start_form(),
   $q->textfield(-name => "textfield"),
   $q->submit(-value => "Submit"),
   $q->end_form,
   "<p>textfield = ", $q->param("textfield"),
   $q->dump,
   "<hr><pre>",
   (map { "$_ = $ENV{$_}\n" } keys %ENV),	  
   "</pre>",	  
   $q->end_html,
);


