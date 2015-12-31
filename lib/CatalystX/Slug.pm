package CatalystX::Slug;
use Moose::Role;

sub slugify {
   my $self   = shift or die;
   my $string = shift or die;

   $string =~ s/['`]//g;                     # remove apostrophe's
   $string =~ s/\s*@\s*/ at /g;              # @ -> at
   $string =~ s/\s*&\s*/ and /g;             # & -> and
   $string =~ s/\s*[^A-Za-z0-9\.\_]\s*/-/g;  # non alphanumeric to -
   $string =~ s/-+/-/g;                      # -- -> -
   $string =~ s/\A[-\.]+|[-\.]+\z//g;        # remove leading/trailing -

   return $string;
}

1;
