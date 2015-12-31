package Networth::Schema::Role::FilterColumn;
use Moo::Role;
use Data::Currency;
use Number::Format qw/unformat_number/;

sub filterDataCurrency {{
    filter_to_storage   => sub { unformat_number $_[1] },
    filter_from_storage => sub {
        my ($self, $value) = @_;
        Data::Currency->new({
            value    => $value,
            code     => $self->user->preferences->currencyCode,
            format   => 'FMT_STANDARD',
        });
    },
}}


1;
