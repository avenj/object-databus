use Test::More;
use strict; use warnings FATAL => 'all';

BEGIN { use_ok 'Object::DataBus' }

# Test covers:
#   - Object::DataBus subscribe/unsubscribe
# FIXME - ->unsubscribe_all
# FIXME - Object destruction / weaken => 0

my $got = {};
my $expected = {
  'got event foo' => 3,
};

{ package
    My::SimpleSub;
  use strict; use warnings FATAL => 'all';
  use Moo;
  with 'Object::DataBus::Role::Listen';
  sub recv_foo {
    my ($self, $bmsg) = @_;
    $got->{'got event foo'}++;
  }
}

my $bus = new_ok 'Object::DataBus';
my $first  = My::SimpleSub->new;
my $second = My::SimpleSub->new;

$bus->subscribe( $_ ) for $first, $second;

$bus->broadcast( foo => qw/bar baz/ );
ok $bus->unsubscribe( $first ), 'unsubscribed first obj';

$bus->broadcast( foo => qw/bar baz/ );
is_deeply $got, $expected, 'subscriber results look ok';

ok $bus->subscribers == 1, 'subscribers returned 1 values';

done_testing;
