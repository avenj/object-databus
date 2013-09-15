package Object::DataBus;
use strictures 1;

use Moo;
with 'Object::DataBus::Role::Broadcast';


1;

=pod

=head1 NAME

Object::DataBus - Minimalist but extensible data bus

=head1 SYNOPSIS

=head1 DESCRIPTION

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
contains sender information/references:

  package My::Listener;
  use strictures 1;
  use Scalar::Util 'refaddr';
  sub _bus_dispatch {
    my ($self, $msg) = @_;
    my ($event, $id, @data) = $msg->data->all;
    return if $id == refaddr $self;
    ...
    $msg->broadcast( foo => refaddr($self) => qw/bar baz/ )
  }

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut

# vim: ts=2 sw=2 et sts=2 ft=perl
