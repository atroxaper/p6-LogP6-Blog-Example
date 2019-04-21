use Prime::Calculator;
use LogP6;

unit class Prime;

has $!log = get-logger($?CLASS.^name);
has Prime::Calculator $.calc is required;

submethod BUILD(:$!calc = Prime::Calculator.new) {}

method check-prime(Int:D $num where * > 0 --> Bool:D) {
	$!log.debug("check prime for $num");
	my $result = $!calc.check-prime($num);
	$!log.debug("$num primarily is $result");
	return $result;
}

method find-prime(Int:D $which where * > -1 --> Int:D) {
	$!log.debug("find $which prime");
	my $found-prime = 2;
	return 2 if $which == 0;
	for 0..^$which {
		$found-prime = $!calc.next-prime($found-prime);
	}
	$!log.debug("found prime: $found-prime");
	return $found-prime;
}