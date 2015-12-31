package Networth::Schema::Result::Asset;
use Moo;
extends 'DBIx::Class::Core';
with 'Networth::Schema::Role::Asset';
with 'Networth::Schema::Role::FilterColumn';

__PACKAGE__->load_components(qw/InflateColumn::DateTime FilterColumn/);
__PACKAGE__->table("Asset");
__PACKAGE__->add_columns(
  "assetId"     , { data_type => "integer" , is_auto_increment => 1   , is_nullable => 0 }  ,
  "userId"      , { data_type => "integer" , is_foreign_key => 1      , is_nullable => 0 }  ,
  "accountId"   , { data_type => "integer" , is_foreign_key => 1      , is_nullable => 0 }  ,
  "description" , { data_type => "varchar" , is_nullable => 0 }       ,
  "value"       , { data_type => "float"   , is_nullable => 0 }       ,
  "date"        , { data_type => "date"    , is_nullable => 0         , timezone => 'UTC' } ,
  "tag"         , { data_type => "varchar" , default_value => \"null" , is_nullable => 1 }  ,
);
__PACKAGE__->filter_column( value => __PACKAGE__->filterDataCurrency );
__PACKAGE__->set_primary_key("assetId");
__PACKAGE__->belongs_to(
  "accounts",
  "Networth::Schema::Result::Account",
  { accountId => "accountId" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);
__PACKAGE__->has_many(
  "importLogs",
  "Networth::Schema::Result::ImportLog",
  { "foreign.assetId" => "self.assetId" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "transactionHistory",
  "Networth::Schema::Result::TransactionHistory",
  { "foreign.assetId" => "self.assetId" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->belongs_to(
  "users",
  "Networth::Schema::Result::User",
  { userId => "userId" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

1;
