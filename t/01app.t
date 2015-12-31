use Test::Most;
use Catalyst::Test 'Networth';

ok( request('/')->is_success, 'Request should succeed' );

done_testing();
