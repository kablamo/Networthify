package Networth::Import::CSV;
use Moose::Role;
use Text::CSV;

has delimiter => (is => 'ro', isa => 'Str', required => 1);

has csv => (
    is       => 'ro',
    isa      => 'Text::CSV',
    lazy     => 1,
    default  => sub {
        my $self = shift;
        Text::CSV->new({
            binary             => 1,
            allow_whitespace   => 1,
            allow_loose_quotes => 1,
            sep_char           => $self->delimiter,
        });
    }
);


1;
