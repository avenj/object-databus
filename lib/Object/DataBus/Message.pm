package Object::DataBus::Message;
use strictures 1;

use Carp 'confess';
use Scalar::Util 'blessed', 'weaken';

use namespace::clean;

sub BUS  () { 0 }
sub OBJ  () { 1 }
sub DATA () { 2 }


sub _obj  { $_[0]->[OBJ] }


sub bus  { $_[0]->[BUS] }
sub data { $_[0]->[DATA] }


sub new {
  my ($class, %params) = @_;

  confess 
   "Expected 'bus =>' to be an Object::DataBus::Role::Broadcast consumer"
   unless $params{bus}->does('Object::DataBus::Role::Broadcast');

  my $self = [
    $params{bus},     # BUS
    $params{object},  # OBJ
    $params{data},    # DATA
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
  $self->bus->alias
}

sub broadcast {
  my ($self) = @_;
  $self->bus->broadcast(@_)
}

sub unsubscribe {
  my ($self) = @_;
  $self->bus->subscriber_del( $self->_obj )
}

1;
