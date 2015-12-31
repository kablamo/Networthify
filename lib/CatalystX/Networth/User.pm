package CatalystX::Networth::User;
use Moo::Role;
use v5.19.6;

use Data::Entropy::Algorithms qw/rand/;
use DateTime;
use DateTime::Format::SQLite;
use Networth::Utils;

requires qw/req set_authen_cookie authen_cookie_value/;

has '_user' => (is => "rw");

sub user {
    my $self = shift;
    my $user = shift;

    # set
    if (defined $user) {
        $self->_user($user);
        $self->_setAuthenCookie($user->userId);
        $self->stash->{user} = $user;
        return $user;
    }

    # get
    $user = defined $self->_user
        ? ($self->_user)
        : ($self->_getUserFromAuthenCookie || $self->_createNewUser);

    $self->_user($user);
    $self->stash->{user} = $user;

    return $user;
}

sub _setAuthenCookie {
    my $self = shift or die;
    my $userId = shift or die;

    my %expires;
    %expires = (expires => '+1y') if $self->req()->param('remember');
    $self->set_authen_cookie(value => {userId => $userId}, %expires);

    return;
}

sub _getUserFromAuthenCookie {   
    my $self   = shift or die;
    my $cookie = $self->authen_cookie_value();
    return unless $cookie && $cookie->{userId};
    return Networth::Schema->rs('User')
        ->search({userId => $cookie->{userId}})
        ->first;
}

sub _username { shift->req->param('email') }

sub _createNewUser {
    my $self = shift;
    my $guest = 'y';
    my $username = $self->_username;

    if (!defined $username) {
        $username = rand(10000000000000000);
    }
    else {
        $guest = 'n';

        my $duplicateUser = Networth::Schema->rs('User')
            ->search({ username => $username })
            ->first;

        Catalyst::Exception->throw('That username is already taken')
            if defined $duplicateUser;
    }

    my $user = Networth::Schema->rs('User')->create({
        username => $username, 
        guest    => $guest,
    });
    Networth::Schema->rs('Preference')->create({ 
        userId       => $user->userId,
        currencyCode => 'USD', 
        lastChanged  => Networth::Utils->now->ymd,
    });
    
    $self->_setAuthenCookie($user->userId);

    return $user;
}

1;
