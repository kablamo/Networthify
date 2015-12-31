package Networth::View::JSON;
use strict;
use base 'Catalyst::View::JSON';
use JSON::XS;

sub encode_json ($) {
    my($self, $c, $data) = @_;
    my $encoder = JSON::XS->new->ascii->pretty->allow_nonref;
    $encoder->allow_blessed(1);
    $encoder->convert_blessed(0);
    $encoder->encode($data);
}


=head1 NAME

Networth::View::JSON - Catalyst JSON View

=head1 SYNOPSIS

See L<Networth>

=head1 DESCRIPTION

Catalyst JSON View.

=head1 AUTHOR

eric,,,

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
