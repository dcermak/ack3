#!perl -T

use strict;
use warnings;
use lib 't';

use Test::More tests => 8;

use Util;
use Barfly;

prep_environment();

# XXX Tests that we need
# ✅ Basic ranges
# ✅ -c has to respect ranges.
# ✅ Handle --range-start without --range-end, and vice versa
# ✅ The patterns in --range-start and --range-end must NOT follow the flags of the original regex: -Q, -i, etc
# ✅ -l and -L have to respect ranges.
# ✅ A range can start and end on the same line.
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


subtest 'Multiple tricky points: Flags' => sub {
    plan tests => 2;

    # This test has a number of things that can go wrong:
    # * The -w should not affect the --range-start and --range-end.
    # * The -w should affect finding of "flag", not "flags".
    # * The --range-start and --range-end have metacharacters in them.
    # * Two of the <div>s have "flag"s that should not be found.

    my $leading = reslash( 't/range/stars-and-stripes.html' );
    my @expected = line_split( <<"HERE" );
$leading:14:            A flag appears 'mid thunderous cheers,
$leading:34:            But the flag of the North and South and West
$leading:35:            Is the flag of flags, the flag of Freedom's nation.
HERE

    my @args = qw( flag -w --range-start=<div\s+id="\w+-strain"> --range-end=/div> );

    my @results = run_ack( @args, 't/range' );
    lists_match( \@results, \@expected, 'Found the flags in the right sections' );
};


subtest 'Multiple tricky points: Forever' => sub {
    plan tests => 4;

    # Danger points:
    # * The range can start and stop on the same line.

    my $leading = reslash( 't/range/stars-and-stripes.html' );
    my @expected = line_split( <<"HERE" );
$leading:4:        <title>The Stars and Stripes Forever</title>
$leading:7:        <h1>The Stars and Stripes Forever</h1>
$leading:40:            May it wave as our standard forever,
$leading:47:            It waves forever.
$leading:52:            May it wave as our standard forever
$leading:59:            It waves forever.
HERE

    my @args = qw( forever -i );
    my @results = run_ack( @args, 't/range' );
    lists_match( \@results, \@expected, 'Found the correct "forever"s' );

    # Now limit to just <h1> and <title> tags.
    push @args, qw( --range-start=<(title|h1)> --range-end=</(title|h1)> );
    @results = run_ack( @args, 't/range' );
    lists_match( \@results, [@expected[0..1]], 'Only the first two forevers should match' );
};


subtest '-l, -L and -c' => sub {
    plan tests => 12;

    my @expected_c = map { reslash($_) } line_split( <<'HERE' );
t/range/america-the-beautiful.html:2
t/range/anchors-aweigh.html:2
t/range/stars-and-stripes.html:2
HERE

    my @expected_l = map { /^(.+):\d/ && $1 } @expected_c;

    # -l, no range
    my @args = qw( sea -i --sort --html );
    my @results = run_ack( @args, '-l', 't/range' );
    lists_match( \@results, \@expected_l, 'Found the correct files' );

    # -L, no range
    @results = run_ack( @args, '-L', 't/range' );
    lists_match( \@results, [], 'All the HTML have sea in them.' );

    # -c, no range
    @results = run_ack( @args, '-c', 't/range' );
    lists_match( \@results, \@expected_c, 'Found the correct counts' );

    # Now do it again with ranges.
    push @args, qw( --range-start=<div\s+id="verse-1"> --range-end=/div> );

    @expected_c = map { reslash($_) } line_split( <<'HERE' );
t/range/america-the-beautiful.html:1
t/range/anchors-aweigh.html:1
t/range/stars-and-stripes.html:0
HERE

    @expected_l = map { /^(.+):1/ ? $1 : () } @expected_c;
    my @expected_L = map { reslash($_) } line_split( <<'HERE' );
t/range/stars-and-stripes.html
HERE

    # -l, in a range of verse-1 only
    @results = run_ack( @args, '-l', 't/range' );
    lists_match( \@results, \@expected_l, 'Found the correct files for -l range' );

    # -L, in a range of verse-1 only
    @results = run_ack( @args, '-L', 't/range' );
    lists_match( \@results, \@expected_L, '-L with a range' );

    # -c, in a range of verse-1 only
    @results = run_ack( @args, '-c', 't/range' );
    lists_match( \@results, \@expected_c, '-c with a range' );

};

subtest 'One-line ranges and ranges with only start or end' => sub {
    plan tests => 8;

    my $start = '--range-start=<h1>';
    my $end   = '--range-end=</h1>';

    my $leading = reslash( 't/range/america-the-beautiful.html' );
    my @expected = line_split( <<"HERE" );
$leading:4:        <title>America the Beautiful</title>
$leading:7:        <h1>America the Beautiful</h1>
$leading:14:            America! America!
$leading:25:            America! America!
$leading:36:            America! America!
$leading:47:            America! America!
HERE

    my @args = qw( America );
    my @results = run_ack( @args, 't/range' );
    lists_match( \@results, \@expected, 'No range finds them all' );

    # Just a start of the range.
    @results = run_ack( @args, $start, 't/range' );
    lists_match( \@results, [@expected[1..5]], 'Start-only range skips the 1st hit' );

    # Just an end of the range.
    @results = run_ack( @args, $end, 't/range' );
    lists_match( \@results, [@expected[0..1]], 'End-only range ends after the 2nd hit' );

    # Start and end give a one-line range.
    @results = run_ack( @args, $start, $end, 't/range' );
    lists_match( \@results, [$expected[1]], 'Start and end gives a one-line range' );
};

done_testing();

exit 0;
