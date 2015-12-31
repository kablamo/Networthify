use Test::Most;

use CatalystX::Test::MockContext;
use HTTP::Request::Common;
use Networth::Test;
use Networth::Schema;

my $m = mock_context('Networth');
my $user;

subtest '/user/signup' => sub {
    my $c = $m->(GET '/user/signup');
    Networth::Controller::User->signup($c);
    is $c->stash->{title}, 'Sign up', "title";
};

subtest '/user/create' => sub {
    my $c = $m->(GET '/user/create');
    throws_ok { Networth::Controller::User->create($c) } qr/password/, 
        'caught missing password exception';

    $c = $m->(POST '/user/create', [password => 'monkey']);
    throws_ok { Networth::Controller::User->create($c) } qr/email/, 
        'caught missing email exception';

    $c = $m->(POST '/user/create', [password => 'monkey', email => 'batman@example.com']);
    Networth::Controller::User->create($c);
    is $c->user->accounts->count,           1, "created an account";
    is $c->user->assets->count,             8, "created some assets";
    is $c->user->transactionHistory->count, 8, "created transaction history";
    $user = $c->user;
};

subtest '/user/login' => sub {
    my $c = $m->(GET '/user/login');
    Networth::Controller::User->login($c);
    is $c->stash->{title}, 'Login', "title";
};

subtest '/user/loginSubmit' => sub {
    my $c = $m->(POST '/user/loginSubmit');
    throws_ok { Networth::Controller::User->loginSubmit($c) } qr/email/, 
        'caught missing email exception';

    $c = $m->(POST '/user/loginSubmit', [email => 'batman@example.com']);
    throws_ok { Networth::Controller::User->loginSubmit($c) } qr/password/, 
        'caught missing password exception';

    $c = $m->(POST '/user/loginSubmit', [password => 'monkey', email => 'batcow@example.com']);
    throws_ok { Networth::Controller::User->loginSubmit($c) } qr/username/, 
        'caught missing username exception';

    $c = $m->(POST '/user/loginSubmit', [password => 'monkee', email => 'batman@example.com']);
    throws_ok { Networth::Controller::User->loginSubmit($c) } qr/wrong/, 
        'caught bad password exception';

    $c = $m->(POST '/user/loginSubmit', [password => 'monkey', email => 'batman@example.com']);
    Networth::Controller::User->loginSubmit($c);
    is $c->user->username, 'batman@example.com', "logged in succesfully";

    my $authenCookie = $c->res->cookies->{'authen-cookie'};
    is $authenCookie->{value}->{userId}, $user->userId, 'authen-cookie userId';
    note("SKIPPING SSL authen-cookie test for now");
    note("SKIPPING HttpOnly authen-cookie test for now");
    #ok $authenCookie->{secure}, 'authen-cookie is SSL only';
};

subtest '/user/view' => sub {
    my $c = $m->(POST '/user/view/' . $user->userId);
    $c->user($user);
    Networth::Controller::User->view($c);
    is $c->stash->{title}, 'Preferences', "title";
    is $c->stash->{user}->username, $user->username, "user";
};

subtest '/user/passwordSubmit' => sub {
    my $c = $m->(POST '/user/passwordSubmit');
    $c->user($user);
    throws_ok { Networth::Controller::User->passwordSubmit($c) } qr/password/,
        'caught missing password exception';

    $c = $m->(POST '/user/passwordSubmit', [password => 'chunky']);
    $c->user($user);
    Networth::Controller::User->passwordSubmit($c);
    ok $c->user->password->match('chunky'), "password updated";
};

subtest '/user/usernameSubmit' => sub {
    my $c = $m->(POST '/user/usernameSubmit');
    $c->user($user);
    throws_ok { Networth::Controller::User->usernameSubmit($c) } qr/username/,
        'caught missing username exception';

    $c = $m->(POST '/user/usernameSubmit', [username => 'chunky']);
    $c->user($user);
    Networth::Controller::User->usernameSubmit($c);
    is $c->user->username, 'chunky', "username updated";
};

subtest '/user/invite' => sub {
    my $c = $m->(POST '/user/invite');
    $c->user($user);
    throws_ok { Networth::Controller::User->invite($c) } qr/email/,
        'caught missing email exception';

    $c = $m->(POST '/user/invite', [email => 'boop@example.com']);
    $c->user($user);
    Networth::Controller::User->invite($c);
    my $email = Networth::Schema->rs('MailingList')->search->first->email;
    is $email, 'boop@example.com', "mailingList updated";
};

subtest '/user/hideInvite' => sub {
    my $c = $m->(POST '/user/hideInvite');
    Networth::Controller::User->hideInvite($c);
    ok $c->res->cookies->{invited}->{value}, "hideInvite cookie set";
};

subtest '/user/logout' => sub {
    my $c = $m->(POST '/user/logout');
    $c->user($user);
    Networth::Controller::User->logout($c);
    ok !$c->_user, "_user is not defined";
    ok !$c->res->cookies->{'authen-cookie'}->{value}, "authen-cookie not set";
};

subtest '/user/delete' => sub {
    my $c = $m->(POST '/user/delete');
    $c->user($user);
    Networth::Controller::User->delete($c);
    my $count = Networth::Schema->rs('User')->search->count;
    ok !$count, 'user was deleted';
};

done_testing;
