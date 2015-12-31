package Networth::Controller::Import;
use Moose;
use namespace::autoclean;
use feature qw/say/;

use DateTime;
use Directory::Scratch;
use File::Copy;
use Number::Format qw/unformat_number/;
use Networth::Import::Head;
use Networth::Import::Everything;
use Path::Class qw/dir file/;

BEGIN { extends 'Catalyst::Controller' }

sub auto : Private {
    my ($self, $c) = @_;
    $c->stash->{showAccounts} = 1;
    $c->stash->{hideDate} = 1;
    return 1 if $c->user->guest ne 'y';
    $c->res->redirect('/');
    $c->detach;
}

sub default :Path('/import') :Args {
    my ($self, $c) = (shift, shift);
    $c->forward(qw/Root prepareAccountBar/, @_);
    $c->stash->{importPage} = 1;
    $c->stash->{template}   = 'import.tt';
}

sub upload :Path('/import/upload') :Args {
    my ($self, $c) = @_;

    if (! $c->req->params->{accountId}) {
        $c->stash->{json} = [ {error => 'accountId required'} ];
        $c->forward('View::JSON');
        return;
    }

    my $accountId = $c->req->params->{accountId};
    my $tmpFile   = file("/tmp/uploads/${accountId}.csv");
    my $upload    = $c->req->upload('file');

    mkdir("/tmp/uploads");
    move($upload->tempname, $tmpFile);

    $c->stash->{json} = [{name => $upload->filename, size => $upload->size}];
    $c->forward('View::JSON');   
}

sub columns :Path('/import/columns') :Args {
    my ($self, $c) = (shift, shift);
    $c->forward(qw/Root prepareAccountBar/, @_);
    $c->user->userId; # security

    my $accountId = $c->stash->{account}->accountId;
    my $tmpFile   = file("/tmp/uploads/${accountId}.csv");

    my @rows = eval { 
        Networth::Import::Head
            ->new(delimiter => ',')
            ->head($tmpFile);
    };
    Catalyst::Exception->throw("Parsing your CSV file failed:<br>$@") if $@;

    $c->stash->{numberOfColumns} = scalar @{ $rows[0] };
    $c->stash->{rows}            = \@rows;
    $c->stash->{template}        = 'import.columns.tt';
}

sub parse :Path('/import/parse') :Args {
    my ($self, $c) = @_;

    $c->req->params->{'accountId'} || die "accountId is required";
    my $params = $c->req->params();

    my $accountId = $c->req->params->{accountId};
    my $tmpFile   = file("/tmp/uploads/${accountId}.csv");

    my $index = {};
    foreach my $i (0..10) {
        next unless defined $params->{$i};
        $index->{date}        = $i if $params->{$i} eq 'date';
        $index->{description} = $i if $params->{$i} eq 'description';
        $index->{value}       = $i if $params->{$i} eq 'value';
        $index->{valueIn}     = $i if $params->{$i} eq 'valueIn';
        $index->{valueOut}    = $i if $params->{$i} eq 'valueOut';
        $index->{category}    = $i if $params->{$i} eq 'category';
    }
    
    die "missing date column"        unless defined $index->{date};
    die "missing description column" unless defined $index->{description};
    die "missing value column"       
        unless (
            defined $index->{value} || 
            (defined $index->{valueIn} && defined $index->{valueOut})
        );

    eval { 
        Networth::Import::Everything->new(
            userId       => $c->user->userId,
            accountId    => $accountId,
            delimiter    => ',',
            thousandsSep => $params->{thousandsSep},
            decimalPoint => $params->{decimalPoint},
            dtFormat     => $params->{dtFormat},
            index        => $index,
        )->go($tmpFile);
    };
    Catalyst::Exception->throw("Parsing your CSV file failed:<br>$@") if $@;

    $c->response->redirect("/transactions/view/${accountId}/" . $c->req->params->{account_name});
}

__PACKAGE__->meta->make_immutable;

1;
