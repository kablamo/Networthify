use Test::Most;

use Networth::Out::StatsHistory;
use Networth::Test;
use Networth::Utils;

my $user;
subtest 'setup' => sub {
    $user = Networth::Test->createUser0;
    pass 'created user0 test data';
};

subtest 'everything' => sub { 
    my $account = $user->accounts->first;
    my $history = Networth::Out::StatsHistory->new(
        user      => $user,
        accountId => $account->accountId,
    );

    my @expectedStartDates = expectedStartDates($history);
    my @expectedEndDates   = expectedEndDates($history);

    foreach my $stats ($history->stats) {
        my $startDate = pop @expectedStartDates;
        my $endDate   = pop @expectedEndDates;
        is $stats->startDate->ymd, $startDate, "$startDate startDate()";
        is $stats->endDate->ymd,   $endDate,   "$endDate endDate()";
    }

    is_deeply [$history->tags], [qw/clothes food salary/], 'tags()';
};

sub expectedEndDates {
    my $history = shift;
    my $max     = $history->months - 1;

    my $dt = Networth::Utils->now;
    $dt->set_day(1)->set_hour(0)->set_minute(0)->set_second(0);
    $dt->subtract(months => 1);

    my @expected;
    push @expected, $dt->clone->subtract(months => $_)->ymd for (0..$max);
    return @expected;
}

sub expectedStartDates {
    my $history = shift;
    my $max     = $history->months - 1;

    my $dt = Networth::Utils->now;
    $dt->set_day(1)->set_hour(0)->set_minute(0)->set_second(0);

    my @expected;
    push @expected, $dt->clone->subtract(months => $_)->ymd for (0..$max);
    return @expected;
}

done_testing;
