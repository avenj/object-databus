package Object::DataBus::Role::Broadcast;
use strictures 1;

use Carp;
use Data::Dumper ();
use Scalar::Util 'blessed', 'refaddr', 'weaken';

use List::Objects::WithUtils ':functions';
use List::Objects::Types -all;
use Types::Standard -all;

use Object::DataBus::Message;


use Moo::Role;
use namespace::clean;


has alias => (
  is        => 'ro',
  isa       => Str,
  default   => sub { my ($self) = @_; "$self" },
);

has dispatch_to => (
  lazy      => 1,
  is        => 'ro',
  isa       => Str,
  default   => sub { '_bus_dispatch' },
);

has message_discipline => (
  is        => 'ro',
  isa       => Bool,
  default   => sub { 0 },
);

has _subbed => (
  is        => 'ro',
  isa       => HashObj,
  default   => sub { hash },
);

sub subscribers {
  my ($self) = @_;
  for my $kv ($self->_subbed->kv->all) {
    # Clear out-of-scope objects.
    $self->_subbed->delete( $kv->[0] ) unless defined $kv->[1]
  }
  $self->_subbed->values->all
}

sub subscribe {
  my ($self, $obj, %params) = @_;
  confess "Expected a blessed object but got $obj"
    unless blessed $obj;
  $self->_subbed->set( refaddr($obj) => $obj );
  unless (defined $params{weaken} && !$params{weaken}) {
    weaken $self->_subbed->{refaddr($obj)}
  }
  1
}

sub unsubscribe {
  my ($self, $obj) = @_;
  $self->_subbed->delete( refaddr($obj) ) ? 1 : ()
}

sub unsubscribe_all {
  my ($self) = @_;
  $self->_subbed->clear;
  1
}

sub broadcast {
  my ($self, @data) = @_;

  my $msg = $self->_pack_bus_msg(@data);
  if ($self->message_discipline) {
    return unless $self->_validate_bus_msg(\$msg)
  }

  my $proto = Object::DataBus::Message->new(
    bus    => $self,
    data   => $msg,
    pkg    => scalar(caller),
  );

  my $meth = $self->dispatch_to;
  for ($self->subscribers) {
    my $actual = $proto->clone_for($_);
    $_->$meth($actual)
  }

  1
}

sub _pack_bus_msg {
  my ($self, @data) = @_;
  immarray @data
}

sub _validate_bus_msg {
  # my ($self, $msgref) = @_;
  # my $msg = $$msgref;
  1
}


1;

=pod

=head1 NAME

Object::DataBus::Role::Broadcast - Data bus subscription and relay methods

=head1 SYNOPSIS

  package My::DataBus;
  use Moo;
  with 'Object::DataBus::Role::Broadcast';

  # The POD for Object::DataBus contains a more extensive synopsis.

=head1 DESCRIPTION

This role provides the behavior implemented by the L<Object::DataBus> class.

=head2 Attributes

=head3 alias

The data bus can be optionally given an C<alias> at construction time;
defaults to the object's stringified value.

=head3 dispatch_to

The method the bus will call on subscribers when dispatching.

Defaults to C<_bus_dispatch>

=head3 message_discipline

Controls whether L</_validate_bus_msg> will be called.

Defaults to false.

=head2 Public Methods

=head3 broadcast

  $bus->broadcast( @items );

Broadcast some data to all bus subscribers.

The message (encapsulated in a L<Object::DataBus::Message>) is delivered to
each subscribed object by calling the L</dispatch_to> method. The only
argument provided to the called method is the L<Object::DataBus::Message>
instance.

By default, the provided list will be packed into a
L<List::Objects::WithUtils::Array::Immutable>. See L</_pack_bus_msg>.

It's worth noting that your subscribers shouldn't modify referenced data when
it is delivered, as message delivery order is not defined.

=head3 subscribers

All objects subscribed to the data bus (as a list).

=head3 subscribe

  $bus->subscribe( $object );

Subscribe the provided object to the data bus.

By default, weak references to the object are kept; when the object goes out
of scope in your codebase, the data bus forgets about it. You can turn this
off on a per-object basis:

  $bus->subscribe( $object, weaken => 0 );

... in which case the object will hang around until unsubscribed (or the bus
goes away).

=head3 unsubscribe

  $bus->unsubscribe( $object );

Unsubscribe the specified object from the bus.

=head3 unsubscribe_all

Unsubscribe all currently-registered objects from the bus.

=head2 Private Methods

These methods can be overriden by consumers to manipulate messages when
L</broadcast> is called.

=head3 _pack_bus_msg

C<_pack_bus_msg> takes the list passed to L</broadcast> and packs it into a
scalar suitable for attaching to an L<Object::DataBus::Message> instance.

By default, data is placed in an immutable array provided by
L<List::Objects::WithUtils::Array::Immutable>.

=head3 _validate_bus_msg

If L</message_discipline> is true, C<_validate_bus_msg> is called after
L</_pack_bus_msg> to verify the message data.

This is passed a B<reference> to the result of L</_pack_bus_msg>, so the data
payload can be modified prior to transmission across the bus:

  sub _validate_bus_msg {
    my ($self, $msgref) = @_;
    die "Expected ARRAY-type object but got ".$$msgref
      unless $$msgref->does('List::Objects::WithUtils::Role::Array');
    1
  }

If the value returned is false, transmission is aborted.

Does nothing (except return true) by default.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
