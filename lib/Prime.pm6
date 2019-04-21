use Prime::Calculator;
use Prime::DbCache;
use LogP6;

unit class Prime;

has $!log = get-logger($?CLASS.^name);
has Prime::Calculator $.calc is required;
has Prime::DbCache $.cache is required;

submethod BUILD(:$!calc = Prime::Calculator.new, :$!cache = Prime::DbCache.new) {}

method check-prime(Int:D $num where * > 0 --> Bool:D) {
	$!log.debug("check prime for $num");
	my $result = $!calc.check-prime($num);
	$!log.debug("$num primarily is $result");
	return $result;
}

method find-prime(Int:D $which where * > -1 --> Int:D) {
	$!log.debug("find $which prime");
	my ($found-which, $found-prime) =
			($!cache.find-same-or-less($which) // %(:0which, :2prime))<which prime>;
	$!log.debug("retrive $found-which => $found-prime from cache");
	return $found-prime if $found-which == $which;

	my %save = %();
	for 0..^$which-$found-which {
		$found-prime = $!calc.next-prime($found-prime);
		%save{++$found-which} = $found-prime;
	}
	$!log.debug("want to save to cache {%save.gist}");
	$!cache.save(%save);
	$!log.debug("found prime: $found-prime");
	return $found-prime;
}