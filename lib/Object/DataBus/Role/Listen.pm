package Object::DataBus::Role::Listen;
use strictures 1;

use List::Objects::WithUtils;

use Role::Tiny;
use namespace::clean;


sub _bus_dispatch {
  my ($self, $msg) = @_;
  # Default pulls a method/event name from first data item:
  my $event = $msg->data->get(0);
  # ... and tries method dispatch:
  if (my $sub = $self->can('recv_'.$event)) {
    return $self->$sub( $msg )
  }

  ()
}


1;

=pod

=head1 NAME

Object::DataBus::Role::Listen - Simple dispatch for data bus messages

=head1 SYNOPSIS

  package My::Subscriber;

  use Moo;
  with 'Object::DataBus::Role::Listen';

  sub recv_foo {
    my ($self, $bmsg) = @_;
    my (undef, @params) = $bmsg->data->all;

    ...

    $bmsg->broadcast( bar => qw/baz quux/ )
  }

=head1 DESCRIPTION

This is a (purely optional) role for simple L<Object::DataBus> subscriber
objects.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
