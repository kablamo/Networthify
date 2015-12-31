use Test::Most;

use DateTime;
use Networth::Schema;
use Networth::Test;
use Networth::Utils;

my $user;
subtest 'setup' => sub {
    $user = Networth::Test->createUser0;
    pass 'created user0 test data';
};

my $accountId = $user->accounts->first->accountId;
my $assets    = Networth::Schema->rs('Asset') 
    ->withAccountId($accountId)
    ->orderBy('date');

subtest 'value()' => sub {
    my $value = $assets->next->value;
    is $value, '-30.00 USD', 'value()';
    is $value->value, -30.00, 'value()->value';
};

subtest 'balanceSoFar()' => sub {
    $assets->reset;
    is $assets->next->balanceSoFar, '-30.00 USD', 'balanceSoFar() 0';
    is $assets->next->balanceSoFar, '-50.00 USD', 'balanceSoFar() 1';
    is $assets->next->balanceSoFar, '-53.00 USD', 'balanceSoFar() 2';
};

subtest 'group by tag' => sub {
    my $startDate = Networth::Utils->now;
    my $endDate   = Networth::Utils->now->subtract(months => 1);
    my $assets    = Networth::Schema->rs('Asset') 
        ->withAccountId($accountId)
        ->withDateBetween($startDate, $endDate)
        ->select({SUM => 'value', -as => 'total'})
        ->groupBy('tag')
        ->orderBy({-asc => 'total'});

    my $taggedAssets = $assets->next;
    is $taggedAssets->tag,                'food', 'tag - food';
    is $taggedAssets->totalCurrency, '93.00 USD', 'totalCurrency';

    $taggedAssets = $assets->next;
    is $taggedAssets->tag,             'clothes', 'tag - clothes';
    is $taggedAssets->totalCurrency, '50.00 USD', 'totalCurrency';
};

subtest 'create/update/delete with transactionHistory' => sub {
    my $accountId = $user->accounts->first->accountId;
    my $asset = $user->assets->create({
        accountId   => $accountId,
        description => 'boop',
        value       => 25,
        date        => DateTime->now,
    });
    is $user->transactionHistory->withAssetId($asset->assetId)->count, 1,
        'created with transactionHistory';

    $asset->update({ description => 'moop' });
    is $user->transactionHistory->withAssetId($asset->assetId)->count, 2,
        'updated with transactionHistory';

    $asset->delete;
    is $user->transactionHistory->withAssetId($asset->assetId)->count, 3,
        'deleted with transactionHistory';
};

subtest 'DateTime objects are handled' => sub {
    my $accountId = $user->accounts->first->accountId;
    my $now = DateTime->now;
    my $asset = $user->assets->create({
        accountId   => $accountId,
        description => 'ballyhoo',
        value       => 25,
        date        => $now,
    });
    is $asset->date->year, $now->year, 'ok';
};

done_testing;
