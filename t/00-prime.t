use Test;

use lib 'lib';
use Prime;
use Prime::DbCache;

plan 16;

my $database = './t/test-db.sqlite';
END { $database.IO.unlink }

my Prime::DbCache $cache .= new: :$database;
my Prime $prime .= new: :$cache;

dies-ok { $prime.check-prime(0) }, 'check prime below -1 dies';
for 1..8 -> $num {
	is $prime.check-prime($num), $num.is-prime, "check prime for $num";
}

nok $cache.find-same-or-less(1), 'cache is empty';
dies-ok { $prime.find-prime(-1) }, "find -1 prime dies";
is $prime.find-prime(0), 2, 'find 0 prime';
is $prime.find-prime(1), 3, 'find 1 prime';
is-deeply $cache.find-same-or-less(1), %(:1which, :3prime), '1 => 3 saved';
is $prime.find-prime(4), 11, 'find 4 prime';
is-deeply $cache.find-same-or-less(3), %(:3which, :7prime), '3 => 7 saved';

done-testing;

