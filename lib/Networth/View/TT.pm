package Networth::View::TT;

use strict;
use base 'Catalyst::View::TT';

__PACKAGE__->config(
   TEMPLATE_EXTENSION => '.tt',
   INCLUDE_PATH       => [ Networth->path_to('root/html'), Networth->path_to('root/js') ],
   TIMER              => Networth->config->{'ttTimer'},
   POST_CHOMP         => 1,
   render_die         => 1,
   ENCODING           => 'utf-8',
#  DEBUG              => 'all',
);

=head1 NAME

Networth::View::TT - TT View for Networth

=head1 DESCRIPTION

TT View for Networth. 

=head1 AUTHOR

=head1 SEE ALSO

L<Networth>

eric,,,

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
