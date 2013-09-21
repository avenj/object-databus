use Test::More;
use strict; use warnings FATAL => 'all';

# Test covers:
#   - Object::DataBus subscription
#     - attribute defaults
#   - Object::DataBus::Role::Listen
#     - Message dispatch
#     - Message payloads

BEGIN { use_ok 'Object::DataBus' }

my $got = {};
my $expected = {
  'got event foo'               => 2,
  'event foo got Message'       => 2,
  'event foo data is immutable' => 2,
};

# Bare Role::Listen consumer:
{ package
    My::SimpleSub;
  use strict; use warnings FATAL => 'all';
  use Test::More;
  use Moo;
  with 'Object::DataBus::Role::Listen';
  sub recv_foo {
    my ($self, $bmsg) = @_;
    $got->{'got event foo'}++;

    if ($bmsg->isa('Object::DataBus::Message')) {
      $got->{'event foo got Message'}++
    } else {
      die "Expected Message object, got $bmsg"
    }

    if ($bmsg->data->isa('List::Objects::WithUtils::Array::Immutable')) {
      $got->{'event foo data is immutable'}++
    } else {
      die "Expected an immarray object but got ".$bmsg->data
    }

    my @arr = $bmsg->data->all;
    is_deeply \@arr, [ foo => 'bar', 'baz' ],
      'data looks ok';
  }
}

my $bus = new_ok 'Object::DataBus';
my $first  = My::SimpleSub->new;
my $second = My::SimpleSub->new;

ok $bus->subscribe( $first ), 'subscribed first obj';
ok $bus->subscribe( $second ), 'subscribed second obj';

ok $bus->broadcast( foo => qw/bar baz/ ), 'broadcast returned true';
is_deeply $got, $expected, 'subscriber results look ok';

ok $bus->alias eq "$bus", 'bus default alias ok';
ok $bus->dispatch_to eq '_bus_dispatch', 'bus dispatch_to ok';
ok $bus->message_discipline == 0, 'bus default message_discipline ok';

ok $bus->subscribers == 2, 'subscribers returned 2 values';
for my $obj ($bus->subscribers) {
  isa_ok $obj, 'My::SimpleSub', 'subscribers returned obj ok';
}

# weaken =>
$bus->subscribe( My::SimpleSub->new );
ok $bus->subscribers == 2, 'weak ref to sub went away';
$bus->subscribe( My::SimpleSub->new, weaken => 0 );
ok $bus->subscribers == 3, 'non-weak ref sub stuck around';

done_testing;
