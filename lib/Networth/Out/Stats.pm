package Networth::Out::Stats;
use v5.19.6;
use Moo;
with qw/Networth::Roles::Coercions/;

use Number::Format qw/format_number/;

=head1 SYNOPSIS

   use Networth::Out::Stats;
   my $overview = Networth::Out::Stats->new(
        user      => $user,
        accountId => $accountId,
        startDate => $startDate,
        endDate   => $endDate,
        assets    => $assets,
   );
   $overview->yearsToFI;
   $overview->savingsRate;
   $overview->expenses;
   $overview->savings;
   $overview->income;
   $overview->balance;

=cut

has startDate      => (is => 'ro', required => 1);
has endDate        => (is => 'ro', required => 1);
has user           => (is => 'ro', required => 1);
has accountId      => (is => 'ro', required => 1);
has assets         => (is => 'lazy');
has savings        => (is => 'lazy');
has expenses       => (is => 'lazy');
has income         => (is => 'lazy');
has balance        => (is => 'lazy');
has savingsRate    => (is => 'lazy');
has yearsToFI      => (is => 'lazy');
has annualIncome   => (is => 'lazy');
has annualExpenses => (is => 'lazy');
has preferences    => (is => 'lazy', 
    handles => [qw/currencyCode withdrawalRate roi/],
);
sub _build_preferences { shift->user->preferences }

# coerce values to type Data::Currency
around 'savings'        => __PACKAGE__->_build_currency;
around 'expenses'       => __PACKAGE__->_build_currency;
around 'income'         => __PACKAGE__->_build_currency;
around 'balance'        => __PACKAGE__->_build_currency;
around 'annualIncome'   => __PACKAGE__->_build_currency;
around 'annualExpenses' => __PACKAGE__->_build_currency;

sub _build_assets {
    my $self = shift;
    return $self->user->assets
        ->withAccountId($self->accountId)
        ->withDateBetween($self->startDate, $self->endDate);
}

sub _build_yearsToFI {
    my ($self)  = @_;

    my $annualIncome   = $self->income * 12;
    my $roi            = $self->roi            / 100;
    my $withdrawalRate = $self->withdrawalRate / 100;
    my $savingsRate    = $self->savingsRate    / 100;
    my $networth       = $self->user->networth;
    my $yearsToFI      = 0;

    if ($savingsRate > 0 && $self->income > 0) {
        my $top    = (($roi * (1 - $savingsRate) * $annualIncome) / $withdrawalRate) + ($savingsRate * $annualIncome);
        my $bottom = ($roi * $networth->value) + ($savingsRate * $annualIncome);
        $yearsToFI = log($top / $bottom) / log(1 + $roi);
    }

    return format_number($yearsToFI, 1, 1);
}

sub _build_savingsRate {
    my ($self)  = @_;
    return 0 if $self->income == 0;
    my $tmp = $self->savings->value / $self->income->value;
    return format_number($tmp, 2) * 100;
}

sub _build_savings { 
    my $self = shift; 
    return $self->income + $self->expenses;
}

sub _build_income {
    my ($self)  = @_;
    my $income   = 0;
    $self->assets->reset;

    while (my $a = $self->assets->next) {
        $income += $a->value if $a->value > 0;
    }

    return $income;
}

sub _build_expenses {
    my ($self)  = @_;
    my $expenses = 0;
    $self->assets->reset;

    while (my $a = $self->assets->next) {
        $expenses += $a->value if $a->value < 0;
    }

    return $expenses;
}

sub _build_annualIncome   { shift->income   * 12 }
sub _build_annualExpenses { shift->expenses * 12 }

sub _build_balance {
    my ($self)  = @_;
    my $balance = 0;
    $self->assets->reset;

    while (my $a = $self->assets->next) {
        $balance += $a->value;
    }

    return $balance;
}

sub tagBalance {
    my ($self, $tag) = @_;
    return $self->user->assets
        ->withAccountId($self->accountId)
        ->withDateBetween($self->startDate, $self->endDate)
        ->withTag($tag)
        ->balance();
}

1;
