package Networth::Schema::ResultSet::Account;
use v5.19.6;
use Moo;
extends 'Networth::Schema::ResultSet';

sub withAccountId { shift->search({ accountId => shift }) }
sub withName      { shift->search({ name      => shift }) }

1;
