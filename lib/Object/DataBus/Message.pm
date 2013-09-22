package Object::DataBus::Message;
use strictures 1;

use Carp;
use Scalar::Util 'blessed', 'weaken';

use namespace::clean;

sub BUS  () { 0 }
sub OBJ  () { 1 }
sub DATA () { 2 }
sub PKG  () { 3 }


sub _obj  { $_[0]->[OBJ] }
sub _bus  { $_[0]->[BUS] }

sub data { $_[0]->[DATA] }
sub pkg  { $_[0]->[PKG] }


sub new {
  my ($class, %params) = @_;

  confess 
   "Expected 'bus =>' to be an Object::DataBus::Role::Broadcast consumer"
   unless $params{bus}->does('Object::DataBus::Role::Broadcast');

  my $self = [
    # Internals:
    $params{bus},     # BUS
    $params{object},  # OBJ
    # Payload:
    $params{data},    # DATA
    $params{pkg},     # PKG
  ];
  weaken $self->[0];
  weaken $self->[1] if $self->[1];
  bless $self, $class
}

sub clone_for {
  my ($self, $obj) = @_;
  my $clone = [ @$self ];
  weaken $clone->[0]; weaken $clone->[1];
  bless $clone, blessed($self)
}


# 'Traveller' methods
sub alias {
  my ($self) = @_;
  $self->_bus ? $self->_bus->alias : ()
}

sub broadcast {
  my ($self) = @_;
  unless ($self->_bus) {
    carp 'broadcast() called but bus has gone away';
    return
  }
  $self->_bus->broadcast(@_)
}

sub unsubscribe {
  my ($self) = @_;
  $self->_bus ? $self->_bus->unsubscribe( $self->_obj ) : ()
}

1;

=pod

=head1 NAME

Object::DataBus::Message - An encapsulated data bus message

=head1 SYNOPSIS

  # In a subscriber class ->
  sub _bus_dispatch {
    my ($self, $bmsg) = @_;

    my $data = $bmsg->data;
    my $from = $bmsg->alias;

    # ... do work, re-dispatch, whatever ...

    # Send another message:
    $bmsg->broadcast( ack => 1 );

    # Unsubscribe from the bus:
    $bmsg->unsubscribe;
  }

=head1 DESCRIPTION

These objects encapsulate a message delivered by an L<Object::DataBus>. They
are created when L<Object::DataBus::Role::Broadcast/"broadcast"> is called;
you shouldn't normally need to construct them yourself (unless overriding
default broadcast behavior).

These are "traveller" objects of sorts; they carry along a weak reference to
the bus, so that the receiving end can call relevant methods. See
L</"Traveller methods">.

=head2 Message methods

=head3 data

Returns the data payload attached to the message.

=head3 pkg

Returns the caller package that originally broadcast the message.

=head2 Traveller methods

These methods are proxied to the L<Object::DataBus> that spawned the message.

=head3 alias

Returns the alias of the sender bus, or an empty list if the bus has gone
away.

See L<Object::DataBus::Role::Broadcast/"alias">.

=head3 broadcast

Broadcast some data via the bus.

See L<Object::DataBus::Role::Broadcast/"broadcast">.

Warns and returns an empty list if the bus has gone away.

=head3 unsubscribe

Unsubscribes the current object from the bus.

See L<Object::DataBus::Role::Broadcast/"unsubscribe">.

A subscriber object can only unsubscribe itself via this method.

Returns the empty list if the bus has gone away.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>


=cut
