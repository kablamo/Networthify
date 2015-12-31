package Networth::Schema::ResultSet::Asset;
use v5.19.6;
use Moo;
extends 'Networth::Schema::ResultSet';

use Data::Currency;

sub user { shift->search_related('users')->first }

sub withTag         { shift->search({ tag         => shift }) }
sub withAccountId   { shift->search({ accountId   => shift }) }
sub withAssetId     { shift->search({ assetId     => shift }) }
sub withDescription { shift->search({ description => shift }) }

sub withDateBetween {
    my ($self, $startDate, $endDate) = @_;
    return $self->search({ 
        date => { -between => [$endDate->ymd, $startDate->ymd] }
    });
}

sub balance {
    my ($self) = @_;
    return Data::Currency->new({
        value    => $self->get_column('value')->sum,
        code     => $self->user->preferences->currencyCode,
        format   => 'FMT_STANDARD',
    });
}

# returns an alphabetically sorted list of tags (strings)
sub tags {
    my ($self, $accountId, $date) = @_;

    my $rows = $self
        ->withAccountId($accountId)
        ->select({COUNT => 'value', -as => 'tagCount'})
        ->groupBy('tag');

    my @notEmpty;
    while (my $row = $rows->next) {
        next if $row->tagCount <= 0;
        push @notEmpty, $row->tag;
    }

    return sort @notEmpty;
}

1;
