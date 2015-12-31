package Networth::Controller::Calculator;
use Moose;
use namespace::autoclean;
use v5.10;

use Networth::Out::RealCost;
use Number::Format qw/unformat_number/;

BEGIN { extends 'Catalyst::Controller' }

sub auto :Private {
    my ($self, $c) = @_;
    $c->stash->{hideAccounts} = 1;
};


sub financialIndependence :Path('/calculator/earlyretirement') :Args {
    my ($self, $c) = @_;
    $c->user;
    my $p = $c->req->params;
    $c->stash->{initialBalance} = $c->req->params->{initialBalance} || 0;
    $c->stash->{income}         = $c->req->params->{income}         || 50_000;
    $c->stash->{expenses}       = $c->req->params->{expenses}       || 20_000;
    $c->stash->{annualPct}      = $c->req->params->{annualPct}      || 5;
    $c->stash->{withdrawalRate} = $c->req->params->{withdrawalRate} || 4;
    $c->stash->{socialButtons}  = 1;
    $c->stash->{title}          = 'Early Retirement Calculator';
    $c->stash->{template}       = 'calculator/fi.tt';
}

sub recurringCharges :Path('/calculator/recurring-charges') :Args(0) {
    my ($self, $c) = @_;
    my $prefs  = $c->user->preferences;
    my $params = $c->req->params;

    $c->stash->{price}          = $params->{price}          || 10;
    $c->stash->{period}         = $params->{period}         || 'monthly';
    $c->stash->{roi}            = $params->{roi}            || $prefs->roi;
    $c->stash->{withdrawalRate} = $params->{withdrawalRate} || $prefs->withdrawalRate;
    $c->stash->{hourlyWage}     = $params->{hourlyWage}     || $prefs->hourlyWage;
    $c->stash->{savingsRate}    = $params->{savingsRate}    || 100;
    $c->stash->{workDay}        = $params->{workDay}        || $prefs->workDay;
    $c->stash->{daysPerYear}    = $params->{daysPerYear}    || $prefs->daysPerYear;

    $c->stash->{$_} = unformat_number($c->stash->{$_})
        foreach qw/price roi withdrawalRate hourlyWage workDay/;

    my $out = Networth::Out::RealCost->new(
        price          => $c->stash->{price},
        period         => $c->stash->{period},
        roi            => $c->stash->{roi},
        withdrawalRate => $c->stash->{withdrawalRate},
        savingsRate    => $c->stash->{savingsRate},
        hourlyWage     => $c->stash->{hourlyWage},
        workDay        => $c->stash->{workDay},
        daysPerYear    => $c->stash->{daysPerYear},
    );

    $c->stash->{out}           = $out;
    $c->stash->{realCost}      = $out->realCost;
    $c->stash->{egg}           = $out->egg;
    $c->stash->{socialButtons} = 1;
    $c->stash->{title}         = 'Understanding Recurring Charges';
    $c->stash->{template}      = 'calculator/realCost.tt';
}

1;
