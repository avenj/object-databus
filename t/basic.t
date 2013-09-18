use Test::More;
use strict; use warnings FATAL => 'all';

BEGIN { use_ok 'Object::DataBus' }

my $got = {};
my $expected = {
  'got event foo'          => 2,
  'event foo correct args' => 2,
};

{ package
    My::SimpleSub;
  use strict; use warnings FATAL => 'all';
  use Moo;
  with 'Object::DataBus::Role::Listen';
  sub recv_foo {
    my ($self, $bmsg) = @_;
    $got->{'got event foo'}++;

    if ($bmsg->isa('Object::DataBus::Message')) {
      $got->{'event foo correct args'}++
    }
  }
}

my $bus = new_ok 'Object::DataBus';
my $first  = My::SimpleSub->new;
my $second = My::SimpleSub->new;

ok $bus->subscribe( $first ), 'subscribed first obj';
ok $bus->subscribe( $second ), 'subscribed second obj';

ok $bus->broadcast( foo => qw/bar baz/ ), 'broadcast returned true';
is_deeply $got, $expected, 'subscriber results look ok';

ok $bus->subscribers == 2, 'subscribers returned 2 values';
for my $obj ($bus->subscribers) {
  isa_ok $obj, 'My::SimpleSub', 'subscribers returned obj ok';
}

done_testing;
