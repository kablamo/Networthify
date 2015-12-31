package Networth::Schema::Result::User;
use Moo;
extends 'DBIx::Class::Core';
with 'Networth::Schema::Role::User';

use Authen::Passphrase;
use HTML::Scrubber;

__PACKAGE__->load_components(qw/
    FilterColumn 
    InflateColumn::Authen::Passphrase
    InflateColumn::DateTime 
/);
__PACKAGE__->table("User");
__PACKAGE__->add_columns(
  "userId"     , { data_type => "integer" , is_auto_increment => 1   , is_nullable => 0 } ,
  "facebookId" , { data_type => "varchar" , default_value => \"null" , is_nullable => 1 } ,
  "openId"     , { data_type => "varchar" , default_value => \"null" , is_nullable => 1 } ,
  "username"   , { data_type => "varchar" , is_nullable => 0 }       ,
  "password"   , { data_type => "varchar" , default_value => \"null" , is_nullable => 1, inflate_passphrase => 'rfc2307' } ,
  "email"      , { data_type => "varchar" , default_value => \"null" , is_nullable => 1 } ,
  "gravatar"   , { data_type => "varchar" , default_value => \"null" , is_nullable => 1 } ,
  "guest"      , { data_type => "varchar" , default_value => "y"     , is_nullable => 1 } ,
  "slug"       , { data_type => "varchar" , default_value => \"null" , is_nullable => 1 } ,
);
__PACKAGE__->filter_column( username => {
    filter_to_storage   => sub { 
        # make sure new usernames are clean
        my $u = HTML::Scrubber->new(allow => [])->scrub($_[1]);
        return (length($u) == 32 && $u !~ /\s/) ? 'guest user' : $u;
    },
    filter_from_storage => sub { 
        # handle bad old usernames
        my $u = HTML::Scrubber->new(allow => [])->scrub($_[1]);
        return (length($u) == 32 && $u !~ /\s/) ? 'guest user' : $u;
    }
});
__PACKAGE__->set_primary_key("userId");
__PACKAGE__->add_unique_constraint("email_unique", ["email"]);
__PACKAGE__->add_unique_constraint("facebookid_unique", ["facebookId"]);
__PACKAGE__->add_unique_constraint("openid_unique", ["openId"]);
__PACKAGE__->add_unique_constraint("username_unique", ["username"]);
__PACKAGE__->has_many(
  "accounts",
  "Networth::Schema::Result::Account",
  { "foreign.userId" => "self.userId" },
  { cascade_copy => 0, cascade_delete => 1 },
);
__PACKAGE__->has_many(
  "assets",
  "Networth::Schema::Result::Asset",
  { "foreign.userId" => "self.userId" },
  { cascade_copy => 0, cascade_delete => 1 },
);
__PACKAGE__->has_many(
  "importLogs",
  "Networth::Schema::Result::ImportLog",
  { "foreign.userId" => "self.userId" },
  { cascade_copy => 0, cascade_delete => 1 },
);
__PACKAGE__->has_many(
  "networths",
  "Networth::Schema::Result::Networth",
  { "foreign.userId" => "self.userId" },
  { cascade_copy => 0, cascade_delete => 1 },
);
__PACKAGE__->might_have(
  "preferences",
  "Networth::Schema::Result::Preference",
  { "foreign.userId" => "self.userId" },
  { cascade_copy => 0, cascade_delete => 1 },
);
__PACKAGE__->has_many(
  "transactionHistory",
  "Networth::Schema::Result::TransactionHistory",
  { "foreign.userId" => "self.userId" },
  { cascade_copy => 0, cascade_delete => 1 },
);

1;
