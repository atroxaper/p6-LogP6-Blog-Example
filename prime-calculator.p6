#!/usr/bin/env perl6

use lib 'lib';
use Prime;

my Prime $prime .= new;

multi sub MAIN(Int :$is-prime!) {
	say "Number $is-prime is ", ($prime.check-prime($is-prime) ?? '' !! 'not '), 'prime';

	CATCH {
		default { say .^name, ' ', .Str }
	}
}

multi sub MAIN(Int :$find-prime!) {
	say "$find-prime prime number is ", $prime.find-prime($find-prime - 1);

	CATCH {
		default { say .^name, ' ', .Str }
	}
}