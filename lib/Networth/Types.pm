package Networth::Types;
use Moose;
use Moose::Util::TypeConstraints;
use MooseX::ClassAttribute;
use Data::Currency;
use Number::Format qw/unformat_number/;
use feature qw/say/;

class_has 'currencyCode' => (
    is       => 'rw',
    isa      => 'Str',
    default  => 'USD',
);

subtype 'Networth::Types::Currency'
     => as 'Data::Currency';

coerce 'Networth::Types::Currency'
    => from 'Num'
    => via { 
        Data::Currency->new({ 
            value  => unformat_number($_),
            code   => Networth::Types->currencyCode,
            format => 'FMT_STANDARD',
        });
};

subtype 'Networth::Types::CurrencyArrayRef'
     => as 'ArrayRef[Data::Currency]';

coerce 'Networth::Types::CurrencyArrayRef'
    => from 'ArrayRef[Num]'
    => via { 
        my @currency;
        foreach my $value (@$_) {
            push @currency, Data::Currency->new({ 
                value  => unformat_number($value),
                code   => Networth::Types->currencyCode,
                format => 'FMT_STANDARD',
            });
        }
        return \@currency;
};

1;
