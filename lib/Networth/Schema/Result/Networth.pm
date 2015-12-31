package Networth::Schema::Result::Networth;
use Moo;
extends 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");
__PACKAGE__->table("Networth");
__PACKAGE__->add_columns(
  "networthId" , { data_type => "integer" , is_auto_increment => 1 , is_nullable => 0 } ,
  "userId"     , { data_type => "integer" , is_foreign_key => 1    , is_nullable => 0 } ,
  "total"      , { data_type => "float"   , is_nullable => 0 }     ,
  "date"       , { data_type => "date"    , is_nullable => 0 }     ,
);
__PACKAGE__->set_primary_key("networthId");
__PACKAGE__->belongs_to(
  "userId",
  "Networth::Schema::Result::User",
  { userId => "userId" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

1;
