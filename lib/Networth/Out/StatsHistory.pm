package Networth::Out::StatsHistory;
use v5.19.6;
use Moose;

use Networth::Out::Stats;
use Networth::Utils;

=head1 SYNOPSIS

   use Networth::Out::StatsHistory;
   my $history = Networth::Out::StatsHistory->new(
        user      => $user,
        accountId => $accountId,
   );
   my @stats      = $history->stats();
   my @categories = $history->categories();

=cut

has user      => (is => 'ro', required => 1);
has accountId => (is => 'ro', required => 1);
has date      => (is => 'ro', default  => sub { Networth::Utils->now });
has months    => (is => 'ro', default  => 6);

sub stats {
    my $self  = shift;
    my @range = (0..($self->months - 1));
    my $assets = $self->user->assets->withAccountId($self->accountId);
    my @stats;

    foreach my $i (@range) {
        my $startDate = $self->date->clone
            ->subtract(months => $i)
            ->set_day(1)
            ->set_hour(0)
            ->set_minute(0);

        my $endDate = $startDate->clone->subtract(months => 1);

        push @stats, Networth::Out::Stats->new(
            startDate => $startDate,
            endDate   => $endDate,
            accountId => $self->accountId,
            user      => $self->user,
            assets    => $assets,
        );
    }

    return reverse @stats;
}

# returns a list of all the tags in this account ordered alphabetically
sub tags {
    my $self = shift;
    return $self->user->assets->tags($self->accountId);
}

1;
