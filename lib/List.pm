package List;
use Moose;

use MooseX::Types::Moose qw(Maybe ArrayRef);

use namespace::autoclean;

has elements => (
  is => 'ro',
  reader => '_elements',
  isa    => ArrayRef,
);

1;
