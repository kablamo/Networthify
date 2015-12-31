use Test::Most;

use Networth::Schema;
use Networth::Test;
use Networth::Utils;

my $user;
subtest 'setup' => sub {
    $user = Networth::Test->createUser0;
    pass 'created user0 test data';
};

my $account = $user->accounts->first;

subtest 'balance()' => sub { 
    is $account->balance, "847.00 USD";
};

subtest 'categories()' => sub {
    my $date       = Networth::Utils->now->subtract(months => 1);
    my $categories = $account->categories($date);
    my $count = 0;
    while (my $category = $categories->next) {
        ok $category->tag,      'got a tag name  for this category';
        ok $category->tagCount, 'got a tag count for this category';
        $count++;
    }
    is $count, 3, "correct number of categories";
};

subtest 'tagBalance()' => sub {
    my $startDate  = Networth::Utils->now->subtract(months => 1);
    my $endDate    = Networth::Utils->now->add(     months => 1);
    my $tagBalance = $account->tagBalance(
        'clothes', $startDate, $endDate
    );
    is $tagBalance, "-50.00 USD";
};

done_testing;
