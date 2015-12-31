use Test::Most;

use Networth::Out::Stats;
use Networth::Test;
use Networth::Utils;

my $user;
subtest 'setup' => sub {
    $user = Networth::Test->createUser0;
    pass 'created user0 test data';
};

subtest 'everything' => sub { 
    my $account   = $user->accounts->first;
    my $endDate   = Networth::Utils->now->subtract(months => 1);
    my $startDate = Networth::Utils->now;
    my $overview  = Networth::Out::Stats->new(
        user      => $user,
        accountId => $account->accountId,
        startDate => $startDate,
        endDate   => $endDate,
    );

    is $overview->yearsToFI,   3.6, "yearsToFI()";
    is $overview->savingsRate,  86, "savingsRate()";

    is $overview->expenses, "-143.00 USD", "expenses()";
    is $overview->savings,   "847.00 USD", "savings()";
    is $overview->income,    "990.00 USD", "income()";
    is $overview->balance,   "847.00 USD", "balance()";

    is $overview->balance->value, 847, "balance()->value()";

    is $overview->tagBalance('clothes'), '-50.00 USD', 
        "tagBalance('clothes')";
};

done_testing;
