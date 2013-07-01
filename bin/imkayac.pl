#!/usr/bin/env perl
# ogata 2013/02/14
# ogata 2013/05/07
# see: http://im.kayac.com/#docs

use strict;
use warnings;
use bytes; # treat message argument as UTF-8 byte stream.

our $VERSION = '0.01';

use Getopt::Long ();
use Pod::Usage 'pod2usage';

use constant HAVE_LWP_UA    => eval { require LWP::UserAgent; 1; };
use constant HAVE_HTTP_TINY => eval { require HTTP::Tiny;     1; };
use constant HAVE_CONFIG_PL => eval {
    require Config::PL;
    import  Config::PL;
    1;
};
use constant ENDPOINT_URL => 'http://im.kayac.com/api/post/';
use constant CONFIG_FILENAME => $ENV{HOME} . '/.imkayac.pl';

if ( -f CONFIG_FILENAME && !HAVE_CONFIG_PL ) {
    warn "Config file " . CONFIG_FILENAME . " is exist. But Config::PL module is not found. Can not read config file.";
}

my $UA_NAME = "xtetsuji.imkayac.pl/$VERSION";

sub post {
    my $post_url = shift;
    my $form_data = shift;
    if ( HAVE_LWP_UA ) {
        my $ua = LWP::UserAgent->new( agent => $UA_NAME );
        $ua->env_proxy();
        my $res = $ua->post( $post_url, $form_data );
        # return value is HTTP::Tiny like.
        return +{
            success => $res->is_success,
            content => $res->content || $res->as_string,
        };
    }
    elsif ( HAVE_HTTP_TINY ) {
        my $http = HTTP::Tiny->new( agent => $UA_NAME );
        return $http->post_form( $post_url, $form_data );
    }
    else {
        die "HTTP module is not found. Install LWP or HTTP::Tiny.\n";
    }
}

### priority: option -> config -> env (username, password)
my %opt;
my $p = Getopt::Long::Parser->new(
    config => [qw(posix_default no_ignore_case auto_help)]
);
$p->getoptions(
    'u|username=s'  => \$opt{username},
    'p|password=s'  => \$opt{password},
    's|secretkey=s' => \$opt{secretkey},
    'H|handler=s'   => \$opt{handler},
    'h|help|usage'  => \$opt{help},
);

my %conf;
if ( HAVE_CONFIG_PL && -f CONFIG_FILENAME ) {
    %conf = config_do CONFIG_FILENAME;
}

my $message = shift;

if ( !defined $message || !length $message ) {
    pod2usage(1);
}
if ( $opt{help} ) {
    pod2usage(0);
}

# Is $message not ASCII? and Terminal encoding is not UTF-8?
if ( $message =~ /[^ !-~-]/ && $ENV{LANG} !~ /\.utf-?8$/i ) {
    local $@;
    require Encode;
    my ($maybe_in_enc) = $ENV{LANG} =~ /\.([^.]+)$/;
    eval { Encode::from_to($message, $maybe_in_enc, 'utf-8'); };
    if ( $@ ) {
        die "It seems that your terminal encoding is not UTF-8.\nAnd this program fault to guess encoding.";
    }
}

my $username = $opt{username} || $conf{username} || $ENV{IMKAYAC_USERNAME};
if ( !$username ) {
    die "username is not defined. specify in option, config or env.\nsee perldoc $0";
}
my $post_url = ENDPOINT_URL . $username;

# password and secretkey is optional on imkayac.
my $password  = $opt{password}  || $conf{password}  || $ENV{IMKAYAC_PASSWORD};
my $secretkey = $opt{secretkey} || $conf{secretkey} || $ENV{IMKAYAC_SECRETKEY};

my %form;
# required:
$form{message}  = $message;
# optional:
$form{handler}  = $opt{handler} if $opt{handler};
$form{sig}      = gen_sig($message, $secretkey) if $secretkey;
$form{password} = $password;

my $res = post($post_url, \%form );

if ( $res->{success} ) {
    print "SUCCESS:\n";
    print $res->{content} . "\n";
}
else {
    print "ERROR:\n";
    print $res->{content} . "\n";
}

exit;

sub gen_sig {
    my ($message, $secretkey) = @_;
    local $@;
    eval { require Digest::SHA; 1; };
    if ( $@ ) {
        die "If you use secret key authentication, then Digest::SHA module is needed.\n";
    }
    return Digest::SHA::sha1_hex($message . $secretkey);
}

__END__

=pod

=head1 NAME

imkayac.pl - very lightweight program to send im.kayac.com.

=head1 SYNOPSIS

 imkayac.pl [OPTIONS] MESSAGE

 imkayac.pl --username=john --password=xxxxxx "Hello!"
 imkayac.pl --username=john --secretkey='SeCrEt' "Good Morning."
 imkayac.pl --handler=tweetbot: "Open Tweetbot"
 imkayac.pl --handler=googlechrome://wwww.google.co.jp/ "Open Gogole by Chrome"

 imkayac.pl [-h|--help|--usage]

OPTIONS are "username", "password", "handler", "password", or "secretkey".

=head1 DESCRIPTIONS

This script is lightweight handling im.kayac.com.

You use "Command line option", "Config" or "Environment variable" for
specify "username", "password" and "secretkey".

Priority: Command line option -> Config -> Environment variable.

=head1 OPTIONS AND CONFIG AND ENVIRONMENT

Command line option details is above.

Config file is ".imkayac.pl" on home directory.
This file syntax is Perl native hash reference powered by L<Config::PL>.
e.g.

 {
    username => "john",
    password => "xxxxxxxx",
 }

Environment variable is reuquired "export"ed as specify name.

Some details are following.

=over

=item * --username|-u USERNAME

Specify username. It is required.

Config file key name is "username" too.

Environment variable name is "IMKAYAC_USERNAME".

  # in your .bashrc or some initial file.
  export IMKAYAC_USERNAME=john

=item * --password|-p PASSWORD

Specify password. It is optional on im.kayac.com.

Config file key name is "password" too.

Environment variable name is "IMKAYAC_PASSWORD".

  # in your .bashrc or some initial file.
  export IMKAYAC_PASSWORD=xxxxxxxx

=item * --secretkey|-s SECRETKEY

Specify secretkey. It is optional on im.kayac.com.

COnfig file key name is "secretkey" too.

Environment variable name is "IMKAYAC_SECRETKEY".

  # in your .bashrc or some initial file.
  export IMKAYAC_SECRETKEY=xxxxxxxx

=item * --handler|-H HANDLER

Specify click callback.

 imkayac.pl --handler=tweetbot: "Open Tweetbot for iOS"

=item * --help|--usage|-h

Show help.

=back

=head1 REQUIREMENT

L<LWP::UserAgent> or L<HTTP::Tiny> (Perl core module of v5.14 later).

If you use config file, then this program needs L<Config::PL>.

If you use secret key authentication, then this program needs L<Digest::SHA>.

=head1 HTTP PROXY

If you use L<LWP::UserAgent>, then this module use proxy environments.
see L<LWP::UserAgent>'s perldoc and "http_proxy" environment.

=head1 SEE ALSO

L<im.kayac.com API Document|http://im.kayac.com/#docs>

=head1 AUTHOR

OGATA Tetsuji E<lt>tetsuji.ogata {at} gmail.comE<gt>

Initial written at 2013/02/14

Initial release at 2013/05/07 on GitHub.

=cut
