unit class Prime::Calculator;

method check-prime(Int:D $num --> Bool:D) {
	return $num.is-prime;
}

method next-prime(Int $after is copy --> Int:D) {
	$after max= 1;
	return ($after+1..*).first(-> $num {self.check-prime($num)});
}