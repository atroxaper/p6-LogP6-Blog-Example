#!/usr/bin/env perl6

use LogP6 :configure;
use lib 'lib';
use Prime;

filter(:name(''), :level($trace), :update);

my Prime $prime .= new;
my \log = get-logger('main-prime');

multi sub MAIN(Int :$is-prime!) {
	my $result = $prime.check-prime($is-prime);
	log.info("Number %d is%s prime", $is-prime, ($result ?? '' !! ' not'));

	CATCH { default { log.error('check prime number fail.', :x($_)) } }
}

multi sub MAIN(Int :$find-prime!) {
	my $result = $prime.find-prime($find-prime - 1);
	log.info('%d prime number is %d', $find-prime, $result);

	CATCH { default { log.error('find prime number fail.', :x($_)) } }
}