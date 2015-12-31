package Networth::Import::Everything;

use Moose;
with 'Networth::Import::CSV';

use DateTime;
use DateTime::Format::Natural;
use Networth::Schema;
use Number::Format qw/unformat_number/;

has thousandsSep => (is => 'ro', isa => 'Str',     required => 1);
has decimalPoint => (is => 'ro', isa => 'Str',     required => 1);
has dtFormat     => (is => 'ro', isa => 'Str',     required => 1); 
has index        => (is => 'ro', isa => 'HashRef', required => 1);
has userId       => (is => 'ro', isa => 'Int',     required => 1);
has accountId    => (is => 'ro', isa => 'Int',     required => 1);

has nf => (
    is      => 'ro', 
    isa     => 'Number::Format',
    lazy    => 1,
    default => sub {
        Number::Format->new(
            -thousands_sep => $_[0]->thousandsSep,
            -decimal_point => $_[0]->decimalPoint,
        );
    }
);

has dtParser => (
    is      => 'ro',
    isa     => 'DateTime::Format::Natural',
    lazy    => 1,
    default => sub {
        my $self = shift;
        DateTime::Format::Natural->new(format => $self->dtFormat)
    },
);

sub go {
    my ($self, $file) = @_;
    $self->validate($file);
    $self->write($file);
}

sub validate {
    my ($self, $file) = @_;

    my $csv = $self->csv;
    open my $fh, "<:encoding(utf8)", $file or die $file . ": $!";

    my $idx;
    my $i = 1;
    while (my $row = $csv->getline($fh)) {

        # date validation
        $idx = $self->index->{date};
        $self->dtParser->parse_datetime($row->[$idx]);
        die "Row $i: Date error in validate().  Can't parse '" . $row->[$idx]  . "'. " . $self->dtParser->error . "\n"
            unless $self->dtParser->success;

        # description validation
        $idx = $self->index->{description};
        $row->[$idx] || 
            die "Row $i: No description found\n";

        # value validation
        if ($self->index->{value}) {
            $idx = $self->index->{value};
            unformat_number($row->[$idx]) || 
                die "Row $i: Value error.  Can't parse " . $row->[$idx] . "\n";
        }
        else {
            my $idxIn  = $self->index->{valueIn};
            my $idxOut = $self->index->{valueOut};

            my $valueIn  = unformat_number($row->[$idxIn ]);
            my $valueOut = unformat_number($row->[$idxOut]);

            my $value;
            $value = $valueIn       if defined $valueIn && $valueIn > 0;
            $value = $valueOut * -1 if defined $valueOut && $valueOut > 0;
            $value || 
                die "Row $i: Value error.  Can't parse " . $row->[$idx];
        }

        $i++;
    }

    $csv->eof or die $csv->error_diag;
    close $fh;

    die "Found zero rows of data in your CSV file"
        if $i == 1;
}

sub write {
    my ($self, $file) = @_;

    my $csv = $self->csv;
    open my $fh, "<:encoding(utf8)", $file or die $file . ": $!";

    my $idx;
    my $i = 0;
    while (my $row = $csv->getline($fh)) {
        $idx = $self->index->{date};
        my $date = $self->dtParser->parse_datetime($row->[$idx]);
        die "Row $i: Date error in write().  Can't parse '" . $row->[$idx]  . "'. " . $self->dtParser->error . "\n"
            unless $self->dtParser->success;

        $idx = $self->index->{description};
        my $description = $row->[$idx] || 
            die "Row $i: No description found";

        my $value;
        if ($self->index->{value}) {
            $idx = $self->index->{value};
            $value = unformat_number($row->[$idx]) || 
                die "Row $i: Value error.  Can't parse " . $row->[$idx];
        }
        else {
            my $idxIn  = $self->index->{valueIn};
            my $idxOut = $self->index->{valueOut};

            my $valueIn  = unformat_number($row->[$idxIn ]);
            my $valueOut = unformat_number($row->[$idxOut]);

            $value = $valueIn       if defined $valueIn && $valueIn > 0;
            $value = $valueOut * -1 if defined $valueOut && $valueOut > 0;
            $value || 
                die "Row $i: Value error.  Can't parse " . $row->[$idx];
        }

        $idx = $self->index->{category};
        my $category = $idx ? $row->[$idx] : "";

        Networth::Schema->rs('Asset')->create({
            date        => $date->ymd, 
            description => $description, 
            value       => $value, 
            tag         => $category,
            userId      => $self->userId, 
            accountId   => $self->accountId,
        });
    }

    $csv->eof or die $csv->error_diag;
    close $fh;
}

1;
