#!/usr/bin/perl
#----------------------------------------------------------------------------
# Module   : MakeExecutablePerl.
# Author   : Deepankumar.P | Programmer Trainee
# Function : IRL
#----------------------------------------------------------------------------

# Histroy
#----------------------------------------------------------------------------
# v1.0 | 30-09-2014 | Deepankumar.P | Initial Development
#----------------------------------------------------------------------------

my $ver = "1.0";

# Module declaration
	use strict;
	use warnings;
	use Time::localtime;
	use File::stat;
	use File::Copy;   #Gives you access to the "move" command
	use Win32;
	BEGIN { Win32::LoadLibrary("comctl32.dll") }
	use File::Basename;
	use Cwd;
	

# Application path
	my $apppath=dirname($0);
	if($apppath=~m/^[ \.]*$/)
	{
		$apppath=cwd();
	}
	$apppath=~s/\//\\/g;

# Command-line input validate
	my $path = "$apppath\\perlpath.ini";
	my $error_log = $path;
	$error_log =~ s{\.[^\. ]*$}{\.log}i;
	
	_exit_main(qq(Invalid input ini or xml file)) if($path!~m{\.(ini|xml)$}i);
	print "\n\n\tAutoExePerl.\n\tVer $ver\n";

#========================DB work=================================================

#!"C:\perl\bin\perl.exe"
use DBI;
#use DBD::mysql;
# HTTP HEADER
# print "Content-type: text/html \n\n";
# MYSQL CONFIG VARIABLES


my $host = "172.18.10.63";
my $database = "ctae_ipubsuite";
my $tablename = "exeperl";
my $user = "ipubsuite_admin";
my $pw = "iPubSuite2015";
# PERL DBI CONNECT()
my $driver = "DBI:mysql:database=$database;host=$host";
my $connect_me = DBI->connect($driver, $user, $pw);
# SELECT DB
my $run_query = $connect_me->prepare("SELECT `version`, `input`, `output` FROM $tablename WHERE id=2");
$run_query->execute();
#looping and displaying the result
# while($result=$run_query->fetchrow_hashref()) {
  # print "<b>Value returned:</b> $result->{time}\n";
# }
# print "<hr>";

my @result;
my $Input_Dir;
my $Output_Dir;
my $version;

$run_query->execute();
while(@result = $run_query->fetchrow_array()){
	$version = $result[0];
	# print "$result[0]\n";
}

$run_query->execute();
while(@result = $run_query->fetchrow_array()){
	$Input_Dir = $result[1];
	# print "$result[1]\n";
}

$run_query->execute();
while(@result = $run_query->fetchrow_array()){
	$Output_Dir = $result[2];
	# print "$result[2]\n";
}

#================================================================================
	
# Global variables
	my $tm;
	my $err_info;
	my $timestamp;
	
	# open(FF,$path);
	# my $cnt = do {local $/;<FF>} or die;
	# close FF;
	
	# my ($Input_Dir) = $cnt =~ m{<input>((?:(?!</?input[ >]).)*)</input>}igs; 
	# my ($Output_Dir) = $cnt =~ m{<output>((?:(?!</?output[ >]).)*)</output>}igs;

	
		# my $cmdpath = "perlapp --force \"$apppath\\$tm\"";
		my $cmdpath = "\"C:\\Program Files\\Git\\bin\\sh.exe\" --login -i";		
		my $gitpath = 'git clone git@bitbucket.org:mdbooks/ember-a-14e.git';
		# $err_info = "$Output_Dir\\$tm";
		my $error="";
		
		# chdir($apppath);
		
		if (open (CHECK, "$cmdpath 2>&1 |")) {
			$error = do{local $/; <CHECK>};				
			close CHECK;
			# $err_info =~ s{\.[^\. ]*$}{\.log}i;
			_err_msg(qq($error)) if(!defined($err_info) or ! -f "$err_info");
		}
		if (open (CHECK, "$gitpath 2>&1 |")) {
			$error = do{local $/; <CHECK>};				
			close CHECK;
			# $err_info =~ s{\.[^\. ]*$}{\.log}i;
			_err_msg(qq($error)) if(!defined($err_info) or ! -f "$err_info");
		}
		
		print $error;exit;
	
	
	
	exit;
	
	
	
	if($version eq "6.0"){
		opendir(DIR, "$Input_Dir");
		my @file = grep{/\.pl$/i} readdir(DIR);
		close(DIR);
	
		foreach $tm(@file){
			
			my $timepath = "$Input_Dir\\$tm";   #used for getting Last Modified time.
			$timestamp = ctime(stat($timepath)->mtime);	#used for getting Last Modified time.
			$timestamp =~ s{\s}{_}ig;
			$timestamp =~ s{([0-9]+):([0-9]+):([0-9]+)}{$1h-$2m-$3s}ig;
			
			mkdir("$apppath\\Backup") unless(-e "$apppath\\Backup");
			move("$Input_Dir\\$tm", "$apppath\\$tm"); #or die "The move operation failed: $!";
			copy("$apppath\\$tm", "$apppath\\Backup\\$tm"); #or die "The copy operation failed: $!";
			rename("$apppath\\Backup\\$tm", "$apppath\\Backup\\$timestamp\_$tm") || die ( "Error in renaming" );
			
			my $logfile = $tm;
			$logfile =~ s{\.[^\. ]*$}{\.log}i;
			
			opendir(DIR, "$Output_Dir");
			my @logfile = grep{/\.log$/ig} readdir(DIR);
			foreach my $log(@logfile){
				if($log eq $logfile){
					unlink("$Output_Dir\\$log");
				}
			}
			close(DIR);
			
			# my $cmdpath = "perlapp --force \"$apppath\\$tm\"";
			my $cmdpath = "\"C:\\Program Files\\Git\\bin\\sh.exe\" --login -i";
			print $cmdpath;exit;
			$err_info = "$Output_Dir\\$tm";
			my $error="";
			
			chdir($apppath);
			
			if (open (CHECK, "$cmdpath 2>&1 |")) {
				$error = do{local $/; <CHECK>};	
				close CHECK;
				$err_info =~ s{\.[^\. ]*$}{\.log}i;
				_err_msg(qq($error)) if(!defined($err_info) or ! -f "$err_info");
			}
			my $exe = $tm;
			$exe =~ s{\.pl$}{\.exe}i;
			move("$apppath\\$exe", "$Output_Dir\\$exe"); #or die "The move operation failed: $!";
			unlink("$apppath\\$tm");
			
		}
	}



# if($version eq "6.0"){
		# opendir(DIR, "$Input_Dir");
		# my @file = grep{/\.pl$/i} readdir(DIR);
		# close(DIR);
		
		# foreach $tm(@file){
			
			# my $timepath = "$Input_Dir\\$tm";   #used for getting Last Modified time.
			# $timestamp = ctime(stat($timepath)->mtime);	#used for getting Last Modified time.
			# $timestamp =~ s{\s}{_}ig;
			# $timestamp =~ s{([0-9]+):([0-9]+):([0-9]+)}{$1h-$2m-$3s}ig;
			
			# mkdir("$apppath\\Backup") unless(-e "$apppath\\Backup");
			# move("$Input_Dir\\$tm", "$apppath\\$tm"); #or die "The move operation failed: $!";
			# copy("$apppath\\$tm", "$apppath\\Backup\\$tm"); #or die "The copy operation failed: $!";
			# rename("$apppath\\Backup\\$tm", "$apppath\\Backup\\$timestamp\_$tm") || die ( "Error in renaming" );
			
			# my $logfile = $tm;
			# $logfile =~ s{\.[^\. ]*$}{\.log}i;
			
			# opendir(DIR, "$Output_Dir");
			# my @logfile = grep{/\.log$/ig} readdir(DIR);
			# foreach my $log(@logfile){
				# if($log eq $logfile){
					# unlink("$Output_Dir\\$log");
				# }
			# }
			# close(DIR);
			
			# my $cmdpath = "perlapp --force \"$apppath\\$tm\"";
			# $err_info = "$Output_Dir\\$tm";
			# my $error="";
			
			# chdir($apppath);
			
			# if (open (CHECK, "$cmdpath 2>&1 |")) {
				# $error = do{local $/; <CHECK>};	
				# close CHECK;
				# $err_info =~ s{\.[^\. ]*$}{\.log}i;
				# _err_msg(qq($error)) if(!defined($err_info) or ! -f "$err_info");
			# }
			# my $exe = $tm;
			# $exe =~ s{\.pl$}{\.exe}i;
			# move("$apppath\\$exe", "$Output_Dir\\$exe"); #or die "The move operation failed: $!";
			# unlink("$apppath\\$tm");
			
		# }
	# }
	
#======================================
sub _exit_main
{
	# my $msg=shift;
	# Win32::MsgBox($msg,64,"Quit");
	# exit;
	
	my $msg = shift;
	print "\n$msg";

	open(FF, ">$error_log");
	print FF $msg;
	close FF;
	exit;
}
#======================================
sub _err_msg
{
	my $msg = shift;
	print "\n$msg";
	open(FF, ">$err_info");
	$msg =~ s{perlapp.*?<info[^>]+>}{}is;
	print FF $msg;
	close FF;
}
#======================================