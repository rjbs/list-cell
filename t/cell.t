use strict;
use warnings;

use Test::More 0.88;

use Cell;

my $cell_1 = Cell->new({ value => \'cell_1' });
my $cell_2 = Cell->new({ value => \'cell_2' });
my $cell_3 = Cell->new({ value => \'cell_3' });

$cell_1->insert_after($cell_2);

$cell_1->next->insert_after($cell_3);

my $cell_4 = Cell->new({ value => \'cell_4' });

$cell_1->next->insert_after($cell_4);

is_deeply(
  [ values_for($cell_1) ],
  [ qw(cell_1 cell_2 cell_4 cell_3) ],
);

my $cell_5 = Cell->new({ value => \'cell_5' });

$cell_1->next_where(sub { ${$_->value} =~ /2/ })->replace_with($cell_5);

is_deeply(
  [ values_for($cell_1) ],
  [ qw(cell_1 cell_5 cell_4 cell_3) ],
);

$cell_5->insert_before($cell_2);

is_deeply(
  [ values_for($cell_1) ],
  [ qw(cell_1 cell_2 cell_5 cell_4 cell_3) ],
);

is_deeply($cell_5->first->value, \'cell_1', 'c->first->value');
is_deeply($cell_5->last->value,  \'cell_3', 'c->last->value');

{
  my $cell_A = Cell->new_from_values([ \qw(cell_1 cell_2 cell_3) ]);
  my $cell_B = Cell->new_from_values([ \qw(cell_X cell_Y cell_Z) ]);

  is_deeply(
    [ values_for($cell_A) ],
    [ qw(cell_1 cell_2 cell_3) ],
  );

  $cell_B->replace_prev($cell_A);

  is_deeply(
    [ values_for($cell_A) ],
    [ qw(cell_1 cell_X cell_Y cell_Z) ],
  );
}

done_testing;

sub values_for {
  my ($head) = @_;

  my @cells = ($head);
  push @cells, $cells[-1]->next while $cells[-1]->next;
  my @values = map {;  ${ $_->value } } @cells;

  diag @values;
  return @values;
}
