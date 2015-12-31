package Networth::Controller::FI;
use Moose;
use namespace::autoclean;
use v5.10;

BEGIN { extends 'Catalyst::Controller' }

sub retirementCalculator :Path('/retirementcalculator') :Args(0) {
    my ( $self, $c) = @_;
    $c->forward('calculator/earlyretirement');
}

sub earlyRetirement :Path('/earlyretirement') :Args(0) {
    my ( $self, $c) = @_;
    $c->forward('calculator/earlyretirement');
}

sub fi :Path('/fi') :Args(0) {
    my ( $self, $c) = @_;
    $c->forward('calculator/earlyretirement');
}

sub financialIndependence :Path('/financialindependence') :Args(0) {
    my ( $self, $c) = @_;
    $c->forward('calculator/earlyretirement');
}

__PACKAGE__->meta->make_immutable;

1;
