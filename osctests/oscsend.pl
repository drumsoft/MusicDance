#!/usr/bin/perl

use strict;
use warnings;

use Time::HiRes qw(time sleep);

use lib './lib';
use Net::OpenSoundControl::Client;

my $verbose = 0;
my $host = "127.0.0.1";
my $port = 7772;

my $addr = $ARGV[0];
if ($addr) {
  if ($addr =~ /^(\d+\.\d+\.\d+\.\d+)/) {
    $host = $1
  }
  if ($addr =~ /(?:^|\:)(\d+)$/) {
    $port = $1;
  }
}

my $start = time();

my $client =
  Net::OpenSoundControl::Client->new(Host => $host, Port => $port)
  or die "Could not start Client: $@\n";

print STDERR "[oscsend] Sending out test messages to $host:$port\n";

my $VAR1;
while (<>) {
  chomp;
  my ($at, $dump) = split /\t/, $_, 2;
  if ($at && $dump) {
    eval($dump);
    if ($@) {
      print STDERR "[oscsend] eval error at $at: $dump\n";
      next;
    }
    my $interval = ($at / 1000) + $start - time();
    print STDERR "[oscsend] $interval: $dump\n" if $verbose;
    if ($interval > 0) {
      sleep($interval);
    }
    $client->send($VAR1);
  }
}

print STDERR "[oscsend] Send finished.\n";
