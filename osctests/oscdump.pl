#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper qw(Dumper);
use Time::HiRes qw(time);

use lib './lib';
use Net::OpenSoundControl::Server;

my $port = $ARGV[0] || 7771;

$Data::Dumper::Indent = 0;
$Data::Dumper::Purity = 1;

my $start;

my $server =
  Net::OpenSoundControl::Server->new(
    Port => $port, MaxLength => 1472,
    Handler => sub {
      $start = time() unless defined $start;
      print int((time() - $start) * 1000), "\t", Dumper($_[1]), "\n";
    })
  or die "Could not start oscdump: $@\n";

$SIG{'INT'} = sub {
  $server->stoploop();
};

print STDERR "[oscdump] Receiving messages on port $port\n";

$server->readloop();

print STDERR "[oscdump] Receive finished.\n";
