package CGI::XA;

use strict;
use vars qw($SL $CRLF $VERSION $Revision);

$VERSION = '0.22305-alpha';

# Preloaded methods go here.

package CGI::XA::TempFile;
# predeclaration to calm down strict

package CGI::XA;
require 5.003;
use FileHandle ();

# Copyright 1995,1996, Lincoln D. Stein.  All rights reserved.
# It may be used and modified freely, but I do request that this copyright
# notice remain attached to the file.  You may modify this module as you
# wish, but if you redistribute a modified version, please attach a note
# listing the modifications you have made.

# Copyright 1996, Andreas K"onig My changes are described in the man
# page. It's rather rudimentary as I don't know what the future of
# this package will be. If Lincoln integrates the changes, I'll drop
# it.

$Revision = q$Id: XA.pm,v 1.10 1996/09/05 21:54:07 dougm Exp $;

# The path separator is a slash, backslash or semicolon, depending
# on the paltform.
$SL = '/';

# This is really "\r\n", but the meaning of \n is different
# in MacPerl, so we resort to octal here.
$CRLF = "\015\012";

# Why, oh why ? Just to make it harder to read?
# use overload '""' => 'as_string';

#### Method: new
# The new routine.  This will check the current environment
# for an existing query string, and initialize itself, if so.
####
sub new {
    my($class,$initializer) = @_;
    my $self = {};
    bless $self, ref $class || $class;
    $initializer = to_filehandle($initializer) if $initializer;
    $self->initialize_it($initializer);
    return $self;
}

#### Method: param

# Returns the value(s) of a named parameter.  If invoked in a list
# context, returns the entire list.  Otherwise returns the first
# member of the list.

# If name is not provided, return a list of all the known parameters
# names available.  If more than one argument is provided, the second
# and subsequent arguments are used to set the value of the parameter.
####
sub param {
    my($self,@p) = @_;
    return $self->all_parameters unless @p;
    my($name,$value,@other);

    # For compatability between old calling style and use_named_parameters() style,
    # we have to special case for a single parameter present.
    if (@p > 1) {
	($name,$value,@other) = $self->rearrange(['NAME',['DEFAULT','VALUE','VALUES']],@p);
	my(@values);

	if (substr($p[0],0,1) eq '-' || $self->use_named_parameters) {
	    @values = defined($value) ? (ref($value) eq 'ARRAY' ? @{$value} : $value) : ();
	} else {
	    foreach ($value,@other) {
		push(@values,$_) if defined($_);
	    }
	}
	# If values is provided, then we set it.
	if (@values) {
	    $self->add_parameter($name);
	    $self->{$name}=[@values];
	}
    } else {
	$name = $p[0];
    }

    return () unless $name && $self->{$name};
    return wantarray ? @{$self->{$name}} : $self->{$name}->[0];
}
##param                  name value other
# #                          ['NAME',['DEFAULT','VALUE','VALUES']]
#sub param {
#    my($self,@p,%p) = @_;
#    if (@p && (substr($p[0],0,1) eq '-' || $self->use_named_parameters)) {
#	 my($k,$v,$lck);
#	 %p = @p;
#	 foreach $k (keys %p) {
#	     $lck = lc $k;
#	     $lck = substr($k,1) if substr($k,0,1) eq "-";
#	     $p{$lck} = $p{$k} if $lck ne $k;;
#	 }
#	 $p{default} ||= $p{value};
#	 $p{default} ||= $p{values};
#     } else {
#	 @p{qw/ name value other/} = @p;
#    }
#    my(@values);
#	 if (substr($p[0],0,1) eq '-' || $self->use_named_parameters) {
#	     @values = defined($p{value}) ? (ref($p{value}) eq 'ARRAY' ? @{$p{value}} : $p{value}) : ();
#	 } else {
#	     foreach ($p{value},@other) {
#		 push(@values,$_) if defined($_);
#	     }
#	 }
#	 
#	 if (@values) {
#	     $self->add_parameter($p{name});
#	     $self->{$p{name}}=[@values];
#	 }
#    } else {
#	 $p{name} = $p[0];
#    }
#    return () unless $p{name} && $self->{$p{name}};
#    return wantarray ? @{$self->{$p{name}}} : $self->{$p{name}}->[0];
#}

#### Method: delete
# Deletes the named parameter entirely.
####
sub delete {
    my($self,$name) = @_;
    delete $self->{$name};
    @{$self->{'.parameters'}}=grep($_ ne $name,$self->param());
    return wantarray ? () : undef;
}

sub isaCGI {
    return 1;
}

#### Method: use_named_parameters
# Force CGI.pm to use named parameter-style method calls
# rather than positional parameters.  The same effect
# will happen automatically if the first parameter
# begins with a -.
sub use_named_parameters {
#    warn "use_named_parameters: @_ from ",join(" ",caller());
    my($self,$use_named) = @_;
    return $self->{'.named'} unless defined ($use_named);

    # stupidity to avoid annoying warnings
    return $self->{'.named'} = $use_named;
}

# Initialize the query object from the environment.
# If a parameter list is found, this object will be set
# to an associative array in which parameter names are keys
# and the values are stored as lists
# If a keyword list is found, this method creates a bogus
# parameter list with the single parameter 'keywords'.

sub initialize_it {
    my($self,$initializer) = @_;
    my($query_string,@lines);
    my($meth) = '';

    $meth = $ENV{'REQUEST_METHOD'} if defined($ENV{'REQUEST_METHOD'});

    my($debugme)=0;

    # If initializer is defined, then read parameters
    # from it.
  METHOD: {
	if (defined($initializer)) {
	    warn qq{initializer [$initializer] ref [}.ref($initializer).qq{] line [}.__LINE__.qq{]\n} if $debugme;
	    if (ref($initializer)) {
		if (ref($initializer) eq 'HASH') {
		    foreach (keys %$initializer) {
			$self->param(-name=>$_,-value=>$initializer->{$_});
		    }
		    last METHOD;
		} else {
		    $initializer = $$initializer;
		}
	    }
	    warn qq{initializer [$initializer] ref [}.ref($initializer).qq{] line [}.__LINE__.qq{]\n} if $debugme;
	    if (defined(fileno($initializer))) {
		while (<$initializer>) {
		    chomp;
		    last if /^=/;
		    push(@lines,$_);
		}
		# massage back into standard format
		if ("@lines" =~ /=/) {
		    $query_string=join("&",@lines);
		} else {
		    $query_string=join("+",@lines);
		}
	    } else {
		$query_string = $initializer;
	    }
	    last METHOD;
	}

	warn qq{initializer [$initializer] ref [}.ref($initializer).qq{] line [}.__LINE__.qq{]\n} if $debugme;

	# If method is GET or HEAD, fetch the query from
	# the environment.
	if ($meth =~ /^(GET|HEAD)$/) {
	    $query_string = $ENV{'QUERY_STRING'};
	    last METHOD;
	}

	# If the method is POST, fetch the query from standard
	# input.
	if ($meth eq 'POST') {
	    if ($ENV{'CONTENT_TYPE'} =~ m|^multipart/form-data|) {
		my($boundary) = $ENV{'CONTENT_TYPE'} =~ /boundary=(\S+)/;
		$self->read_multipart($boundary, $ENV{'CONTENT_LENGTH'});
	    } else {
		$self->read_from_client(\*STDIN,\$query_string,$ENV{'CONTENT_LENGTH'},0)
		    if $ENV{'CONTENT_LENGTH'} > 0;
	    }
	    last METHOD;
	}
	
	# If neither is set, assume we're being debugged offline.
	# Check the command line and then the standard input for data.
	# We use the shellwords package in order to behave the way that
	# UN*X programmers expect.
	$query_string = &read_from_cmdline;

    } # END OF METHOD

    warn qq{query_string [$query_string] line [}.__LINE__.qq{]\n} if $debugme;

    # We now have the query string in hand.  We do slightly
    # different things for keyword lists and parameter lists.
    if ($query_string) {
	if ($query_string =~ /=/) {
	    $self->parse_params($query_string);
	} else {
	    $self->add_parameter('keywords');
	    $self->{'keywords'} = [$self->parse_keywordlist($query_string)];
	}
    }

    # Special case.  Erase everything if there is a field named
    # .defaults.
    if ($self->param('.defaults')) {
	undef %{$self};
    }

    # flag that we've been inited
    $self->{'.init'}++ if $self->param;

    # Clear out our default submission button flag if present
    $self->delete('.submit');
}

# FUNCTIONS TO OVERRIDE:

# Turn a string into a filehandle

sub to_filehandle {
    my $string = shift;
    if ($string && (ref($string) eq '')) {
	my($package) = caller(1);
	my($tmp) = $string=~/[\':]/ ? $string : "$package\:\:$string";
	return $tmp if defined(fileno($tmp));
    }
    return $string;
}

# Create a new multipart buffer
sub new_MultipartBuffer {
    my($self,$boundary,$length,$filehandle) = @_;
    return CGI::XA::MultipartBuffer->new($self,$boundary,$length,$filehandle);
}

# Read data from a file handle
sub read_from_client {
    my($self, $fh, $buff, $len, $offset) = @_;
    local $^W=0;		# prevent a warning
    return read($fh, $$buff, $len, $offset);
}

# send output to the browser
sub put {
    my($self,@p) = @_;
    $self->print(@p);
}

# print to standard output (for overriding in mod_perl)
sub print {
    shift;
    CORE::print(@_);
}

# unescape URL-encoded data
sub unescape {
    my($todecode) = @_;
    $todecode =~ tr/+/ /;	# pluses become spaces
    $todecode =~ s/%([0-9a-fA-F]{2})/pack("c",hex($1))/ge;
    return $todecode;
}

# URL-encode data
sub escape {
    my($toencode) = @_;
    $toencode=~s/([^a-zA-Z0-9_\-.])/uc sprintf("%%%02x",ord($1))/eg;
    return $toencode;
}

sub parse_keywordlist {
    my($self,$tosplit) = @_;
    $tosplit = &unescape($tosplit); # unescape the keywords
    $tosplit=~tr/+/ /;		# pluses to spaces
    my(@keywords) = split(/\s+/,$tosplit);
    return @keywords;
}

sub parse_params {
    my($self,$tosplit) = @_;
    my(@pairs) = split('&',$tosplit);
    my($param,$value);
    foreach (@pairs) {
	($param,$value) = split('=');
	$param = &unescape($param);
	$value = &unescape($value);
	$self->add_parameter($param);
	push (@{$self->{$param}},$value);
    }
}

sub add_parameter {
    my($self,$param)=@_;
    push (@{$self->{'.parameters'}},$param)
	unless defined($self->{$param});
}

sub all_parameters {
    return @{shift->{'.parameters'}||[]};
}

#### Method as_string
#
# synonym for "dump"
####
*as_string = \&dump;

sub URL_ENCODED { 'application/x-www-form-urlencoded'; }

sub MULTIPART {  'multipart/form-data'; }

#### Method: keywords
# Keywords acts a bit differently.  Calling it in a list context
# returns the list of keywords.
# Calling it in a scalar context gives you the size of the list.
####
sub keywords {
    my($self,@values) = @_;
    # If values is provided, then we set it.
    $self->{'keywords'}=[@values] if @values;
    my(@result) = @{$self->{'keywords'}};
    @result;
}

####
# Append a new value to an existing query
####
sub append {
    my($self,@p) = @_;
    my($name,$value) = $self->rearrange(['NAME',['VALUE','VALUES']],@p);
    my(@values) = defined($value) ? (ref($value) ? @{$value} : $value) : ();
    if (@values) {
	$self->add_parameter($name);
	push(@{$self->{$name}},@values);
    }
    return $self->param($name);
}
#append                 name value
 #                          ['NAME',['VALUE','VALUES']]

#sub append {
#    my($self,@p,%p) = @_;
#    if (@p && (substr($p[0],0,1) eq '-' || $self->use_named_parameters)) {
#	 my($k,$v,$lck);
#	 %p = @p;
#	 foreach $k (keys %p) {
#	     $lck = lc $k;
#	     $lck = substr($k,1) if substr($k,0,1) eq "-";
#	     $p{$lck} = $p{$k} if $lck ne $k;
#	 }
#	 $p{value} ||= $p{'values'};
#     } else {
#	 @p{qw/ name value/} = @p;
#    }
#    my(@values) = defined($p{value}) ? (ref($p{value}) ? @{$p{value}} : $p{value}) : ();
#    if (@values) {
#	 $self->add_parameter($p{name});
#	 push(@{$self->{$p{name}}},@values);
#    }
#    return $self->param($p{name});
#}

#### Method: delete_all
# Delete all parameters
####
sub delete_all {
    my($self) = @_;
    undef %{$self};
}

#### Method: autoescape
# If you won't to turn off the autoescaping features,
# call this method with undef as the argument
sub autoEscape {
    my($self,$escape) = @_;
    $self->{'dontescape'}=!$escape;
}

sub make_attributes {
    my($self,$attr) = @_;
    return () unless $attr && ref($attr) eq 'HASH';
    my(@att);
    foreach (keys %{$attr}) {
	my($key) = $_;
	$key=~s/^\-//;     # get rid of initial - if present
	$key=~tr/a-z/A-Z/; # parameters are upper case
	push(@att,$attr->{$_} ne '' ? qq/$key="$attr->{$_}"/ : qq/$key/);
    }
    return @att;
}

#### Method: dump
# Returns a string in which all the known parameter/value
# pairs are represented as nested lists, mainly for the purposes
# of debugging.
####
sub dump {
    my($self) = @_;
    my($param,$value,@result);
#    use Data::Dumper;
#    return join "", "<PRE>", Dumper($self), "</PRE>\n";
    return '<UL></UL>' unless $self->param;
    push(@result,"<UL>");
    foreach $param ($self->param) {
	my($name) = $param;
	$self->escapeHTML($name);
	push(@result,"<LI><STRONG>$name</STRONG>");
	push(@result,"<UL>");
	foreach $value ($self->param($param)) {
	    $self->escapeHTML($value);
	    push(@result,"<LI>$value");
	}
	push(@result,"</UL>");
    }
    push(@result,"</UL>\n");
    return join("\n",@result);
}


#### Method: save
# Write values out to a filehandle in such a way that they can
# be reinitialized by the filehandle form of the new() method
####
sub save {
    my($self,$filehandle) = @_;
    my($param);
    my($package) = caller;
    $filehandle = $filehandle=~/[\':]/ ? $filehandle : "$package\:\:$filehandle";
    foreach $param ($self->param) {
	my($escaped_param) = &escape($param);
	my($value);
	foreach $value ($self->param($param)) {
	    print $filehandle "$escaped_param=",escape($value),"\n";
	}
    }
    print $filehandle "=\n";	# end of record
}


#### Method: header
# Return a Content-Type: style header
#
####
sub header {
   my($self,@p) = @_;
    my(@header);

    my($type,$status,$cookie,$target,$expires,@other) =
	 $self->rearrange(['TYPE','STATUS',['COOKIE','COOKIES'],'TARGET','EXPIRES'],@p);

    # rearrange() was designed for the HTML portion, so we
    # need to fix it up a little.
    foreach (@other) {
	 next unless my($header,$value) = /(\S+)=(.+)/;
	 substr($header,1,1000)=~tr/A-Z/a-z/;
	 ($value) = $value =~ /^"(.*)"$/;
	 $_ = "$header: $value";
    }

    $type = $type || 'text/html';

    push(@header,"Status: $status") if $status;
    push(@header,"Window-target: $target") if $target;
    # push all the cookies -- there may be several
    if ($cookie) {
	 my(@cookie) = ref($cookie) ? @{$cookie} : $cookie;
	 foreach (@cookie) {
	     push(@header,"Set-cookie: $_");
	 }
    }
    push(@header,"Expires: " . &expires($expires)) if $expires;
    push(@header,"Pragma: no-cache") if $self->cache();
    push(@header,@other);
    push(@header,"Content-type: $type");

    my $header = join($CRLF,@header);
    return $header . "$CRLF$CRLF";
}

#### Method: cache
# Control whether header() will produce the no-cache
# Pragma directive.
####
sub cache {
    my($self,$new_value) = @_;
    $new_value = '' unless $new_value;
    if ($new_value ne '') {
	$self->{'cache'} = $new_value;
    }
    return $self->{'cache'};
}


#### Method: redirect
# Return a Location: style header
#
####
sub redirect {
    my($self,@p) = @_;
    my($url,$target,$cookie,@other) = $self->rearrange([['URI','URL'],'TARGET','COOKIE'],@p);
    $url = $url || $self->self_url;
    my(@o);
    foreach (@other) { push(@o,split("=")); }
    push(@o,
	 '-Status'=>'302 Found',
	 '-Location'=>$url,
	 '-URI'=>$url);
    push(@o,'-Target'=>$target) if $target;
    push(@o,'-Cookie'=>$cookie) if $cookie;
    return $self->header(@o);
}
##redirect               url target cookie other
# #                          [['URI','URL'],'TARGET','COOKIE']
#sub redirect {
#    my($self,@p,%p) = @_;
#    if (@p && (substr($p[0],0,1) eq '-' || $self->use_named_parameters)) {
#	 my($k,$v,$lck);
#	 %p = @p;
#	 foreach $k (keys %p) {
#	     $lck = lc $k;
#	     $lck = substr($k,1) if substr($k,0,1) eq "-";
#	     $p{$lck} = $p{$k} if $lck ne $k;;
#	 }
#	 $p{uri} ||= $p{url};
#     } else {
#	 @p{qw/ url target cookie other/} = @p;
#    }
#    $p{url} = $p{url} || $self->self_url;
#    my(@o);
#    foreach (@other) { push(@o,split("=")); }
#    push(@o,
#	  '-Status'=>'302 Found',
#	  '-Location'=>$p{url},
#	  '-URI'=>$p{url});
#    push(@o,'-Target'=>$p{target}) if $p{target};
#    push(@o,'-Cookie'=>$p{cookie}) if $p{cookie};
#    return $self->header(@o);
#}


#### Method: start_html
# Canned HTML header
#
# Parameters:
# $title -> (optional) The title for this HTML document (-title)
# $author -> (optional) e-mail address of the author (-author)
# $base -> (option) if set to true, will enter the BASE address of this document
#          for resolving relative references (-base)
# $xbase -> (option) alternative base at some remote location (-xbase)
# $script -> (option) Javascript code (-script)
# @other -> (option) any other named parameters you'd like to incorporate into
#           the <BODY> tag.
####
sub start_html {
    my($self,@p) = @_;
    my($title,$author,$base,$xbase,$script,$meta,@other) =
	$self->rearrange(['TITLE','AUTHOR','BASE','XBASE','SCRIPT','META'],@p);

    # strangely enough, the title needs to be escaped as HTML
    # while the author needs to be escaped as a URL
    $self->escapeHTML($title);
    $title ||= 'Untitled Document';
    $self->escapeHTML($author);
    my(@result);
    push(@result,"<HTML><HEAD><TITLE>$title</TITLE>");
    push(@result,"<LINK REV=MADE HREF=\"mailto:$author\">") if $author;
    push(@result,"<BASE HREF=\"http://".$self->server_name.":".$self->server_port.$self->script_name."\">")
	if $base && !$xbase;
    push(@result,"<BASE HREF=\"$xbase\">") if $xbase;
    if ($meta && (ref($meta) eq 'HASH')) {
	foreach (keys %$meta) { push(@result,qq(<META NAME="$_" CONTENT="$meta->{$_}">)); }
    }
    push(@result,<<END) if $script;
<SCRIPT>
<!-- Hide script from HTML-compliant browsers
$script
// End script hiding. -->
</SCRIPT>
END
    ;
    push(@result,"</HEAD><BODY @other>");
    return join("\n",@result);
}
##start_html             title author base xbase script meta other
# #                          ['TITLE','AUTHOR','BASE','XBASE','SCRIPT','META']
#sub start_html {
#    my($self,@p,%p) = @_;
#    if (@p && (substr($p[0],0,1) eq '-' || $self->use_named_parameters)) {
#	 my($k,$v,$lck);
#	 %p = @p;
#	 foreach $k (keys %p) {
#	     $lck = lc $k;
#	     $lck = substr($k,1) if substr($k,0,1) eq "-";
#	     $p{$lck} = $p{$k} if $lck ne $k;;
#	 }
#     } else {
#	 @p{qw/ title author base xbase script meta other/} = @p;
#    }
#    $self->escapeHTML($p{title});
#    $p{title} ||= 'Untitled Document';
#    $self->escapeHTML($p{author});
#    my(@result);
#    push(@result,"<HTML><HEAD><TITLE>$p{title}</TITLE>");
#    push(@result,"<LINK REV=MADE HREF=\"mailto:$p{author}\">") if $p{author};
#    push(@result,"<BASE HREF=\"http://".$self->server_name.":".$self->server_port.$self->script_name."\">")
#	 if $p{base} && !$p{xbase};
#    push(@result,"<BASE HREF=\"$p{xbase}\">") if $p{xbase};
#    if ($p{meta} && (ref($p{meta}) eq 'HASH')) {
#	 foreach (keys %$p{meta}) { push(@result,qq(<META NAME="$_" CONTENT="$p{meta}->{$_}">)); }
#    }
#    push(@result,<<END) if $p{script};
#<SCRIPT>
#<!-- Hide script from HTML-compliant browsers
#$p{script}
#// End script hiding. -->
#</SCRIPT>
#END
#    ;
#    push(@result,"</HEAD><BODY @other>");
#    return join("\n",@result);
#}


#### Method: end_html
# End an HTML document.
# Trivial method for completeness.  Just returns "</BODY>"
####
sub end_html {
    return "</BODY></HTML>";
}


################################
# METHODS USED IN BUILDING FORMS
################################

#### Method: isindex
# Just prints out the isindex tag.
# Parameters:
#  $action -> optional URL of script to run
# Returns:
#   A string containing a <ISINDEX> tag
#sub isindex {
#    my($self,@p) = @_;
#    my($action,@other) = $self->rearrange(['ACTION'],@p);
#    $action = qq/ACTION="$action"/ if $action;
#    return "<ISINDEX $action @other>";
#}
##isindex                action other
 #                          ['ACTION']

sub isindex {
    my($self, @p, %p) = @_;
   if (substr($p[0],0,1) eq '-' || $self->use_named_parameters) {
	 my($k,$v,$lck);
	 %p = @p;
	 foreach $k (keys %p) {
	     $lck = lc $k;
	     $lck = substr($k,1) if substr($k,0,1) eq "-";
	     $p{$lck} = $p{$k} if $lck ne $k;;
	}
     } else {
	@p{qw/ action other/} = @p;
    }
    $p{action} = qq/ACTION="$p{action}"/ if $p{action};
$p{other} ||= '';
    return "<ISINDEX $p{action} $p{other}>";
}

#### Method: startform
# Start a form
# Parameters:
#   $method -> optional submission method to use (GET or POST)
#   $action -> optional URL of script to run
#   $enctype ->encoding to use (URL_ENCODED or MULTIPART)
sub startform {
    my($self,@p) = @_;

    my($method,$action,$enctype,@other) =
	$self->rearrange(['METHOD','ACTION','ENCTYPE'],@p);

    $method = $method || 'POST';
    $enctype = $enctype || &URL_ENCODED;
    $action = $action ? qq/ACTION="$action"/ : '';
    return qq/<FORM METHOD="$method" $action ENCTYPE=$enctype @other>\n/;
}
##startform              method action enctype other
# #                          ['METHOD','ACTION','ENCTYPE']
#sub startform {
#    my($self,@p,%p) = @_;
#    if (@p && (substr($p[0],0,1) eq '-' || $self->use_named_parameters)) {
#	 my($k,$v,$lck);
#	 %p = @p;
#	 foreach $k (keys %p) {
#	     $lck = lc $k;
#	     $lck = substr($k,1) if substr($k,0,1) eq "-";
#	     $p{$lck} = $p{$k} if $lck ne $k;;
#	 }
#     } else {
#	 @p{qw/ method action enctype other/} = @p;
#    }
#    $p{method} = $p{method} || 'POST';
#    $p{enctype} = $p{enctype} || &URL_ENCODED;
#    $p{action} = $p{action} ? qq/ACTION="$p{action}"/ : '';
#    return qq/<FORM METHOD="$p{method}" $p{action} ENCTYPE=$p{enctype} @other>\n/;
#}

*start_form = \&startform;

#### Method: start_multipart_form
# synonym for startform
sub start_multipart_form {
    my($self,@p) = @_;
    my($method,$action,$enctype,@other) =
	$self->rearrange(['METHOD','ACTION','ENCTYPE'],@p);
    $self->startform($method,$action,$enctype || &MULTIPART,@other);
}
##start_multipart_form   method action enctype other
# #                          ['METHOD','ACTION','ENCTYPE']
#sub start_multipart_form {
#    my($self,@p,%p) = @_;
#    if (@p && (substr($p[0],0,1) eq '-' || $self->use_named_parameters)) {
#	 my($k,$v,$lck);
#	 %p = @p;
#	 foreach $k (keys %p) {
#	     $lck = lc $k;
#	     $lck = substr($k,1) if substr($k,0,1) eq "-";
#	     $p{$lck} = $p{$k} if $lck ne $k;;
#	 }
#     } else {
#	 @p{qw/ method action enctype other/} = @p;
#    }
#    $self->startform($p{method},$p{action},$p{enctype} || &MULTIPART,@other);
#}

#### Method: endform
# End a form
sub endform {
    return "</FORM>\n";
}

*end_form = \&endform;

#### Method: textfield
# Parameters:
#   $name -> Name of the text field
#   $default -> Optional default value of the field if not
#                already defined.
#   $size ->  Optional width of field in characaters.
#   $maxlength -> Optional maximum number of characters.
# Returns:
#   A string containing a <INPUT TYPE="text"> field
#

# renamed for benchmark
sub oldtextfield {
    my($self,@p) = @_;
    my($name,$default,$size,$maxlength,$override,@other) =
	$self->rearrange(['NAME',['DEFAULT','VALUE'],'SIZE','MAXLENGTH',['OVERRIDE','FORCE']],@p);

    my $current = $override ? $default :
	(defined($self->param($name)) ? $self->param($name) : $default);

    $self->escapeHTML($current);
    $self->escapeHTML($name);
    my($s) = defined($size) ? qq/ SIZE=$size/ : '';
    my($m) = defined($maxlength) ? qq/ MAXLENGTH=$maxlength/ : '';
    my($other) = join(" ",@other);
    return qq/<INPUT TYPE="text" NAME="$name" VALUE="$current"$s$m$other>/;
}

sub textfield {
    my($self,@p,%p) = @_;
    if (@p && (substr($p[0],0,1) eq '-' || $self->use_named_parameters)) {
	my($k,$v,$lck);
	%p = @p;
	foreach $k (keys %p) {
	    $lck = lc $k;
	    $lck = substr($k,1) if substr($k,0,1) eq "-";
	    $p{$lck} = $p{$k} if $lck ne $k;;
	}
	# DEFAULT takes precedence over VALUE
	$p{default} ||= $p{value};
	$p{override}||= $p{force};
    } else {
	@p{qw/name default size maxlength override other/} = @p;
    }

    my $current = $p{override} ? $p{default} :
	(defined($self->param($p{name})) ? $self->param($p{name}) : $p{default});

    $self->escapeHTML($current);
    $self->escapeHTML($p{name});
    $p{other} ||= ''; # we've changed semantics for
                                      # @other. Only one excess
                                      # argument is recognized now
    my($s) = defined($p{size}) ? qq/ SIZE=$p{size}/ : '';
    my($m) = defined($p{maxlength}) ? qq/ MAXLENGTH=$p{maxlength}/ : '';
    return qq/<INPUT TYPE="text" NAME="$p{name}" VALUE="$current"$s$m$p{other}>/;
}

# A.K.: I think I saw this in libwww somewhere -- should be replaced
# some day when we know about the fate of this library
sub escapeHTML {
    $_[1] ||= '';
    return unless $_[1];
    return if $_[0]->{'dontescape'};
    $_[1] =~ s/&/&amp;/g;
    $_[1] =~ s/\"/&quot;/g;
    $_[1] =~ s/>/&gt;/g;
    $_[1] =~ s/</&lt;/g;
}

#### Method: filefield
# Parameters:
#   $name -> Name of the file upload field
#   $size ->  Optional width of field in characaters.
#   $maxlength -> Optional maximum number of characters.
# Returns:
#   A string containing a <INPUT TYPE="text"> field
#
#sub filefield {
#    my($self,@p) = @_;
#
#    my($name,$default,$size,$maxlength,$override,@other) =
#	 $self->rearrange(['NAME',['DEFAULT','VALUE'],'SIZE','MAXLENGTH',['OVERRIDE','FORCE']],@p);
#
#    my $current = $override ? $default :
#	 (defined($self->param($name)) ? $self->param($name) : $default);
#
#    $self->escapeHTML($name);
#    my($s) = defined($size) ? qq/ SIZE=$size/ : '';
#    my($m) = defined($maxlength) ? qq/ MAXLENGTH=$maxlength/ : '';
#    $self->escapeHTML($current);
#    my($other) =join(" ",@other);
#    return qq/<INPUT TYPE="file" NAME="$name" VALUE="$current"$s$m$other>/;
#}
#
#filefield              name default size maxlength override other
 #                          ['NAME',['DEFAULT','VALUE'],'SIZE','MAXLENGTH',['OVERRIDE','FORCE']]

sub filefield {
    my($self,@p,%p) = @_;
    if (@p && (substr($p[0],0,1) eq '-' || $self->use_named_parameters)) {
	my($k,$v,$lck);
	%p = @p;
	foreach $k (keys %p) {
	    $lck = lc $k;
	    $lck = substr($k,1) if substr($k,0,1) eq "-";
	    $p{$lck} = $p{$k} if $lck ne $k;;
	}
        $p{default} ||= $p{value};
        $p{override} ||= $p{force};
     } else {
	@p{qw/ name default size maxlength override other/} = @p;
    }
    my $current = $p{override} ? $p{default} :
	(defined($self->param($p{name})) ? $self->param($p{name}) : $p{default});

    $self->escapeHTML($p{name});
    my($s) = defined($p{size}) ? qq/ SIZE=$p{size}/ : '';
    my($m) = defined($p{maxlength}) ? qq/ MAXLENGTH=$p{maxlength}/ : '';
    $self->escapeHTML($current);
    $p{other} ||= '';
    return qq/<INPUT TYPE="file" NAME="$p{name}" VALUE="$current"$s$m$p{other}>/;
}


#### Method: password
# Create a "secret password" entry field
# Parameters:
#   $name -> Name of the field
#   $default -> Optional default value of the field if not
#                already defined.
#   $size ->  Optional width of field in characters.
#   $maxlength -> Optional maximum characters that can be entered.
# Returns:
#   A string containing a <INPUT TYPE="password"> field
#
#sub password_field {
#    my ($self,@p) = @_;
#
#    my($name,$default,$size,$maxlength,$override,@other) =
#	 $self->rearrange(['NAME',['DEFAULT','VALUE'],'SIZE','MAXLENGTH',['OVERRIDE','FORCE']],@p);
#
#    my($current) =  $override ? $default :
#	 (defined($self->param($name)) ? $self->param($name) : $default);
#
#    $self->escapeHTML($name);
#    $self->escapeHTML($current);
#    my($s) = defined($size) ? qq/ SIZE=$size/ : '';
#    my($m) = defined($maxlength) ? qq/ MAXLENGTH=$maxlength/ : '';
#    my($other) = join(" ",@other);
#    return qq/<INPUT TYPE="password" NAME="$name" VALUE="$current"$s$m$other>/;
#}
##password_field         name default size maxlength override other
 #                          ['NAME',['DEFAULT','VALUE'],'SIZE','MAXLENGTH',['OVERRIDE','FORCE']]
sub password_field {
    my($self,@p,%p) = @_;
    if (@p && (substr($p[0],0,1) eq '-' || $self->use_named_parameters)) {
	 my($k,$v,$lck);
	 %p = @p;
	 foreach $k (keys %p) {
	     $lck = lc $k;
	     $lck = substr($k,1) if substr($k,0,1) eq "-";
	     $p{$lck} = $p{$k} if $lck ne $k;;
	 }
	 $p{default} ||= $p{value};
	 $p{override} ||= $p{force};
     } else {
	 @p{qw/ name default size maxlength override other/} = @p;
    }
    my($current) =  $p{override} ? $p{default} :
	 (defined($self->param($p{name})) ? $self->param($p{name}) : $p{default});
    $self->escapeHTML($p{name});
    $self->escapeHTML($current);
    my($s) = defined($p{size}) ? qq/ SIZE=$p{size}/ : '';
    my($m) = defined($p{maxlength}) ? qq/ MAXLENGTH=$p{maxlength}/ : '';
    $p{other} ||= '';
    return qq/<INPUT TYPE="password" NAME="$p{name}" VALUE="$current"$s$m$p{other}>/;
}


#### Method: textarea
# Parameters:
#   $name -> Name of the text field
#   $default -> Optional default value of the field if not
#                already defined.
#   $rows ->  Optional number of rows in text area
#   $columns -> Optional number of columns in text area
# Returns:
#   A string containing a <TEXTAREA></TEXTAREA> tag
#
#sub textarea {
#    my($self,@p) = @_;
#
#    my($name,$default,$rows,$cols,$override,@other) =
#	 $self->rearrange(['NAME',['DEFAULT','VALUE'],'ROWS',['COLS','COLUMNS'],['OVERRIDE','FORCE']],@p);
#
#    my($current)= $override ? $default :
#	 (defined($self->param($name)) ? $self->param($name) : $default);
#
#    $self->escapeHTML($name);
#    $self->escapeHTML($current);
#    my($r) = $rows ? " ROWS=$rows" : '';
#    my($c) = $cols ? " COLS=$cols" : '';
#    my($other) = join(' ',@other);
#    return qq{<TEXTAREA NAME="$name"$r$c$other>$current</TEXTAREA>};
#}
##textarea               name default rows cols override other
 #                          ['NAME',['DEFAULT','VALUE'],'ROWS',['COLS','COLUMNS'],['OVERRIDE','FORCE']]
sub textarea {
    my($self,@p,%p) = @_;
    if (@p && (substr($p[0],0,1) eq '-' || $self->use_named_parameters)) {
	 my($k,$v,$lck);
	 %p = @p;
	 foreach $k (keys %p) {
	     $lck = lc $k;
	     $lck = substr($k,1) if substr($k,0,1) eq "-";
	     $p{$lck} = $p{$k} if $lck ne $k;;
	 }
	 $p{default} ||= $p{value};
	 $p{cols} ||= $p{columns};
	 $p{override} ||= $p{force};
     } else {
	 @p{qw/ name default rows cols override other/} = @p;
    }
    my($current)= $p{override} ? $p{default} :
	 (defined($self->param($p{name})) ? $self->param($p{name}) : $p{default});
    $self->escapeHTML($p{name});
    $self->escapeHTML($current);
    my($r) = $p{rows} ? " ROWS=$p{rows}" : '';
    my($c) = $p{cols} ? " COLS=$p{cols}" : '';
    $p{other} ||= '';
    return qq{<TEXTAREA NAME="$p{name}"$r$c$p{other}>$current</TEXTAREA>};
}


#### Method: button
# Create a javascript button.
# Parameters:
#   $name ->  (optional) Name for the button. (-name)
#   $value -> (optional) Value of the button when selected (and visible name) (-value)
#   $onclick -> (optional) Text of the JavaScript to run when the button is
#                clicked.
# Returns:
#   A string containing a <INPUT TYPE="button"> tag
####
#
# A.K. My impression is, this was completely broken. I've corrected what I could guess.
#sub button {
#    my($self,@p) = @_;
#
#    my($label,$value,$script,@other) = $self->rearrange(['NAME',['VALUE','LABEL'],
#							  ['ONCLICK','SCRIPT']],@p);
#
#    $self->escapeHTML($label);
#    $self->escapeHTML($value);
#    $self->escapeHTML($script);
#
#    my($name) = '';
#    $name = qq/ NAME="$label"/ if $label;
#    $value = $value || $label;
#    my($val) = '';
#    $val = qq/ VALUE="$value"/ if $value;
#    $script = qq/ ONCLICK="$script"/ if $script;
#    my($other) =join(" ",@other);
#    return qq/<INPUT TYPE="button"$name$val$script$other>/;
#}
#button                 label value script other
 #                          ['NAME',['VALUE','LABEL'], ['ONCLICK','SCRIPT']]

sub button {
    my($self,@p,%p) = @_;
    if (@p && (substr($p[0],0,1) eq '-' || $self->use_named_parameters)) {
	my($k,$v,$lck);
	%p = @p;
	foreach $k (keys %p) {
	    $lck = lc $k;
	    $lck = substr($k,1) if substr($k,0,1) eq "-";
	    $p{$lck} = $p{$k} if $lck ne $k;;
	}
        $p{value} ||= $p{label};
        $p{onclick} ||= $p{script};
     } else {
	@p{qw/name value onclick other/} = @p;
    }
    $self->escapeHTML($p{name});
    $self->escapeHTML($p{value});
    $self->escapeHTML($p{onclick});
    $p{other} ||= '';

    $p{name} = qq/ NAME="$p{name}"/ if $p{name};
    $p{value} = qq/ VALUE="$p{value}"/ if $p{value};
    $p{onclick} = qq/ ONCLICK="$p{onclick}"/ if $p{onclick};
    return qq/<INPUT TYPE="button"$p{name}$p{value}$p{onclick}$p{other}>/;
}



#### Method: submit
# Create a "submit query" button.
# Parameters:
#   $name ->  (optional) Name for the button.
#   $value -> (optional) Value of the button when selected (also doubles as label).
#   $label -> (optional) Label printed on the button(also doubles as the value).
# Returns:
#   A string containing a <INPUT TYPE="submit"> tag
####
#sub submit {
#    my($self,@p) = @_;
#
#    my($label,$value,@other) = $self->rearrange(['NAME',['VALUE','LABEL']],@p);
#
#    $self->escapeHTML($label);
#    $self->escapeHTML($value);
#
#    my($name) = ' NAME=".submit"';
#    $name = qq/ NAME="$label"/ if $label;
#    $value = $value || $label;
#    my($val) = '';
#    $val = qq/ VALUE="$value"/ if defined($value);
#    my($other) = join(' ',@other);
#    return qq/<INPUT TYPE="submit"$name$val$other>/;
#}
##submit                 label value other
 #                          ['NAME',['VALUE','LABEL']]
sub submit {
    my($self,@p,%p) = @_;
    if (@p && (substr($p[0],0,1) eq '-' || $self->use_named_parameters)) {
	 my($k,$v,$lck);
	 %p = @p;
	 foreach $k (keys %p) {
	     $lck = lc $k;
	     $lck = substr($k,1) if substr($k,0,1) eq "-";
	     $p{$lck} = $p{$k} if $lck ne $k;;
	 }
	 $p{value} ||= $p{label};
     } else {
	 @p{qw/name value other/} = @p;
    }
    $self->escapeHTML($p{label});
    $self->escapeHTML($p{value});
    my($name) = ' NAME=".submit"';
    $name = qq/ NAME="$p{name}"/ if $p{name};
    $p{value} = qq/ VALUE="$p{value}"/ if defined($p{value});
    $p{other} ||= '';
    return qq/<INPUT TYPE="submit"$name$p{value}$p{other}>/;
}

#### Method: reset
# Create a "reset" button.
# Parameters:
#   $name -> (optional) Name for the button.
# Returns:
#   A string containing a <INPUT TYPE="reset"> tag
####
#sub reset {
#    my($self,@p) = @_;
#    my($label,@other) = $self->rearrange(['NAME'],@p);
#    $self->escapeHTML($label);
#    my($value) = defined($label) ? qq/ VALUE="$label"/ : '';
#    my($other) = join(' ',@other);
#    return qq/<INPUT TYPE="reset"$value$other>/;
#}
#reset                  label other
 #                          ['NAME']
sub reset {
    my($self,@p,%p) = @_;
    if (@p && (substr($p[0],0,1) eq '-' || $self->use_named_parameters)) {
	 my($k,$v,$lck);
	 %p = @p;
	 foreach $k (keys %p) {
	     $lck = lc $k;
	     $lck = substr($k,1) if substr($k,0,1) eq "-";
	     $p{$lck} = $p{$k} if $lck ne $k;;
	 }
     } else {
	 @p{qw/ label other/} = @p;
    }
    $self->escapeHTML($p{label});
    my($value) = defined($p{label}) ? qq/ VALUE="$p{label}"/ : '';
    $p{other} ||= '';
    return qq/<INPUT TYPE="reset"$value$p{other}>/;
}

#### Method: defaults
# Create a "defaults" button.
# Parameters:
#   $name -> (optional) Name for the button.
# Returns:
#   A string containing a <INPUT TYPE="submit" NAME=".defaults"> tag
#
# Note: this button has a special meaning to the initialization script,
# and tells it to ERASE the current query string so that your defaults
# are used again!
####
#sub defaults {
#    my($self,@p) = @_;
#
#    my($label,@other) = $self->rearrange([['NAME','VALUE']],@p);
#
#    $self->escapeHTML($label);
#    $label ||= "Defaults";
#    my($value) = qq/ VALUE="$label"/;
#    my($other) = join(' ',@other);
#    return qq/<INPUT TYPE="submit" NAME=".defaults"$value$other>/;
#}
##defaults               label other
 #                          [['NAME','VALUE']]

sub defaults {
    my($self,@p,%p) = @_;
    if (@p && (substr($p[0],0,1) eq '-' || $self->use_named_parameters)) {
	my($k,$v,$lck);
	%p = @p;
	foreach $k (keys %p) {
	    $lck = lc $k;
	    $lck = substr($k,1) if substr($k,0,1) eq "-";
	    $p{$lck} = $p{$k} if $lck ne $k;;
	}
        $p{name} ||= $p{value};
     } else {
	@p{qw/label other/} = @p;
    }
    $self->escapeHTML($p{label});
    $p{label} ||= "Defaults";
    my($value) = qq/ VALUE="$p{label}"/;
    $p{other} ||= '';
    return qq/<INPUT TYPE="submit" NAME=".defaults"$value$p{other}>/;
}


#### Method: checkbox
# Create a checkbox that is not logically linked to any others.
# The field value is "on" when the button is checked.
# Parameters:
#   $name -> Name of the checkbox
#   $checked -> (optional) turned on by default if true
#   $value -> (optional) value of the checkbox, 'on' by default
#   $label -> (optional) a user-readable label printed next to the box.
#             Otherwise the checkbox name is used.
# Returns:
#   A string containing a <INPUT TYPE="checkbox"> field
####
#sub checkbox {
#    my($self,@p) = @_;
#
#    my($name,$checked,$value,$label,$override,@other) =
#	 $self->rearrange(['NAME',['CHECKED','SELECTED','ON'],'VALUE','LABEL',['OVERRIDE','FORCE']],@p);
#
#    if (!$override && $self->inited) {
#	 $checked = $self->param($name) ? ' CHECKED' : '';
#	 $value = defined $self->param($name) ? $self->param($name) :
#	     (defined $value ? $value : 'on');
#    } else {
#	 $checked = defined($checked) ? ' CHECKED' : '';
#	 $value = defined $value ? $value : 'on';
#    }
#    my($the_label) = defined $label ? $label : $name;
#    $self->escapeHTML($name);
#    $self->escapeHTML($value);
#    $self->escapeHTML($the_label);
#    my($other) = join(" ",@other);
#    return <<END;
#<INPUT TYPE="checkbox" NAME="$name" VALUE="$value"$checked$other>$the_label
#END
#}
#checkbox               name checked value label override other
#                          ['NAME',['CHECKED','SELECTED','ON'],'VALUE','LABEL',['OVERRIDE','FORCE']]

sub checkbox {
   my($self,@p,%p) = @_;
    if (@p && (substr($p[0],0,1) eq '-' || $self->use_named_parameters)) {
	my($k,$v,$lck);
	%p = @p;
	foreach $k (keys %p) {
	    $lck = lc $k;
	    $lck = substr($k,1) if substr($k,0,1) eq "-";
	    $p{$lck} = $p{$k} if $lck ne $k;;
	}
        $p{checked} ||= $p{selected};
        $p{checked} ||= $p{on};
        $p{override} ||= $p{force};
     } else {
	@p{qw/ name checked value label override other/} = @p;
    }
    if (!$p{override} && $self->inited) {
	$p{checked} = $self->param($p{name}) ? ' CHECKED' : '';
	$p{value} = defined $self->param($p{name}) ? $self->param($p{name}) :
	    (defined $p{value} ? $p{value} : 'on');
    } else {
	$p{checked} = defined($p{checked}) ? ' CHECKED' : '';
	$p{value} = defined $p{value} ? $p{value} : 'on';
    }
    $self->escapeHTML($p{name});
   $p{label} ||= $p{name};
    $self->escapeHTML($p{value});
    $p{other} ||= '';
    return qq[<INPUT TYPE="checkbox" NAME="$p{name}" VALUE="$p{value}"$p{checked}$p{other}>$p{label}\n];
}

#### Method: checkbox_group
# Create a list of logically-linked checkboxes.
# Parameters:
#   $name -> Common name for all the check boxes
#   $values -> A pointer to a regular array containing the
#             values for each checkbox in the group.
#   $defaults -> (optional)
#             1. If a pointer to a regular array of checkbox values,
#             then this will be used to decide which
#             checkboxes to turn on by default.
#             2. If a scalar, will be assumed to hold the
#             value of a single checkbox in the group to turn on.
#   $linebreak -> (optional) Set to true to place linebreaks
#             between the buttons.
#   $labels -> (optional)
#             A pointer to an associative array of labels to print next to each checkbox
#             in the form $label{'value'}="Long explanatory label".
#             Otherwise the provided values are used as the labels.
# Returns:
#   An ARRAY containing a series of <INPUT TYPE="checkbox"> fields
####
#sub checkbox_group {
#    my($self,@p) = @_;
#
#    my($name,$values,$defaults,$linebreak,$labels,$rows,$columns,
#	$rowheaders,$colheaders,$override,$nolabels,@other) =
#	 $self->rearrange(['NAME',['VALUES','VALUE'],['DEFAULTS','DEFAULT'],
#			   'LINEBREAK','LABELS','ROWS',['COLUMNS','COLS'],
#			   'ROWHEADERS','COLHEADERS',
#			   ['OVERRIDE','FORCE'],'NOLABELS'],@p);
#
#    my($checked,$break,$result,$label);
#
#    my(%checked) = $self->previous_or_default($name,$defaults,$override);
#
#    $break = $linebreak ? "<BR>" : '';
#    $self->escapeHTML($name);
#
#    # Create the elements
#    my(@elements);
#    my(@values) = $values ? @$values : $self->param($name);
#    my($other) = join(" ",@other);
#    foreach (@values) {
#	 $checked = $checked{$_} ? ' CHECKED' : '';
#	 $label = '';
#	 unless (defined($nolabels) && $nolabels) {
#	     $label = $_;
#	     $label = $labels->{$_} if defined($labels) && $labels->{$_};
#	     $self->escapeHTML($label);
#	 }
#	 $self->escapeHTML($_);
#	 push(@elements,qq/<INPUT TYPE="checkbox" NAME="$name" VALUE="$_"$checked$other>${label} ${break}/);
#    }
#    return wantarray ? @elements : join('',@elements) unless $columns;
#    return _tableize($rows,$columns,$rowheaders,$colheaders,@elements);
#}
#
##checkbox_group         name values defaults linebreak labels rows columns   rowheaders
 #                      colheaders override nolabels other
 #                          ['NAME',['VALUES','VALUE'],['DEFAULTS','DEFAULT'], 'LINEBREAK','LABELS','ROWS',[
 #                          'COLUMNS','COLS'], 'ROWHEADERS','COLHEADERS', ['OVERRIDE','FORCE'],'NOLABELS']

sub checkbox_group {
    my($self,@p,%p) = @_;
    if (@p && (substr($p[0],0,1) eq '-' || $self->use_named_parameters)) {
	my($k,$v,$lck);
%p = @p;
	foreach $k (keys %p) {
	    $lck = lc $k;
	    $lck = substr($k,1) if substr($k,0,1) eq "-";
	    $p{$lck} = $p{$k} if $lck ne $k;;
	}
        $p{'values'} ||= $p{value};
        $p{'defaults'} ||= $p{default};
        $p{columns} ||= $p{cols};
       $p{override} ||= $p{force};
     } else {
       @p{qw/ name values defaults linebreak labels rows columns 
              rowheaders colheaders override nolabels other/} = @p;
    }
    my($checked,$break,$result,$label);

    my(%checked) = $self->previous_or_default($p{name},$p{'defaults'},$p{override});

    $break = $p{linebreak} ? "<BR>" : '';
    $self->escapeHTML($p{name});

    
    my(@elements);
    my(@values) = $p{'values'} ? @{$p{'values'}} : $self->param($p{name});
    $p{other} ||= '';
    foreach (@values) {
	$checked = $checked{$_} ? ' CHECKED' : '';
	$label = '';
	unless (defined($p{nolabels}) && $p{nolabels}) {
	    $label = $_;
	    $label = $p{labels}->{$_} if defined($p{labels}) && $p{labels}->{$_};
	    $self->escapeHTML($label);
	}
	$self->escapeHTML($_);
	push(@elements,qq/<INPUT TYPE="checkbox" NAME="$p{name}" VALUE="$_"$checked$p{other}>${label} ${break}/);
    }
    return wantarray ? @elements : join('',@elements) unless $p{columns};
    return _tableize($p{rows},$p{columns},$p{rowheaders},$p{colheaders},@elements);
}

# Escape HTML -- used internally
# A.K. replaced it by escapeHTML which in turn is stolen from libwww
#sub escapeHTML {
#    my($self,$toencode) = @_;
#    return undef unless defined($toencode);
#    return $toencode if $self->{'dontescape'};
#    $toencode=~s/&/&amp;/g;
#    $toencode=~s/\"/&quot;/g;
#    $toencode=~s/>/&gt;/g;
#    $toencode=~s/</&lt;/g;
#    return $toencode;
#}


# Internal procedure - don't use
sub _tableize {
    my($rows,$columns,$rowheaders,$colheaders,@elements) = @_;
    my($result);

    $rows = int(0.99 + @elements/$columns) unless $rows;
    # rearrange into a pretty table
    $result = "<TABLE>";
    my($row,$column);
    unshift(@$colheaders,'') if @$colheaders && @$rowheaders;
    $result .= "<TR><TH>" . join ("<TH>",@{$colheaders}) if @{$colheaders};
    for ($row=0;$row<$rows;$row++) {
	$result .= "<TR>";
	$result .= "<TH>$rowheaders->[$row]" if @$rowheaders;
	for ($column=0;$column<$columns;$column++) {
	    $result .= "<TD>" . $elements[$column*$rows + $row];
	}
    }
    $result .= "</TABLE>";
    return $result;
}

#### Method: radio_group
# Create a list of logically-linked radio buttons.
# Parameters:
#   $name -> Common name for all the buttons.
#   $values -> A pointer to a regular array containing the
#             values for each button in the group.
#   $default -> (optional) Value of the button to turn on by default.  Pass '-'
#               to turn _nothing_ on.
#   $linebreak -> (optional) Set to true to place linebreaks
#             between the buttons.
#   $labels -> (optional)
#             A pointer to an associative array of labels to print next to each checkbox
#             in the form $label{'value'}="Long explanatory label".
#             Otherwise the provided values are used as the labels.
# Returns:
#   An ARRAY containing a series of <INPUT TYPE="radio"> fields
####
#sub radio_group {
#    my($self,@p) = @_;
#
#    my($name,$values,$default,$linebreak,$labels,
#	$rows,$columns,$rowheaders,$colheaders,$override,$nolabels,@other) =
#	 $self->rearrange(['NAME',['VALUES','VALUE'],'DEFAULT','LINEBREAK','LABELS',
#			   'ROWS',['COLUMNS','COLS'],
#			   'ROWHEADERS','COLHEADERS',
#			   ['OVERRIDE','FORCE'],'NOLABELS'],@p);
#    my($result,$checked);
#
#    if (!$override && defined($self->param($name))) {
#	 $checked = $self->param($name);
#    } else {
#	 $checked = $default;
#    }
#    # If no check array is specified, check the first by default
#    $checked = $values->[0] unless $checked;
#    $self->escapeHTML($name);
#
#    my(@elements);
#    my(@values) = $values ? @$values : $self->param($name);
#    my($other) = join(" ",@other);
#    foreach (@values) {
#	 my($checkit) = $checked eq $_ ? ' CHECKED' : '';
#	 my($break) = $linebreak ? '<BR>' : '';
#	 my($label)='';
#	 unless (defined($nolabels) && $nolabels) {
#	     $label = $_;
#	     $label = $labels->{$_} if defined($labels) && $labels->{$_};
#	     $self->escapeHTML($label);
#	 }
#	 $self->escapeHTML($_);
#	 push(@elements,qq/<INPUT TYPE="radio" NAME="$name" VALUE="$_"$checkit$other>${label} ${break}/);
#    }
#    return wantarray ? @elements : join('',@elements) unless $columns;
#    return _tableize($rows,$columns,$rowheaders,$colheaders,@elements);
#}
##radio_group            name values default linebreak labels   rows columns rowheaders colheaders
 #                      override nolabels other
 #                          ['NAME',['VALUES','VALUE'],'DEFAULT','LINEBREAK','LABELS', 'ROWS',['COLUMNS',
 #                          'COLS'], 'ROWHEADERS','COLHEADERS', ['OVERRIDE','FORCE'],'NOLABELS']
sub radio_group {
    my($self,@p,%p) = @_;
    if (@p && (substr($p[0],0,1) eq '-' || $self->use_named_parameters)) {
	 my($k,$v,$lck);
	 %p = @p;
	 foreach $k (keys %p) {
	     $lck = lc $k;
	     $lck = substr($k,1) if substr($k,0,1) eq "-";
	     $p{$lck} = $p{$k} if $lck ne $k;;
	 }
	 $p{'values'} ||= $p{value};
	 $p{columns} ||= $p{cols};
	 $p{override} ||= $p{force};
     } else {
	 @p{qw/ name values default linebreak labels   rows columns rowheaders colheaders override nolabels other/} = @p;
    }
    my($result,$checked);
    if (!$p{override} && defined($self->param($p{name}))) {
	 $checked = $self->param($p{name});
    } else {
	 $checked = $p{default};
    }
    
    $checked = $p{'values'}->[0] unless $checked;
    $self->escapeHTML($p{name});
    my(@elements);
    my(@values) = $p{'values'} ? @{$p{'values'}} : $self->param($p{name});
    $p{other} ||= '';
    foreach (@values) {
	 my($checkit) = $checked eq $_ ? ' CHECKED' : '';
	 my($break) = $p{linebreak} ? '<BR>' : '';
	 my($label)='';
	 unless (defined($p{nolabels}) && $p{nolabels}) {
	     $label = $_;
	     $label = $p{labels}->{$_} if defined($p{labels}) && $p{labels}->{$_};
	     $self->escapeHTML($label);
	 }
	 $self->escapeHTML($_);
	 push(@elements,qq/<INPUT TYPE="radio" NAME="$p{name}" VALUE="$_"$checkit$p{other}>$label $break/);
    }
    return wantarray ? @elements : join('',@elements) unless $p{columns};
    return _tableize($p{rows},$p{columns},$p{rowheaders},$p{colheaders},@elements);
}

#### Method: popup_menu
# Create a popup menu.
# Parameters:
#   $name -> Name for all the menu
#   $values -> A pointer to a regular array containing the
#             text of each menu item.
#   $default -> (optional) Default item to display
#   $labels -> (optional)
#             A pointer to an associative array of labels to print next to each checkbox
#             in the form $label{'value'}="Long explanatory label".
#             Otherwise the provided values are used as the labels.
# Returns:
#   A string containing the definition of a popup menu.
####
#sub popup_menu {
#    my($self,@p) = @_;
#
#    my($name,$values,$default,$labels,$override,@other) =
#	 $self->rearrange(['NAME',['VALUES','VALUE'],['DEFAULT','DEFAULTS'],'LABELS',['OVERRIDE','FORCE']],@p);
#    my($result,$selected);
#
#    if (!$override && defined($self->param($name))) {
#	 $selected = $self->param($name);
#    } else {
#	 $selected = $default;
#    }
#    $self->escapeHTML($name);
#    my($other) = join(" ",@other);
#
#    my(@values) = $values ? @$values : $self->param($name);
#    $result = qq/<SELECT NAME="$name"$other>\n/;
#    foreach (@values) {
#	 my($selectit) = defined($selected) ? ($selected eq $_ ? 'SELECTED' : '' ) : '';
#	 my($label) = $_;
#	 $label = $labels->{$_} if defined($labels) && $labels->{$_};
#	 my($value) = $_;
#	 $self->escapeHTML($value);
#	 $self->escapeHTML($label);
#	 $result .= "<OPTION $selectit VALUE=\"$value\">$label\n";
#    }
#
#    $result .= "</SELECT>\n";
#    return $result;
#}
##popup_menu             name values default labels override other
 #                          ['NAME',['VALUES','VALUE'],['DEFAULT','DEFAULTS'],'LABELS',['OVERRIDE','FORCE']]
sub popup_menu {
    my($self,@p,%p) = @_;
    if (@p && (substr($p[0],0,1) eq '-' || $self->use_named_parameters)) {
	 my($k,$v,$lck);
	 %p = @p;
	 foreach $k (keys %p) {
	     $lck = lc $k;
	     $lck = substr($k,1) if substr($k,0,1) eq "-";
	     $p{$lck} = $p{$k} if $lck ne $k;;
	 }
	 $p{'values'} ||= $p{value};
	 $p{default} ||= $p{'defaults'};
	 $p{override} ||= $p{force};
     } else {
	 @p{qw/ name values default labels override other/} = @p;
    }
    my($result,$selected);
    if (!$p{override} && defined($self->param($p{name}))) {
	 $selected = $self->param($p{name});
    } else {
	 $selected = $p{default};
    }
    $self->escapeHTML($p{name});
    $p{other} ||= '';
    my(@values) = $p{'values'} ? @{$p{'values'}} : $self->param($p{name});
    $result = qq/<SELECT NAME="$p{name}"$p{other}>\n/;
    foreach (@values) {
	 my($selectit) = defined($selected) ? ($selected eq $_ ? 'SELECTED' : '' ) : '';
	 my($label) = $_;
	 $label = $p{labels}->{$_} if defined($p{labels}) && $p{labels}->{$_};
	 my($value) = $_;
	 $self->escapeHTML($value);
	 $self->escapeHTML($label);
	 $result .= "<OPTION $selectit VALUE=\"$value\">$label\n";
    }
    $result .= "</SELECT>\n";
    return $result;
}

#### Method: scrolling_list
# Create a scrolling list.
# Parameters:
#   $name -> name for the list
#   $values -> A pointer to a regular array containing the
#             values for each option line in the list.
#   $defaults -> (optional)
#             1. If a pointer to a regular array of options,
#             then this will be used to decide which
#             lines to turn on by default.
#             2. Otherwise holds the value of the single line to turn on.
#   $size -> (optional) Size of the list.
#   $multiple -> (optional) If set, allow multiple selections.
#   $labels -> (optional)
#             A pointer to an associative array of labels to print next to each checkbox
#             in the form $label{'value'}="Long explanatory label".
#             Otherwise the provided values are used as the labels.
# Returns:
#   A string containing the definition of a scrolling list.
####
#sub scrolling_list {
#    my($self,@p) = @_;
#    my($name,$values,$defaults,$size,$multiple,$labels,$override,@other)
#	 = $self->rearrange(['NAME',['VALUES','VALUE'],['DEFAULTS','DEFAULT'],
#			     'SIZE','MULTIPLE','LABELS',['OVERRIDE','FORCE']],@p);
#
#    my($result);
#    my(@values) = $values ? @$values : $self->param($name);
#    $size = $size || scalar(@values);
#
#    my(%selected) = $self->previous_or_default($name,$defaults,$override);
#    my($is_multiple) = $multiple ? ' MULTIPLE' : '';
#    my($has_size) = $size ? " SIZE=$size" : '';
#    my($other) = join(" ",@other);
#
#    $self->escapeHTML($name);
#    $result = qq/<SELECT NAME="$name"$has_size$is_multiple$other>\n/;
#    foreach (@values) {
#	 my($selectit) = $selected{$_} ? 'SELECTED' : '';
#	 my($label) = $_;
#	 $label = $labels->{$_} if defined($labels) && $labels->{$_};
#	 $self->escapeHTML($label);
#	 my($value) = $_;
#	 $self->escapeHTML($value);
#	 $result .= "<OPTION $selectit VALUE=\"$value\">$label\n";
#    }
#    $result .= "</SELECT>\n";
#    return $result;
#}
##scrolling_list         name values defaults size multiple labels override other
 #                          ['NAME',['VALUES','VALUE'],['DEFAULTS','DEFAULT'], 'SIZE','MULTIPLE','LABELS',[
 #                          'OVERRIDE','FORCE']]
sub scrolling_list {
    my($self,@p,%p) = @_;
    if (@p && (substr($p[0],0,1) eq '-' || $self->use_named_parameters)) {
	 my($k,$v,$lck);
	 %p = @p;
	 foreach $k (keys %p) {
	     $lck = lc $k;
	     $lck = substr($k,1) if substr($k,0,1) eq "-";
	     $p{$lck} = $p{$k} if $lck ne $k;;
	 }
	 $p{'values'} ||= $p{value};
	 $p{'defaults'} ||= $p{default};
	 $p{override} ||= $p{force};
     } else {
	 @p{qw/ name values defaults size multiple labels override other/} = @p;
    }
    my($result);
    my(@values) = $p{'values'} ? @{$p{'values'}} : $self->param($p{name});
    $p{size} = $p{size} || scalar(@values);
    my(%selected) = $self->previous_or_default($p{name},$p{'defaults'},$p{override});
    my($is_multiple) = $p{multiple} ? ' MULTIPLE' : '';
    my($has_size) = $p{size} ? " SIZE=$p{size}" : '';
    $p{other} ||= '';
    $self->escapeHTML($p{name});
    $result = qq/<SELECT NAME="$p{name}"$has_size$is_multiple$p{other}>\n/;
    foreach (@values) {
	 my($selectit) = $selected{$_} ? 'SELECTED' : '';
	 my($label) = $_;
	 $label = $p{labels}->{$_} if defined($p{labels}) && $p{labels}->{$_};
	 $self->escapeHTML($label);
	 my($value) = $_;
	 $self->escapeHTML($value);
	 $result .= "<OPTION $selectit VALUE=\"$value\">$label\n";
    }
    $result .= "</SELECT>\n";
    return $result;
}

#### Method: hidden
# Parameters:
#   $name -> Name of the hidden field
#   @default -> (optional) Initial values of field (may be an array)
#      or
#   $default->[initial values of field]
# Returns:
#   A string containing a <INPUT TYPE="hidden" NAME="name" VALUE="value">
####
sub hidden {
    my($self,@p) = @_;

    # this is the one place where we departed from our standard
    # calling scheme, so we have to special-case (darn)
    my(@result,@value);
    my($name,$default,$override,@other) =
	 $self->rearrange(['NAME',['DEFAULT','VALUE','VALUES'],['OVERRIDE','FORCE']],@p);

    my $do_override = 0;
    if ( substr($p[0],0,1) eq '-' || $self->use_named_parameters ) {
	 @value = ref($default) ? @{$default} : $default;
	 $do_override = $override;
    } else {
	 foreach ($default,$override,@other) {
	     push(@value,$_) if defined($_);
	 }
    }

    # use previous values if override is not set
    my @prev = $self->param($name);
    @value = @prev if !$do_override && @prev;

    $self->escapeHTML($name);
    foreach (@value) {
	 $self->escapeHTML($_);
	 push(@result,qq/<INPUT TYPE="hidden" NAME="$name" VALUE="$_">/);
    }
    return wantarray ? @result : join('',@result);
}


#### Method: image_button
# Parameters:
#   $name -> Name of the button
#   $src ->  URL of the image source
#   $align -> Alignment style (TOP, BOTTOM or MIDDLE)
# Returns:
#   A string containing a <INPUT TYPE="image" NAME="name" SRC="url" ALIGN="alignment">
####
#sub image_button {
#    my($self,@p) = @_;
#
#    my($name,$src,$alignment,@other) =
#	 $self->rearrange(['NAME','SRC','ALIGN'],@p);
#
#    my($align) = $alignment ? " ALIGN=\U$alignment" : '';
#    my($other) = join(" ",@other);
#    $self->escapeHTML($name);
#    return qq/<INPUT TYPE="image" NAME="$name" SRC="$src"$align$other>/;
#}
##image_button           name src alignment other
 #                          ['NAME','SRC','ALIGN']
sub image_button {
    my($self,@p,%p) = @_;
    if (@p && (substr($p[0],0,1) eq '-' || $self->use_named_parameters)) {
	 my($k,$v,$lck);
	 %p = @p;
	 foreach $k (keys %p) {
	     $lck = lc $k;
	     $lck = substr($k,1) if substr($k,0,1) eq "-";
	     $p{$lck} = $p{$k} if $lck ne $k;;
	 }
     } else {
	 @p{qw/ name src align other/} = @p;
    }
    $p{align} = $p{align} ? " ALIGN=\U$p{align}" : '';
    $p{other} ||= '';
    $self->escapeHTML($p{name});
    return qq/<INPUT TYPE="image" NAME="$p{name}" SRC="$p{src}"$p{align}$p{other}>/;
}

#### Method: self_url
# Returns a URL containing the current script and all its
# param/value pairs arranged as a query.  You can use this
# to create a link that, when selected, will reinvoke the
# script with all its state information preserved.
####
sub self_url {
    my($self) = @_;
    my($query_string) = $self->query_string;
    my $protocol = $self->protocol();
    my $name = "$protocol://" . $self->server_name;
    $name .= ":" . $self->server_port
	unless $self->server_port == 80;
    $name .= $self->script_name;
    $name .= $self->path_info if $self->path_info;
    return $name unless $query_string;
    return "$name?$query_string";
}

# This is provided as a synonym to self_url() for people unfortunate
# enough to have incorporated it into their programs already!
*state= \&self_url;

#### Method: url
# Like self_url, but doesn't return the query string part of
# the URL.
####
sub url {
    my($self) = @_;
    my $protocol = $self->protocol();
    my $name = "$protocol://" . $self->server_name;
    $name .= ":" . $self->server_port
	unless $self->server_port == 80;
    $name .= $self->script_name;
    return $name;
}

#### Method: cookie
# Set or read a cookie from the specified name.
# Cookie can then be passed to header().
# Usual rules apply to the stickiness of -value.
#  Parameters:
#   -name -> name for this cookie (required)
#   -value -> value of this cookie (scalar, array or hash)
#   -path -> paths for which this cookie is valid (optional)
#   -domain -> internet domain in which this cookie is valid (optional)
#   -secure -> if true, cookie only passed through secure channel (optional)
#   -expires -> expiry date in format Wdy, DD-Mon-YY HH:MM:SS GMT (optional)
####
#sub cookie {
#    my($self,@p) = @_;
#    my($name,$value,$path,$domain,$secure,$expires) =
#	 $self->rearrange(['NAME',['VALUE','VALUES'],'PATH','DOMAIN','SECURE','EXPIRES'],@p);
#    # if no value is supplied, then we retrieve the
#    # value of the cookie, if any.  For efficiency, we cache the parsed
#    # cookie in our state variables.
#    unless (defined($value)) {
#	 unless ($self->{'.cookies'}) {
#	     my(@pairs) = split("; ",$self->raw_cookie);
#	     foreach (@pairs) {
#		 my($key,$value) = split("=");
#		 my(@values) = map unescape($_),split('&',$value);
#		 $self->{'.cookies'}->{unescape($key)} = [@values];
#	     }
#	 }
#	 return wantarray ? @{$self->{'.cookies'}->{$name}} : $self->{'.cookies'}->{$name}->[0];
#    }
#    my(@values);
#
#    # Pull out our parameters.
#    @values = map escape($_),
#	    ref($value) eq 'ARRAY' ? @$value : (ref($value) eq 'HASH' ? %$value : $value);
#
#    my(@constant_values);
#    push(@constant_values,"domain=$domain") if $domain;
#    push(@constant_values,"path=$path") if $path;
#    push(@constant_values,"expires=".&expires($expires)) if $expires;
#    push(@constant_values,'secure') if $secure;
#
#    my($key) = &escape($name);
#    my($cookie) = join("=",$key,join("&",@values));
#    return join("; ",$cookie,@constant_values);
#}
##cookie                 name value path domain secure expires
 #                          ['NAME',['VALUE','VALUES'],'PATH','DOMAIN','SECURE','EXPIRES']

sub cookie {
    my($self,@p,%p) = @_;
    if (@p && (substr($p[0],0,1) eq '-' || $self->use_named_parameters)) {
	my($k,$v,$lck);
	%p = @p;
	foreach $k (keys %p) {
	    $lck = lc $k;
	    $lck = substr($k,1) if substr($k,0,1) eq "-";
	    $p{$lck} = $p{$k} if $lck ne $k;;
	}
        $p{value} ||= $p{'values'};
     } else {
	@p{qw/ name value path domain secure expires/} = @p;
    }
    unless (defined($p{value})) {
	unless ($self->{'.cookies'}) {
	    my(@pairs) = split("; ",$self->raw_cookie);
            my($key);
	    foreach (@pairs) {
		($key,$p{value}) = split("=");
		my(@values) = map unescape($_),split('&',$p{value});
		$self->{'.cookies'}->{unescape($key)} = [@values];
	    }
	}
	return wantarray ? @{$self->{'.cookies'}->{$p{name}}} : $self->{'.cookies'}->{$p{name}}->[0];
    }
    my(@values);

    @values = map escape($_),
           ref($p{value}) eq 'ARRAY' ? @{$p{value}} : (ref($p{value}) eq 'HASH' ? %{$p{value}} : $p{value});

    my(@constant_values);
    push(@constant_values,"domain=$p{domain}") if $p{domain};
    push(@constant_values,"path=$p{path}") if $p{path};
    push(@constant_values,"expires=".&expires($p{expires})) if $p{expires};
    push(@constant_values,'secure') if $p{secure};

    my($key) = &escape($p{name});
    my($cookie) = join("=",$key,join("&",@values));
    return join("; ",$cookie,@constant_values);
}

# This internal routine creates an expires string exactly some number of
# hours from the current time in GMT.  This is the format
# required by Netscape cookies, and I think it works for the HTTP
# Expires: header as well.
sub expires {
    my($time) = @_;
    my(@MON)=qw/Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec/;
    my(@WDAY) = qw/Sunday Monday Tuesday Wednesday Thursday Friday Saturday/;
    my(%mult) = ('s'=>1,
		 'm'=>60,
		 'h'=>60*60,
		 'd'=>60*60*24,
		 'M'=>60*60*24*30,
		 'y'=>60*60*24*365);
    # format for time can be in any of the forms...
    # "now" -- expire immediately
    # "+180s" -- in 180 seconds
    # "+2m" -- in 2 minutes
    # "+12h" -- in 12 hours
    # "+1d"  -- in 1 day
    # "+3M"  -- in 3 months
    # "+2y"  -- in 2 years
    # "-3m"  -- 3 minutes ago(!)
    # If you don't supply one of these forms, we assume you are
    # specifying the date yourself
    my($offset);
    if (!$time || ($time eq 'now')) {
	$offset = 0;
    } elsif ($time=~/^([+-]?\d+)([mhdMy]?)/) {
	$offset = ($mult{$2} || 1)*$1;
    } else {
	return $time;
    }
    my($sec,$min,$hour,$mday,$mon,$year,$wday) = gmtime(time+$offset);
    return sprintf("%s, %02d-%s-%02d %02d:%02d:%02d GMT",
		   $WDAY[$wday],$mday,$MON[$mon],$year,$hour,$min,$sec);
}

###############################################
# OTHER INFORMATION PROVIDED BY THE ENVIRONMENT
###############################################

sub path_info       { return $ENV{'PATH_INFO'};      }
sub request_method  { return $ENV{'REQUEST_METHOD'}; }
sub path_translated { return $ENV{'PATH_TRANSLATED'};}

#### Method: query_string
# Synthesize a query string from our current
# parameters
####
sub query_string {
    my $self = shift;
    my($param,$value,@pairs);
    foreach $param ($self->param) {
	my($eparam) = &escape($param);
	foreach $value ($self->param($param)) {
	    $value = &escape($value);
	    push(@pairs,"$eparam=$value");
	}
    }
    return join("&",@pairs);
}

#### Method: accept
# Without parameters, returns an array of the
# MIME types the browser accepts.
# With a single parameter equal to a MIME
# type, will return undef if the browser won't
# accept it, 1 if the browser accepts it but
# doesn't give a preference, or a floating point
# value between 0.0 and 1.0 if the browser
# declares a quantitative score for it.
# This handles MIME type globs correctly.
####
sub accept {
    my($self,$search) = @_;
    my(%prefs,$type,$pref,$pat);

    my(@accept) = split(',',$self->http('accept'));

    foreach (@accept) {
	($pref) = /q=(\d\.\d+|\d+)/;
	($type) = m#(\S+/[^;]+)#;
	next unless $type;
	$prefs{$type}=$pref || 1;
    }

    return keys %prefs unless $search;

    # if a search type is provided, we may need to
    # perform a pattern matching operation.
    # The MIME types use a glob mechanism, which
    # is easily translated into a perl pattern match

    # First return the preference for directly supported
    # types:
    return $prefs{$search} if $prefs{$search};

    # Didn't get it, so try pattern matching.
    foreach (keys %prefs) {
	next unless /\*/;	# not a pattern match
	($pat = $_) =~ s/([^\w*])/\\$1/g; # escape meta characters
	$pat =~ s/\*/.*/g; # turn it into a pattern
	return $prefs{$_} if $search=~/$pat/;
    }
}

#### Method: user_agent
# If called with no parameters, returns the user agent.
# If called with one parameter, does a pattern match (case
# insensitive) on the user agent.
####
sub user_agent {
    my($self,$match)=@_;
    return $self->http('user_agent') unless $match;
    return $self->http('user_agent') =~ /$match/i;
}

#### Method: cookie
# Returns the magic cookie for the session.
# To set the magic cookie for new transations,
# try print $q->header('-Set-cookie'=>'my cookie')
####
sub raw_cookie {
    my($self) = @_;
    return $self->http('cookie') || '';
}

#### Method: remote_host
# Return the name of the remote host, or its IP
# address if unavailable.  If this variable isn't
# defined, it returns "localhost" for debugging
# purposes.
####
sub remote_host {
    return $ENV{'REMOTE_HOST'} || $ENV{'REMOTE_ADDR'}
    || 'localhost';
}

#### Method: remote_addr
# Return the IP addr of the remote host.
####
sub remote_addr {
    return $ENV{'REMOTE_ADDR'} || '127.0.0.1';
}

#### Method: script_name
# Return the partial URL to this script for
# self-referencing scripts.  Also see
# self_url(), which returns a URL with all state information
# preserved.
####
sub script_name {
    return $ENV{'SCRIPT_NAME'} if $ENV{'SCRIPT_NAME'};
    # These are for debugging
    return "/$0" unless $0=~/^\//;
    return $0;
}

#### Method: referer
# Return the HTTP_REFERER: useful for generating
# a GO BACK button.
####
sub referer {
    my($self) = @_;
    return $self->http('referer');
}

#### Method: server_name
# Return the name of the server
####
sub server_name {
    return $ENV{'SERVER_NAME'} || 'dummy.host.name';
}

#### Method: server_port
# Return the tcp/ip port the server is running on
####
sub server_port {
    return $ENV{'SERVER_PORT'} || 80; # for debugging
}

#### Method: server_protocol
# Return the protocol (usually HTTP/1.0)
####
sub server_protocol {
    return $ENV{'SERVER_PROTOCOL'} || 'HTTP/1.0'; # for debugging
}

#### Method: http
# Return the value of an HTTP variable, or
# the list of variables if none provided
####
sub http {
    my ($self,$parameter) = @_;
    return $ENV{$parameter} if $parameter=~/^HTTP/;
    return $ENV{"HTTP_\U$parameter\E"} if $parameter;
    my(@p);
    foreach (keys %ENV) {
	push(@p,$_) if /^HTTP/;
    }
    return @p;
}

#### Method: https
# Return the value of HTTPS
####
sub https {
    local($^W)=0;
    my ($self,$parameter) = @_;
    return $ENV{$parameter} if $parameter=~/^HTTPS/;
    return $ENV{"HTTPS_\U$parameter\E"} if $parameter;
    my(@p);
    foreach (keys %ENV) {
	push(@p,$_) if /^HTTPS/;
    }
    return @p;
}

#### Method: protocol
# Return the protocol (http or https currently)
####
sub protocol {
    my $self = shift;
    return 'https' if $self->https();
    return 'https' if $self->server_port == 443;
    my $prot = $self->server_protocol;
    return 'http' if $prot =~ /http/i;
    my($protocol,$version) = split('/',$prot);
    return "\L$protocol\E";
}

sub remote_ident { return $ENV{'REMOTE_IDENT'} }
sub auth_type    { return $ENV{'AUTH_TYPE'}    }
sub remote_user  { return $ENV{'REMOTE_USER'}  }

#### Method: user_name
# Try to return the remote user's name by hook or by
# crook
####
sub user_name {
    my ($self) = @_;
    return $self->http('from') || $ENV{'REMOTE_IDENT'} || $ENV{'REMOTE_USER'};
}

# Return true if we've been initialized with a query
# string.
sub inited {
    my($self) = shift;
    return $self->{'.init'};
}

# -------------- really private subroutines -----------------
# Smart rearrangement of parameters to allow named parameter
# calling.  We do the rearrangement if:
# 1. The first parameter begins with a -
# 2. The use_named_parameters() method returns true
sub rearrange {
    my($self,$order,@param) = @_;
    return () unless @param;

    return @param unless (defined($param[0]) && substr($param[0],0,1) eq '-')
	|| $self->use_named_parameters;

    my $i;
    for ($i=0;$i<@param;$i+=2) {
	$param[$i] =~ s/^\-//;     # get rid of initial - if present
	$param[$i] =~ tr/a-z/A-Z/; # parameters are upper case
    }

    my(%param) = @param;		# convert into associative array
    my(@return_array);

    my($key);
    foreach $key (@$order) {
	my($value);
	# this is an awful hack to fix spurious warnings when the
	# -w switch is set.
	if (ref($key) && ref($key) eq 'ARRAY') {
	    foreach (@$key) {
		$value = $param{$_} unless defined($value);
		delete $param{$_};
	    }
	} else {
	    $value = $param{$key};
	}
	delete $param{$key};
	push(@return_array,$value);
    }
    push (@return_array,$self->make_attributes(\%param)) if %param;
    return (@return_array);
}

sub previous_or_default {
    my($self,$name,$defaults,$override) = @_;
    my(%selected);

    if (!$override && ($self->inited || $self->param($name))) {
	grep($selected{$_}++,$self->param($name));
    } elsif (defined($defaults) && ref($defaults) &&
	     (ref($defaults) eq 'ARRAY')) {
	grep($selected{$_}++,@{$defaults});
    } else {
	$selected{$defaults}++ if defined($defaults);
    }

    return %selected;
}

sub read_from_cmdline {
    require Text::ParseWords;
    my($input,@words,@lines);
    my($query_string);
    if (@ARGV) {
	$input = join(" ",@ARGV);
    } else {
	print STDERR "(offline mode: enter name=value pairs on standard input)\n";
	chomp(@lines = <>); # remove newlines
	$input = join(" ",@lines);
    }

    # minimal handling of escape characters
    $input=~s/\\=/%3D/g;
    $input=~s/\\&/%26/g;

    @words = Text::ParseWords::shellwords($input);
    if ("@words"=~/=/) {
	$query_string = join('&',@words);
    } else {
	$query_string = join('+',@words);
    }
    return $query_string;
}

#####
# subroutine: read_multipart
#
# Read multipart data and store it into our parameters.
# An interesting feature is that if any of the parts is a file, we
# create a temporary file and open up a filehandle on it so that the
# caller can read from it if necessary.
#####
sub read_multipart {
    my($self,$boundary,$length) = @_;
    my($buffer) = $self->new_MultipartBuffer($boundary,$length);
    return unless $buffer;
    my(%header,$body);
    while (!$buffer->eof) {
	%header = $buffer->readHeader;
	# In beta1 it was "Content-disposition".  In beta2 it's "Content-Disposition"
	# Sheesh.
	my($key) = $header{'Content-disposition'} ? 'Content-disposition' : 'Content-Disposition';
	my($param)= $header{$key}=~/ name="([^\"]*)"/;

	# possible bug: our regular expression expects the filename= part to fall
	# at the end of the line.  Netscape doesn't escape quotation marks in file names!!!
	my($filename) = $header{$key} =~ / filename="(.*)"$/;

	# add this parameter to our list
	$self->add_parameter($param);

	# If no filename specified, then just read the data and assign it
	# to our parameter list.
	unless ($filename) {
	    my($value) = $buffer->readBody;
	    push(@{$self->{$param}},$value);
	    next;
	}

	# If we get here, then we are dealing with a potentially large
	# uploaded form.  Save the data to a temporary file, then open
	# the file for reading.
	my($tmpfileobj) = CGI::XA::TempFile->new;
	my($tmpfile)    = $tmpfileobj->as_string;
	my $out = new FileHandle;
	open $out, ">$tmpfile" or die "CGI::XA open of $tmpfile: $!\n";
	chmod 0666,$tmpfile;	# make sure anyone can delete it.
	my $data;
	while ($data = $buffer->read) {
	    print $out $data;
	}
	close $out;

	# Now create a new filehandle in the caller's namespace.
	# The name of this filehandle just happens to be identical
	# to the original filename (NOT the name of the temporary
        # file, which is hidden!)

	# We break compatibility to Lincoln's package here, because we
	# think we cannot accept the main::namespace for all filenames
	# starting with a dot. We delete leading non-alphas instead

	my($filehandle);
	$filename =~ s/^[^A-Za-z_]+//;
	$filename ||= "CGI_generated_filename"; # if the filename has no letters at all
	my($frame,$cp)=(1);
	do { $cp = caller($frame++); } until !eval{$cp->isaCGI()};
	$filehandle = "$cp\::$filename";

	{
	    no strict;
	    open($filehandle,$tmpfile) || die "CGI open of $tmpfile: $!\n";
	}

	$tmpfileobj->_opened_with($filehandle);
	push(@{$self->{$param}},$filename);

	# Under Unix, it would be safe to let the temporary file
	# be deleted immediately.  However, I fear that other operating
	# systems are not so forgiving.  Therefore we save a reference
	# to the temporary file in the CGI object so that the file
	# isn't unlinked until the CGI object itself goes out of
	# scope.  This is a bit hacky, but it has the interesting side
	# effect that one can access the name of the tmpfile by
	# asking for $query->{$query->param('foo')}, where 'foo'
	# is the name of the file upload field.
	$self->{'.tmpfiles'}->{$filename}=$tmpfileobj;
    }
}

sub DESTROY {
    my($self) = shift;
    delete $self->{'.tmpfiles'};
}

# Globals and stubs for other packages that we use
package CGI::XA::MultipartBuffer;

use vars qw(@ISA $FILLUNIT $TIMEOUT $SPIN_LOOP_MAX $CRLF);
@ISA = qw(CGI::XA);

# how many bytes to read at a time.  We use
# a 5K buffer by default.

$FILLUNIT      = 1024 * 5;
$TIMEOUT       = 10*60;           # 10 minute timeout
$SPIN_LOOP_MAX = 1000;	          # bug fix for some Netscape servers
$CRLF          = $CGI::XA::CRLF;

sub new {
    my($package,$interface,$boundary,$length,$filehandle) = @_;
    my $IN;
    if ($filehandle) {
	my($package) = caller;
	# force into caller's package if necessary
	$IN = $filehandle=~/[\':]/ ? $filehandle : "$package\:\:$filehandle";
    }
    $IN ||= \*STDIN;

    # If the user types garbage into the file upload field,
    # then Netscape passes NOTHING to the server (not good).
    # We may hang on this read in that case. So we implement
    # a read timeout.  If nothing is ready to read
    # by then, we return.

    # Netscape seems to be a little bit unreliable
    # about providing boundary strings.
    if ($boundary) {

	# Under the MIME spec, the boundary consists of the
	# characters "--" PLUS the Boundary string
	$boundary = "--$boundary";
	# Read the topmost (boundary) line plus the CRLF
	my($null) = '';
	$length -= $interface->read_from_client($IN,\$null,length($boundary)+2,0);

    } else { # otherwise we find it ourselves
	my($old);
	($old,$/) = ($/,$CRLF);	# read a CRLF-delimited line
	$boundary = <$IN>;	# BUG: This won't work correctly under mod_perl
	$length -= length($boundary);
	chomp($boundary);		# remove the CRLF
	$/ = $old;			# restore old line separator
    }

    my $self = {LENGTH=>$length,
		BOUNDARY=>$boundary,
		IN=>$IN,
		INTERFACE=>$interface,
		BUFFER=>'',
	    };

    $FILLUNIT = length($boundary)
	if length($boundary) > $FILLUNIT;

    return bless $self,ref $package || $package;
}

sub readHeader {
    my($self) = @_;
    my($end);
    my($ok) = 0;
    do {
	$self->fillBuffer($FILLUNIT);
	$ok++ if ($end = index($self->{BUFFER},"${CRLF}${CRLF}")) >= 0;
	$ok++ if $self->{BUFFER} eq '';
	$FILLUNIT *= 2 if length($self->{BUFFER}) >= $FILLUNIT;	
    } until $ok;

    my($header) = substr($self->{BUFFER},0,$end+2);
    substr($self->{BUFFER},0,$end+4) = '';
    my %return;
    while ($header=~/^([\w-]+): (.*)$CRLF/mog) {
	$return{$1}=$2;
    }
    return %return;
}

# This reads and returns the body as a single scalar value.
sub readBody {
    my($self) = @_;
    my($data);
    my($returnval)='';
    while (defined($data = $self->read)) {
	$returnval .= $data;
    }
    return $returnval;
}

# This will read $bytes or until the boundary is hit, whichever happens
# first.  After the boundary is hit, we return undef.  The next read will
# skip over the boundary and begin reading again;
sub read {
    my($self,$bytes) = @_;

    # default number of bytes to read
    $bytes ||= $FILLUNIT;	

    # Fill up our internal buffer in such a way that the boundary
    # is never split between reads.
    $self->fillBuffer($bytes);

    # Find the boundary in the buffer (it may not be there).
    my $start = index($self->{BUFFER},$self->{BOUNDARY});

    # If the boundary begins the data, then skip past it
    # and return undef.  The +2 here is a fiendish plot to
    # remove the CR/LF pair at the end of the boundary.
    if ($start == 0) {

	# clear us out completely if we've hit the last boundary.
	if (index($self->{BUFFER},"$self->{BOUNDARY}--")==0) {
	    $self->{BUFFER}='';
	    $self->{LENGTH}=0;
	    return undef;
	}

	# just remove the boundary.
	substr($self->{BUFFER},0,length($self->{BOUNDARY})+2)='';
	return undef;
    }

    my $bytesToReturn;
    if ($start > 0) {		# read up to the boundary
	$bytesToReturn = $start > $bytes ? $bytes : $start;
    } else {	# read the requested number of bytes
	# leave enough bytes in the buffer to allow us to read
	# the boundary.  Thanks to Kevin Hendrick for finding
	# this one.
	$bytesToReturn = $bytes - (length($self->{BOUNDARY})+1);
    }

    my $returnval=substr($self->{BUFFER},0,$bytesToReturn);
    substr($self->{BUFFER},0,$bytesToReturn)='';

    # If we hit the boundary, remove the CRLF from the end.
    return ($start > 0) ? substr($returnval,0,-2) : $returnval;
}

# This fills up our internal buffer in such a way that the
# boundary is never split between reads
sub fillBuffer {
    my($self,$bytes) = @_;
    return unless $self->{LENGTH};

    my($boundaryLength) = length($self->{BOUNDARY});
    my($bufferLength) = length($self->{BUFFER});
    my($bytesToRead) = $bytes - $bufferLength + $boundaryLength + 2;
    $bytesToRead = $self->{LENGTH} if $self->{LENGTH} < $bytesToRead;

    # Try to read some data.  We may hang here if the browser is screwed up.
#    $SIG{__WARN__} = $SIG{__DIE__} = sub { warn Carp::longmess(); };
#    warn "$self ref ".ref $self;
    my $bytesRead = $self->read_from_client(
					    $self->{IN},
					    \$self->{BUFFER},
					    $bytesToRead,
					    $bufferLength
					   );

    # An apparent bug in the Netscape Commerce server causes the read()
    # to return zero bytes repeatedly without blocking if the
    # remote user aborts during a file transfer.  I don't know how
    # they manage this, but the workaround is to abort if we get
    # more than SPIN_LOOP_MAX consecutive zero reads.
    if ($bytesRead == 0) {
	die  "CGI.pm: Server closed socket during multipart read (client aborted?).\n"
	    if ($self->{ZERO_LOOP_COUNTER}++ >= $SPIN_LOOP_MAX);
    } else {
	$self->{ZERO_LOOP_COUNTER}=0;
    }

    $self->{LENGTH} -= $bytesRead;
}


# Return true when we've finished reading
sub eof {
    my($self) = @_;
    return 1 if (length($self->{BUFFER}) == 0)
	&& ($self->{LENGTH} <= 0);
}

####################################################################################
################################## TEMPORARY FILES #################################
####################################################################################
package CGI::XA::TempFile;

use vars qw($SL $TMPDIRECTORY $SEQUENCE);

$SL = $CGI::XA::SL;
{
    my @temp=("${SL}usr${SL}tmp","${SL}var${SL}tmp","${SL}tmp","${SL}temp","${SL}Temporary Items");
    foreach (@temp) {
	$TMPDIRECTORY = $_, last if -w $_;
    }
    $TMPDIRECTORY  ||= "." ;
}
$SEQUENCE="CGItemp$$0000";

sub as_string {
    my($self) = @_;
    return $self->[0];
}

sub new {
    my($package) = @_;
    my $file = "$TMPDIRECTORY$SL" . ++$SEQUENCE;
    return bless [$file], $package;
}

#
# keep a record of the filehandle for this file
#
sub _opened_with {
    my($self,$fh) = @_;
    $self->[1] = $fh;
}

sub DESTROY {
    my($self) = @_;
    # warn "destroying filename [$self->[0]] handle [$self->[1]]\n";
    unlink $self->[0];		# get rid of the file
    {
	no strict;
	my $fh = $self->[1];
	close $fh if fileno($fh);
	undef($fh) if defined($fh);
    }
}

package CGI::XA;

$Revision;

__END__

=head1 NAME

CGI::XA - Clone of CGI.pm with less backwards compatibility and less namespace pollution

=head1 SYNOPSIS

  use CGI::XA;
  # then follow the CGI.pm docs and see if it does the same.

=head1 BE AWARE, THIS IS ALPHA SOFTWARE

It's main purpose is to start a discussion about CGI.pm. Maybe parts
of this will be folded back to CGI.pm, and then probably this module
won't be developed any further.

=head1 DESCRIPTION

I have started with major hacks on top of Lincoln's version 2.23 of
CGI.pm in order to get rid of both AUTOLOADING and uncontrolled
global variables.

I release this package as CGI::XA (which stands for "for Apache")
for a limited audience as a test case.

This software is alpha software and it is not clear if it will be
supported for a longer time. My preferred solution would be, Lincoln
accepts (most of) the changes and continues with his excellent work.

=head2 where are the main differences?

    No AUTOLOAD
    use strict clean
    no exports
    no cgi-lib.pl compatibility
    no "Q" namespace
    abandoned the rearrange method in several places

=head2 DOCUMENTATION

is in CGI.pm with which we are quite compatible with. See comments in
the code. If you could supply test cases for methods that are not
depending on a browser, we'd be glad to hear from you.

=head1 AUTHOR

Lincoln D. Stein is th author of the original code which was the basis
for this development. Responsibility is with Andreas König
E<lt>andreas.koenig@mind.deE<gt>

=head1 SEE ALSO

perl(1), Apache(3), Apache::Switch(3).

=cut

