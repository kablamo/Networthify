package Networth::Controller::User;
use v5.19.6;
use Moose;

use Authen::Passphrase::BlowfishCrypt;
use Locale::Currency;
use URI::Escape qw/uri_escape/;
use Networth::Utils;

BEGIN { extends 'Catalyst::Controller' }

sub auto {
    my ($self, $c) = @_; 
    return 1 if $c->user->guest ne 'y';
    return 1 if $c->req->path =~ m{^/login};
    return 1 if $c->req->path =~ m{^/signup};
    return 1 if $c->req->path =~ m{^/create};
    return 1 if $c->req->path =~ m{^/hideinvite};
    return 1 if $c->req->path =~ m{^/invite};
    $c->res->redirect('/');
    $c->log->warning('permission denied');
    $c->detach;
}

sub login : Local {
   my ($self, $c) = @_; 
   $c->stash->{title} = 'Login';
}

sub loginSubmit : Local {
    my ($self, $c) = @_;
 
    my $email    = $c->req->body_params->{email};
    my $password = $c->req->body_params->{password};
 
    Catalyst::Exception->throw('<b>email</b> is a required field') if !$email;
    Catalyst::Exception->throw('<b>password</b> is a required field')
        if !$password;
 
    my $user = Networth::Schema->rs('User')->withUsername($email)->first ||
        Catalyst::Exception->throw("The username <b>$email</b> doesn't exist");
     
    $user->password->match($password) 
       ? $c->user($user)
       : Catalyst::Exception->throw('your email or password is wrong');
 
    $c->response->redirect('/transactions/view');
}

sub signup : Local {
   my ($self, $c) = @_; 
   $c->stash->{title} = 'Sign up';
}

sub create : Local {
    my ($self, $c) = @_; 
 
    Catalyst::Exception->throw('<b>password</b> is a required field')
        if !$c->req->body_params->{password};
    Catalyst::Exception->throw('<b>email</b> is a required field')
        if !$c->req->body_params->{email};
 
    my $blowfish = Authen::Passphrase::BlowfishCrypt->new(
        passphrase  => $c->req->body_params->{password},
        salt_random => 1,
        cost        => 14,
    );

    # FIXME: messy hack
    # if the user is logged in as the demo user, the update below will update
    # the account and the demo account will be come the user's account and the
    # demo username/passwd will no longer work.  This is a fix for that.
    if ($c->user->username eq 'demo') {
        my $user = $c->_createNewUser;
        $c->_user($user);
        $c->stash->{user} = $user;
    }
 
    eval { 
        $c->user->update({
            username => $c->req->body_params->{email},
            password => $blowfish,
            email    => $c->req->body_params->{email},
            guest    => "n",
            slug     => $c->slugify($c->req->body_params->{email}),
        });
    };
    Catalyst::Exception->throw('Sorry that username is taken.') 
        if $@;
    
    my $account = $c->user->accounts->create({name => 'Checking account'});
 
    $account->assets->create({userId => $c->user->userId, %$_}) 
        for $self->transactionsForNewUsers;
 
    $c->res->redirect('/transactions/view/' . $account->accountId . '/' . $account->name);
}

sub transactionsForNewUsers : Private {
    my $today = Networth::Utils->now;
    return ({
        description => "Dinosaur: Manly Fragrance.",
        value       => -70,
        tag         => 'Household',
        date        => $today->clone->subtract(days => 7),
    },{
        description => '800 Super strong magnets',
        value       => -80,
        tag         => 'Entertainment',
        date        => $today->clone->subtract(days => 6),
    },{
        description => 'Debonaire bow tie and suspenders',
        value       => -50,
        tag         => 'Clothes',
        date        => $today->clone->subtract(days => 5),
    },{
        description => 'Concrete coffee mug',
        value       => -10,
        tag         => 'Household',
        date        => $today->clone->subtract(days => 4),
    },{
        description => 'Hearty steak',
        value       => -10,
        tag         => 'Dining out',
        date        => $today->clone->subtract(days => 3),
    },{
        description => '50 pounds of pizza flavored dog kibbles',
        value       => -40,
        tag         => 'Dog',
        date        => $today->clone->subtract(days => 2),
    },{
        description => 'Wild Man Beard Shampoo',
        value       => -20,
        tag         => 'Household',
        date        => $today->clone->subtract(days => 1),
    },{
        description => 'Rocky Mountain Wilderness Rescue',
        value       => 1000,
        tag         => 'Salary',
        date        => $today,
    });
}

sub logout : Local {
   my ($self, $c) = @_;
   $c->unset_authen_cookie();
   $c->_user(undef);
   $c->res->redirect("/");
}  

sub user : Chained('/') CaptureArgs(1) {
   my ($self, $c, $userId) = @_; 
   $c->stash->{userId} = $userId;
}

sub view : Local {
    my ($self, $c) = @_; 

    my @currencies = map  { {code => $_, name => code2currency($_)} }
        grep { $_ !~ /^X/ }
        all_currency_codes;

    $c->stash->{preferences}  = $c->user->preferences;
    $c->stash->{currencies}   = \@currencies;
    $c->stash->{currencyName} = code2currency($c->user->preferences->currencyCode);
    $c->stash->{user}         = $c->user;
    $c->stash->{template}     = 'user/profile.tt';
    $c->stash->{title}        = 'Preferences';
}

sub passwordSubmit : Local {
   my ($self, $c) = @_; 
   my $user     = $c->user;
   my $username = uri_escape($user->username);
   my $userId   = $user->userId;

   Catalyst::Exception->throw("You can't do that as a Demo user")
       if $c->user->username eq 'demo';
   Catalyst::Exception->throw("password required")
       if !$c->req->body_params->{password};

   my $blowfish = Authen::Passphrase::BlowfishCrypt->new(
      passphrase  => $c->req->body_params->{password},
      salt_random => 1,
      cost        => 12,
   );

   $c->user->update({ password => $blowfish });
}

sub usernameSubmit : Local {
   my ($self, $c) = @_;
   my $user     = $c->user;
   my $username = uri_escape($user->username);
   my $userId   = $user->userId;

   Catalyst::Exception->throw("You can't do that as a Demo user")
       if $c->user->username eq 'demo';
   Catalyst::Exception->throw("username required")
       if !$c->req->body_params->{username};

   $c->user->update({ username => $c->req->body_params->{username} });
}

sub preferences : Chained('user') {
   my ($self, $c) = @_;

   my $currencyCode   = $c->req->body_params->{currencyCode};
   my $withdrawalRate = $c->req->body_params->{withdrawalRate};
   my $roi            = $c->req->body_params->{roi};

   Catalyst::Exception->throw('currencyCode required')   if !$currencyCode;
   Catalyst::Exception->throw('withdrawalRate required') if !$withdrawalRate;
   Catalyst::Exception->throw('roi required')            if !$roi;

   $c->user->preferences->update(
      currencyCode   => $currencyCode,
      withdrawalRate => $withdrawalRate,
      roi            => $roi,
   );

   $c->response->redirect("/");
}

sub invite : Local {
    my ($self, $c) = @_;
    my $email = $c->req->body_params->{email};

    Catalyst::Exception->throw('Please enter an <b>email address</b>') 
        if !$email;

    eval { Networth::Schema->rs('MailingList')->create({ email => $email}) };

    $c->response->cookies->{invited} = {value => 1, expires => "+14d"};
    $c->response->redirect("/calculator/earlyretirement");
}

sub hideInvite : Local {
   my ($self, $c) = @_;
   $c->response->cookies->{invited} = {value => 1, expires => "+14d"};
   $c->response->redirect("/calculator/earlyretirement");
}

sub delete : Local {
   my ($self, $c) = @_;
    Catalyst::Exception->throw("You can't do that as a Demo user")
        if $c->user->username eq 'demo';
   $c->user->delete();
   $c->response->redirect("/");
}

1;
