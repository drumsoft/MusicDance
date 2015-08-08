#!/usr/bin/perl

use strict;
use warnings;
use Net::OpenSoundControl::Server;
use Data::Dumper qw(Dumper);
use Time::HiRes qw(time);

my $port = $ARGV[0] || 7771;

$Data::Dumper::Indent = 0;
$Data::Dumper::Purity = 1;

my $start = time();

my $server =
  Net::OpenSoundControl::Server->new(
    Port => $port, 
    Handler => sub {
      print int((time() - $start) * 1000), "\t", Dumper($_[1]), "\n";
    })
  or die "Could not start oscdump: $@\n";

print STDERR "[oscdump] Receiving messages on port $port\n";

$server->readloop();
