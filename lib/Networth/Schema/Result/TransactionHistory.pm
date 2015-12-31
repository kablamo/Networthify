package Networth::Schema::Result::TransactionHistory;
use Moo;
extends 'DBIx::Class::Core';
with 'Networth::Schema::Role::FilterColumn';

__PACKAGE__->load_components(qw/InflateColumn::DateTime FilterColumn/);
__PACKAGE__->table("TransactionHistory");
__PACKAGE__->add_columns(
  "transactionHistoryId" , { data_type => "integer"  , is_auto_increment => 1                , is_nullable => 0 } ,
  "action"               , { data_type => "varchar"  , is_nullable => 0 }                    ,
  "assetId"              , { data_type => "integer"  , is_foreign_key => 1                   , is_nullable => 0 } ,
  "userId"               , { data_type => "integer"  , is_foreign_key => 1                   , is_nullable => 0 } ,
  "accountId"            , { data_type => "integer"  , is_foreign_key => 1                   , is_nullable => 0 } ,
  "date"                 , { data_type => "datetime" , default_value => \"current_timestamp" , is_nullable => 1 , timezone => 'UTC' } ,
  "newDescription"       , { data_type => "varchar"  , default_value => \"null"              , is_nullable => 1 } ,
  "newValue"             , { data_type => "float"    , default_value => \"null"              , is_nullable => 1 } ,
  "newDate"              , { data_type => "date"     , default_value => \"null"              , is_nullable => 1 , timezone => 'UTC' } ,
  "newTag"               , { data_type => "varchar"  , default_value => \"null"              , is_nullable => 1 } ,
  "oldDescription"       , { data_type => "varchar"  , default_value => \"null"              , is_nullable => 1 } ,
  "oldValue"             , { data_type => "float"    , default_value => \"null"              , is_nullable => 1 } ,
  "oldDate"              , { data_type => "date"     , default_value => \"null"              , is_nullable => 1 , timezone => 'UTC' } ,
  "oldTag"               , { data_type => "varchar"  , default_value => \"null"              , is_nullable => 1 } ,
);
__PACKAGE__->filter_column( newValue => __PACKAGE__->filterDataCurrency );
__PACKAGE__->filter_column( oldValue => __PACKAGE__->filterDataCurrency );
__PACKAGE__->set_primary_key("transactionHistoryId");
__PACKAGE__->belongs_to(
  "accountId",
  "Networth::Schema::Result::Account",
  { accountId => "accountId" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);
__PACKAGE__->belongs_to(
  "assetId",
  "Networth::Schema::Result::Asset",
  { assetId => "assetId" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);
__PACKAGE__->belongs_to(
  "userId",
  "Networth::Schema::Result::User",
  { userId => "userId" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

1;
