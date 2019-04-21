use DBIish;
use LogP6;

unit class Prime::DbCache;

has $!log = get-logger($?CLASS.^name);
has $!db;

submethod TWEAK(Str :$database = './resources/cache.sqlite') {
	$!log.info('connecting to ' ~ $database.IO.path);
	$!db = DBIish.connect("SQLite", :$database);
	$!db.do('create table if not exists cache_find (which integer, prime integer)');
	$!log.debug('connected to ' ~ $database.IO.path);
}

method find-same-or-less($which --> Map) {
	$!log.debug('find cache for ' ~ $which);
	my $stm = $!db.prepare(
		'select which, prime from cache_find ' ~
		"where which <= $which order by which desc limit 1");
	$stm.execute;
	my $result = $stm.allrows[0];
	$stm.finish;
	$!log.debug('found %s for %d', ($result // ()).gist, $which);
	return $result ?? %(:which($result[0]), :prime($result[1])) !! Map;
}

method save(%result) {
	my $stm = $!db.prepare('insert into cache_find (which, prime) values (?, ?)');
	for %result.kv -> $which, $prime {
		$!log.debug("save $which => $prime");
		$stm.execute($which, $prime);
	}
	$stm.finish;
}
