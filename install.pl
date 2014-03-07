#! /usr/bin/env perl

# install.pl
# script to create symlinks from the checkout of davesdots to the home directory

use strict;
use warnings;

use File::Path qw(mkpath rmtree);
use File::Glob ':glob';
use Cwd 'cwd';

my $scriptdir = cwd() . '/' . $0;
$scriptdir    =~ s{/ [^/]+ $}{}x;

my $home = bsd_glob('~', GLOB_TILDE);

if(grep /^(?:-h|--help|-\?)$/, @ARGV) {
	print <<EOH;
install.pl: installs symbolic links from dotfile repo into your home directory

Options:
	-f          force an overwrite existing files
	-h, -?      print this help

Destination directory is "$home".
Source files are in "$scriptdir".
EOH
	exit;
}

my $force = 0;
$force = 1 if grep /^(?:-f|--force)$/, @ARGV;

unless(eval {symlink('', ''); 1;}) {
	die "Your symbolic links are not very link-like.\n";
}

my %links = (
	'Wombat.xccolortheme'  => 'Library/Application Support/Xcode/Color Themes/Wombat.xccolortheme',
	'Xdefaults' => '.Xdefaults',
	'Xresources' => '.Xresources',
	'_vimrc'   => '_vimrc',
	'ackrc'      => '.ackrc',
	'bash' => '.bash',
	'bash_profile' => '.bash_profile',
	'bashrc' => '.bashrc',
	'bin/git-info' => 'bin/git-info',
	'bin/inxi' => 'bin/inxi',
	'bin/stats.rb' => 'bin/stats.rb',
	'caffeinate' => 'bin/caffeinate',
	'commonsh' => '.commonsh',
	'dir_colors' => '.dir_colors',
	'gdbinit' => '.gdbinit',
	'git-info'            => 'bin/git-info',
	'git-untrack-ignored' => 'bin/git-untracked-ignored',
	'gitconfig' => '.gitconfig',
	'gitignore' => '.gitignore',
	'gpg-agent.conf' => '.gnupg/gpg-agent.conf',
	'gvimrc'   => '.gvimrc',
	'indent.pro'     => '.indent.pro',
	'inputrc' => '.inputrc',
	'irbrc' => '.irbrc',
	'ksh'      => '.ksh',
	'kshrc'    => '.kshrc',
	'lessfilter' => '.lessfilter',
	'mkshrc' => '.mkshrc',
	'screenrc' => '.screenrc',
	'shinit' => '.shinit',
	'sshconfig' => ".ssh/config",
	'terminator.config' => '.config/terminator/config',
	'tigrc'     => '.tigrc',
	'toprc'      => '.toprc',
	'uncrustify.cfg' => '.uncrustify.cfg',
	'vim' => '.vim',
	'vimrc' => '.vimrc',
	'xbindkeysrc' => '.xbindkeysrc',
	'xinitrc' => '.xinitrc',
	'xmobarrc' => '.xmobarrc',
	'xmodmaprc' => '.xmodmaprc',
	'xmonad.hs' => '.xmonad/xmonad.hs',
	'xmonad.hs' => '.xmonad/xmonad.hs',
	'xscreensaver' => '.xscreensaver',
	'zsh' => '.zsh',
	'zshrc' => '.zshrc'
);

my $hostname = `hostname`;
chomp($hostname);
if ( -d "$scriptdir/machines/$hostname" ) {
	$links{"machines/$hostname"} = ".$hostname";
}

my $contained = (substr $scriptdir, 0, length($home)) eq $home;
my $prefix = undef;
if ($contained) {
	$prefix = substr $scriptdir, length($home);
	($prefix) = $prefix =~ m{^\/? (.+) [^/]+ $}x;
}

my $i = 0; # Keep track of how many links we added
for my $file (keys %links) {
	# See if this file resides in a directory, and create it if needed.
	my($path) = $links{$file} =~ m{^ (.+/)? [^/]+ $}x;
	mkpath("$home/$path") if $path;

	my $src  = "$scriptdir/$file";
	my $dest = "$home/$links{$file}";

	# If a link already exists, see if it points to this file. If so, skip it.
	# This prevents extra warnings caused by previous runs of install.pl.
	if(!$force && -e $dest && -l $dest) {
		next if readlink($dest) eq $src;
	}

	# Remove the destination if it exists and we were told to force an overwrite
	if($force && -d $dest) {
		rmtree($dest) || warn "Couldn't rmtree '$dest': $!\n";
	} elsif($force) {
		unlink($dest) || warn "Couldn't unlink '$dest': $!\n";
	}

	if ($contained) {
		chdir $home;
		$dest = "$links{$file}";
		$src = "$prefix$file";
		if ($path) {
			my $nesting = split(/\//, $dest) - 1;
			$src = "../"x $nesting . "$src";
		}
	}

	symlink($src => $dest) ? $i++ : warn "Couldn't link '$src' to '$dest': $!\n";
}

print "$i link";
print 's' if $i != 1;
print " created\n";


