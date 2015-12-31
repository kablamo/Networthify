package Networth::Import::Head;
use Moose;

with 'Networth::Import::CSV';

sub head {
    my ($self, $file) = @_;

    my $csv = $self->csv;
    open my $fh, "<:encoding(utf8)", $file or die $file . ": $!";


    my $i = 0;
    my @rows;
    while (my $row = $csv->getline($fh)) {
        push @rows, $row;
        last if $i++ > 2;
    }

    close $fh;

    die "Found zero rows of data in your CSV file"
        if $i == 0;

    return @rows;
}

1;
