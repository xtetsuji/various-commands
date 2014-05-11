#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use List::Util qw(sum);

binmode STDOUT, ':utf8';
binmode STDERR, ':utf8';

my $str = shift; # e.g. 20010203

$str =~ s/\D//g;

if ( $str !~ /^[12]\d{5,7}$/ ) {
    die "YYYYMMDD の形式で誕生日を入れて下さい\n";
}

my $sum = $str;

while ( $sum >= 10 ) {
    my @digits = split //, $sum;
    $sum = sum @digits;
}

print "誕生日 $str の運命数は $sum です\n";
