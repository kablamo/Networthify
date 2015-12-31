package Networth::Schema::Result::MailingList;
use Moo;
extends 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");
__PACKAGE__->table("MailingList");
__PACKAGE__->add_columns(
  "email" , { data_type => "varchar" , is_nullable => 0 }   ,
  "beta"  , { data_type => "varchar" , default_value => "n" , is_nullable => 1 } ,
);
__PACKAGE__->set_primary_key("email");

1;
