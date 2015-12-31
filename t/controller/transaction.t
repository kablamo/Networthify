use Test::Most;

use CatalystX::Test::MockContext;
use HTTP::Request::Common;
use Networth::Controller::Transaction;
use Networth::Test;

my $m = mock_context('Networth');
my $user;
my $assetId;
my $accountId;
my $accountId2;

subtest 'setup' => sub {
    $user = Networth::Test->createUser0;
    my $accounts = $user->accounts;
    $accountId  = $accounts->next->accountId;
    $accountId2 = $accounts->next->accountId;
    pass;
};


subtest '/transaction/create' => sub {
    my $c = $m->(POST '/transaction/create');
    $c->user($user);
    throws_ok { Networth::Controller::Transaction->create($c) } qr/required/,
        'caught missing fields exception';

    $c = $m->(POST '/transaction/create', [
        accountId   => $accountId,
        description => 'boop',
        value       => 25,
        date        => '2013-12-31',
        urlBase     => 'boop'
    ]);
    $c->user($user);
    Networth::Controller::Transaction->create($c);

    my $asset = $user->assets->withDescription('boop')->first;
    is $asset->accountId, $accountId, 'accountId';
    is $asset->description, 'boop', 'description';
    is $asset->value->value, 25, 'value';
    is $asset->date, '2013-12-31T00:00:00', 'date';

    is $user->transactionHistory->count, 1, 'found transactionHistory';

    $assetId = $asset->assetId;
};

subtest '/transaction/update' => sub {
    my $c = $m->(POST '/transaction/update');
    $c->user($user);
    throws_ok { Networth::Controller::Transaction->update($c) } qr/required/,
        'caught missing fields exception';

    $c = $m->(POST '/transaction/update', [
        accountId   => $accountId,
        assetId     => $assetId,
        description => 'kablamo',
        value       => 40,
        date        => '2013-12-31',
    ]);
    $c->user($user);
    Networth::Controller::Transaction->update($c);

    my $asset = $user->assets->withAssetId($assetId)->first;
    is $asset->accountId, $accountId, 'accountId';
    is $asset->assetId, $assetId, 'assetId';
    is $asset->description, 'kablamo', 'description';
    is $asset->value->value, 40, 'value';
    is $asset->date, '2013-12-31T00:00:00', 'date';

    is $user->transactionHistory->count, 2, 'found transactionHistory';
};

subtest '/transaction/split in the same account' => sub {
    my $c = $m->(POST '/transaction/split');
    $c->user($user);
    throws_ok { Networth::Controller::Transaction->split($c) } qr/required/,
        'caught missing fields exception';

    $c = $m->(POST '/transaction/split', [
        accountId   => $accountId,
        accountId2  => $accountId,
        value       => 20,
        value2      => 20,
        assetId     => $assetId,
    ]);
    $c->user($user);
    Networth::Controller::Transaction->split($c);

    my $assets = $user->assets->withDescription('kablamo');

    my $asset1 = $assets->next;
    is $asset1->accountId, $accountId, 'accountId';
    is $asset1->assetId, $assetId, 'assetId';
    is $asset1->description, 'kablamo', 'description';
    is $asset1->value->value, 20, 'value';
    is $asset1->date, '2013-12-31T00:00:00', 'date';

    my $asset2 = $assets->next;
    is $asset2->accountId, $accountId, 'accountId';
    is $asset2->description, 'kablamo', 'description';
    is $asset2->value->value, 20, 'value';
    is $asset2->date, '2013-12-31T00:00:00', 'date';
    is $asset2->tag, $asset1->tag, 'tag';

    is $user->transactionHistory->count, 4, 'found transactionHistory';
};

subtest '/transaction/split into different accounts' => sub {
    my $c = $m->(POST '/transaction/split');
    $c->user($user);
    throws_ok { Networth::Controller::Transaction->split($c) } qr/required/,
        'caught missing fields exception';

    $c = $m->(POST '/transaction/split', [
        accountId   => $accountId,
        accountId2  => $accountId2,
        value       => 10,
        value2      => 10,
        assetId     => $assetId,
    ]);
    $c->user($user);
    Networth::Controller::Transaction->split($c);

    my $assets = $user->assets->withDescription('kablamo')->orderBy('assetId');

    my $asset1 = $assets->next;
    is $asset1->accountId, $accountId, 'accountId';
    is $asset1->assetId, $assetId, 'assetId';
    is $asset1->description, 'kablamo', 'description';
    is $asset1->value->value, 10, 'value';
    is $asset1->date, '2013-12-31T00:00:00', 'date';

    my $asset2 = $assets->next;
    is $asset2->accountId, $accountId, 'accountId';
    is $asset2->description, 'kablamo', 'description';
    is $asset2->value->value, 20, 'value';
    is $asset2->date, '2013-12-31T00:00:00', 'date';

    my $asset3 = $assets->next;
    is $asset3->accountId, $accountId2, 'accountId';
    is $asset3->description, 'kablamo', 'description';
    is $asset3->value->value, 10, 'value';
    is $asset3->date, '2013-12-31T00:00:00', 'date';
    is $asset3->tag, $asset1->tag, 'tag';

    is $user->transactionHistory->count, 6, 'found transactionHistory';
};

subtest '/transaction/transfer' => sub {
    my $c = $m->(POST '/transaction/transfer');
    $c->user($user);
    throws_ok { Networth::Controller::Transaction->transfer($c) } qr/required/,
        'caught missing fields exception';

    $c = $m->(POST '/transaction/transfer', [
        accountId   => $accountId,
        accountId2  => $accountId2,
        assetId     => $assetId,
    ]);
    $c->user($user);
    Networth::Controller::Transaction->transfer($c);

    my $asset = $user->assets->withAssetId($assetId)->first;
    is $asset->accountId, $accountId2, 'the asset moved';

    is $user->transactionHistory->count, 7, 'found transactionHistory';
};

subtest '/transaction/delete' => sub {
    my $c = $m->(POST '/transaction/delete');
    $c->user($user);
    throws_ok { Networth::Controller::Transaction->delete($c) } qr/required/,
        'caught missing fields exception';

    $c = $m->(POST '/transaction/delete', [ assetId => $assetId ]);
    $c->user($user);
    Networth::Controller::Transaction->delete($c);

    ok !$user->assets->withAssetId($assetId)->count, 'the asset was deleted';

    is $user->transactionHistory->count, 8, 'found transactionHistory';
};

done_testing;
