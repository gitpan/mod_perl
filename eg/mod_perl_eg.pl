
#example script for use with mod_perl
#make sure this is not in a ScriptAlias'd directory

use Apache ();

my $req = Apache->request;

my $host = $req->get_remote_host;
my $user = $req->connection->user;

$req->content_type("text/html");
$req->send_http_header;  # actually start a reply

$req->write_client (
      "Hey you from $host! <br>\n",
      "I bet your name is $user. <br>\n",
      "Yippe! <hr>\n",
);
