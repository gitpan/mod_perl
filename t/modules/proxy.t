use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest;

my $module = 'TestModules::proxy';

Apache::TestRequest::module($module);
my $path     = Apache::TestRequest::module2path($module);
my $config   = Apache::Test::config();
my $hostport = Apache::TestRequest::hostport($config);
t_debug("connecting to $hostport");

plan tests => 1, (need_module('proxy') &&
                  need_access);

my $expected = "ok";
my $received = GET_BODY_ASSERT "http://$hostport/$path";;
ok t_cmp($received, $expected, "internally proxified request");
