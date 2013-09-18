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

FIXME

=head1 DESCRIPTION

=head2 Message methods

=head3 data

FIXME

=head3 pkg

FIXME

=head2 Traveller methods

These methods are proxied to the L<Object::DataBus> that spawned the message.

=head3 alias

FIXME

=head3 broadcast

FIXME

=head3 unsubscribe

FIXME

=head2 Construction methods

(These are only useful if you are implementing a
L<Object::DataBus::Role::Broadcast> consumer; there is no need to construct
your own L<Object::DataBus::Message> prior to sending.)

=head3 new

=head3 clone_for

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>


=cut
