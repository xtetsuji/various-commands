#!/usr/bin/perl
# 2013/01/21
# 27歳は祝おう

use strict;
use warnings;

use Time::Piece;
use Time::Seconds;

my $t = eval { Time::Piece->strptime(shift, "%Y/%m/%d"); }
    or die "Time parse error. e.g. YYYY/MM/DD.\n";

$t += ONE_DAY * 10_000;

printf "%d/%d/%d (%s)\n", map { $t->$_() } qw(year mon mday wdayname);
