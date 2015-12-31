package Networth::Out::Categories;
use v5.19.6;
use Moo;
use Number::Format qw/format_number/;
use List::Util qw/reduce/;
use Networth::Schema;

=head1 SYNOPSIS

   use Networth::Out::Categories;
   my $categories = Networth::Out::Categories->new(
      user      => $user
      accountId => 1123,
      startDate => DateTime->now,
      endDate   => DateTime->now->add(months => 1),
   );
   $categories->positive;
   $categories->negative;

=cut

has startDate               => (is => 'ro', required => 1);
has endDate                 => (is => 'ro', required => 1);
has user                    => (is => 'ro', required => 1);
has accountId               => (is => 'ro', required => 1);
has positive                => (is => 'rw');
has negative                => (is => 'rw');
has assetsGroupedByCategory => (is => 'lazy');

sub _build_assetsGroupedByCategory {
    my $self = shift;
    $self->user->assets->withAccountId($self->accountId)
        ->withDateBetween($self->startDate, $self->endDate)
        ->select({SUM => 'value', -as => 'total'})
        ->groupBy('tag');
}

has preferences => (
    is         => 'ro', 
    lazy       => 1,
    default    => sub {shift->user->preferences},
    handles    => [qw/currencyCode daysPerYear workDay withdrawalRate/],
);

with qw/Networth::Roles::HumanDuration/;

sub BUILD {
    my $self = shift;
    my (@positive, @negative);
    my $boop = $self->assetsGroupedByCategory;

    my $daysPerMonth  = $self->daysPerYear / 12.0;
    my $hoursPerMonth = $daysPerMonth * $self->workDay;
    my @assets = $self->assetsGroupedByCategory->all;
    my $max = reduce { abs($a->total) > abs($b->total) ? $a : $b } @assets;

    my $income = 0;
    foreach my $a (@assets) {
        next unless $a->total > 0;
        $income += $a->total;
    }

    my $maxMinus = 0;
    foreach my $a (@assets) {
        next unless $a->total < 0;
        next unless $a->total < $maxMinus;
        $maxMinus = $a->total;
    }

    my $maxPlus = 0;
    foreach my $a (@assets) {
        next unless $a->total > 0;
        next unless $a->total > $maxPlus;
        $maxPlus = $a->total;
    }
 
    foreach my $a (@assets) {

        # PERCENT OF TOTAL
        my $maxyMax = $a->total > 0 ? $maxPlus : $maxMinus;
        my $percent = 520 * abs($a->total) / abs($maxyMax);
        $percent = format_number($percent, 0);

        # NEST EGG
        # egg * interest = price
        #            egg = price / interest
        my $categoryTotal  = $a->totalCurrency->value;
        my $withdrawalRate = $self->withdrawalRate / 100;
        my $egg = $categoryTotal / ($withdrawalRate / 12);
        $egg = Data::Currency->new({
            value  => $egg, 
            code   => $self->currencyCode,
            format => 'FMT_STANDARD | FMT_NOZEROS',
        });

        # HOURS WORKED
        # $income / hoursPerMonth = categoryTotal / hoursOfWork
        # hoursOfWork = (categoryTotal * hoursPerMonth) / $income
        my $hours = ($income > 0) 
            ? (($categoryTotal * $hoursPerMonth) / $income) 
            : 0;
        $hours = $self->humanDuration($hours);
 
        my $category = {};
        $category->{tag}           = $a->tag;
        $category->{percent}       = $percent;
        $category->{totalCurrency} = $a->totalCurrency;
        $category->{total}         = $a->total;
        $category->{hoursOfWork}   = $hours;
        $category->{nestEgg}       = $egg;
        #$category->{assets}        = 
        #    $self->user->assets
        #        ->withAccountId($self->accountId)
        #        ->withDateBetween($self->startDate, $self->endDate)
        #        ->groupBy($a->tag);
        
        push @positive, $category if $a->total > 0;
        push @negative, $category if $a->total < 0;
    }
 
    $self->positive(\@positive);
    $self->negative(\@negative);
 
    return $self;
}

1;
