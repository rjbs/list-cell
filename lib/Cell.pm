package Cell;
use Moose;

use MooseX::Types::Moose qw(Ref);
use MooseX::Types -declare => [ qw(Cell) ];

class_type Cell, { class => 'Cell' };

use namespace::autoclean;

has prev => (
  is  => 'ro',
  isa => Cell,
  clearer  => '__clear_prev',
  writer   => '__set_prev',
  weak_ref => 1,
);

has next => (
  is  => 'ro',
  isa => Cell,
  clearer  => '__clear_next',
  writer   => '__set_next',
);

has value => (
  is  => 'rw',
  isa => Ref,
  required => 1,
);

sub splice_next {
  my ($self, @cells) = @_;
  return unless @cells;

  my $next = $self->next;
  $self->_set_next(@cells);
  $cells[-1]->_set_next($next) if $next;

  return;
}

sub _clear_prev {
  shift->__clear_prev;
}

sub _set_next {
  my ($self, @cells) = @_;
  
  die "unimplemented" unless @cells == 1;

  $cells[0]->_clear_prev;
  $cells[0]->__set_prev($self);
  $self->__set_next($cells[0]);
}

sub replace_with {
  my ($self, @cells) = @_;

  die "unimplemented" unless @cells == 1;

  $self->prev->_set_next($cells[0]);
  $cells[-1]->_set_next($self->next);

  return;
}

sub next_where {
  my ($self, $sub) = @_;
  my $next = $self->next;
  return $next if do { local $_ = $next; $next->$sub; };
  return $next->next_where($sub);
}

sub is_first { ! (shift)->prev }
sub is_last  { ! (shift)->next }

1;
