package Networth::Schema::Role::Account;
use v5.19.6;
use Moo::Role;

use Networth::Schema;
use Data::Currency;

sub balance {
    my ($self) = @_;
    return Data::Currency->new({
        value    => $self->assets->get_column('value')->sum,
        code     => $self->user->preferences->currencyCode,
        format   => 'FMT_STANDARD',
    });
}

sub categories {
    my ($self, $date) = @_;
    die "date param required" unless $date;
    return $self->assets->search({ 
        date => { '>' => $date->ymd }, 
    }, { 
        '+select' => [{ count => 'assetId', -as => 'tagCount' }],
        group_by  => 'tag',
    });
}

sub tagBalance {
    my ($self, $tag, $startDate, $endDate) = @_;
    die "tag param required"       unless $tag;
    die "startDate param required" unless $startDate;
    die "endDate param required"   unless $endDate;
    my $rs = $self->assets->search({
        'tag'       => $tag,
        'date'      => { -between => [$startDate->ymd, $endDate->ymd] },
    });
    return Data::Currency->new({
        value    => $rs->get_column('value')->sum,
        code     => $self->user->preferences->currencyCode,
        format   => 'FMT_STANDARD',
    });
}

1;
