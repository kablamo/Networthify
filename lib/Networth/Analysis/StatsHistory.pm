package Networth::Analysis::StatsHistory;

sub find {
    my ($class, %args) = @_;
    my $assets = $args{user}->assets(
        accountId => $args{accountId},
        startDate => $args{startDate},
        endDate   => $args{endDate},
    );

    while (my $asset = $assets->next) {
    }
}

1;
