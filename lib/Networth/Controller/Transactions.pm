package Networth::Controller::Transactions;
use Moose;
use namespace::autoclean;
use feature qw/say/;

use Number::Format qw/unformat_number/;

BEGIN { extends 'Catalyst::Controller' }

sub auto : Private {
    my ($self, $c) = @_;
    $c->stash->{showAccounts} = 1;
    return 1 if $c->user->guest ne 'y';
    $c->res->redirect('/');
    $c->log->warning('permission denied');
    $c->detach;
}

sub view : Path('/transactions/view') {
    my ($self, $c) = (shift, shift);
    $c->forward(qw/Root prepareAccountBar/, @_);
    $c->stash->{template} = 'account/transactions.tt';
}

sub viewData : Path('/transactions/view-data') {
    my ($self, $c) = (shift, shift);
    $c->forward(qw/Root prepareAccountBar/, @_);

    my $startDate = $c->stash->{when}->{start};
    my $endDate   = $c->stash->{when}->{end};

    my $assets = $c->user->assets
        ->withAccountId($c->stash->{account}->accountId)
        ->withDateBetween($startDate, $endDate)
        ->orderBy({ -desc => 'date'});

    my $csv = "accountName,assetId,dateRaw,date,valueRaw,value,description,tag,balanceRaw,balance\n";
    while (my $asset = $assets->next) {
        my $str;
        $str .= '"' . $c->stash->{account}->name      . '",';
        $str .= '"' . $asset->assetId                 . '",';
        $str .= '"' . $asset->date->ymd               . '",';
        $str .= '"' . $asset->date->strftime("%b %d") . '",';
        $str .= '"' . $asset->value->value            . '",';
        $str .= '"' . $asset->value                   . '",';
        $str .= '"' . $asset->description             . '",';
        $str .= '"' . $asset->tag                     . '",';
        $str .= '"' . $asset->balanceSoFar->value     . '",';
        $str .= '"' . $asset->balanceSoFar            . '",';
        $csv .= $str . "\n";
    }

    $c->res->content_type('text/comma-separated-values');
    $c->res->body($csv);
    $c->res->header('Content-Disposition', qq[attachment; filename="data.csv"]);
}

__PACKAGE__->meta->make_immutable;

1;
