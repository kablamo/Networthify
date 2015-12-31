package Networth::Analysis::Stats;
use Moose;

has income => (
    is  => 'rw',
    isa => 'Data::Currency',
    required => 1,
);

has expenses => (
    is  => 'rw',
    isa => 'Data::Currency',
    required => 1,
);

has savings => (
    is  => 'rw',
    isa => 'Data::Currency',
    required => 1,
);

has savingsRate => (
    is  => 'rw',
    required => 1,
);

has yearsToFI => (
    is  => 'rw',
    isa => 'Int',
    required => 1,
);

1;
