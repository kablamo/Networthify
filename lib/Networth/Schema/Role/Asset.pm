package Networth::Schema::Role::Asset;
use v5.19.6;
use Moo::Role;

around 'insert' => sub {
    my $orig = shift;
    my $self = shift;
    my $guard = $self->result_source->schema->txn_scope_guard;

    my $asset = $orig->($self, @_);
    $asset->transactionHistory->create({
        action         => 'insert',
        userId         => $asset->userId,
        accountId      => $asset->accountId,
        newDate        => $asset->date,
        newDescription => $asset->description,
        newValue       => $asset->value,
        newTag         => $asset->tag,
    });

    $guard->commit;

    return $asset;
};

around 'update' => sub {
    my $orig = shift;
    my $self = shift;
    my $guard = $self->result_source->schema->txn_scope_guard;

    my %args;
    $args{oldDate}        = $self->date;
    $args{oldDescription} = $self->description;
    $args{oldValue}       = $self->value;
    $args{oldTag}         = $self->tag;

    my $asset = $orig->($self, @_);
    $asset->transactionHistory->create({
        action         => 'update',
        userId         => $asset->userId,
        accountId      => $asset->accountId,
        newDate        => $asset->date,
        newDescription => $asset->description,
        newValue       => $asset->value,
        newTag         => $asset->tag,
        %args,
    });

    $guard->commit;

    return $asset;
};

around 'delete' => sub {
    my $orig = shift;
    my $self = shift;
    my $guard = $self->result_source->schema->txn_scope_guard;

    # NOTE: $self->user almost always exists.  $self->user does not exist if
    # this sub is called as a result of calling $user_rs->delete_all.  if that
    # is true we don't need to create a transactionHistory row because its
    # about to be deleted anyway.
    if ($self->user) {
        $self->transactionHistory->create({
            action         => 'delete',
            userId         => $self->userId,
            accountId      => $self->accountId,
            oldDate        => $self->date,
            oldDescription => $self->description,
            oldValue       => $self->value,
            oldTag         => $self->tag,
        });
    }
    my $rv = $orig->($self, @_);

    $guard->commit;

    return $rv;
};

sub user { shift->search_related('users')->first }

has total => (
    is      => 'ro',
    lazy    => 1,
    default => sub { shift->get_column('total') },
);

sub totalCurrency {
    my ($self) = @_;
    return Data::Currency->new({
        value   => abs($self->total), 
        code    => $self->user->preferences->currencyCode,
        format  => 'FMT_STANDARD',
    });
}

has tagCount => ( 
    is      => 'ro',
    lazy    => 1,
    default => sub { shift->get_column('tagCount') },
);

sub balanceSoFar {
    my ($self) = @_;
    
    my $rs = Networth::Schema->rs("Asset")->search({
        userId    => $self->userId,
        accountId => $self->accountId,
        date      => { '<=' =>  $self->date->ymd },
    });
 
    return Data::Currency->new({
        value    => $rs->get_column('value')->sum,
        code     => $self->user->preferences->currencyCode,
        format   => 'FMT_STANDARD',
    });
}

1;
