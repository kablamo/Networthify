package Networth::Schema::ResultSet::TransactionHistory;
use v5.19.6;
use Moo;
extends 'Networth::Schema::ResultSet';

use Data::Currency;

sub withDateBetween {
    my ($self, $startDate, $endDate) = @_;
    return $self->search({ 
        date => { -between => [$endDate->ymd, $startDate->ymd] }
    });
}

sub withAccountId { shift->search({ accountId => shift }) }
sub withAssetId   { shift->search({ assetId   => shift }) }


1;
