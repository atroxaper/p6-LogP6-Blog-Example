use Prime::Calculator;

unit class Prime;
has Prime::Calculator $.calc is required;

submethod BUILD(:$!calc = Prime::Calculator.new) {}

method check-prime(Int:D $num where * > 0 --> Bool:D) {
	return $!calc.check-prime($num);
}

method find-prime(Int:D $which where * > -1 --> Int:D) {
	my $found-prime = 2;
	return 2 if $which == 0;
	for 0..^$which {
		$found-prime = $!calc.next-prime($found-prime);
	}
	return $found-prime;
}