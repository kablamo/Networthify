package Networth::Roles::Coercions;
use Moo::Role;
use Data::Currency;

sub _build_currency {
    return sub {
        my ($orig, $self, $value) = @_;

        return $orig->($self) unless defined $value;

        my $currency = Data::Currency->new({ 
            value  => unformat_number($value),
            code   => $self->user->preferences->currencyCode,
            format => 'FMT_STANDARD',
        });

        return $orig->($self, $currency);
    };
};


1;
