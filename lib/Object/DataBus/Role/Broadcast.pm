package Object::DataBus::Role::Broadcast;
use strictures 1;

use Carp;
use Data::Dumper ();
use Scalar::Util 'blessed', 'refaddr';

use List::Objects::WithUtils ':functions';
use List::Objects::Types -all;
use Types::Standard -all;

use Object::DataBus::Traveller;


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

has _traveller => (
  lazy      => 1,
  is        => 'ro',
  isa       => InstanceOf['Object::DataBus::Traveller'],
  default   => sub {
    my ($self) = @_;
    Object::DataBus::Traveller->new( bus => $self )
  },
);

sub subscribers {
  # Return objects.
  my ($self) = @_;
  $self->_subbed->values->all
}

sub subscriber_add {
  my ($self, $obj) = @_;
  $self->_subbed->set( refaddr($obj) => $obj );
}

sub subscriber_del {
  my ($self, $obj) = @_;
  $self->_subbed->delete( refaddr($obj) )
}

sub broadcast {
  my ($self, $msg) = @_;
  $self->_validate_bus_msg(\$msg);
  my $meth = $self->dispatch_to;
  $_->$meth($msg) for $self->subscribers;
}

sub _validate_bus_msg {
  my ($self, $msgref) = @_;
  
  return unless $self->message_discipline;

  confess "Expected ARRAY or array-type object, got ".$$msgref
    unless ref $$msgref eq 'ARRAY'
    or is_ArrayObj($$msgref);

  $$msgref = immarray( blessed $$msgref ? $$msgref->all : @$msgref )
    unless is_ImmutableArray($$msgref);
}


1;
