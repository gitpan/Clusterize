use strict;
use warnings;
use Test::More tests => 16;
use Clusterize;
use Clusterize::Pattern;

my %pairs = (
	'key1' => ['str1', 'str2', 'str3'],
	'key2' => ['str4', 'str5'],
	'key3' => ['str6'],
	'key4' => ['str7', 'str8'],
	'key5' => ['str9', 'str10', 'str11'],
);
my $clusterize = Clusterize->new;
my $digest1 = Clusterize::Pattern->text2digest(	['str1', 'str2', 'str3'] );
is_deeply($digest1, {'[a-z\d]+' => 'str3', '[a-z\d]{4}' => 'str3',
	'[a-z]+\d+' => 'str3', '[a-z]{3}\d{1}' => 'str3', '\w+' => 'str3',
	'\w{4}' => 'str3'}, "test digest1");
$clusterize->add_pair('key1', $digest1);

my $digest2 = Clusterize::Pattern->text2digest(	['str4', 'str5'] );
is_deeply($digest2, {'[a-z\d]+' => 'str5', '[a-z\d]{4}' => 'str5',
	'[a-z]+\d+' => 'str5', '[a-z]{3}\d{1}' => 'str5', '\w+' => 'str5',
	'\w{4}' => 'str5'}, "test digest2");
$clusterize->add_pair('key2', $digest2);

my $digest3 = Clusterize::Pattern->text2digest( ['str6'] );
is_deeply($digest3, {'[a-z\d]+' => 'str6', '[a-z\d]{4}' => 'str6',
	'[a-z]+\d+' => 'str6', '[a-z]{3}\d{1}' => 'str6', '\w+' => 'str6',
	'\w{4}' => 'str6'}, "test digest3");
$clusterize->add_pair('key3', $digest3);

my $digest4 = Clusterize::Pattern->text2digest(	['str7', 'str8'] );
is_deeply($digest4, {'[a-z\d]+' => 'str8', '[a-z\d]{4}' => 'str8',
	'[a-z]+\d+' => 'str8', '[a-z]{3}\\d{1}' => 'str8', '\w+' => 'str8',
	'\w{4}' => 'str8'}, "test digest4");
$clusterize->add_pair('key4', $digest4);

my $digest5 = Clusterize::Pattern->text2digest(	['str9', 'str10', 'str11'] );
is_deeply($digest5, {'[a-z\d]+' => 'str11', '[a-z\d]{4}' => 'str9',
	'[a-z\d]{5}' => 'str11', '[a-z]+\d+' => 'str11', 
	'[a-z]{3}\d{1}' => 'str9', '[a-z]{3}\d{2}' => 'str11',
	'\w+' => 'str11', '\w{4}' => 'str9', '\w{5}' => 'str11'}, "test digest5");
$clusterize->add_pair('key5', $digest5);

is_deeply([sort $clusterize->cluster_list], ['[a-z\d]+', '[a-z\d]{4}',
	'[a-z\d]{5}', '[a-z]+\d+', '[a-z]{3}\d{1}', '[a-z]{3}\d{2}',
	'\w+', '\w{4}', '\w{5}'], "test cluster list");

$clusterize->remove_pair('key5');
is_deeply([sort $clusterize->cluster_list], ['[a-z\d]+', '[a-z\d]{4}', '[a-z]+\d+',
	'[a-z]{3}\d{1}', '\w+', '\w{4}'], "test cluster list after remove of key5");

my ( $c ) = $clusterize->list;
isa_ok($c, 'Clusterize::Pattern', 'test Clusterize::Pattern');
ok($c->digest eq '3fe08ca439efc1f68a2d4cb0f50830b1', 'test digest');
ok($c->pattern eq 'str\d', 'test pattern');
cmp_ok(sprintf("%.3f", $c->accuracy), '==', 0.136, 'test accuracy');
is_deeply($c->pairs, {'key1' => 'str3', 'key2' => 'str5',
	'key3' => 'str6', 'key4' => 'str8'}, 'test pairs');

$clusterize->remove_pair('key4');
is_deeply([sort $clusterize->cluster_list], ['[a-z\d]+', '[a-z\d]{4}', '[a-z]+\d+',
	'[a-z]{3}\d{1}', '\w+', '\w{4}'], "test cluster list after remove of key4");

$clusterize->remove_pair('key2');
is_deeply([sort $clusterize->cluster_list], ['[a-z\d]+', '[a-z\d]{4}', '[a-z]+\d+',
	'[a-z]{3}\d{1}', '\w+', '\w{4}'], "test cluster list after remove of key2");

$clusterize->remove_pair('key3');
is_deeply([sort $clusterize->cluster_list], ['[a-z\d]+', '[a-z\d]{4}', '[a-z]+\d+',
	'[a-z]{3}\d{1}', '\w+', '\w{4}'], "test cluster list after remove of key3");

$clusterize->remove_pair('key1');
is_deeply([sort $clusterize->cluster_list], [], "test cluster list after remove of key1");

exit;

