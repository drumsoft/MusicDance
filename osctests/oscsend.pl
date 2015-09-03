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
  } elsif ($_) {
    $file = $_;
  }
}
if (! defined $file) {
  print STDERR "usage: oscsend.pl [-l] [[127.0.0.1:]7772] file.log\n";
  print STDERR "no file specified.\n";
  exit(0);
}
if (! -e $file) {
  print "file not exists: $file\n";
  exit(-1);
}

my $start = time();

my $client =
  Net::OpenSoundControl::Client->new(Host => $host, Port => $port)
  or die "Could not start Client: $@\n";

print STDERR "[oscsend] Sending out test messages to $host:$port\n";

my $VAR1;

while (1) {
  my $in;
  open($in, $file);
  while (<$in>) {
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
  close($in);
  if ($loop) {
    $start = time();
    print STDERR "[oscsend] looping.\n";
  } else {
    last;
  }
}

print STDERR "[oscsend] Send finished.\n";
