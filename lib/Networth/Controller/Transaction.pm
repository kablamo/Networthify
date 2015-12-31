package Networth::Controller::Transaction;
use Moose;

use DateTime;
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

# TODO: Return JSON instead
sub create :Path('/transaction/create') :Args {
    my ($self, $c) = @_;

    my $p = $c->request->params;

    Catalyst::Exception->throw("AccountId is required")     unless $p->{accountId};
    Catalyst::Exception->throw("A description is required") unless $p->{description};
    Catalyst::Exception->throw("A value is required")       unless $p->{value};
    Catalyst::Exception->throw("A date is required")        unless $p->{date};
    Catalyst::Exception->throw("A date is required")        unless $p->{urlBase};
    Catalyst::Exception->throw("The date format is bad")
        unless $p->{date} =~ /^(\d\d\d\d)-(\d\d)-(\d\d)/;

    my $date = DateTime->new(
        year      => $1,
        month     => $2,
        day       => $3,
        time_zone => 'UTC',
    );

    my $asset = $c->user->assets->create({
        accountId   => $p->{accountId},
        description => $p->{description},
        value       => unformat_number($p->{value}),
        tag         => $p->{tag},
        date        => $date,
    });

    $c->res->redirect("/transactions/view/" . $p->{urlBase});
}

sub delete :Path('/transaction/delete') :Args {
    my ($self, $c) = @_;
    my $p = $c->request->params;

    Catalyst::Exception->throw("params are required")
        unless $p->{assetId};

    $c->user->assets->withAssetId($p->{assetId})->first->delete;
}

sub update :Path('/transaction/update') :Args {
    my ($self, $c, @args) = @_;
    my $p = $c->request->params;

    Catalyst::Exception->throw("AcccountId is required")    unless $p->{accountId};
    Catalyst::Exception->throw("AssetId is required")       unless $p->{assetId};
    Catalyst::Exception->throw("A date is required")        unless $p->{date};
    Catalyst::Exception->throw("A description is required") unless $p->{description};
    Catalyst::Exception->throw("A value is required")       unless $p->{value};
    Catalyst::Exception->throw("The date format is bad")
        unless $p->{date} =~ /^(\d\d\d\d)-(\d\d)-(\d\d)/;

    my $date = DateTime->new(
        year      => $1,
        month     => $2,
        day       => $3,
        time_zone => 'UTC',
    );

    my $asset = $c->user->assets->withAssetId($p->{assetId})->first;
    $asset->update({
        description => $p->{description},
        value       => unformat_number($p->{value}),
        tag         => $p->{tag},
        date        => $date,
    });
}

sub split : Path('/transaction/split') Args {
    my ($self, $c) = @_;
    my $p = $c->req->body_params;

    Catalyst::Exception->throw("params are required")
        unless $p->{accountId}    && 
               $p->{accountId2}   && 
               $p->{value}        && 
               $p->{value2}       &&
               $p->{assetId};

    my $oldAsset  = $c->user->assets->withAssetId($p->{assetId})->first;
    my $newAsset  = $c->user->assets->create({
        accountId    => $p->{accountId2},
        description  => $oldAsset->description,
        value        => unformat_number($p->{value2}),
        date         => $oldAsset->date,
        tag          => $oldAsset->tag,
    }) || die "can't insert";

    $oldAsset->update({ value => unformat_number($p->{value}) });
}

sub transfer :Path('/transaction/transfer') :Args {
    my ($self, $c) = @_;
    my $p = $c->request->body_params;

    Catalyst::Exception->throw("params are required")
        unless $p->{accountId}  && 
               $p->{accountId2} && 
               $p->{assetId};

    my $asset = $c->user->assets->search({ assetId => $p->{assetId} })->first;
    $asset->update({ accountId => $p->{accountId2} });
}

sub end :Private {
    my ($self, $c) = @_;

    if ($c->req->body_params->{accountId}) {
        my $accountId = $c->req->body_params->{accountId};
        my $account = $c->user->accounts->withAccountId( $accountId )->first;
        my $balance = $account->balance->as_string;
        $c->stash->{json} = { success => 1, currentBalance => $balance };
    }
    else {
        # /transaction/delete needs this bit
        $c->stash->{json} = { success => 1 };
    }

    $c->forward('View::JSON');
}

__PACKAGE__->meta->make_immutable;

1;
