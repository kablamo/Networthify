package Networth::Out::RealCost;
use Moo;
use Number::Format qw/format_number/;
use List::Util qw/reduce/;
use Math::Round qw/round/;

=head1 SYNOPSIS

    use Networth::Out::RealCost;
    my $realCost = Networth::Out::RealCost->new(
        price          => $price,
        period         => $period,
        roi            => $roi,           
        withdrawalRate => $withdrawalRate,
        hourlyWage     => $hourlyWage,   
        workDay        => $workDay,     
    );
    $realCost->price;
    $realCost->period;
    $realCost->roi;
    $realCost->withdrawalRate;
    $realCost->egg;
    $realCost->realCost;

=cut

has period         => (is => 'rw');
has price          => (is => 'rw');
has roi            => (is => 'rw');
has withdrawalRate => (is => 'rw');
has savingsRate    => (is => 'rw');
has hourlyWage     => (is => 'rw');
has workDay        => (is => 'rw');
has daysPerYear    => (is => 'rw');
has workTime       => (is => 'rw');
has egg            => (is => 'rw');
has realCost       => (is => 'rw');
has equations      => (is => 'rw');

with qw/Networth::Roles::HumanDuration/;

sub BUILD {
    my $self = shift;

    ## REAL COST and HOURS WORKED

    my $savingsRate = $self->savingsRate / 100;
    my $roi         = $self->roi / 100 / 12;
    my $price       = $self->price;
    $price = $self->period eq 'annual' ? ($price       / 12) 
           : $self->period eq 'weekly' ? ($price * 52  / 12) 
           : $self->period eq 'daily'  ? ($price * 365 / 12)
           : $price;

    my @realCost;
    foreach my $years (1..20) {
        my $months    = $years * 12;
        my $numerator = ((1 + $roi)**$months) - 1;
        my $money     = $price * $numerator / $roi;

        my $timeWorked = $money / ($self->hourlyWage * $savingsRate);

        push @realCost, {
            money      => format_number($money, 0),
            timeWorked => $self->humanDuration($timeWorked),
        }
    }
    $self->realCost(\@realCost);


    ## EGG

    # egg * interest = price
    #            egg = price / interest
    my $withdrawalRate = $self->withdrawalRate / 100;
    my $egg = $price / ($withdrawalRate / 12);
    $self->egg(format_number($egg, 0));


    ## WORK TIME
    my $workTime = $egg / ($self->hourlyWage * $savingsRate);
    $self->workTime($self->humanDuration($workTime));


    ## EQUATIONS

    my $annualCost  = $egg * $withdrawalRate;
       $annualCost  = format_number($annualCost, 2, 1);
    my $monthlyCost = $egg * ($withdrawalRate / 12);
       $monthlyCost = format_number($monthlyCost, 2, 1);
    my $weeklyCost  = $egg * ($withdrawalRate / 52);
       $weeklyCost  = format_number($weeklyCost, 2, 1);
    my $dailyCost   = $egg * ($withdrawalRate / 365);
       $dailyCost   = format_number($dailyCost, 2, 1);

    my $left       = '$' . $self->egg . " x $withdrawalRate";

    my $monthlyPad = length($annualCost) - length($monthlyCost);
    my $weeklyPad  = length($annualCost) - length($weeklyCost);
    my $dailyPad   = length($annualCost) - length($dailyCost);

    $monthlyCost = ' ' x $monthlyPad . $monthlyCost;
    $weeklyCost  = ' ' x $weeklyPad  . $weeklyCost;
    $dailyCost   = ' ' x $dailyPad   . $dailyCost;

    my $equations = "$left       = \$$annualCost a year \n";
    $equations   .= "$left /  12 = \$$monthlyCost a month\n";
    $equations   .= "$left /  52 = \$$weeklyCost a week \n";
    $equations   .= "$left / 365 = \$$dailyCost a day  \n";

    $self->equations($equations);
    return;
}

1;
