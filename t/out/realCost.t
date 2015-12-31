use Test::Most;

use Networth::Out::RealCost;
use Networth::Test;
use Networth::Utils;

Networth::Test->createUser0;
pass 'created user0 test data';

{ 
    my $out = Networth::Out::RealCost->new(
        price          => 10,
        period         => 'monthly',
        roi            => 7,
        withdrawalRate => 4,
        savingsRate    => 100,
        hourlyWage     => 20,
        workDay        => 8,
        daysPerYear    => 232,
    );

    is_deeply $out->realCost, expectedRealCost(), "realCost()";
    is $out->equations, expectedEquations(), "equations()";
    is $out->egg, '3,000', "egg()";
};

done_testing;

sub expectedEquations {
    return <<EOF
\$3,000 x 0.04       = \$120.00 a year 
\$3,000 x 0.04 /  12 = \$ 10.00 a month
\$3,000 x 0.04 /  52 = \$  2.31 a week 
\$3,000 x 0.04 / 365 = \$  0.33 a day  
EOF
}

sub expectedRealCost {[
    { money => 124    , timeWorked => "6hrs" },
    { money => 257    , timeWorked => "1dy&nbsp;&nbsp;4hrs" },
    { money => 399    , timeWorked => "2dys 3hrs" },
    { money => 552    , timeWorked => "3dys 3hrs" },
    { money => 716    , timeWorked => "4dys 3hrs" },
    { money => 892    , timeWorked => "5dys 4hrs" },
    { money => "1,080", timeWorked => "6dys 5hrs" },
    { money => "1,282", timeWorked => "8dys 0hrs" },
    { money => "1,499", timeWorked => "9dys 2hrs" },
    { money => "1,731", timeWorked => "10dys 6hrs" },
    { money => "1,980", timeWorked => "12dys 2hrs" },
    { money => "2,247", timeWorked => "14dys 0hrs" },
    { money => "2,533", timeWorked => "15dys 6hrs" },
    { money => "2,840", timeWorked => "17dys 6hrs" },
    { money => "3,170", timeWorked => "19dys 6hrs" },
    { money => "3,523", timeWorked => "22dys 0hrs" },
    { money => "3,901", timeWorked => "24dys 3hrs" },
    { money => "4,307", timeWorked => "26dys 7hrs" },
    { money => "4,743", timeWorked => "29dys 5hrs" },
    { money => "5,209", timeWorked => "32dys 4hrs" },
]}

