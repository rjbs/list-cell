use strict;
use warnings;

use Test::More 0.88;

use Cell;

my $cell_1 = Cell->new({ value => 1 });
my $cell_2 = Cell->new({ value => 2 });
my $cell_3 = Cell->new({ value => 3 });

$cell_1->insert_after($cell_2);

values_are($cell_1, [ qw(1 2) ]);

$cell_1->next->insert_after($cell_3);

values_are($cell_1, [ qw(1 2 3) ]);

my $cell_4 = Cell->new({ value => 4 });

$cell_1->next->insert_after($cell_4);

values_are($cell_1, [ qw(1 2 4 3) ]);

my $cell_5 = Cell->new({ value => 5 });

$cell_1->next_where(sub { $_->value =~ /2/ })->replace_with($cell_5);

values_are($cell_1, [ qw(1 5 4 3) ]);

is($cell_2->prev, undef, "replacing cell_2 eliminated its prev");
is($cell_2->next, undef, "replacing cell_2 eliminated its next");

ok($cell_2->is_first, "...which means that it's now a head");

$cell_5->insert_before($cell_2);

values_are($cell_1, [ qw(1 2 5 4 3) ]);

is($cell_5->first->value, 1, 'c->first->value');
is($cell_5->last->value,  3, 'c->last->value');

{
  my $cell_A = Cell->new_from_values([ qw(1 2 3) ]);
  my $cell_B = Cell->new_from_values([ qw(X Y Z) ]);

  values_are($cell_A, [ qw(1 2 3) ]);

  $cell_B->replace_prev($cell_A->extract);

  values_are($cell_A, [ qw(1 X Y Z) ]);
}

done_testing;

### LOOK OUT BELOW

sub values_are {
  my ($head, $values, $comment) = @_;

  my @values = values_for($head);
  is_deeply(\@values, $values, ($comment || "vals: @$values"));
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
