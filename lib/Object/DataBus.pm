package Object::DataBus;
use strictures 1;

use Moo;
with 'Object::DataBus::Role::Broadcast';


1;

=pod

=head1 NAME

Object::DataBus - Minimalist but extensible data bus

=head1 SYNOPSIS

  ## Simple usage ->
  # A pair of objects that talk to each other:

  package My::First;
  use Moo;
  # The Listen role assumes the first data item is an event name
  # and redispatches to method 'recv_$event':
  with 'Object::DataBus::Role::Listen';
  sub recv_foo {
    my ($self, $bmsg)   = @_;
    # Ignore the first item ('foo'):
    my (undef, @params) = $bmsg->data->all;
    # ... do some work ...
    # Pass a message:
    $bmsg->broadcast( bar => qw/ baz quux / );
  }

  package My::Second;
  use Moo;
  with 'Object::DataBus::Role::Listen';
  sub recv_bar {
    my ($self, $bmsg)   = @_;
    my (undef, @params) = $bmsg->data->all;
    # ...
  }

  # A class with a bus that manages our objects:
  package My::Class;
  use Object::DataBus;
  use Moo;

  has bus => (
    is      => 'ro',
    default => sub { Object::DataBus->new },
  );

  has first => (
    is      => 'ro',
    default => sub { My::First->new },
  );

  has second => (
    is      => 'ro',
    default => sub { My::Second->new },
  );

  sub do_work {
    my ($self, @data) = @_;
    $self->bus->broadcast( foo => @data )
  }

=head1 DESCRIPTION

(L<Object::DataBus::Role::Broadcast> documents all methods implemented by this
class; the following is a broad overview of this module's purpose.)

The B<data bus> pattern allows communication between objects that aren't
necessarily aware of each other. Rather than talking directly to each other,
objects talk through the bus; the bus itself is dumb, simply keeping track of
its subscribed objects and relaying messages.

Why would you want to do this? The pattern makes it easy to add and subtract
components at run-time. Adding new functionality is easy, and new unknown events
can be simply ignored by listeners. Debugging is also easy (by watching bus
traffic).

The provided bus does not keep strong references unless told to (objects
should be held elsewhere).

The bus also does not keep track of senders -- all messages are sent to all
receivers. It is up to the receiving end to decide what to do with it.
If looping is a concern, you can use a message format that
contains sender information:

  package My::Listener;
  use strictures 1;
  use Scalar::Util 'refaddr';
  sub _bus_dispatch {
    my ($self, $bmsg) = @_;
    my ($event, $id, @data) = $bmsg->data->all;
    return if $id == refaddr $self;
    ...
    $bmsg->broadcast( foo => refaddr($self) => qw/bar baz/ )
  }

Arbitrary lists of data can be sent across the bus.
L<Object::DataBus::Role::Listen> provides a simplistic dispatch system wherein
bus message data is assumed to be in the format of C<< $event => @params >>
and dispatched to the subscribed object's C<recv_$event> method (if present),
but any object can provide a B<_bus_dispatch> method and hook into the bus.

Data is packaged up into L<Object::DataBus::Message> objects; these serve as
'travellers', visiting all of your subscribers and providing messages and a
safe interface to the bus.

By default, message data is packaged up into a
L<List::Objects::WithUtils::Array::Immutable> object. Most methods
are documented in L<List::Objects::WithUtils::Role::Array>.

This particular class can be instanced to provide a simple data bus.
L<Object::DataBus::Role::Broadcast> provides all implemented methods; see the
documentation for that role for usage details.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut

# vim: ts=2 sw=2 et sts=2 ft=perl
