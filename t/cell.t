use strict;
use warnings;

use Test::More 0.90;

my $total = 0;

{
  package Test::Cell;
  use Moose;
  with 'List::Cell';

  has value => (is  => 'rw', required => 1);
  sub from_values {
    return (shift)->new_from_arrayref( [ map {;{value=>$_}} @{ shift() } ] );
  }

  sub BUILD   { $total++; }
  sub DESTROY { $total--; }
}

{
  my $cell_1 = Test::Cell->new({ value => 1 });
  my $cell_2 = Test::Cell->new({ value => 2 });
  my $cell_3 = Test::Cell->new({ value => 3 });

  $cell_1->insert_after($cell_2);

  values_are($cell_1, [ qw(1 2) ]);

  $cell_1->next->insert_after($cell_3);

  values_are($cell_1, [ qw(1 2 3) ]);

  my $cell_4 = Test::Cell->new({ value => 4 });

  $cell_1->next->insert_after($cell_4);

  values_are($cell_1, [ qw(1 2 4 3) ]);

  my $cell_5 = Test::Cell->new({ value => 5 });

  # This line demonstrates the most common usage of this library that I have in
  # mind.  -- rjbs, 2009-12-08
  $cell_1->next_where(sub { $_->value =~ /2/ })->replace_with($cell_5);

  values_are($cell_1, [ qw(1 5 4 3) ]);

  is($cell_2->prev, undef, "replacing cell_2 eliminated its prev");
  is($cell_2->next, undef, "...and its next");

  ok($cell_2->is_first, "...which means that it's now a head");

  $cell_5->insert_before($cell_2);

  values_are($cell_1, [ qw(1 2 5 4 3) ]);

  is($cell_5->first->value, 1, 'c->first->value');
  is($cell_5->last->value,  3, 'c->last->value');
}

is($total, 0, "all cells destroyed");

{
  my $cell_A = Test::Cell->from_values([ qw(1 2 3) ]);
  my $cell_B = Test::Cell->from_values([ qw(X Y Z) ]);

  values_are($cell_A, [ qw(1 2 3) ]);

  $cell_B->replace_prev($cell_A->extract);

  values_are($cell_A, [ qw(1 X Y Z) ]);
}

is($total, 0, "all cells destroyed");

{
  my $cell_A = Test::Cell->from_values([ qw(1 2 3) ]);
  my $cell_B = Test::Cell->from_values([ qw(4) ]);

  values_are($cell_A, [ qw(1 2 3) ]);

  $cell_B->replace_prev($cell_A);

  values_are($cell_A, [ qw(1 2 3 4) ]);
  values_are($cell_B->first, [ qw(1 2 3 4) ]);
}

is($total, 0, "all cells destroyed");

subtest 'pad-front' => sub {
  my $pass  = 1;
  my @start = qw(3 4 5);
  my $first = Test::Cell->from_values(\@start);

  while ($first->value != 0) {
    my $prev_val  = $first->value - 1;
    my $prev_cell = Test::Cell->from_values([ $prev_val ]);

    values_are($first, \@start);

    $first->replace_prev( $prev_cell );
    is($first->first, $prev_cell, "new head is the cell we just made");

    unshift @start, $prev_val;
    values_are($first->first, \@start);

    $first = $first->first;
  }

  done_testing;
};

done_testing;

### LOOK OUT BELOW

sub values_are {
  my ($head, $values, $comment) = @_;

  my @values = values_for($head);
  # is_deeply(\@values, $values, ($comment || "vals: @$values"));
  is("@values", "@$values", ($comment || "vals: @$values"));
  bidi_traverse_ok($head);
}

sub bidi_traverse_ok {
  my ($cell) = @_;

  my @fd;
  my @bk;

  my $first = $cell->first;
  my $next  = $first;
  while (1) {
    push @fd, $next->value;
    last unless $next->next;
    $next = $next->next;
  }

  my $prev = $next;
  while ($prev) {
    unshift @bk, $prev->value;
    $prev = $prev->prev;
  }

  is_deeply(\@fd, \@bk, "bidi: @fd");
}

sub values_for {
  my ($head) = @_;

  my @cells = ($head);
  push @cells, $cells[-1]->next while $cells[-1]->next;
  my @values = map {;  $_->value } @cells;

  return @values;
}
