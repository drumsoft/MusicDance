#!/usr/bin/perl

use strict;
use warnings;
use Encode;
use File::Find;

my $sleep_time = 10;
my $activate_java = 1;

my $NOOP = 0;
my $QUIT = 1;
my $LAUNCH = 2;
my $HIDE = 4;

my $self_pid_file = 'watchd.pid';

my %operation_by_appnames = (
  'java' => $NOOP,
  'Finder' => $NOOP,
  'CotEditor' => $NOOP,
  'Terminal' => $NOOP,
  'Activity Monitor' => $NOOP,
  'Console' => $NOOP,
  'firefox' => $NOOP,
  'SoundGrid Studio System' => $LAUNCH,
);

my $operation_default = $QUIT;

my $java_root = '/Users/hrk/projects/MusicDance/git';

my %java_processes = (
  MusicDanceB => {
    search => ' -Xdock:name=MusicDanceB ',
    command => "processing-java --present --sketch=$java_root/MusicDanceB --output=$java_root/output --force",
    dir => "$java_root/MusicDanceB",
    datefile => "MusicDanceB.pid",
  }
);

ExclusiveLaunch::launch($self_pid_file, \&main);

# -------------------------------

sub main {
  while (1) {
    if (!is_key_injected()) {
      operate_apps();
      javaapp_launch();
      java_activate() if $activate_java;
    }
    sleep($sleep_time);
    if (ExclusiveLaunch::check_update($self_pid_file)) {
      report("I'm updated.");
      last;
    }
  }
}

# -------------------------------

sub javaapp_launch {
  local $/ = undef;
  my ($fh, @ps);
  
  open $fh, 'ps ax |' or die 'cannot exec ps command.';
  @ps = <$fh>;
  close $fh;
  
  while  (my ($name, $process) = each %java_processes) {
    my $launched = 0 < (grep { /$process->{search}/ } @ps);
    if ($launched && dir_updated_date($process->{dir}) > get_file_updated_date($process->{datefile})) {
      report('kill java (to relaunch):', $name);
      system('killall java');
      $launched = 0;
    }
    if (!$launched) {
      report('launch java:', $name);
      system($process->{command} . ' &');
      set_file_updated_date($process->{datefile});
    }
  }
}

sub operate_apps {
  my @all_apps = get_all_application_names();
  my @visible_apps = get_visible_application_names();
  my %apps;
  
  foreach my $name (@visible_apps) {
    if (operation($name) & $QUIT) {
      kill_app($name);
    } elsif (operation($name) & $HIDE) {
      hide_app($name);
    }
  }
  foreach my $name (keys %operation_by_appnames) {
    if ((operation($name) & $LAUNCH) && !(grep {$_ eq $name} @all_apps)) {
      launch_app($name);
    }
  }
}

sub operation {
  my $appname = shift;
  return (exists $operation_by_appnames{$appname}) ? $operation_by_appnames{$appname} : $operation_default;
}

sub is_key_injected {
  my ($fh, @volumes);
  open $fh, 'ls /Volumes/ |' or die 'cannot ls Volumes.';
  @volumes = <$fh>;
  close $fh;
  return 0 < grep(/USB/, @volumes);
}

sub java_activate {
  exec_applescript(qq{
tell application "Finder"
  if name of first item of (processes whose frontmost is true) is not "java" then
    set (frontmost of processes whose name is "java") to true
  end if
end tell
  });
}

# -------------------------------

sub launch_app {
  my $name = shift;
  report("launch app:", $name);
  system("open -a '$name'");
}

sub kill_app {
  my $name = shift;
  my $pid = get_pid_from_app($name);
  if (defined $pid && $pid =~ /^\d+$/) {
    report("kill app:", $pid, $name);
    system("kill -9 $pid");
  }
}

sub hide_app {
  my $name = shift;
  report("hide app:", $name);
  exec_applescript(qq{tell application "Finder" to set visible of application process "$name" to false});
}

sub get_pid_from_app {
  my $name = shift;
  my $command = qq{
tell application "System Events"
    set procList to every process whose name contains "$name"
    if procList is not equal to {} then
        set aProc to contents of first item of procList
        tell aProc
            unix id
        end tell
    end if
end tell
  };
  return exec_applescript($command);
}

sub get_visible_application_names {
  my $result = exec_applescript('tell application "System Events" to name of every application process whose visible is true');
  return split(/\, +/, $result);
}

sub get_all_application_names {
  my $result = exec_applescript('tell application "System Events" to name of every application process');
  return split(/\, +/, $result);
}

sub set_file_updated_date {
  my $path = shift;
  my $fh;
  open $fh, '>', $path;
  close $fh;
}

sub get_file_updated_date {
  my $path = shift;
  return -e $path ? (stat($path))[9] : 0;
}

sub dir_updated_date {
  my $start = shift;
  my $date = 0;
  find(sub {
    my $updated = (stat($_))[9];
    if ($date < $updated) {
      $date = $updated;
    }
  }, $start);
  return $date;
}

# -------------------------------

sub exec_applescript {
  my $script = shift;
  my $result;
  {
    local $/ = undef;
    $script =~ s/\"/"\\\""/eg;
    open (my $osa, qq{osascript -e "$script" |}) or die "cannot open osascript";
    $result = Encode::decode('utf8', <$osa>);
    close $osa;
  }
  chomp $result;
  return $result;
}

sub report {
  print '[watched] ', join(' ', @_);
  print "\n";
}

# --------------------------------

package ExclusiveLaunch;

sub launch {
  my $pid_file = shift;
  my $main = shift;
  
  my $pid_fh = _open_pid_file($pid_file);
  my $prev_pid = _get_pid($pid_fh);
  if (_exists_process($prev_pid)) { # launched
    print "[watched] already launched.\n";
    _close_pid($pid_fh);
    return;
  }
  _write_pid($pid_fh,   _current_pid());
  _close_pid($pid_fh);
  
  print "[watched] launched.\n";
  $main->();
}

sub check_update {
  my $pid_file = shift;
  return _get_timestamp($0) > _get_timestamp($pid_file);
}

sub _open_pid_file {
  my $path = shift;
  my $fh;
  open $fh, '+>>', $path or die "open failed $path.";
  flock $fh, 2 or die "flock failed $path.";
  return $fh;
}
sub _get_pid {
  my $fh = shift;
  seek $fh, 0, 0 or die "seek failed.";
  return <$fh>;
}
sub _write_pid {
  my $fh = shift;
  my $pid = shift;
  seek $fh, 0, 0 or die "seek failed.";
  truncate $fh, 0 or die "trancate failed.";
  print $fh $pid;
}
sub _close_pid {
  my $fh = shift;
  close $fh;
}

sub _get_timestamp {
  my $path = shift;
  return -e $path ? (stat($path))[9] : 0;
}

sub _exists_process {
  my $pid = shift;
  return $pid && kill(0 => $pid);
}

sub _kill_process {
  my $tokill = shift;
  kill 15 => $tokill or die "[$0] cannot send SIGTERM to checkd process.";
  my $counter = 3;
  while ( kill 0 => $tokill ) {
    if ($counter-- <= 0) {
      warn "timeout! SIGKILL will send.\n";
      kill 9 => $tokill or die "[$0] cannot send SIGKILL to checkd process.";
      last;
    }
    sleep(1);
  }
}

sub _current_pid {
  return $$;
}

1;
