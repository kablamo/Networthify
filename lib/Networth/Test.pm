package Networth::Test;
# import/unimport code adapated from Modern::Perl
 
use strict;
use warnings;

use Networth::Schema;
use Networth::Test::Data;

use mro     ();
use feature ();
 
# enable methods on filehandles; unnecessary when 5.14 autoloads them
use IO::File   ();
use IO::Handle ();
 
sub import {
    warnings->import();
    strict->import();
    feature->import( ':5.14' );
    mro::set_mro( scalar caller(), 'c3' );
}
 
sub unimport {
    warnings->unimport;
    strict->unimport;
    feature->unimport;
}

sub truncateAllTables {
    die "you are not in test mode" 
        unless Networth::Utils->test_mode;

    Networth::Schema->rs($_)->search->delete_all 
        for qw/User Account Asset ImportLog MailingList Networth Preference TransactionHistory/;
}

truncateAllTables();

sub createUser0 { Networth::Test::Data->createUser0(@_) }

1;
