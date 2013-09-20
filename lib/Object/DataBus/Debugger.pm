package Object::DataBus::Debugger;
use strictures 1;
use Data::Dumper 'Dumper';
use namespace::clean;

sub new { bless [], shift }

sub _bus_dispatch {
  my ($self, $msg) = @_;
  print Dumper $msg
}

1;
