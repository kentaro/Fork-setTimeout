use strict;
use warnings;
use Test::More tests => 6;
use Fork::setTimeout;

my $timer1 = setTimeout(
    sub {
        pass "timer1";
    }, 10);

{
    my $timer2 = setTimeout(
        sub {
            fail "cleared";
        }, 10);

    clearTimeout($timer2);
}

my $timer3 = setTimeout(
    sub {
        pass "timer3";
    }, 10);

my $timer4 = setTimeout(
    sub {
        die "foo";
    }, 10);

my $nest1 = setTimeout(
    sub {
        pass "nest1";
        my $nest2 = setTimeout(
            sub {
                pass "nest2";
                my $nest3 = setTimeout(
                    sub {
                        pass "nest3";
                        my $nest4 = setTimeout(
                            sub {
                                pass "nest4";
                            }, 10);
                    }, 10);
            }, 10);
    }, 10);
