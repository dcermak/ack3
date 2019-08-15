#!perl -T

use strict;
use warnings;
use lib 't';

use Test::More tests => 4;

use Util;
use Barfly;

prep_environment();

# XXX Tests that we need
# -c has to respect ranges.
# -l and -L have to respect ranges.
# -v has to respect ranges.
# Ranges don't affect context.
# What should --passthru do?
# The patterns in --range-start and --range-end have to follow all the flags of the original regex: -Q, -i, etc
# Handle --range-start without --range-end, and vice versa

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

    my @args    = qw( print --range-start=^sub --range-end=^} );
    my @results = run_ack( @args, 't/range/rangefile.pm' );

    lists_match( \@results, \@expected, 'Simple range' );
};

subtest 'Start with no end' => sub {
    plan tests => 2;

    my @expected = line_split( <<'HERE' );
    print 'foo';
my $print = 1;
    print 'bar';
my $task = 'print';
HERE

    my @args    = qw( print --range-start=^sub );
    my @results = run_ack( @args, 't/range/rangefile.pm' );

    lists_match( \@results, \@expected, 'Start with no end' );
};


subtest 'End with no start' => sub {
    plan tests => 2;

    my @expected = line_split( <<'HERE' );
# This function calls print on "foo".
    print 'foo';
HERE

    my @args    = qw( print --range-end=^} );
    my @results = run_ack( @args, 't/range/rangefile.pm' );

    lists_match( \@results, \@expected, 'End with no start' );
};


done_testing();

exit 0;
