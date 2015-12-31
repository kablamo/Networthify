use Test::Most;

use CatalystX::Test::MockContext;
use HTTP::Request::Common;
use Networth::Controller::Account;
use Networth::Test;

my $m = mock_context('Networth');
my $user;

subtest 'setup' => sub {
    $user = Networth::Test->createUser0;
    pass;
};

subtest '/account/create' => sub {
    my $c = $m->(POST '/account/create');
    $c->user($user);
    throws_ok { Networth::Controller::Account->create($c) } qr/name/,
        'caught name missing exception';

    $c = $m->(POST '/account/create', [name => 'Big Bank']);
    $c->user($user);
    Networth::Controller::Account->create($c);
    my $account = $user->accounts->withName('Big Bank')->first;
    is $account->name, 'Big Bank', 'account name';

    $c = $m->(POST '/account/create', [name => 'Big Bank']);
    $c->user($user);
    throws_ok { Networth::Controller::Account->create($c) } qr/exists/,
        'caught account exists exception';
};

subtest '/account/rename' => sub {
    my $c = $m->(POST '/account/rename');
    $c->user($user);
    throws_ok { Networth::Controller::Account->rename($c) } qr/name/,
        'caught name or id missing exception';

    $c = $m->(POST '/account/rename', [name => 'Big Bank']);
    $c->user($user);
    throws_ok { Networth::Controller::Account->rename($c) } qr/name/,
        'caught name or id missing exception';

    $c = $m->(POST '/account/rename', [name => 'Big Bank', accountId => 1]);
    $c->user($user);
    throws_ok { Networth::Controller::Account->rename($c) } qr/not found/,
        'caught account not found exception';

    $c = $m->(POST '/account/rename', [name => 'Big Boop', accountId => $user->accounts->first->accountId]);
    $c->user($user);
    Networth::Controller::Account->rename($c);
    my $account = $user->accounts->withName('Big Boop')->first;
    is $account->name, 'Big Boop', 'account name';
};


subtest '/account/delete' => sub {
    my $c = $m->(POST '/account/delete');
    $c->user($user);
    throws_ok { Networth::Controller::Account->delete($c) } qr/Account id/,
        'caught account id missing exception';

    my $accountId = $user->accounts->first->accountId;
    $c = $m->(POST '/account/delete', [accountId => $accountId]);
    $c->user($user);
    Networth::Controller::Account->delete($c);
    ok !$user->accounts->withAccountId($accountId)->count, 'account deleted';
};

done_testing;
