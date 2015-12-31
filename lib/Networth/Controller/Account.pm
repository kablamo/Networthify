package Networth::Controller::Account;
use Moose;
use namespace::autoclean;

use Number::Format;

BEGIN { extends 'Catalyst::Controller' }

sub auto : Private {
    my ($self, $c) = @_;
    return 1 if $c->user->guest ne 'y';
    $c->res->redirect('/');
    $c->detach;
}

sub create : Path('/account/create') Args {
    my ($self, $c) = @_;
    my $name = $c->req->body_params->{name};

    Catalyst::Exception->throw("Account name required") unless $name;

    Catalyst::Exception->throw("An account named ${name} already exists")
        if $c->user->accounts->search({ name => $name })->count;

    my $account = $c->user->accounts->create({ name => $name });
    my $id = $account->accountId;
    my $nm = $account->name;
    
    $c->res->redirect("/transactions/view/$id/$nm");
}

sub delete : Path('/account/delete') Args {
    my ($self, $c) = @_;
    my $accountId = $c->req->body_params->{accountId};

    Catalyst::Exception->throw("Account id required") unless $accountId;

    Catalyst::Exception->throw("You can't do that in the Demo account")
        if $c->user->username eq 'demo';

    $c->user->accounts->withAccountId($accountId)->first->delete;

    $c->res->redirect('/transactions/view/');
}

sub rename : Path('/account/rename') Args {
    my ($self, $c) = @_;
    my $params = $c->req->body_params;

    Catalyst::Exception->throw("Account id and name required")
        unless $params->{accountId} && $params->{name};

    my $account = $c->user->accounts
        ->withAccountId($params->{accountId})
        ->first;

    Catalyst::Exception->throw("Account not found: $params->{accountId}")
        unless $account;

    $account->update({ name => $params->{name} });

    my $id   = $account->accountId;
    my $name = $account->name;
    $c->res->redirect("/transactions/view/$id/$name");
}

sub manage : Path('/account/manage') {
    my ($self, $c) = (shift, shift);
    $c->forward(qw/Root prepareAccountBar/, @_);
    $c->stash->{showAccounts} = 1;
    $c->stash->{hideDate}     = 1;
    $c->stash->{template}     = 'account/manage.tt';
}

__PACKAGE__->meta->make_immutable;

1;
