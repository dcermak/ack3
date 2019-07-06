#!perl -T

use strict;
use warnings;
use lib 't';

use Test::More tests => 9;

use Util;
use Barfly;

prep_environment();

subtest 'Simple' => sub {
    plan tests => 4;

    my @expected = line_split( <<'HERE' );
BLAH BLAH
HERE

    my @targets = map { "t/swamp/groceries/$_" } qw( fruit junk meat );

    my @args    = qw( print --range-start='^sub' --range-end='^\}' );
    my @results = run_ack( @args, 't/range' );

    lists_match( \@results, \@expected, 'Simple range' );
};

done_testing();

exit 0;
