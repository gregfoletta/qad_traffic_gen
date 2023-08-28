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
    'selenium-ips=s',
    'iterations=n',
    'help' => sub { pod2usage(1) }
) or pod2usage(2);

=pod

=head1 NAME

=head1 SYNOPSIS

=cut

# Default to 2 threads
$args{iterations} //= 100;

croak "Need to specify --uris <file>" unless defined $args{uris};
croak "Need to specify --users <file>" unless defined $args{users};
croak "Need to specify --selenium-ips ip_1[,ip_2, ...]" unless defined $args{'selenium-ips'};

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


# Split the selenium IPs and connect to the drivers
my @selenium_ips = split(",", $args{'selenium-ips'});

my @selenium_drivers = ();
for my $selenium_host (@selenium_ips) {
	say "- Creating Selenium driver to $selenium_host";

	my $driver = Selenium::Remote::Driver->new(
	    browser_name => 'firefox',
	    error_handler => sub { print $_[1]; },
	    accept_ssl_certs => 1,
	    remote_server_addr => $selenium_host,
	    port               => '4444',
	    'auto_close'         => 1
	);

	push @selenium_drivers, { host => $selenium_host, driver => $driver };
}


say "- Requesting random URI/user pairs with $args{iterations} iterations";

foreach (1 .. $args{iterations}) {
    my ($uri_r, $user_r, $sel_r) = (@uris[rand @uris], @users[rand @users], @selenium_drivers[rand @selenium_drivers]);

    $uri_r->userinfo($user_r);
    say "- Requesting " . $uri_r->as_string . " from " . $sel_r->{host};

    $sel_r->{driver}->get( $uri_r->as_string );
}




