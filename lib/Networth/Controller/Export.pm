package Networth::Controller::Export;
use Moose;

use Networth::Utils;

BEGIN { extends 'Catalyst::Controller' }

sub auto : Private {
    my ($self, $c) = @_;
    $c->stash->{showAccounts} = 1;
    $c->stash->{hideDate} = 1;
    return 1 if $c->user->guest ne 'y';
    $c->res->redirect('/');
    $c->detach;
}

sub default :Path('/export') :Args {
    my ($self, $c) = (shift, shift);
    $c->forward(qw/Root prepareAccountBar/, @_);
    $c->stash->{importPage} = 1;
    $c->stash->{template}   = 'export.tt';
}

sub exportSubmit :Path('/export/submit') :Args {
    my ($self, $c, $accountId, $accountName, $startDate, $endDate) = @_;
    $c->user->userId; # security

    Catalyst::Exception->throw("AccountId is required")   unless $accountId;
    Catalyst::Exception->throw("AccountName is required") unless $accountName;

    my $dt   = Networth::Utils->now;
    my $date = $dt->ymd . ' ' . $dt->hms;
    my $file = "${accountName}-${date}.csv";

    $c->res->content_type('text/csv');
    $c->res->header('Content-Disposition', qq[attachment; filename="$file"]);

    my $assets = $c->user->assets(accountId => $accountId);
    my $body = '';
    while (my $row = $assets->next) {
        $body .= sprintf(qq/"%s","%s","%s","%s"\r\n/,
            $row->date->ymd,
            $row->description,
            $row->value->value,
            $row->tag,
        );
    }

    $c->res->body($body);
}

__PACKAGE__->meta->make_immutable;

1;
