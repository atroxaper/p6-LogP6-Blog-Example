# First look at LogP6

As a Java developer, I can not imagine serious application without writing logs.
A good logging system should be:
- fine-tunable. For example, we must be able to write something to a console,
other things to file or even a database. Of course, there are conditions for
writing or not;
- useful both during developing and during debugging. It means apply logger
configuration in runtime;
- as fast as possible. Logging is necessary but secondary in comparison to
application logic;
- friendly for using it in library modules. If a library author wants to leave
logging in the library code then then end user must not feel discomfort about
it.

The idea to write the new logging system originated from a thought that almost all
already written logging systems parse a pattern (or layout - a string with
placeholders for log data) each time the user wants to write a log or even several
times per log. Other systems do not provide a possibility to have several loggers
in an application. Eventually, I couldn't find a logging module where I can
apply a patch with all my wishes without rewriting a whole module and lose its
unique author's idea. Note that LogP6 is not a clone of another library from
other languages.

Let's try to imagine a process of application writing and see how we can use
LogP6. You can find source codes of the example on
[GitHub](https://github.com/atroxaper/p6-logp6-blog-example).

## Initial commit. Create prime numbers calculator

To show LogP6 basics we will write a web service which can check if a
number is prime or not and can return N-st prime number (for example 73 is the
21st prime number).

Firstly we need a calculator with two methods and a test for it, of course:

```perl6
# lib/Prime/Calculator.pm6
unit class Prime::Calculator;

method check-prime(Int:D $num --> Bool:D) { $num.is-prime }

method next-prime(Int $after is copy --> Int:D) {
  $after max= 1;
  return ($after+1..*).first(-> $num {self.check-prime($num)});
}

# t/00-calculator.t
use Test;
use lib 'lib';
use Prime::Calculator;

plan 13;

my Prime::Calculator $calc .= new;

for -1..8 -> $num { is $calc.check-prime($num), $num.is-prime, "check prime $num" }
is $calc.next-prime(-1), 2, "next prime after -1";
is $calc.next-prime(0), 2, "next prime after 0";
is $calc.next-prime(5), 7, "next prime after 5";

done-testing;
```

And the main module. Let's call it Prime:

```perl6
# /lib/Prime.pm6
use Prime::Calculator;

unit class Prime;
has Prime::Calculator $.calc is required;

submethod BUILD(:$!calc = Prime::Calculator.new) {}

method check-prime(Int:D $num where * > 0 --> Bool:D) { $!calc.check-prime($num) }

method find-prime(Int:D $which where * > -1 --> Int:D) {
  my $found-prime = 2;
  return 2 if $which == 0;
  for 0..^$which {
    $found-prime = $!calc.next-prime($found-prime);
  }
  return $found-prime;
}

# t/01-prime.t
use Test;
use lib 'lib';
use Prime;

plan 12;

my Prime $prime .= new;

dies-ok { $prime.check-prime(0) }, 'check prime below -1 dies';
for 1..8 -> $num { is $prime.check-prime($num), $num.is-prime, "check prime for $num" }
dies-ok { $prime.find-prime(-1) }, "find -1 prime dies";
is $prime.find-prime(0), 2, 'find 0 prime';
is $prime.find-prime(4), 11, 'find 4 prime';

done-testing;
```

As we are just starting to develop a service we write the MAIN script for now:

```perl6
# prime-calculator.p6
#!/usr/bin/env perl6

use lib 'lib';
use Prime;

my Prime $prime .= new;

multi sub MAIN(Int :$is-prime!) {
  say "Number $is-prime is ", ($prime.check-prime($is-prime) ?? '' !! 'not '), 'prime';
  CATCH { default { say .^name, ' ', .Str } }
}

multi sub MAIN(Int :$find-prime!) {
  say "$find-prime prime number is ", $prime.find-prime($find-prime - 1);
  CATCH { default { say .^name, ' ', .Str } }
}
```

As you can see, we use `say` routine to output results to the user. But we are
talking about logging! Let's change `say` to using LogP6.

## Add LogP6 using

All that you need to do to start using LogP6 is to add `use LogP6;` line to your
script and call `get-logger` with logger's `trait`. Logger trait is a string value
that describes the semantic purpose of particular Logger. In our case, I called it
`main-prime`. A logger has usual methods like `trace`, `debug`, `info`, `warn` and
`error` where you can pass one or more positional arguments. If there are more
than one argument, the first one will be used as a pattern for `sprintf`
routine and the rest as `sprintf` arguments. There is an optional named argument `:x`,
it can be used for passing an exception for logging. If we did not configure
any logger then we will get a default logger which use `$*OUT` for output.

```perl6
# prime-calculator.p6
use LogP6;
use lib 'lib';
use Prime;

my \log = get-logger('main-prime');
my Prime $prime .= new;

multi sub MAIN(Int :$is-prime!) {
  my $result = $prime.check-prime($is-prime);
  log.info("Number %d is%s prime", $is-prime, ($result ?? '' !! ' not'));
  CATCH { default { log.error('check prime number fail.', :x($_)) } }
}
# ...
```

If we run the script `perl6 prime-calculator.p6 --is-prime=73` then we will see no
output at all. It is because the default logger level is `error` - all logs with
importance level below error will be dropped. Let's update default logger filter
to allow all log levels. We can do it by calling `filter` routine with the
filter name and a desired log level. Default filter has a zero-length string name.
Default LogP6 module export contains only `get-logger` routine. For getting
access to configuration routines you need to `use LogP6 ` with `:configure;`
tag.

```perl6
# prime-calculator.p6
use LogP6 :configure;
use lib 'lib';
use Prime;

filter(:name(''), :level($trace), :update);
my \log = get-logger('main-prime');
my Prime $prime .= new;
# ...
```

Now, if you run the script `perl6 prime-calculator.p6 --is-prime=73` you will see
something like `[23:25:20][INFO] Number 73 is prime`. The same way we will add
logging to the Calculator and Prime classes:

```perl6
# lib/Prime/Calculator.pm6
use LogP6;

unit class Prime::Calculator;

has $!log = get-logger($?CLASS.^name);

method check-prime(Int:D $num --> Bool:D) {
  $!log.trace('will check prime for num ' ~ $num);
  my $result = $num.is-prime;
  $!log.trace('num %s prime is %s', $num, $result);
  return $result;
}
```

We add a Logger as a class attribute in Calculator and use `$?CLASS.^name` as logger trait.
Using class name as logger trait is a good practice to allow simpler loggers
configuration. Note that we do not need to configure logger in Calculator class
and are using LogP6 module without tags. In the same way we can add a logger to Prime
(for example, with `debug` level). After that the script output can look like:

```bash
[23:25:20][DEBUG] check prime for 73
[23:25:20][TRACE] will check prime for num 73
[23:25:20][TRACE] num 73 prime is True
[23:25:20][DEBUG] 73 primarily is True
[23:25:20][INFO] Number 73 is prime
```

If you change `$trace` log level to `$debug` in the MAIN script then you will
not see logs from Calculator.

## Cache primes using a database

Add some logic to our application - add a database for caching primes. If a user
asks 1000th prime number. then we will calculate all thousand primes and store it in
the database for future calls:

```perl6
# lib/Prime/DbCache.pm6
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

# t/02-dbcache.t
use Test;
use lib 'lib';
use Prime::DbCache;

plan 6;

my $database = './t/test-db.sqlite';
END { $database.IO.unlink }

my Prime::DbCache $cache .= new: :$database;
is $cache.find-same-or-less(0)<prime>, Any, 'did not find prime in empty base';
$cache.save(%(0 => 2, 1 => 3, 2 => 5));
is $cache.find-same-or-less(0)<prime>, 2, 'find 2 in base';
is $cache.find-same-or-less(1)<prime>, 3, 'find 3 in base';
is $cache.find-same-or-less(2)<prime>, 5, 'find 5 in base';
is $cache.find-same-or-less(3)<prime>, 5, 'find 5 for 3 in base';
is $cache.find-same-or-less(3)<which>, 2, '2 is third in base';

done-testing;
```

Note that we have logging code in the module but it does not prevent testing.
For now, it is because default log level is error and we do not use it in
DbCache. But if needed, it is possible to `turn off` the default logger. It
can be done by the `cliche` routine call:
`cliche(:name(''), :matcher(/.*/), :replace))`. The meaning of this expression
is explained later.

Integrate DbCache to Prime now:

```perl6
# /lib/Prime.pm6
use Prime::Calculator;
use Prime::DbCache;
use LogP6;

unit class Prime;

has $!log = get-logger($?CLASS.^name);
has Prime::Calculator $.calc is required;
has Prime::DbCache $.cache is required;

submethod BUILD(:$!calc = Prime::Calculator.new, :$!cache = Prime::DbCache.new) {}

#...

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
```

You can see there are four loggers already and it is difficult to
understand which logger wrote this or that. Let's add `trait` logger value into
logger pattern. To do it, we call the `writer` routine and specify the new
pattern for the default logger writer.

```perl6
# prime-calculator.p6
#...
filter(:name(''), :level($trace), :update);
writer(:name(''), :pattern('[%date|%level|%trait] %msg'), :update);
# ...
```

With that our output can look like:

```bash
[23:59:51:948|INFO|Prime::DbCache] connecting to ./resources/cache.sqlite
[23:59:52:342|DEBUG|Prime::DbCache] connected to ./resources/cache.sqlite
[23:59:52:357|DEBUG|Prime] find 72 prime
[23:59:52:358|DEBUG|Prime::DbCache] find cache for 72
[23:59:52:361|DEBUG|Prime::DbCache] found () for 72
[23:59:52:362|DEBUG|Prime] retrive 0 => 2 from cache
[23:59:52:364|TRACE|Prime::Calculator] will find next prime after 2
[23:59:52:365|TRACE|Prime::Calculator] will check prime for num 3
[23:59:52:367|TRACE|Prime::Calculator] num 3 prime is True
[23:59:52:369|TRACE|Prime::Calculator] next prime after 2 is 3
...
[23:59:53:180|DEBUG|Prime::DbCache] save 19 => 71
[23:59:53:185|DEBUG|Prime::DbCache] save 72 => 367
[23:59:53:191|DEBUG|Prime::DbCache] save 66 => 331
[23:59:53:192|DEBUG|Prime::DbCache] save 45 => 199
...
[23:59:53:332|DEBUG|Prime] found prime: 367
[23:59:53:333|INFO|main-prime] 73 prime number is 367
```

So far so good. Now we remember that we were going to write a web service. Let's
do this.

## Implement a web service with Cro

We will use Cro to write a simple web service. If you are not familiar
with Cro then you can read about it on the
[official site](http://cro.services). To add LogP6 into a Cro service I
wrote a `Cro::Transformer` which extracts the response information and logs it.

```perl6
# prime-calculator.p6
#!/usr/bin/env perl6
use LogP6 :configure;
use lib 'lib';
use Prime;
use Cro::HTTP::Router;
use Cro::HTTP::Server;
use Cro::Transform;

filter(:name(''), :level($trace), :update);
writer(:name(''), :pattern('[%date|%level|%trait] %msg'), :update);

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
```

Good news: you can run the script `perl6 prime-calculator.p6`, make a http
request from your browser (just visit `localhost:1000/is-prime/73`) and get `True` as
response. Bad news: there are too many log messages - we need to manage it somehow.

## Configure several loggers

Let's talk about configuring loggers in general. Firstly, LogP6 distinguish a
logger and a logger configuration. Each time you call `get-logger('trait')`,
LogP6 finds a logger configuration (`cliche`) by specified trait and creates a logger
from the cliche. Of course, there is a cache and you will get already created
logger if it exists. Cliche has a required parameter `matcher` - a string or a
regex. The trait must satisfy the cliche's matcher for creating a logger by the
cliche. Also, a cliche has `grooves` - pairs of writer and filter. Each time you
want to log something, the logger goes through its every groove - checks a filter
and if it passes, uses paired writer. If there are no grooves, then it is a
`turned off` logger. We did exactly this - turned off the default logger in the
comment about tests above.

Now, we are going to create three cliches - one for the Cro part, one
for the Calculator (it produces so many log messages) and one for the rest of
Prime:: classes.
So let's change code that updates default writer and filter in prime-calculator.p6 with
this:

```perl6
# prime-calculator.p6
# ...
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
# ...
```

We use the same `:name` values for the cliche, writer and filter for clarity.
You can use any names you want. We use `/^Prime/` regex in `prime` cliche's
matcher. It will match Prime and Prime::DbCache. It will match Prime::Calculator
too, but Calculator has its own cliche. Note that the order of cliches makes
sense. If you swap `prime` and `calculator` cliche then Calculator will use the
prime cliche.

One more thing - a default pattern. We decided to use the same pattern in all our
writers. We do not want to write `:pattern('...')` three times and just set the
default value. The value that will be used in writes does not have its own pattern.

Good news: we can configure a log level for each logger. Bad news: for change a
log level we have to stop the service, change the code and start the service
again.

## Move log configuration to configuration file

Fortunately, we can configure logger not only in the code, but in the
configuration file. The configuration file is a JSON formatted file named `log-p6.json`,
which has to be placed in the same directory of your script.
You can also provide a path to a configuration file using `LOG_p6_JSON` environment
variable.

Let's move our three cliches from `prime-calculator.p6` to `log-p6.json`:

```json
# log-p6.json
{
  "default-pattern": "[%date|%level|%trait] %msg",
  "writers": [
    { "type": "std", "name": "route",
      "handle": { "type": "file", "path": "resources/route.log", "out-buffer": 0 }
    },
    { "type": "std", "name": "prime",
      "handle": { "type": "file", "path": "resources/prime.log", "out-buffer": 0 }
    },
    { "type": "std", "name": "calculator",
      "handle": { "type": "std", "path": "out" }
    }
  ],
  "filters": [
    { "type": "std", "name": "route", "level": "info" },
    { "type": "std", "name": "prime", "level": "debug" },
    { "type": "std", "name": "calculator", "level": "trace" }
  ],
  "cliches": [
    { "name": "route", "matcher": "route", "grooves": [ "route", "route" ] },
    { "name": "prime", "matcher": "/^Prime/", "grooves": [ "prime", "prime" ] },
    { "name": "calculator", "matcher": "Prime::Calculator", "grooves": [ "calculator", "calculator" ] }
  ]
}
```

The format is self-descriptive: we decided to write cro and prime
logs to files and calculator to standard output.

Now, we separate process of logger usage and configuring it. It provides us the possibility to
manage loggers without code changes. But actually not in runtime for now :)

The thing we did not describe yet is configuration synchronization. This means
synchronization between loggers and its configuration. When you change a cliche,
a writer, a filter or any other thing you expect that the logger will change its
behavior. But the logger itself is an immutable object, so you have to `wrap` a logger with
a `wrapper` to add some functionality to it. In our case - synchronisation
functionality. LogP6 has two synchronization wrappers out of the box -
`time wrapper` (try to sync each X seconds) and `each wrapper` (sync logger each
log call). Maybe it sounds a little tricky, but... Anyway, for now, we need 
synchronization - let's wrap all loggers:

```json
# log-p6.json
...
"default-wrapper": { "type": "time", "seconds": 5},
...
```

Now, we will get a fresh logger every 5 seconds. You can try it out,
running the script and playing with logger levels.

## Logging web session information

As we have a web service, we can face concurrent users calls. In such case, it
is be difficult to understand which user 'produced' a particular log entry.
We need to identify each user call by a session id, for example. After that, we
have to add the session id to each log call. It is not a terribly wise decision to add a
`session-id` argument to each method and routine in our application just for
logging purpose. Fortunately, LogP6 provides us a Mapped Diagnostic Context (or MDC) -
Thread associated Map structure where you can store any data you want and use
for logging. So we are going to store a session-id with it and correct the pattern:

```perl6
# prime-calculator.p6
# ...
sub log-session { log.mdc-put('session', 1000000.rand.Int) }

my $application = route {
  get -> 'is-prime', Int $num {
    CATCH { default { log.error('check prime number fail.', :x($_)); response.status = 500; } }
    log-session;
    log.info("is-prime request for '$num'");
    my $result = $prime.check-prime($num);
    log.info("result is $result");
    content 'text/plain', ~$result;
  }
# ...

# log-p6.json
...
"default-pattern": "[%date|%level|%trait|%mdc{session}] %msg",
...
```

With that, each log entry is signed by a session id:

```bash
# resources/route.log
[18:50:13:442|INFO|route|768469] find-prime request for '430'
[18:50:13:459|INFO|route|768469] result is 2999
[18:50:13:462|INFO|route|768469] 200 /find-prime/430 - ::1
[18:50:33:166|INFO|route|988683] find-prime request for '430'
[18:50:33:174|INFO|route|988683] result is 2999
[18:50:33:176|INFO|route|988683] 200 /find-prime/430 - ::1

# resource/prime.log
[18:50:13:445|DEBUG|Prime|768469] find 429 prime
[18:50:13:448|DEBUG|Prime::DbCache|768469] find cache for 429
[18:50:13:455|DEBUG|Prime::DbCache|768469] found [429 2999] for 429
[18:50:13:458|DEBUG|Prime|768469] retrive 429 => 2999 from cache
[18:50:33:168|DEBUG|Prime|988683] find 429 prime
[18:50:33:169|DEBUG|Prime::DbCache|988683] find cache for 429
[18:50:33:171|DEBUG|Prime::DbCache|988683] found [429 2999] for 429
[18:50:33:173|DEBUG|Prime|988683] retrive 429 => 2999 from cache
```

## Conclusions

That was a brief introduction to LogP6. There are many things not covered in
the article which LogP6 provides. For example, fully customizable filtering -
you can describe any filtering logic, including random filtering :) Other than that you can
modify any data (log level, log message or so) at filter stage. Writers are
customizable too - you can create your own writer with your own logic. For
example, there is
[LogP6::Writer::Journald](https://modules.perl6.org/dist/LogP6-Writer-Journald:cpan:ATROXAPER)
module for `systemd journald` support (++[timotimo](https://github.com/timo) for
the idea). Actually, you can change almost all the parts for your needs. Please
see [official README](https://modules.perl6.org/dist/LogP6:cpan:ATROXAPER) for
more detailed information.
