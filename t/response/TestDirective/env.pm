package TestDirective::env;

use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestUtil;

use Apache::RequestRec ();
use APR::Table ();

use Apache::Const -compile => 'OK';

sub handler {
    my $r = shift;

    plan $r, tests => 8;

    # %ENV
    ok t_cmp('env_dir1', 
             env_get('srv1'),
             '%ENV per-dir override per-srv');

    ok t_cmp('env_srv2', 
             env_get('srv2'),
             '%ENV per-srv');

    ok t_cmp('env_dir2', 
             env_get('dir2'),
             '%ENV per-dir');

    # setup by Apache::TestRun
    ok t_cmp('test.host.name',
             $ENV{APACHE_TEST_HOSTNAME},
             '%ENV PerlPassEnv');

    # $r->subprocess_env
    ok t_cmp('env_dir1', 
             env_get('srv1', $r),
             '$r->subprocess_env per-dir override per-srv');

    ok t_cmp('env_srv2', 
             env_get('srv2', $r),
             '$r->subprocess_env per-srv');

    ok t_cmp('env_dir2', 
             env_get('dir2', $r),
             '$r->subprocess_env per-dir');

    # setup by Apache::TestRun
    ok t_cmp('test.host.name',
             $r->subprocess_env->get('APACHE_TEST_HOSTNAME'),
             '$r->subprocess_env PerlPassEnv');

    Apache::OK;
}

sub env_get {
    my($name, $r) = @_;
    my $key = 'TestDirective__env_' . $name;

    my $value = $ENV{$key};

    if ($r) {
        my @values = $r->subprocess_env->get($key);

        if (@values > 1) {
            $value = "too many values for $key!";
        }
        else {
            $value = $values[0];
        }
    }

    return $value;
}

1;
__END__
# SetupEnv ought to have no effect on PerlSetEnv or PerlPassEnv
PerlOptions -SetupEnv

<Base>
    # per-server entry overwritten by per-directory entry
    PerlSetEnv TestDirective__env_srv1 env_srv1

    # per-server entry not overwritten
    PerlSetEnv TestDirective__env_srv2 env_srv2

    # PerlPassEnv is only per-server
    PerlPassEnv APACHE_TEST_HOSTNAME
</Base>

# per-directory entry overwrites per-server
PerlSetEnv TestDirective__env_srv1 env_dir1

# PerlSetEnv resets the table for each directive
PerlSetEnv TestDirective__env_dir2 ToBeLost
PerlSetEnv TestDirective__env_dir2 env_dir2

