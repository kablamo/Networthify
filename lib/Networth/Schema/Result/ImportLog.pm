package Networth::Schema::Result::ImportLog;
use Moo;
extends 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");
__PACKAGE__->table("ImportLog");
__PACKAGE__->add_columns(
  "importLogId" , { data_type => "integer"  , is_auto_increment => 1                , is_nullable => 0 } ,
  "userId"      , { data_type => "integer"  , is_foreign_key => 1                   , is_nullable => 0 } ,
  "accountId"   , { data_type => "integer"  , is_foreign_key => 1                   , is_nullable => 0 } ,
  "date"        , { data_type => "datetime" , default_value => \"current_timestamp" , is_nullable => 1 } ,
  "assetId"     , { data_type => "integer"  , is_foreign_key => 1                   , is_nullable => 0 } ,
);
__PACKAGE__->set_primary_key("importLogId");
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
