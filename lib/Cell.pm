package Cell;
use Moose;

use MooseX::Types::Moose qw(Ref);
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
  isa => Ref,
  required => 1,
);

sub new_from_values {
  my ($self, $values) = @_;

  # my %seen;
  # for my $value (@$values) {
  #   confess "duplicate value in values list" if $seen{ refaddr($value) }++;
  # }

  my @cells = map {; $self->new({ value => $_ }) } @$values;
  my $head  = shift @cells;

  $head->replace_next(@cells);

  return $head;
}

sub insert_before {
  my ($self, @cells) = @_;
  return unless @cells;

  my $prev = $self->prev;
  $cells[-1]->replace_next($self);
  $prev->replace_next($cells[0]) if $prev;

  return;
}

sub insert_after {
  my ($self, @cells) = @_;
  return unless @cells;

  my $next = $self->next;
  $self->replace_next(@cells);
  $cells[-1]->replace_next($next) if $next;

  return;
}

sub __linearize {
  my ($self, @cells) = @_;

  for my $i (0 .. $#cells) {
    $cells[ $i ]->replace_next($cells[ $i + 1 ]) if $i < $#cells;
  }
}

sub replace_prev {
  my ($self, @cells) = @_;

  die "no replacement cell given" unless @cells;

  $self->__linearize(@cells) if @cells > 1;

  $cells[-1]->replace_next($self);
  return;
}

sub replace_next {
  my ($self, @cells) = @_;
  
  die "no replacement cell given" unless @cells;

  $self->__linearize(@cells) if @cells > 1;

  $cells[0]->__set_prev($self);
  $self->__set_next($cells[0]);

  return;
}

sub clear_next {
  my ($self) = @_;
  return unless $self->next;
  $self->next->__clear_prev;
  $self->__clear_next;

  return;
}

sub replace_with {
  my ($self, @cells) = @_;

  $self->prev->replace_next($cells[0]);
  $cells[-1]->replace_next($self->next);

  return;
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
