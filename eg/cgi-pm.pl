require Apache::CGI;

#does the same as tryit.cgi from the CGI.pm distribution

sub response {
    my $query = new Apache::CGI $r;

    $query->print(
	$query->header,
        $query->start_html,
    );

    $query->print(<<END);
<TITLE>A Simple Example</TITLE>
<A NAME="top">
<H1>A Simple Example</H1>
</A>
END

    $query->print( 
	$query->startform,
	"What's your name? ", $query->textfield('name'),
        "<P>What's the combination?<P>",
        $query->checkbox_group(-name=>'words',
			       -values=>['eenie','meenie','minie','moe']),

	"<P>What's your favorite color? ",
        $query->popup_menu(-name=>'color',
			   -values=>['red','green','blue','chartreuse']),
	"<P>",

        $query->submit,
        $query->endform,

        "<HR>\n",
     );

    if ($query->param) {
	$query->print(
            "Your name is <EM>",$query->param(name),"</EM>\n",
            "<P>The keywords are: <EM>",join(", ",$query->param(words)),"</EM>\n",
            "<P>Your favorite color is <EM>",$query->param(color),"</EM>\n",
	);
    }

    $query->print($query->end_html, $query->dump);

    return 200;
}

1;
