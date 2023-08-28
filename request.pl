#!/usr/bin/env perl

$|=1;

use strict;
use warnings;
use 5.010;
use Pod::Usage;
use Getopt::Long;
use Selenium::Remote::Driver;
use Carp;

my %args;
GetOptions(
    \%args,
    'uris=s',
    'users=s',
    'user-index=n',
    'selenium-ip=s',
    'iterations=n',
    'help' => sub { pod2usage(1) }
) or pod2usage(2);

=pod

=head1 NAME

=head1 SYNOPSIS

=cut

# Set teh defaults
$args{iterations} //= 100;
$args{'user-index'} //= 1;
croak "Need to specify --uris <file>" unless defined $args{uris};
croak "Need to specify --users <file>" unless defined $args{users};
croak "Need to specify --selenium-ip <ip>" unless defined $args{'selenium-ip'};

# Load up the URIs from the file
open(my $fh, "<:encoding(UTF-8)", $args{uris}) or die "Cannot open $args{uris}";
my @uris;
while (<$fh>) {
    chomp;
    my $uri = URI->new($_);
    push @uris, $uri;
}
close($fh);

# Load up the users (one user per line, <username>:<password>
open($fh, "<:encoding(UTF-8)", $args{users}) or die "Cannot open $args{users}";
my @users;
push @users, $_ while (<$fh>);
chomp @users;
close($fh);


# Pull out the user we'll be using.
my $user = $users[ $args{'user-index'} ];

# Make the requests
say "- Requesting random URIs with $args{iterations} iterations";
foreach (1 .. $args{iterations}) {
    my $rand_sleep = int(rand(40));

    my $driver = Selenium::Remote::Driver->new(
        browser_name => 'chrome',
        pageLoadStrategy => 'eager',
        #debug => 1,
        extra_capabilities => {
            'goog:chromeOptions' => {
    	    args => [
                    'ignore-certificate-errors'
    	    ]
    	}
        },
        error_handler => sub { print $_[1]; },
        accept_ssl_certs => 0,
        remote_server_addr => $args{'selenium-ip'},
        port               => '4444'
    );

    say "- Index $args{'user-index'} sleeping for $rand_sleep";
    sleep($rand_sleep);

    my $uri_r = @uris[rand @uris];

    $uri_r->userinfo($user);
    say "- Requesting " . $uri_r->as_string;
    $driver->get( $uri_r->as_string );

    $driver->close();
    $driver->quit();
}




