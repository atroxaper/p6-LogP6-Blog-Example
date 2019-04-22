#!/usr/bin/env perl6

use LogP6 :configure;
use lib 'lib';
use Prime;
use Cro::HTTP::Router;
use Cro::HTTP::Server;
use Cro::Transform;

set-default-pattern('[%date][%level{length=5}][%trait] %msg');
cliche(:name<route>, :matcher<route>, grooves => (
		writer(:name<route>, :handle($*OUT)),
		filter(:name<route>, :level($info)))
);

cliche(:name<prime>, :matcher(/^Prime/), grooves => (
		writer(:name<prime>, :handle($*OUT)),
		filter(:name<prime>, :level($debug)))
);

cliche(:name<calculator>, :matcher<Prime::Calculator>, grooves => (
		writer(:name<calculator>, :handle($*OUT)),
		filter(:name<calculator>, :level($trace)))
);

my Prime $prime .= new;
my \log = get-logger('route');

class CroLogger does Cro::Transform {
	has $.log;
	method consumes() { Cro::HTTP::Response }
	method produces() { Cro::HTTP::Response }
	method transformer(Supply $pipeline --> Supply) {
		supply {
			whenever $pipeline -> $resp {
				my $msg = "{$resp.status} {$resp.request.original-target} - {$resp.request.connection.peer-host}";
				$resp.status < 400 ?? $!log.info($msg) !! $!log.error($msg);
				emit $resp;
			}
		}
	}
}

my $application = route {
	get -> 'is-prime', Int $num {
		CATCH { default { log.error('check prime number fail.', :x($_)); response.status = 500; } }
		log.info("is-prime request for '$num'");
		my $result = $prime.check-prime($num);
		log.info("result is $result");
		content 'text/plain', ~$result;
	}
	get -> 'find-prime', $which {
		CATCH { default { log.error('find prime number fail.', :x($_)); response.status = 500; } }
		log.info("find-prime request for '$which'");
		my $result = $prime.find-prime($which - 1);
		log.info("result is $result");
		content 'text/plain', ~$result;
	}
}
my Cro::Service $prime-service = Cro::HTTP::Server.new:
		:host<localhost>, :port<10000>, :$application,
		after => [ CroLogger.new(:log(log)) ];
$prime-service.start;
log.info('prime service started');

react whenever signal(SIGINT) { $prime-service.stop; exit; }