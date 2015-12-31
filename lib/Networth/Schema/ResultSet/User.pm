package Networth::Schema::ResultSet::User;
use v5.19.6;
use Moo;
extends 'Networth::Schema::ResultSet';

use Data::Currency;

sub withUsername { shift->search({ username => shift}) }
sub withUserId   { shift->search({ userId   => shift}) }


1;
