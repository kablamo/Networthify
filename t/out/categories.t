use Test::Most;

use Networth::Out::Categories;
use Networth::Test;
use Networth::Utils;

my $now = Networth::Utils->now;
my $user;
my $account;

subtest 'setup' => sub {
    $user = Networth::Test->createUser0;
    $account = $user->accounts->first;
    pass;
};

subtest 'everything' => sub { 
    my $categories = Networth::Out::Categories->new(
        user      => $user,
        accountId => $account->accountId,
        startDate => $now->clone->add(months => 1),
        endDate   => $now->clone->subtract(months => 2),
    );

    my @expectedPos = ({tag => 'salary'  , hoursOfWork => "19dys 2hrs"          , nestEgg => 297_000 , percent => 520 , total => 990});
    my @expectedNeg = ({tag => 'food'    , hoursOfWork => "1dy&nbsp;&nbsp;6hrs" , nestEgg => 27_900  , percent => 520 , total => -93},
                       {tag => 'clothes' , hoursOfWork => "8hrs"                , nestEgg => 15_000  , percent => 280 , total => -50});

    foreach my $pos (@{ $categories->positive }) {
        my $expected = pop @expectedPos;
        is $pos->{tag}                  , $expected->{tag}         , "tag - $expected->{tag}";
        is $pos->{hoursOfWork}          , $expected->{hoursOfWork} , "hoursOfWork";
        is $pos->{nestEgg}->value       , $expected->{nestEgg}     , "nestEgg";
        is $pos->{percent}              , $expected->{percent}     , "percent";
        is $pos->{total}                , $expected->{total}       , "percent";
        is $pos->{totalCurrency}->value , abs $expected->{total}   , "totalCurrency";
    }

    foreach my $neg (@{ $categories->negative }) {
        my $expected = pop @expectedNeg;
        is $neg->{tag}                  , $expected->{tag}         , "tag - $expected->{tag}";
        is $neg->{hoursOfWork}          , $expected->{hoursOfWork} , "hoursOfWork";
        is $neg->{nestEgg}->value       , $expected->{nestEgg}     , "nestEgg";
        is $neg->{percent}              , $expected->{percent}     , "percent";
        is $neg->{total}                , $expected->{total}       , "percent";
        is $neg->{totalCurrency}->value , abs $expected->{total}   , "totalCurrency";
    }
};

done_testing;
