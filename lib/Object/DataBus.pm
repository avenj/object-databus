package Object::DataBus;
use strictures 1;

use Moo;
with 'Object::DataBus::Role::Broadcast';


1;

=pod

=head1 NAME

=head1 SYNOPSIS

=head1 DESCRIPTION

The B<data bus> pattern allows communication between objects that aren't aware
of each other. Rather than talking directly to each other, objects talk
through the bus; the bus itself is dumb, simply keeping track of its
subscribed objects and relaying messages.

=head1 AUTHOR

=cut

# vim: ts=2 sw=2 et sts=2 ft=perl
