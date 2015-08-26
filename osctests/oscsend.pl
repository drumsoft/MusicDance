#!/usr/bin/perl

use strict;
use warnings;

use Time::HiRes qw(time sleep);

use lib './lib';
use Net::OpenSoundControl::Client;

my $verbose = 0;
my $host = "127.0.0.1";
my $port = 7772;
my $file;
my $loop = 0;

foreach (@ARGV) {
  if ($_ eq '-l' || $_ eq '--loop') {
    $loop = 1;
  } elsif (/^[\d\.\:]+$/) {
    if (/^(\d+\.\d+\.\d+\.\d+)/) {
      $host = $1
    }
    if (/(?:^|\:)(\d+)$/) {
      $port = $1;
    }
  } elsif (-e $_) {
    $file = $_;
  }
}


my $start = time();

my $client =
  Net::OpenSoundControl::Client->new(Host => $host, Port => $port)
  or die "Could not start Client: $@\n";

print STDERR "[oscsend] Sending out test messages to $host:$port\n";

if ($file) {
  open(STDIN, $file);
}

my $VAR1;

while (1) {
  while (<STDIN>) {
    chomp;
    my ($at, $dump) = split /\t/, $_, 2;
    if ($at =~ /^\d+$/ && $dump) {
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
  if ($loop) {
    seek(STDIN, 0, 0);
    $start = time();
    print STDERR "[oscsend] looping.\n";
  } else {
    last;
  }
}

if ($file) {
  close(STDIN);
}

print STDERR "[oscsend] Send finished.\n";
