package Object::DataBus;
use strictures 1;

use Moo;
with 'Object::DataBus::Role::Broadcast';


1;

=pod

=head1 NAME

Object::DataBus - Minimalist but extensible data bus

=head1 SYNOPSIS

  # A data bus that is an IRC client ->

  package My::Subscriber;
  use Moo;
  use feature 'say';
  with 'Object::DataBus::Role::Listen';
  
  # Role::Listen default behavior; uses the first item in the data payload
  # as an event name and dispatches to 'recv_$event'
  sub recv_message {
    my ($self, $bmsg) = @_;
    # $bmsg->data payload is packed into an immutable array obj by default
    # (specifically a List::Objects::WithUtils::Array::Immutable)
    my (undef, $data) = $bmsg->data->head;
    my ($cmd, $ircmsg, $hints) = $data->all;
    say "Subscriber got message ".$ircmsg->stream_to_line;
  }

  package My::IRC;
  use IO::Async::Loop; 
  use Net::Async::IRC;
  use Moo;
  with 'Object::DataBus::Role::Broadcast';

  has _loop => ( is => 'ro', builder => sub { IO::Async::Loop->new } );
  has irc   => ( is => 'ro', builder => 1 );

  sub _build_irc {
    my ($self) = @_;
    Net::Async::IRC->new(
      on_message => sub {
        my $irc = shift;
        # Dispatch to our subscribers:
        $self->broadcast( message => @_ )
      },
    )
  }

  sub run {
    my ($self) = @_;
    $self->_loop->add( $self->irc );
    $self->irc->login(
      nick => 'DataBusExample'.$$,
      host => 'irc.cobaltirc.org',
      on_login => sub {
        my ($irc) = @_;
        # ...
      },
    );
    $self->_loop->loop_forever;
  }

  package main;
  my $ircbus = My::IRC->new;
  my $subbed = My::Subscriber->new;
  $ircbus->subscribe( $subbed );
  $ircbus->run

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

Arbitrary data can be sent across the bus.
L<Object::DataBus::Role::Listen> provides a simplistic dispatch system wherein
bus message data is assumed to be in the format of C<< $event => @params >>
and dispatched to the subscribed object's C<recv_$event> method (if present),
but any object can provide a B<_bus_dispatch> method and hook into the bus.

Messages are delivered as L<Object::DataBus::Message> objects; these serve as
'travellers', visiting all of your subscribers and providing messages and a
safe interface to the bus.

By default, message data is packaged up into a
L<List::Objects::WithUtils::Array::Immutable> object.
See the documentation for that module and
L<List::Objects::WithUtils::Role::Array> for details.
L<Object::DataBus::Role::Broadcast> provides documentation on overriding this
behavior.

This particular class can be instanced to provide a simple data bus.
L<Object::DataBus::Role::Broadcast> provides all implemented methods; see the
documentation for that role for usage details.

Message dispatch is not ordered in any defined way.  If you need something
that looks more like a plugin pipeline, you may want to check out
L<MooX::Role::Pluggable>.  L<MooX::Role::POE::Emitter> is a more advanced
Observer Pattern implementation for POE, and also provides a plugin pipeline
via L<MooX::Role::Pluggable>.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut

# vim: ts=2 sw=2 et sts=2 ft=perl
