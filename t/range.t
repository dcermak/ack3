#!perl -T

use strict;
use warnings;
use lib 't';

use Test::More tests => 4;

use Util;
use Barfly;

prep_environment();

# XXX Tests that we need
# ✅ Basic ranges
# ✅ -c has to respect ranges.
# ✅ Handle --range-start without --range-end, and vice versa
# The patterns in --range-start and --range-end must NOT follow the flags of the original regex: -Q, -i, etc
# -l and -L have to respect ranges.
# -v has to respect ranges.
# Ranges must not affect context.
# --passthru doesn't affect what matches, and --range doesn't affect --passthru's behavior.

subtest 'No range' => sub {
    plan tests => 4;

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

    # Test -c
    @results = run_ack( @args, '-c', 't/range/rangefile.pm' );
    lists_match( \@results, [ scalar @expected ], '-c under simple range' );
};


subtest 'Simple range' => sub {
    plan tests => 4;

    my @expected = line_split( <<'HERE' );
    print 'foo';
    print 'bar';
HERE

    my @args    = qw( print --range-start=^sub --range-end=^} );
    my @results = run_ack( @args, 't/range/rangefile.pm' );
    lists_match( \@results, \@expected, 'Simple range' );

    # Test -c
    @results = run_ack( @args, '-c', 't/range/rangefile.pm' );
    lists_match( \@results, [ scalar @expected ], '-c under simple range' );
};


subtest 'Start with no end' => sub {
    plan tests => 4;

    my @expected = line_split( <<'HERE' );
    print 'foo';
my $print = 1;
    print 'bar';
my $task = 'print';
HERE

    my @args    = qw( print --range-start=^sub );
    my @results = run_ack( @args, 't/range/rangefile.pm' );

    lists_match( \@results, \@expected, 'Start with no end' );

    # Test -c
    @results = run_ack( @args, '-c', 't/range/rangefile.pm' );
    lists_match( \@results, [ scalar @expected ], '-c under simple range' );
};


subtest 'End with no start' => sub {
    plan tests => 4;

    my @expected = line_split( <<'HERE' );
# This function calls print on "foo".
    print 'foo';
HERE

    my @args    = qw( print --range-end=^} );
    my @results = run_ack( @args, 't/range/rangefile.pm' );

    lists_match( \@results, \@expected, 'End with no start' );

    # Test -c
    @results = run_ack( @args, '-c', 't/range/rangefile.pm' );
    lists_match( \@results, [ scalar @expected ], '-c under simple range' );
};


done_testing();

exit 0;
