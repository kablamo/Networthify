package Networth::Controller::Root;
use Moose;
use namespace::autoclean;
use feature qw/say/;

use File::Copy qw/copy/;
use List::AllUtils qw/first/;
use Networth::Utils;
use Digest::MD5 qw/md5/;
use Path::Class;

BEGIN { extends 'Catalyst::Controller' }

# Set the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
__PACKAGE__->config(namespace => '');

my $dev = Networth::Utils->dev_mode;

sub begin :Private {
    my ($self, $c) = @_;

    if ($dev) {
        my $out = "root/css/networthify.css";
        my $new = file("root/css/style.less");
        my $old = file("root/css/style.less.old");
        my $newMD5 = md5 scalar $new->slurp;
        my $oldMD5 = md5 scalar $old->slurp;

        if ($oldMD5 ne $newMD5) {
            say "css changed";
            copy($new, $old);
            $c->log->info("running lessc");
            system("/home/eric/node_modules/.bin/lessc ${new} ${out}");
        }
    }

    $c->stash->{dev} = $dev;
    $c->stash->{psgixAssets} = $c->engine->env->{'psgix.assets'};

    my $path = $c->req->path;
    return if $path =~ m{^/calculator};

    if ($path =~ m{^/fi} || $path =~ m{^/earlyretirement}) {
        $c->res->redirect('/calculator/earlyretirement');
        $c->detach;
    }

    Networth::Utils->clearNow;
        
    $c->stash->{path} = $c->req->path;
}

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->res->redirect('/transactions/view')
        if $c->user->guest eq 'n';

    $c->stash->{title}         = 'Networthify.com';
    $c->stash->{socialButtons} = 1;
}

sub default :Path {
    my ( $self, $c ) = @_;
    $c->response->body( 'Page not found' );
    $c->response->status(404);
}

sub end : ActionClass('RenderView') {
    my $self = shift;
    my $c    = shift;

    if (scalar @{ $c->error } && ${$c->error()}[0] !~ /Caught exception/i) {
       $c->stash->{errors}   = $c->error;
       $c->stash->{template} = 'error.tt';
       $c->forward('Networth::View::TT');
       $c->error(0);
    }

    $c->response->content_type('text/html; charset=utf-8')
       unless $c->response->content_type;
    $c->response->header('Cache-Control' => 'max-age: 3600');
}

sub upload :Path('/upload') {
    my ( $self, $c ) = @_;
    $c->user->userId;
    $c->stash->{template} = 'upload.tt';
}

sub prepareAccountBar {
    my ($self, $c, $accountId, $name, $startDate, $endDate) = @_;

    my $accounts = $c->user->accounts;
    my $account  = $accounts->withAccountId($accountId)->first 
        || $accounts->first;

    $accountId = $account->accountId;
    $name      = $account->name;

    my $balance = $account ? $account->balance : $c->user->networth;

    my %when = $c->when($accountId, $startDate, $endDate);

    my $path = $c->req->path;
    $path =~ s|/${accountId}/.*$||;
    $path =~ s|/+$||;

    $c->stash->{when}     = \%when;
    $c->stash->{now}      = $when{now};
    $c->stash->{date}     = $when{end};
    $c->stash->{urls}     = $c->urls($accountId, $name, \%when, $path);
    $c->stash->{accounts} = $accounts;
    $c->stash->{account}  = $account;
    $c->stash->{balance}  = $balance;
}

sub rs { Networth::Schema->rs($_[1]) }

__PACKAGE__->meta->make_immutable;

1;
