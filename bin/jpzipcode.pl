#!/usr/bin/env perl
# see: http://www.post.japanpost.jp/zipcode/dl/kogaki.html
# first release at 2013/05/12

use strict;
use warnings;
use utf8;

use Cwd qw(getcwd);
use Encode;
use File::Basename qw(dirname);
use File::Spec;
use File::Temp qw(tempdir tempfile);
use Getopt::Long;
use LWP::UserAgent;
use Pod::Usage qw(pod2usage);

use constant DEBUG => 1;

our $VERSION = '0.01';

my $DB_DIR = dirname(__FILE__);

warn "DB_DIR=$DB_DIR\n" if DEBUG;

my $KEN_ALL_URL = 'http://www.post.japanpost.jp/zipcode/dl/kogaki/zip/ken_all.zip';

my $CSV_FILE = $DB_DIR . '/ken_all.csv';

my $CSV_CHARSET = 'shift-jis';

my $parser = Getopt::Long::Parser->new(
    config => [qw(posix_default no_ignore_case auto_help)]
);
$parser->getoptions(
    \my %opt, 'version', 'get', 'clean'
);

if ( $opt{version} ) {
    print "$0 Version $VERSION\n";
    exit;
}
if ( $opt{usage} ) {
    pod2usage();
}
if ( $opt{get} ) {
    get();
    print "get success.\n";
    exit;
}
elsif ( $opt{clean} ) {
    clean();
    print "clean success.\n";
    exit;
}

my $TERMINAL_CHARSET = ($ENV{LANG} =~ /\.([^.]+)$/)[0] || 'utf-8';

$TERMINAL_CHARSET =~ s/-//;
$TERMINAL_CHARSET = lc $TERMINAL_CHARSET;

print "TERMINAL_CHARSET=$TERMINAL_CHARSET\n" if DEBUG;

binmode STDOUT, $TERMINAL_CHARSET;
binmode STDERR, $TERMINAL_CHARSET;

my $keyword = decode($TERMINAL_CHARSET, shift || '');
$keyword =~ s/-//g;

if ( !$keyword ) {
    print "keyword is not defined\n";
    pod2usage(1);
}

if ( !-f $CSV_FILE ) {
    print qq(csvfile=$CSV_FILE is not found. type "$0 --get".\n);
    exit;
}

open my $csv_fh, "<:encoding($CSV_CHARSET)", $CSV_FILE
    or die "open CSV_FILE failed: $!\n";

my $keyword_re = qr/$keyword/;

print "keyword_re=$keyword_re keyword=$keyword\n" if DEBUG;

my $match_count;
while (<$csv_fh>) {
    print and $match_count++ if /$keyword_re/;
}

if ( !$match_count ) {
    print "no match\n";
}

exit;

sub get {
    my $cur_dir = getcwd();
    chdir $DB_DIR
        or die "chdir failed: $!\n";
    my $ua = LWP::UserAgent->new();
    $ua->timeout(10);
    $ua->env_proxy();
    my $content_filename = "ken_all.zip";
    my $res = $ua->get($KEN_ALL_URL, ":content_file" => $content_filename );
    if ( $res->is_success ) {
        my $fh = IO::File->new($content_filename, "r");
        unzip_ken_all($fh, $content_filename);
    }
    else {
        die "get failed: " . $res->as_string;
    }
    unlink $content_filename if -f $content_filename;
    chdir $cur_dir;
}

sub unzip_ken_all {
    my ($fh, $filename) = @_;
    if ( DEBUG ) {
        print "unzip_ken_all: content length is " . (-s $filename) . "\n";
    }
    my ($have_iouu, $have_unzip_cmd);
    local $@;
    $have_iouu      = eval { require IO::Uncompress::Unzip; 1; };
    $have_unzip_cmd = (0 == system("type unzip >/dev/null 2>&1"));
    if ( $have_iouu ) {
        no warnings 'once';
        print "Use IO::Uncompress::Unzip module\n" if DEBUG;
        IO::Uncompress::Unzip::unzip(
            $fh => "ken_all.csv", # uncompressed filename
            Name => "KEN_ALL.CSV" # filename on zipfile
        ) or die "unzip failed: $IO::Uncompress::Unzip::UnzipError\n";
    }
    elsif ( $have_unzip_cmd ) {
        print "Use unzip command\n" if DEBUG;
        system("unzip $filename") == 0
            or die "unzip failed: $!";
    }
    else {
        die "unzip_ken_all: require IO::Uncompress::Unzip module or unzip command.";
    }
}

sub clean {
    unlink $CSV_FILE if -f $CSV_FILE;
}

=pod

=encoding utf-8

=head1 NAME

jpzipcode.pl - 日本の郵便番号を検索

=head1 SYNOPSIS

 jpzipcode.pl --get

 jpzipcode.pl --clean

 # search zipcode
 jpzipcode.pl 0030001

=cut
