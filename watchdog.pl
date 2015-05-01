#!/usr/bin/perl -w

# watchdog.pl
# Use in conjuntion with cron and Nagios plugin NSCA to monitor one or more process
# and send passive check results back to a Nagios station

# written by bn@ucsd.edu - 11.8.2006
# modified: 11.12.2006
# update log:
# - initial version 
# - added new functions to handle process check

# methods for checking a status of a program
# - on REDHAT systems
# pidof
# then try /var/run/*.pid
# then check to see if /var/lock/subsys/PROGRAM exist and return if locked
##########################################################################

#using PIDOF
# pidof -o %PPID -x <program>
# -o %PPID - ignore parent
# -x - list pid of script too
my $pidof = "pidof -x \%PPID -x";

#use /var/run/*.pid
my $rundir = "/var/run";
my @pidfiles = glob "$rundir/*.pid";
print "DEBUG-pidfiles: $pidfiles[0]", "\n";

#open syslog with macros option
use Sys::Syslog qw(:standard :macros);

#obsolete
my $pidfile = "/var/run/sshd.pid";
my $check_command = "uxmon";
my $start_command = "/etc/init.d/nrpe restart";

# call to check the pidof of a process
#&pidof;

#main system call
&watchdog();

sub watchdog {
   # argument
   my $process;

   foreach $arg (@ARGV) {
      print "DEBUG-arg: $arg", "\n";
      my $process = $arg;	 
      &check_proc($process);
   }
}

sub pidof () {
   #get the argument
   my $process = $_[0];
   print "DEBUG-process: $process", "\n";

   # run a program and pass to filehandler
   open PID, "$pidof $process |" or die "Command not found\n";

   if (<PID>) {
   while (<PID>) {
      $pid = $_;
      print "DEBUG-line: $pid", "\n";

      # pidof returns "6798 6152 4862 23824 20281 15223 5893" if there are more then one pid
      @pidsplit = split;
      print "DEBUG-line-array: $pidsplit[0]", "\n";
      print "DEBUG-line-array: $pidsplit[1]", "\n";
    }
   } else {
      print "DEBUG-pid: not found", "\n";
   }
}

sub check_proc() {
   # retreive argument, only get the first and only expect 1
   my $process = $_[0];

   openlog("ProcessWatcher", "pid",LOG_LOCAL0);

   foreach $i (@pidfiles) {
      print "DEBUG-i: $i", "\n";      
      print "DEBUG-process: ", $rundir . "/" . $process . ".pid", "\n";      
      if ($i ne $process) {
	 syslog(LOG_WARNING, "Process ID file not found, restarting application");
	 &restart_proc;
	 #exit;
      }
   
      open IN, $i || syslog(LOG_ERR, "Couldn't read $pidfile- $!");
      my $pid = <IN>;
      chomp $pid;
      #what the heck im i suppose to see from these statements?
      print "DEBUG-pid-openfile: $pid", "\n";      
   
      #my $ret = `ps -p $pid -o comm=`;
      my $ret = &pidof($process);
      if ($ret != $check_command) {
	 syslog(LOG_ERR, "Return value mismatch, restarting Process");
	 &restart_proc;
	 exit;
      }
   }
}

sub restart_proc() {
   #my $msg = `$start_command`;
   print "DEBUG-restart: restart function called", "\n";      
   #syslog (LOG_INFO, "Restarting Process returned: $msg");
}

