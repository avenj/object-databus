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
  # Return objects.
  my ($self) = @_;
  $self->_subbed->values->all
}

sub subscriber_add {
  my ($self, $obj, %params) = @_;
  $self->_subbed->set( refaddr($obj) => $obj );
  unless (defined $params{weaken} && !$params{weaken}) {
    weaken($self->_subbed->{refaddr($obj)})
  }
  1
}

sub subscriber_del {
  my ($self, $obj) = @_;
  $self->_subbed->delete( refaddr($obj) ) ? 1 : ()
}

sub broadcast {
  my ($self, $msg) = @_;

  $self->_validate_bus_msg(\$msg) if $self->message_discipline;
  
  my $proto = Object::DataBus::Message->new(
    bus    => $self,
    data   => $msg,
  );

  my $meth = $self->dispatch_to;
  for ($self->subscribers) {
    my $actual = $proto->clone_for($_);
    $_->$meth($actual)
  }

  1
}

sub _validate_bus_msg {
  my ($self, $msgref) = @_;
  
  confess "Expected ARRAY or array-type object, got ".$$msgref
    unless ref $$msgref eq 'ARRAY'
    or is_ArrayObj($$msgref);

  $$msgref = immarray( blessed $$msgref ? $$msgref->all : @$msgref )
    unless is_ImmutableArray($$msgref);
}


1;
