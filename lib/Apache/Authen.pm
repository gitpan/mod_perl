package Apache::Authen;

use HTTPD::UserAdmin ();

#XXX get this with DBD::mSQL
#$SIG{__WARN__} = sub {
#    $_[0] =~ /Database handle destroyed without explicit disconnect/ && return;
#    warn(@_);
#};

sub handler {
    my($self, $r, $attr) = @_;
    my($res, $sent_pwd, $passwd);

    ($res, $sent_pwd) = $r->get_basic_auth_pw;
    return $res if $res; #decline if not Basic
    
    my $user = $r->connection->user;

    my $u = HTTPD::UserAdmin->new(%$attr);
    unless($passwd = $u->password($user)) {
	$r->log_reason("User '$user' not found", $r->uri);
	$r->note_basic_auth_failure;
	return 401;
    }

    unless(crypt($sent_pwd, $passwd) eq $passwd) {
	$r->log_reason("user $user: password mismatch", $r->uri);
	$r->note_basic_auth_failure;
	return 401;
    }
    return 200;
}

package Apache::DBIAuthen;

%Config = (
    AuthDBIDB => "",
    AuthDBIUserTable => "",
    AuthDBIDriver => "",
    AuthDBINameField => "user",
    AuthDBIPasswordField => "password",
    AuthDBIUser => "",
    AuthDBIAuth => "",	   
);

sub handler {
    my($r) = @_;
    my($key,$val);
    my $attr = {
	DBType => 'SQL',
    };
    while(($key,$val) = each %Config) {
	$val = $r->dir_config($key) || $val;
	$key =~ s/^AuthDBI//; 
	$attr->{$key} = $val;
    }
    $attr->{DB} = delete $attr->{User} if #bleh, inconsistent
	$attr->{Driver} eq "mSQL";
     
    Apache::Authen->handler($r, $attr);
}

1;

__END__

=head1 NAME

Apache::Authen - Perl Apache authentication handlers

=head1 SYNOPSIS

 #httpd.conf or srm.conf

 PerlModule Apache::Authen

 #.htaccess
 AuthName DBI
 AuthType Basic

 #authenticate via DBI
 PerlAuthenHandler Apache::DBIAuthen::handler

 PerlSetVar AuthDBIDB     dbname
 PerlSetVar AuthDBIUser   username
 PerlSetVar AuthDBIAuth   password
 PerlSetVar AuthDBIDriver Oracle
 #DBI->connect(qw(AuthDBIDB AuthDBIUser AuthDBIAuth AuthDBIDriver))

 PerlSetVar AuthDBIUserTable www_users
 PerlSetVar AuthDBINameField user
 PerlSetVar AuthDBIPasswordField password

<Limit GET POST>
require valid-user
</Limit>

=head1 DESCRIPTION

With the PerlAuthenHandler set, you may define a subroutine handler
to preform the authentication check.
This module provides some building blocks and some full-fledged handlers.

=head1 HANDLERS

=item Apache::AuthenDBI::handler

This handler authenticates against a database such as Oracle, DB2, Sybase,
and others supported by the DBI module.
For supported drivers see:
http://www.hermetica.com/technologia/DBI

This handler users L<HTTPD::UserAdmin> to lookup the username and password.
This may change.

=head1 SEE ALSO

Apache(3), HTTPD::UserAdmin(3), DBI(3)

=head1 AUTHOR

Doug MacEachern <dougm@osf.org>
