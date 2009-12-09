package Cell;
use Moose;

use MooseX::Types::Moose qw(Item);
use MooseX::Types -declare => [ qw(Cell) ];

use Scalar::Util qw(refaddr);

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
  isa => Item,
  required => 1,
);

sub new_from_values {
  my ($self, $values) = @_;

  # my %seen;
  # for my $value (@$values) {
  #   confess "duplicate value in values list" if $seen{ refaddr($value) }++;
  # }

  my @cells = map {; $self->new({ value => $_ }) } @$values;

  $self->__linearize(@cells);

  return $cells[0];
}

sub __linearize {
  my ($self, @cells) = @_;

  for my $i (0 .. $#cells) {
    $cells[ $i ]->replace_next($cells[ $i + 1 ]) if $i < $#cells;
  }
}

sub insert_before {
  my ($self, $head) = @_;

  return unless $head;
  confess "given head is not the head of a chain" unless $head->is_first;

  my $prev = $self->prev;
  $self->clear_prev;

  $head->replace_prev($prev) if $prev;

  $head->last->replace_next($self);

  return;
}

sub insert_after {
  my ($self, $head) = @_;

  return unless $head;
  confess "given head is not the head of a chain" unless $head->is_first;

  my $next = $self->next;

  $self->replace_next($head);
  $head->last->replace_next($next) if $next;

  return;
}

sub replace_prev {
  my ($self, $head) = @_;

  confess "no replacement cell given" unless $head;
  confess "given head is not the head of a chain" unless $head->is_first;

  $head->last->replace_next($self);
  return;
}

sub replace_next {
  my ($self, $head) = @_;
  
  confess "no replacement cell given" unless $head;
  confess "given head is not the head of a chain" unless $head->is_first;

  $head->__set_prev($self);
  $self->next->__clear_prev if $self->next;
  $self->__set_next($head);

  return;
}

sub clear_prev {
  my ($self) = @_;

  return unless my $prev = $self->prev;
  $prev->clear_next;

  return $prev;
}

sub clear_next {
  my ($self) = @_;

  return unless my $next = $self->next;
  $next->__clear_prev;
  $self->__clear_next;

  return $next;
}

sub replace_with {
  my ($self, $head) = @_;

  confess "no replacement cell given" unless $head;
  confess "given head is not the head of a chain" unless $head->is_first;

  my $prev = $self->clear_prev;
  my $next = $self->clear_next;

  $prev->replace_next($head) if $prev;
  $head->last->replace_next($next) if $next;

  return $self;
}

sub extract {
  my ($self) = @_;

  my $prev = $self->clear_prev;
  my $next = $self->clear_next;

  $prev->replace_next($next) if $prev and $next;

  return $self;
}

## TRAVERSAL METHODS.  EASY PEASY

sub next_where {
  my ($self, $sub) = @_;
  my $next = $self->next;
  return $next if do { local $_ = $next; $next->$sub; };
  return $next->next_where($sub);
}

sub prev_where {
  my ($self, $sub) = @_;
  my $prev = $self->prev;
  return $prev if do { local $_ = $prev; $prev->$sub; };
  return $prev->prev_where($sub);
}

sub is_first { ! (shift)->prev }
sub is_last  { ! (shift)->next }

sub first { return $_[0]->prev ?  $_[0]->prev->first : $_[0]; }
sub last  { return $_[0]->next ?  $_[0]->next->last  : $_[0]; }

1;
