#!/usr/bin/env perl

use strict;
use warnings;

use AnyEvent;
use Furl;
use Web::Query;
use Pod::Usage 'pod2usage';
use Encode;

use Data::Dumper;

use constant DEBUG => 1;
use constant ITAI_NEWS_CHARSET => 'euc-jp';

binmode STDOUT, ':utf8';

my $url = shift; # itai-news URL
my $interval_min = shift || 1;
if ( !$url || $url !~ m{^http://blog.livedoor.jp/dqnplus/archives/} ) {
    pod2usage(1);
}

my $furl = Furl->new(
    agent => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_2) AppleWebKit/537.17 (KHTML, like Gecko) Chrome/24.0.1312.57 Safari/537.17',
    timeout => 10,
);

my $cv = AnyEvent->condvar;

my @comments;
my @new_comment_numbers;

my $crawl_timer = AnyEvent->timer(
    interval => $interval_min * 60,
    cb => sub {
        my $res = $furl->get($url);
        return if !$res->is_success;
        my $content = decode(ITAI_NEWS_CHARSET, $res->content);
        my $document = wq($content);
        my $title = $document->find('title')->text();
        #print "title=$title\n\n" if DEBUG;
        my $first_call = @comments == 0 ? 1 : 0;
        $document->find('.commentttl, .commenttext')
            ->each(sub {
                       my ($i, $elem) = @_;
#                        print "num=$i\n";
#                        print "elem=" . $elem->text() . "\n";
#                        print "elem class is " . $elem->attr('class') . "\n";
                       if ( $elem->attr('class') eq 'commentttl' ) {
                           my ($number) = $elem->text() =~ /^(\d+)\./
                               or die;
                           if ( !exists $comments[$number] ) {
                               $comments[$number] = { ttl => $elem->text() };
                               push @new_comment_numbers, $number;
                           }
                       }
                       elsif ( $elem->attr('class') eq 'commenttext' ) {
                           $comments[-1]->{text} = $elem->text();
                       } else { die "unknown error"; }
                   });
        # new_comment_numbers を表示
        for my $number (@new_comment_numbers) {
            my $comment = $comments[$number];
            printf "> %s\n%s\n", @$comment{qw/ttl text/};
        }

        @new_comment_numbers = ();
    },
);

$SIG{USR1} = sub {
    for my $num (1..(@comments-1)) {
        my $comment = $comments[$num];
        printf "num=%d\nttl=%s\ncomment%s\n", $num, $comment->{ttl}, $comment->{text};
    }
};

$cv->recv();

exit;

__END__

=pod

=head1 NAME

itai-comment.pl - itai-news comment watcher

=head1 SYNOPSIS

 itai-comment.pl <itai_news_url> [<interval_minutes>] &

=head1 DESCRIPTION

(stub)

=head1 AUTHOR

OGATA Tetsuji E<lt>tetsuji.ogata {at} gmail.comE<gt>

First release at 2013/02/24

=cut
