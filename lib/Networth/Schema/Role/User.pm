package Networth::Schema::Role::User;
use v5.19.6;
use Moo::Role;

sub networth {
    my ($self) = @_;
    my $value = $self->assets->get_column('value')->sum;
    return Data::Currency->new({
        value    => $value,
        code     => $self->preferences->currencyCode,
        format   => 'FMT_STANDARD',
    });
}

1;
