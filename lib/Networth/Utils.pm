package Networth::Utils;
use strict;
use warnings;
use DateTime;
use List::AllUtils qw/any/;
use Sys::Hostname;


sub test_mode {
    return 1 if any {$_ eq 'Test/Most.pm'} keys %INC;
    return 0;
}

sub dev_mode {
    return 1 if hostname ne 'kablamo.xen.prgmr.com';
    return 0;
}

my $NOW;
sub now { 
    return $NOW->clone if $NOW;
    $NOW = DateTime->now;
    $NOW->set_time_zone('UTC'); 
    return $NOW->clone;
}

sub clearNow { $NOW = undef }

sub newDate {
    my $class = shift;
    my $date = DateTime->new(@_);
    $date->set_time_zone('UTC'); 
    return $date;
}

1;
