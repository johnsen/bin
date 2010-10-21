#!/usr/bin/perl

use strict;

print "Checking if you are root... ";
if ($< == 0)
{
	print "yes - not good.\n";
	print "** You are running this script as root. Please run it as a regular user for the most reliable results.\n"
}
else
{
	print "no - good.\n"
}

### Checks van http://irc.esben-stien.name/mediawiki/index.php/Setting_Up_Real_Time_Operation_on_GNU/Linux_Systems
## Kernel
# CONFIG_NO_HZ: TODO see launchpad #229499
# higres: TODO

print "Finding current kernel config... ";
my $kernelConfig = "none";
my $filename = "/boot/config-" . `uname -r`;
chomp($filename);
if ( -e ("/proc/config.gz") )
{
	print "found /proc/config.gz.\n";
	$kernelConfig = `zcat /proc/config.gz`;
}
elsif ( -e $filename )
{
	print "found $filename\n";
	$kernelConfig = `cat $filename`;
}
else
{
	print "not found.\n";
	print "/boot/config-" . `uname -r`;
	print "** Warning: Kernel config not found, options not verified\n";
}

if ($kernelConfig ne "none")
{
	print "Checking for Ingo Molnar's Real-Time Preemption... ";
	if ( $kernelConfig !~ /CONFIG_PREEMPT_RT=y/)
	{
		print "not found.\n"; 
		print "** Kernel without real-time capabilities found\n";
		print "   For more information, see http://wiki.linuxmusicians.com/doku.php?id=system_configuration#installing_a_real-time_kernel\n";
	} else { 
		print "found - good.\n"; 
	}
	
	print "Checking for high-resolution timers... ";
	if ( $kernelConfig !~ /CONFIG_HIGH_RES_TIMERS=y/)
	{
		print "not found.\n"; 
		print "** Kernel without high-resolution timers\n";
	} else { 
		print "found - good.\n"; 
	}

	print "Checking for Generic PCI bus-master DMA support... ";
	if ( $kernelConfig !~ /CONFIG_BLK_DEV_IDEDMA_PCI=y/)
	{
		print "not found.\n"; 
		print "** Kernel without Generic PCI bus-master DMA support\n";
		print "   For more information, see:\n";
		print "   - http://lowlatency.linuxaudio.org\n";
	} else { 
		print "found - good.\n"; 
	}
		

	# This check has been removed: see http://linuxmusicians.com/viewtopic.php?f=27&t=456
	#print "Checking for tickless time support... ";
	#if ( $kernelConfig =~ /CONFIG_NO_HZ=y/)
	#{
	#	print "found.\n"; 
	#	print "** Tickless timer found. This is said to reduce realtime performance\n";
	#	print "   For more information, see http://linuxmusicians.com/viewtopic.php?f=27&t=456\n";
	#} else { 
	#	print "not found - good.\n"; 
	#}

	print "Checking for 1000hz clock... ";
	if ( $kernelConfig =~ /CONFIG_HZ=1000/)
	{
		print "found - good.\n"; 
	} else { 
		print "not found.\n"; 
		print "** Try setting your clock to 1000hz\n";
		print "   For more information, see http://wiki.linuxmusicians.com/doku.php?id=system_configuration#installing_a_real-time_kernel\n";
	}

	print "Checking for High Resolution Timers... ";
	if ( $kernelConfig =~ /CONFIG_HIGH_RES_TIMERS=y/ )
	{
		print "found - good.\n"; 
	} else { 
		print "not found.\n"; 
		print "** Try enabling high-resolution timers (CONFIG_HIGH_RES_TIMERS under 'Processor type and features')\n";
		print "   For more information, see http://wiki.linuxmusicians.com/doku.php?id=system_configuration#installing_a_real-time_kernel\n";
	}

}

# 1000hz: TODO

## File System
my @filesystems;
my $mount = `mount`;
while ($mount =~ /(\S*) on (\S+) type (\S+) \(([^)]*)\)/gi)
{
	my %filesystem;
	$filesystem{dev} = $1;
	$filesystem{mountpoint} = $2;
	$filesystem{type} = $3;
	$filesystem{params} = $4;
	push(@filesystems, \%filesystem);
}

print "Checking filesystem types... ";
my $foundMessage = 0;
my $tmpfs = 0;
foreach my $fsref (@filesystems)
{
	my %fs = %{$fsref};
	if ($fs{dev} =~ /^\/dev/ && $fs{mountpoint} !~ /^\/media/ &&(($fs{type} eq "fuseblk") || ($fs{type} eq "reiserfs")))
	{
		if (!$foundMessage)
		{
			print "\n";
			$foundMessage = 1;
		}
		print "** Warning: do not use $fs{mountpoint} for audio files.\n";
		print "   $fs{type} is not a good filesystem type for realtime use and large files.\n";
	}
	if (($fs{type} eq "tmpfs") && ($fs{mountpoint} eq "/tmp"))
	{
		$tmpfs = 1;
	}
}

if (!$foundMessage)
{
	print "ok.\n";
}
else
{
	print "   For more information, see http://wiki.linuxmusicians.com/doku.php?id=system_configuration#filesystems\n";
}

print "Checking tmpfs mounted on /tmp..  ";
if ($tmpfs)
{
	print "ok.\n";
}
else
{
	print "not found.\n";
	print "** Warning: no tmpfs partition mounted on /tmp\n";
	# TODO tip about 'sudo mount -t tmpfs none /tmp' or editing fstab.
	print "   For more information, see:\n";
	print "   - http://wiki.linuxmusicians.com/doku.php?id=system_configuration#tmpfs\n";
	print "   - http://lowlatency.linuxaudio.org\n";
}

# noatime
print "Checking filesystem 'noatime' parameter... ";
my $foundMessage = 0;
foreach my $fsref (@filesystems)
{
	my %fs = %{$fsref};
	if ($fs{dev} =~ /^\/dev/ && $fs{params} !~ /noatime/)
	{
		if (!$foundMessage)
		{
			print "\n";
			$foundMessage = 1;
		}
		print "** Warning: $fs{mountpoint} does not have the 'noatime' parameter set\n";
		print "   For more information, see http://wiki.linuxmusicians.com/doku.php?id=system_configuration#filesystems\n";
	}
}
if ($foundMessage == 0)
{
	print "ok.\n";
}

if (!defined $ENV{SOUND_CARD_IRQ})
{
	print "** Set \$SOUND_CARD_IRQ to the IRQ of your soundcard to enable more checks.\n";
	print "   Find your sound card's IRQ by looking at '/proc/interrupts' and lspci.\n";
}
elsif ($ENV{SOUND_CARD_IRQ} eq "none")
{
#	print "\$SOUND_CARD_IRQ set to 'none', skipping IRQ tests\n";
}
else
{
	my $irqline = `cat /proc/interrupts | grep $ENV{SOUND_CARD_IRQ}:`;
	#my @fields = split(/\s+/, $irqline);
	if ($irqline =~ /,/)
	{
		print "** multiple devices found at the sound cards' IRQ\n";
	}
}

## PCI
#if (!defined $ENV{SOUND_CARD_PCI_ID})
#{
#	print "** Set \$SOUND_CARD_PCI_ID to the pci-id of your soundcard to enable more checks\n";
#}
#elsif ($ENV{SOUND_CARD_PCI_ID} eq "none")
#{
#	print "\$SOUND_CARD_PCI_ID set to 'none', skipping PCI tests\n";
#}
#else
#{
#	my $lspci = `lspci -v`;
#	# TODO latencies en burst settings bekijken
#}

## Hardware priority (IRQ)
# TODO: find out what APIC means.

## Software priority
# TODO:  ps -Leo rtprio,cmd,pid | grep -v -e "^     - "
# then check that watchdog, irq9, jack, rtapps are prioritized in that order.

# TODO Hardware memory: CAS-latency of '2' is advised - is this really that relevant?

# TODO check for iostat
#print "Checking for paging... ";
#if (not (-e `which iostat` ))
#{
#	print " can't find iostat.\n";
#	print "** Warning: install iostat (often in the sysstat package) to check for paging\n";
#}

# TODO Check out latency TOP

## JACK
# TODO: esben-stein mentions '/dev/shm' usage, but I don't see that in 'man jackd'.
# TODO: check if hardware supports --hwmon, if so check whether it's used

## Misc

# security/limits.conf
print "Checking the ability to prioritize processes with (re)nice... ";
my $niceout = `nice -n -5 nice`;
chomp($niceout);
if ($niceout eq "-5")
{
	print "yes - good.\n";
}
else
{
	print "no.\n";
	print "** Could not assign a -5 nice value. Set up limits.conf.\n";
	print "   For more information, see http://wiki.linuxmusicians.com/doku.php?id=system_configuration#limits.conf\n";
}
print "Checking the ability to prioritize processes with rtprio... ";
my $rtprioexec = `which rtprio`;
chomp($rtprioexec);
if (-e $rtprioexec)
{
	my $rtprioout = `rtprio 80 echo success`;
	if ($rtprioout =~ /success/)
	{
		print "yes - good.\n";
	}
	else
	{
		print "** Could not assign a 80 rtprio value. Set up limits.conf.\n";
		print "   For more information, see http://wiki.linuxmusicians.com/doku.php?id=system_configuration#limits.conf\n";
	}
}
else
{
	print " unknown.\n";
	print "** rtprio command-line tool $rtprioexec not found - install it for improved feedback\n";
	print "   For more information, see http://wiki.linuxmusicians.com/doku.php?id=system_configuration#priorities\n"
}
# TODO other limits.conf settings: 

print "Checking whether you're in the 'audio' group... ";
if ( `groups | grep audio` eq "" )
{
	print "no.\n";
	print "** add yourself to the audio group with 'adduser \$USER audio'\n"
} else {
	print "yes - good.\n"
}
print "Checking for multiple 'audio' groups... ";
my $audioGroups = `cat /etc/group | grep audio | wc -l`;
chomp($audioGroups);
if ( $audioGroups eq "1" )
{
	print "no - good.\n";
} else {
	print "yes.\n";
	print "** Found $audioGroups groups with name 'audio'. You should not have duplicate 'audio' groups.\n";
	print "   For more information, see http://wiki.linuxmusicians.com/doku.php?id=system_configuration#audio_group\n";
}

print "Checking access to the real-time clock... ";
if ( -e "/dev/rtc" )
{
	if ( -r "/dev/rtc" )
	{
		print "readable - good.\n";
	}
	else
	{	
		print "not readable.\n";
		print "** Warning: /dev/rtc found, but not readable.\n";
		print "** make /dev/rtc readable by the 'audio' group\n";
		print "   For more information, see http://wiki.linuxmusicians.com/doku.php?id=system_configuration#real-time_clock\n";
	}
}
else
{
	print "not found.\n";
	print "** Warning: /dev/rtc not found.\n";
}

print "Checking sysctl settings:\n";
print "- checking inotify max_user_watches... ";
if ((`cat /proc/sys/fs/inotify/max_user_watches` < 524288))
{
	print "too small.\n";
	print "** /proc/sys/fs/inotify/max_user_watches is smaller than 524288\n";
	print "** increase it by adding 'fs.inotify.max_user_watches = 524288' to /etc/sysctl.conf and rebooting\n";
	print "   For more information, see http://wiki.linuxmusicians.com/doku.php?id=system_configuration#sysctl.conf\n";
} else {
	print ">= 524288 - good.\n"
}

print "Checking for resource-intensive background processes... ";
$foundMessage = 0;
foreach my $process (( 'powersaved', 'kpowersave' ))
{
	if (`ps aux | grep $process | grep -v grep` ne "")
	{
		print "\n** Found $process background process";
		$foundMessage = 1;
	}
}
if ($foundMessage)
{
	print "\n   For more information, see http://wiki.linuxmusicians.com/doku.php?id=system_configuration#Disabling_resource-intensive_daemons\n";
}
else
{
	print "none found - good.\n";
}

# TODO
# print "Checking for jack configuration... ";

#if ( File.exists("~/.jackdrc") )
#{
#	my $jackconf=`line < ~/.jackdrc`;
#	print "found ~/.jackdrc: $jackconf"
#} else {
#	print 'not found.'
#}

# security/limits.conf
