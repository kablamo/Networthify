package Networth::Schema::Result::Preference;
use Moo;
extends 'DBIx::Class::Core';
with 'Networth::Schema::Role::Preference';

__PACKAGE__->load_components("InflateColumn::DateTime");
__PACKAGE__->table("Preferences");
__PACKAGE__->add_columns(
  "userId"         , { data_type => "integer" , is_auto_increment => 1                , is_foreign_key => 1 , is_nullable => 0 } ,
  "currencyCode"   , { data_type => "varchar" , default_value => \"null"              , is_nullable => 1 }  ,
  "lastChanged"    , { data_type => "date"    , default_value => \"current_timestamp" , is_nullable => 1 }  ,
  "withdrawalRate" , { data_type => "float"   , default_value => "4.0"                , is_nullable => 1 }  ,
  "roi"            , { data_type => "float"   , default_value => "7.0"                , is_nullable => 1 }  ,
  "hourlyWage"     , { data_type => "float"   , default_value => 20                   , is_nullable => 1 }  ,
  "workDay"        , { data_type => "float"   , default_value => 8                    , is_nullable => 1 }  ,
  "daysPerYear"    , { data_type => "float"   , default_value => 232                  , is_nullable => 1 }  ,
);
__PACKAGE__->set_primary_key("userId");
__PACKAGE__->belongs_to(
  "userId",
  "Networth::Schema::Result::User",
  { userId => "userId" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

1;
