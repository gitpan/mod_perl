#!/usr/local/bin/perl

require CGI::Switch;
use File::CounterFile;

my $q = new CGI::Switch;

$q->print(
   $q->header,	
   $q->start_html(),	  
   "Can you tell if I've been run under CGI or Apache::Registry?<p>",
   $q->start_form(),
   $q->textfield(-name => "textfield"),
   $q->submit(),
   $q->end_form,
   "<p>textfield = ", $q->param("textfield"),
		"<PRE>",
	  "Running in Process <B>$$</B>\n",

);

my $c = File::CounterFile->new("COUNTER2","00000000");
my $id = $c->inc;

$q->print(
	  "<H4>", scalar(localtime()),"</H4>",
	  sprintf("Accessed %d times",$id),
	  $q->end_html,
	 );
