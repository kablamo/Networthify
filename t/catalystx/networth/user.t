use MooseX::Test::Role;
use Test::Most;

use CatalystX::Networth::User;
use Networth::Test;

subtest '_createNewUser() with no username' => sub {
    my $consumer = consumer_of(
        'CatalystX::Networth::User', 
        _setAuthenCookie => sub { 1 },
        _username        => sub { undef },
    );

    my $user = $consumer->_createNewUser();
    isa_ok $user, 'Networth::Schema::Result::User';
    is $user->guest, 'y';
    is $user->preferences->currencyCode, 'USD';
};

my $user;
subtest '_createNewUser() with a username' => sub {
    my $consumer = consumer_of(
        'CatalystX::Networth::User', 
        _setAuthenCookie => sub { 1 },
        _username        => sub { 'Batman' },
    );

    $user = $consumer->_createNewUser();
    isa_ok $user, 'Networth::Schema::Result::User';
    is $user->guest, 'n';
    is $user->username, 'Batman';
    is $user->preferences->currencyCode, 'USD';
};

subtest '_createNewUser() with a username that already exists' => sub {
    my $consumer = consumer_of(
        'CatalystX::Networth::User', 
        _setAuthenCookie => sub { 1 },
        _username        => sub { 'Batman' },
    );

    dies_ok { $consumer->_createNewUser() };
};

subtest '_getUserFromAuthenCookie()' => sub {
    my $consumer = consumer_of(
        'CatalystX::Networth::User', 
        authen_cookie_value => sub { { userId => $user->userId } },
    );

    my $cookie_user = $consumer->_getUserFromAuthenCookie();
    isa_ok $cookie_user, 'Networth::Schema::Result::User';
    is $cookie_user->guest, 'n';
    is $cookie_user->username, 'Batman';
    is $cookie_user->preferences->currencyCode, 'USD';
};

subtest 'user()' => sub {
    my $consumer = consumer_of(
        'CatalystX::Networth::User', 
        authen_cookie_value => sub { { userId => $user->userId } },
        stash               => sub { {} },
    );

    my $cookie_user = $consumer->user();
    isa_ok $cookie_user, 'Networth::Schema::Result::User';
    is $cookie_user->guest, 'n';
    is $cookie_user->username, 'Batman';
    is $cookie_user->preferences->currencyCode, 'USD';
};


done_testing;
