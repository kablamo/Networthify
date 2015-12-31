package Networth::Schema::Result::Account;
use Moo;
extends 'DBIx::Class::Core';
with 'Networth::Schema::Role::Account';

__PACKAGE__->load_components("InflateColumn::DateTime");
__PACKAGE__->table("Account");
__PACKAGE__->add_columns(
  "accountId"       , { data_type => "integer" , is_auto_increment => 1    , is_nullable => 0 }  ,
  "userId"          , { data_type => "integer" , is_foreign_key => 1       , is_nullable => 0 }  ,
  "name"            , { data_type => "varchar" , is_nullable => 0 }        ,
  "parentAccountId" , { data_type => "integer" , default_value  => \"null" , is_foreign_key => 1 , is_nullable => 1 } ,
);
__PACKAGE__->set_primary_key("accountId");
__PACKAGE__->has_many(
  "childAccounts",
  "Networth::Schema::Result::Account",
  { "foreign.parentAccountId" => "self.accountId" },
  { cascade_copy => 0, cascade_delete => 1 },
);
__PACKAGE__->has_many(
  "assets",
  "Networth::Schema::Result::Asset",
  { "foreign.accountId" => "self.accountId" },
  { cascade_copy => 0, cascade_delete => 1 },
);
__PACKAGE__->has_many(
  "importLogs",
  "Networth::Schema::Result::ImportLog",
  { "foreign.accountId" => "self.accountId" },
  { cascade_copy => 0, cascade_delete => 1 },
);
__PACKAGE__->belongs_to(
  "parentAccount",
  "Networth::Schema::Result::Account",
  { accountId => "parentAccountId" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);
__PACKAGE__->has_many(
  "transactionHistory",
  "Networth::Schema::Result::TransactionHistory",
  { "foreign.accountId" => "self.accountId" },
  { cascade_copy => 0, cascade_delete => 1 },
);
__PACKAGE__->belongs_to(
  "user",
  "Networth::Schema::Result::User",
  { "foreign.userId" => "self.userId" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

1;
