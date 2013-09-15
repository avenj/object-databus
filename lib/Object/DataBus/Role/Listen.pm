package Object::DataBus::Role::Listen;
use strictures 1;

use List::Objects::WithUtils;

use Role::Tiny;
use namespace::clean;


sub _bus_dispatch {
  my ($self, $msg) = @_;
  my $data  = $msg->data;

  # Default pulls a method/event name from first data item:
  my $event = $data->get(0);
  # ... and tries method dispatch:
  if (my $sub = $self->can('recv_'.$event)) {
    my $parsed = array( $data->all );
    $parsed->shift;
    return $self->$sub( $parsed )
  }

  ()
}


1;
