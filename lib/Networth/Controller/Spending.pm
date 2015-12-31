package Networth::Controller::Spending;
use Moose;
use namespace::autoclean;
use feature qw/say/;

use Networth::Out::Categories;
use Networth::Out::Stats;
use Networth::Out::StatsHistory;
use Number::Format qw/format_number/;

BEGIN { extends 'Catalyst::Controller' }

sub auto : Private {
    my ($self, $c) = @_;
    $c->stash->{showAccounts} = 1;
    return 1 if $c->user->guest ne 'y';
    $c->res->redirect('/');
    $c->detach;
}

sub spending : Path('/spending') Args {
    my ($self, $c) = (shift, shift);
    $c->forward(qw/Root prepareAccountBar/, @_);

    my $categories = Networth::Out::Categories->new(
        user      => $c->user, 
        accountId => $c->stash->{account}->accountId,
        startDate => $c->stash->{when}->{start},
        endDate   => $c->stash->{when}->{end},
    );

    my $overview = Networth::Out::Stats->new(
        user      => $c->user,
        accountId => $c->stash->{account}->accountId,
        startDate => $c->stash->{when}->{start},
        endDate   => $c->stash->{when}->{end},
    );

    $c->stash->{overview} = $overview;
    $c->stash->{negCount} = scalar @{ $categories->negative };
    $c->stash->{posCount} = scalar @{ $categories->positive };
    $c->stash->{template} = 'account/categories.tt';
}

sub accountBalance : Path('/analysis/accountbalance') Args {
    my ($self, $c) = (shift, shift);
    $c->forward(qw/Root prepareAccountBar/, @_);

    my $overview = Networth::Out::Stats->new(
        user      => $c->user,
        accountId => $c->stash->{account}->accountId,
        startDate => $c->stash->{when}->{start},
        endDate   => $c->stash->{when}->{end},
    );

    $c->stash->{overview}   = $overview;
    $c->stash->{template}   = 'analysis/accountBalance.tt';
}

sub expenses : Path('/analysis/expenses') Args {
    my ($self, $c) = (shift, shift);
    $c->forward(qw/Root prepareAccountBar/, @_);

    my $overview = Networth::Out::Stats->new(
        user      => $c->user,
        accountId => $c->stash->{account}->accountId,
        startDate => $c->stash->{when}->{start},
        endDate   => $c->stash->{when}->{end},
    );

    $c->stash->{overview}   = $overview;
    $c->stash->{template}   = 'analysis/expenses.tt';
}

sub savingsRate : Path('/analysis/savingsrate') Args {
    my ($self, $c) = (shift, shift);
    $c->forward(qw/Root prepareAccountBar/, @_);

    my $overview = Networth::Out::Stats->new(
        user      => $c->user,
        accountId => $c->stash->{account}->accountId,
        startDate => $c->stash->{when}->{start},
        endDate   => $c->stash->{when}->{end},
    );

    $c->stash->{overview}   = $overview;
    $c->stash->{template}   = 'analysis/savingsRate.tt';
}

sub stats : Path('/analysis/stats') Args {
    my ($self, $c) = (shift, shift);
    $c->forward(qw/Root prepareAccountBar/, @_);

    my $overview = Networth::Out::Stats->new(
        user      => $c->user,
        accountId => $c->stash->{account}->accountId,
        startDate => $c->stash->{when}->{start},
        endDate   => $c->stash->{when}->{end},
    );

    $c->stash->{overview}   = $overview;
    $c->stash->{template}   = 'analysis/stats.tt';
}

sub statsHistory : Path('/analysis/stats-history') Args {
    my ($self, $c) = (shift, shift);
    $c->forward(qw/Root prepareAccountBar/, @_);

    my $overview = Networth::Out::Stats->new(
        user      => $c->user,
        accountId => $c->stash->{account}->accountId,
        startDate => $c->stash->{when}->{start},
        endDate   => $c->stash->{when}->{end},
    );

    my $history = Networth::Out::StatsHistory->new(
        user      => $c->user,
        accountId => $c->stash->{account}->accountId,
#       startDate => $c->stash->{when}->{start},
#       endDate   => $c->stash->{when}->{end},
    );

    $c->stash->{overview} = $overview;
    $c->stash->{history}  = $history;
    $c->stash->{template} = 'analysis/statsHistory.tt';
}

sub categoriesIncomeData : Path('/analysis/categories/income-data') Args {
    my ($self, $c ) = (shift, shift);
    $c->forward(qw/Root prepareAccountBar/, @_);

    my $categories = Networth::Out::Categories->new(
        user      => $c->user, 
        accountId => $c->stash->{account}->accountId,
        startDate => $c->stash->{when}->{start},
        endDate   => $c->stash->{when}->{end},
    );

    my $csv = "name,percent,total,totalCurrency,hoursOfWork,nestEgg\n";
    foreach my $cat (reverse @{ $categories->positive }) {
        print $cat->{tag},"\n";
        my $str = join('","', ucfirst $cat->{tag}, $cat->{percent}, format_number($cat->{total}, 2, 2), $cat->{totalCurrency}, $cat->{hoursOfWork}, $cat->{nestEgg});
        $csv .= "\"${str}\"\n";
    }
    print $csv;
    
    $c->res->content_type('text/comma-separated-values');
    $c->res->body($csv);
    $c->res->header('Content-Disposition', qq[attachment; filename="data.csv"]);
}

sub categoriesExpensesData : Path('/analysis/categories/expenses-data') Args {
    my ($self, $c ) = (shift, shift);
    $c->forward(qw/Root prepareAccountBar/, @_);

    my $categories = Networth::Out::Categories->new(
        user      => $c->user, 
        accountId => $c->stash->{account}->accountId,
        startDate => $c->stash->{when}->{start},
        endDate   => $c->stash->{when}->{end},
    );

    my $csv = "name,percent,total,totalCurrency,hoursOfWork,nestEgg\n";
    foreach my $cat (@{ $categories->negative }) {
        print $cat->{tag},"\n";
        my $str = join('","', ucfirst $cat->{tag}, $cat->{percent}, format_number($cat->{total}, 2, 2), $cat->{totalCurrency}, $cat->{hoursOfWork}, $cat->{nestEgg});
        $csv .= "\"${str}\"\n";
    }
    print $csv;
    
    $c->res->content_type('text/comma-separated-values');
    $c->res->body($csv);
    $c->res->header('Content-Disposition', qq[attachment; filename="data.csv"]);
}

sub accountBalanceData : Path('/analysis/account-balance-data') Args(1) {
    my ($self, $c, $accountId) = @_;

    my $history = Networth::Out::StatsHistory->new(
        user      => $c->user,
        accountId => $accountId,
        months    => 12,
    );

    my $csv = "datetime,balance\n";
    foreach my $stat ($history->stats) {
        my $str = join('","', $stat->endDate->ymd, $stat->balance->value);
        $csv .= "\"${str}\"\n";
    }

    $c->res->content_type('text/comma-separated-values');
    $c->res->body($csv);
    $c->res->header('Content-Disposition', qq[attachment; filename="data.csv"]);
}

sub expensesData : Path('/analysis/expenses-data') Args(1) {
    my ($self, $c, $accountId) = @_;

    my $history = Networth::Out::StatsHistory->new(
        user      => $c->user,
        accountId => $accountId,
        months    => 12,
    );

    my $csv = "datetime,income,expenses\n";
    foreach my $stat ($history->stats) {
        my $str = join('","', $stat->endDate->ymd, $stat->income->value, abs $stat->expenses->value);
        $csv .= "\"${str}\"\n";
    }

    $c->res->content_type('text/comma-separated-values');
    $c->res->body($csv);
    $c->res->header('Content-Disposition', qq[attachment; filename="data.csv"]);
}

sub savingsRateData : Path('/analysis/savings-rate-data') Args(1) {
    my ($self, $c, $accountId) = @_;

    my $history = Networth::Out::StatsHistory->new(
        user      => $c->user,
        accountId => $accountId,
        months    => 12,
    );

    my $csv = "datetime,savingsRate\n";
    foreach my $stat ($history->stats) {
        my $str = join('","', $stat->endDate->ymd, $stat->savingsRate);
        $csv .= "\"${str}\"\n";
    }

    $c->res->content_type('text/comma-separated-values');
    $c->res->body($csv);
    $c->res->header('Content-Disposition', qq[attachment; filename="data.csv"]);
}

__PACKAGE__->meta->make_immutable;

1;
