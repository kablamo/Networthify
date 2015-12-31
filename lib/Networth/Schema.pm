package Networth::Schema;
use Moo;
extends 'DBIx::Class::Schema';

use Networth::Utils;

__PACKAGE__->load_namespaces(default_resultset_class => 'ResultSet');

my $_schema;
sub schema {
    my ($class) = @_;
    my $db = "networth.db";
    $db = "networth.db.dev"  if Networth::Utils->dev_mode;
    $db = "networth.db.test" if Networth::Utils->test_mode;
    my $dsn  = "dbi:SQLite:$db";
    my $opts = { quote_names => 1, sqlite_unicode => 1 };
    $_schema //= $class->connect($dsn, '', '', $opts);
}

# Networth::Schema->rs('Account');
#   or
# $c->rs('Account');
sub rs {
    my ($class, $rs) = @_;
    $class->schema->resultset($rs);
}

sub trace {
    my ($class, $i) = @_;
    $class->schema->storage->debug( $i || 1 );
}

1;
