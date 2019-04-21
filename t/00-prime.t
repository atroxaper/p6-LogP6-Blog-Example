use Test;

use lib 'lib';
use Prime;

plan 13;

my Prime $prime .= new;

dies-ok { $prime.check-prime(0) }, 'check prime below -1 dies';
for 1..8 -> $num {
	is $prime.check-prime($num), $num.is-prime, "check prime for $num";
}

dies-ok { $prime.find-prime(-1) }, "find -1 prime dies";
is $prime.find-prime(0), 2, 'find 0 prime';
is $prime.find-prime(1), 3, 'find 1 prime';
is $prime.find-prime(4), 11, 'find 4 prime';

done-testing;
