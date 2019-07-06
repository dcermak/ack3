#!perl -T

use strict;
use warnings;
use lib 't';

use Test::More tests => 2;

use Util;
use Barfly;

prep_environment();

subtest 'No range' => sub {
    plan tests => 2;

    my @expected = line_split( <<'HERE' );
# This function calls print on "foo".
    print 'foo';
my $print = 1;
    print 'bar';
my $task = 'print';
HERE

    my @args    = qw( print );
    my @results = run_ack( @args, 't/range/rangefile.pm' );

    lists_match( \@results, \@expected, 'No range' );
};


subtest 'Simple range' => sub {
    plan tests => 2;

    my @expected = line_split( <<'HERE' );
    print 'foo';
    print 'bar';
HERE

    my @args    = qw( print --range-start='^sub' --range-end='^\}' );
    my @results = run_ack( @args, 't/range/rangefile.pm' );

    lists_match( \@results, \@expected, 'Simple range' );
};

done_testing();

exit 0;
