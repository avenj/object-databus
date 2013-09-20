package My::FirstSub;
use Moo;
use feature 'say';
with 'Object::DataBus::Role::Listen';

sub recv_message {
  my ($self, $bmsg) = @_;
  my (undef, $data) = $bmsg->data->head;
  my ($cmd, $ircmsg, $hints) = $data->all;
  say "First subscriber got message ".$ircmsg->stream_to_line;
}

package My::SecondSub;
use Moo;
use feature 'say';
with 'Object::DataBus::Role::Listen';

sub recv_message {
  my ($self, $bmsg) = @_;
  my (undef, $data) = $bmsg->data->head;
  my ($cmd, $ircmsg, $hints) = $data->all;
  say "Second subscriber got message ".$ircmsg->stream_to_line;
}

package My::IRC;
use IO::Async::Loop;
use Net::Async::IRC;
use Moo;
with 'Object::DataBus::Role::Broadcast';

has _loop => ( is => 'ro', builder => sub { IO::Async::Loop->new } );
has irc   => ( 
  is      => 'ro',
  builder => 1,
);

sub _build_irc {
  my ($self) = @_;
  Net::Async::IRC->new(
    on_message => sub {
      my ($irc, $msg, $hints) = @_;
      $self->broadcast( message => $msg, $hints )
    },
  )
}

sub BUILD {
  my ($self) = @_;
  $self->_loop->add( $self->irc );
}

sub run {
  my ($self) = @_;
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
use strictures 1;

my $ircbus = My::IRC->new;

my $firstsub  = My::FirstSub->new;
my $secondsub = My::SecondSub->new;

$ircbus->subscribe( $firstsub );
$ircbus->subscribe( $secondsub );

$ircbus->run
