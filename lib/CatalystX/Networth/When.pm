package CatalystX::Networth::When;
use Moo::Role;
use DateTime::Format::SQLite;
use Networth::Utils;

sub when {
    my ($c, $accountId, $startDate, $endDate) = @_;

    my %when;

    $when{now} = Networth::Utils->now;

    $when{start} = $startDate 
        ? DateTime::Format::SQLite->parse_datetime($startDate) 
        : ($c->guessStartDate($accountId) || $when{now}->clone->add(days => 1));

    $when{end}   = $endDate   
        ? DateTime::Format::SQLite->parse_datetime($endDate)   
        : $when{start}->clone
                      ->set_day(1)
                      ->set_hour(0)
                      ->set_minute(0);

    $when{prevEnd}   = $when{end}->clone->subtract(months => 1);
    $when{prevStart} = $when{prevEnd}->clone->add(months => 1);
    $when{nextEnd}   = $when{end}->clone->add(months => 1);
    $when{nextStart} = $when{nextEnd}->clone->add(months => 1);

    return %when;
}

sub guessStartDate {
    my ($c, $accountId) = @_;
    my $asset = $c->user->assets
        ->withAccountId($accountId)
        ->orderBy({ -desc => 'date'})
        ->limit(1)
        ->first;
    return 0 unless $asset;
    return $asset->date->clone->add(days => 1);
}

1;
