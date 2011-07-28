use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Name::FromLine;

use Fork::setTimeout;

subtest 'setTimeout()' => sub {
    my $timer1 = setTimeout(sub { pass 'timer1' }, 10);
    my $timer2 = setTimeout(
        sub {
            pass 'timer2';
            my $timer3 = setTimeout(
                sub {
                    pass 'timer3';
                    my $timer4 = setTimeout(
                        sub {
                            pass 'timer4';
                        }, 1000);
                }, 1000);
        }, 1000);
};

subtest 'clearTimeout()' => sub {
    my $i = 0;

    my $timer1 = setTimeout(
        sub {
            $i++;

            my $timer2 = setTimeout(
                sub {
                    fail 'cleared';
                }, 1000);
            clearTimeout($timer2);

            is $i => 1;
          }, 1000);
};

subtest 'closure' => sub {
    my $i = 0;

    my $timer1 = setTimeout(sub { $i++; is $i => 1 }, 1000);
    my $timer2 = setTimeout(sub { $i++; is $i => 2 }, 2000);
};

done_testing;
