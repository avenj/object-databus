package Object::DataBus::Debugger;

use Data::Dumper ();
use Types::Standard -types;

use Moo;

has bus => (
  required  => 1,
  is        => 'ro',
  isa       => ConsumerOf['Object::DataBus::Role::Broadcast'],
  trigger   => sub {
    my ($self, $val) = @_;
    $val->subscribe($self);
  },
);

sub _bus_dispatch {
  my ($self, $msg) = @_;
  print Data::Dumper::Dumper($msg);
}

1;
