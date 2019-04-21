use Test;

use lib 'lib';
use Prime::Calculator;

plan 17;

my Prime::Calculator $calc .= new;

for -1..8 -> $num {
	is $calc.check-prime($num), $num.is-prime, "check prime $num";
}
is $calc.next-prime(-1), 2, "next prime after -1";
is $calc.next-prime(0), 2, "next prime after 0";
is $calc.next-prime(1), 2, "next prime after 1";
is $calc.next-prime(2), 3, "next prime after 2";
is $calc.next-prime(3), 5, "next prime after 3";
is $calc.next-prime(4), 5, "next prime after 4";
is $calc.next-prime(5), 7, "next prime after 5";

done-testing;
