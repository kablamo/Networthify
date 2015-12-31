package Networth::Test::Data;
use v5.19.6;
use strict;
use warnings;

sub now { Networth::Utils->now }

sub createUser0 {
    my $user0 = Networth::Schema->rs('User')->create({ 
        username => 'test0',
        email    => 'test0',
        guest    => 'n',
        slug     => 'test0',
    });

    my $preferences = Networth::Schema->rs('Preference')->create({ 
        userId         => $user0->userId,
        currencyCode   => 'USD',
        withdrawalRate => 4.0,
        roi            => 7.0,
        hourlyWage     => 20.0,
        workDay        => 8.0,
        daysPerYear    => 232.0,
    });

    my $account0 = Networth::Schema->rs('Account')->create({ 
        userId => $user0->userId,
        name   => 'Checking',
    });
    my $account1 = Networth::Schema->rs('Account')->create({ 
        userId => $user0->userId,
        name   => 'Savings',
    });

    my $userId     = $user0->userId;
    my $accountId0 = $account0->accountId;
    my $accountId1 = $account1->accountId;
    Networth::Schema->rs('Asset')->populate([
        [ qw/ userId accountId description value date tag /],
        [ $userId, $accountId0, 'spiderman underpants', -30.00, now()->clone->subtract(days => 9)->ymd, 'clothes' ],
        [ $userId, $accountId0,    'batman underpants', -20.00, now()->clone->subtract(days => 8)->ymd, 'clothes' ],
        [ $userId, $accountId0,              'cabbage',  -3.00, now()->clone->subtract(days => 7)->ymd, 'food'    ],
        [ $userId, $accountId0,           'miso paste',    -90, now()->clone->subtract(days => 6)->ymd, 'food'    ],
        [ $userId, $accountId0,      'Big Corporation',    990, now()->clone->subtract(days => 5)->ymd, 'salary'  ],
        [ $userId, $accountId1, 'spiderman underpants', -20.00,                             now()->ymd, 'clothes' ],
        [ $userId, $accountId1,    'batman underpants', -20.00,                             now()->ymd, 'clothes' ],
        [ $userId, $accountId1,              'cabbage',  -3.00,                             now()->ymd, 'food'    ],
    ]);

    return $user0;
}

sub createUser1 {
    my $user1 = Networth::Schema->rs('User')->create({ 
        username => 'test1',
        email    => 'test1',
        guest    => 'n',
        slug     => 'test1',
    });

    my $preferences = Networth::Schema->rs('Preference')->create({ 
        userId         => $user1->userId,
        currencyCode   => 'USD',
        withdrawalRate => 4.0,
        roi            => 7.0,
        hourlyWage     => 20.0,
        workDay        => 8.0,
        daysPerYear    => 232.0,
    });

    my $account0 = Networth::Schema->rs('Account')->create({ 
        userId => $user1->userId,
        name   => 'Checking',
    });
    my $account1 = Networth::Schema->rs('Account')->create({ 
        userId => $user1->userId,
        name   => 'Savings',
    });

    my $userId     = $user1->userId;
    my $accountId0 = $account0->accountId;
    my $accountId1 = $account1->accountId;
    Networth::Schema->rs('Asset')->populate([
        [ qw/ userId accountId description value date tag /],
        [ $userId, $accountId0, 'spiderman underpants', -20.00, now()->ymd, 'clothes'],
        [ $userId, $accountId0, 'batman underpants',    -20.00, now()->ymd, 'clothes'],
        [ $userId, $accountId0, 'cabbage',               -3.00, now()->ymd, 'food'   ],
        [ $userId, $accountId1, 'spiderman underpants', -20.00, now()->ymd, 'clothes'],
        [ $userId, $accountId1, 'batman underpants',    -20.00, now()->ymd, 'clothes'],
        [ $userId, $accountId1, 'cabbage',               -3.00, now()->ymd, 'food'   ],
    ]);

    return $user1;
}

1;
