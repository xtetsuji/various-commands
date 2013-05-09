#!/usr/bin/perl
# 2013/01/21
# 27歳は祝おう

use strict;
use warnings;

use Pod::Usage 'pod2usage';
use Time::Piece;
use Time::Seconds;

my $arg = shift;

pod2sage(0) if !$arg;

my $t = eval { Time::Piece->strptime($arg, "%Y/%m/%d"); }
    or die "Time parse error. e.g. YYYY/MM/DD.\n";

$t += ONE_DAY * 10_000;

printf "%d/%d/%d (%s)\n", map { $t->$_() } qw(year mon mday wdayname);

exit;

__END__

=pod

=head1 NAME

10000days.pl - Happy 10,000 days, Happy 27 age!

=head1 SYNOPSIS

 10000days.pl 1992/12/25

output date after 10,000 days of specific date.

=head1 REQUIREMENTS

L<Pod::Usage>, L<Time::Piece>, L<Time::Seconds>.

Those packages are core module of Perl 5.10 later.

=head1 AUTHOR

OGATA Tetsuji E<lt>tetsuji.ogata {at} gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by OGATA Tetsuji

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
