use Test;

use lib 'lib';
use Prime::DbCache;

plan 6;

my $database = './t/test-db.sqlite';
END { $database.IO.unlink }

my Prime::DbCache $cache .= new: :$database;
is $cache.find-same-or-less(0)<prime>, Any, 'did not find prime in empty base';
$cache.save(%(0 => 2, 1 => 3, 2 => 5));
is $cache.find-same-or-less(0)<prime>, 2, 'find 2 in base';
is $cache.find-same-or-less(1)<prime>, 3, 'find 3 in base';
is $cache.find-same-or-less(2)<prime>, 5, 'find 5 in base';
is $cache.find-same-or-less(3)<prime>, 5, 'find 5 for 3 in base';
is $cache.find-same-or-less(3)<which>, 2, '2 is third in base';

done-testing;
