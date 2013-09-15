package Object::DataBus::Traveller;
use strictures 1;

use Types::Standard -types;

use Moo;
use namespace::clean;

has _bus => (
  is        => 'ro',
  isa       => ConsumerOf['Object::DataBus::Role::Broadcast'],
  init_arg  => 'bus',
  required  => 1,
  weak_ref  => 1,
);

sub alias { shift->alias }

sub broadcast {
  shift->_bus->broadcast(@_)
}

sub subscriber_del {
  shift->_bus->subscriber_del(@_)
}

1;
