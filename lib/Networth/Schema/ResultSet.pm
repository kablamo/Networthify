package Networth::Schema::ResultSet;
use Moo;
extends qw{
   DBIx::Class::ResultSet
   DBIx::Class::Helper::ResultSet::AutoRemoveColumns
   DBIx::Class::Helper::ResultSet::CorrelateRelationship
   DBIx::Class::Helper::ResultSet::IgnoreWantarray
   DBIx::Class::Helper::ResultSet::Me
   DBIx::Class::Helper::ResultSet::NoColumns
   DBIx::Class::Helper::ResultSet::Random
   DBIx::Class::Helper::ResultSet::RemoveColumns
   DBIx::Class::Helper::ResultSet::ResultClassDWIM
   DBIx::Class::Helper::ResultSet::SearchOr
   DBIx::Class::Helper::ResultSet::SetOperations
   DBIx::Class::Helper::ResultSet::Shortcut
};


sub select {
    my ($self, @select) = @_;
    return $self->search({}, {'+select' => \@select});
}

sub orderBy { shift->order_by(@_) }
sub groupBy { shift->group_by(@_) }
 
1;
