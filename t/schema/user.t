use Test::Most;

use Authen::Passphrase::BlowfishCrypt;
use Networth::Schema;
use Networth::Test;

my $user;
subtest 'setup' => sub {
    $user = Networth::Test->createUser0;
    pass 'created user0 test data';
};

subtest 'change password' => sub {
    my $blowfish = Authen::Passphrase::BlowfishCrypt->new(
       passphrase  => 'pie',
       salt_random => 1,
       cost        => 4,
    );
    $user->update( { password => $blowfish });
    $user = Networth::Schema->rs('User')
        ->search({userId => $user->userId})
        ->first;

    ok $user->password->match('pie'), 'password()';
};

subtest 'clean username' => sub {
    $user->update( { username => '<div>pie</div>' });
    $user = Networth::Schema->rs('User')
        ->search({userId => $user->userId})
        ->first;

    is $user->username, 'pie', 'username()';
};

subtest 'networth()' => sub { 
    is $user->networth, "804.00 USD";
};

done_testing;
