package Networth::Controller::History;
use Moose;
use namespace::autoclean;

use DateTime;

BEGIN { extends 'Catalyst::Controller' }

sub auto : Private {
    my ($self, $c) = @_;
    return 1 if $c->user->guest ne 'y';
    $c->res->redirect('/');
    $c->detach;
}

sub history :Path('/history') :Args {
    my ($self, $c) = (shift, shift);
    $c->forward(qw/Root prepareAccountBar/, @_);

    my $startDate = $c->stash->{when}->{start};
    my $endDate   = $c->stash->{when}->{end};
    $c->stash->{history}  = $self->user->transactionHistory
        ->withAccountId($self->accountId)
        ->withDateBetween($startDate, $endDate);

    $c->stash->{template} = 'history.tt';
}

__PACKAGE__->meta->make_immutable;

1;
