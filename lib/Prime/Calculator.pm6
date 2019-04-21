use LogP6;

unit class Prime::Calculator;

has $!log = get-logger($?CLASS.^name);

method check-prime(Int:D $num --> Bool:D) {
	$!log.trace('will check prime for num ' ~ $num);
	my $result = $num.is-prime;
	$!log.trace('num %s prime is %s', $num, $result);
	return $result;
}

method next-prime(Int $after is copy --> Int:D) {
	$!log.trace('will find next prime after ' ~ $after);
	$after max= 1;
	my $result = ($after+1..*).first(-> $num {self.check-prime($num)});
	$!log.trace('next prime after %d is %d', $after, $result);
	return $result;
}