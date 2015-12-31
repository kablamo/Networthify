use Test::Most;

use Networth::Import::Everything;
use Networth::Test;

my $user;
my $account;

subtest 'setup' => sub {
    $user = Networth::Test->createUser0;
    ok $user->userId, 'created user0 test data';

    $account = $user->accounts->first;
};

subtest 'go() with value' => sub { 
    Networth::Import::Everything->new(
        userId       => $user->userId,
        accountId    => $account->accountId,
        delimiter    => ',',
        thousandsSep => ',',
        decimalPoint => '.',
        dtFormat     => 'd/m/y',
        index        => { 
            date        => 0,
            description => 1,
            value       => 2,
            tag         => 3,
        },
    )->go("t/data/value.csv");
    is $account->balance, "-798.44 USD";
};

done_testing;
