#!/usr/bin/perl

# launchd でファイルの変更時に実行してみたんだけど、フォーカスが java に奪われてしまう…。

use strict;
use warnings;

main(
	'processing-java --build --sketch=/Users/hrk/projects/MusicDance/git/MusicDanceB/ --output=../output --force',
	'.previous_error',
	'MusicDanceB'
);

sub main {
	my $cmd = shift;
	my $prev = shift;
	my $title = shift;
	my $preverr = -e $prev ? readfile($prev) : '';
	system $cmd . " 2> " . $prev;
	my $currerr = -e $prev ? readfile($prev) : '';
	if ($preverr ne $currerr) {
		notify($title, $currerr);
	}
}

sub readfile {
	my $path = shift;
	my $content;
	local $/ = undef;
	open my($in), $path;
	$content = <$in>;
	close $in;
	chomp $content;
	return $content;
}

sub notify {
	my $title = shift;
	my $body  = shift;
	system qq{terminal-notifier -message '$body' -title '$title'} or die 'terminal-notifier error';
}
