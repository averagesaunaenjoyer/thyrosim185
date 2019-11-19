#!/usr/bin/perl
use v5.10; use strict; use warnings;
#==============================================================================
# FILE:         getplot.cgi
# AUTHOR:       Simon X. Han
# DESCRIPTION:
#   The main function that:
#     1. Takes input from the browser
#     2. Sends commands out to the ODE solver
#     3. Collects results to send back to the browser for graphing
# NOTE:
#   SS: Steady state
#   IC: Initial condition
#==============================================================================

use CGI qw/:standard/;
use Data::Dumper;
use JSON::Syck; # Convert between JSON and Perl objects
$Data::Dumper::Sortkeys = 1;

# Set document root and folder root at compile time
my @S_NAME;
my $F_ROOT;
BEGIN {

    # Folder root
    @S_NAME = split(/\//, $ENV{SCRIPT_NAME});
    $F_ROOT = $S_NAME[1];

    # Document root
    if(!$ENV{DOCUMENT_ROOT}) {
        $ENV{DOCUMENT_ROOT} = '/home/www';
    }
}

use lib $ENV{'DOCUMENT_ROOT'}."/$F_ROOT/pm";
use THYROSIM;

# Create THYROSIM object
my $thsim = THYROSIM->new(toShow  => 'default',
                          docRoot => $ENV{DOCUMENT_ROOT},
                          fRoot   => $F_ROOT);

# New CGI object and read input from UI.
my $cgi = new CGI;
my $dat = $cgi->param('data'); # Inputs are passed as 1 string

# For testing, can use a custom input. See $thsim->customInput().
# E.g., $dat = $thsim->customInput("3");
$thsim->processInputs(\$dat);

#--------------------------------------------------
# Define command. Currently using Java ODE solver. Command arguments are
# generated in the section below.
# Description of command arguments (zero-based):
# 0 - 18:  19 compartments' initial conditions.
# 19:      ODE start time.
# 20:      ODE end time.
# 21 - 24: Dial values (secretion/absorption).
# 25 - 26: Infusion values.
# 27:      The thysim parameters to load.
#--------------------------------------------------
my $command = $thsim->getCommand("java");
my $getinit = $thsim->getCommand("java","getinit");
my $thysim = $thsim->getThysim();

#--------------------------------------------------
# Decide whether to perform the 0th integration.
# When the SS values are already known or if recalculate IC is off, 0th
# integration is skipped. Otherwise, perform the 0th integration. In either case
# we must set the IC for the next integration, q1.
# NOTE: The 0th integration (q0) runs the model to SS using clinically derived
# IC. This step is important because it allows material to enter the delay
# compartments. The end values of q0 are used as the IC of q1. We run q0 from
# 0-1008 hours so that it is a multiple of 24. This solved an issue where the
# initial day didn't start at exactly SS (q0 used to run from 0-1000 hours).
#--------------------------------------------------
my $dials = $thsim->getDialString(); # Only needed once
my $ickey = $thsim->getICKey();
if ($thsim->hasICKey($ickey) || !$thsim->recalcIC()) { # Skipping 0th
    $thsim->processKeyVal($ickey,'q0');
} else {
    my $ICstr = $thsim->getICString('q0');

    my $cmd = "$getinit $ICstr 0 1008 $dials 0 0 $thysim";
    my @res = `$cmd` or die "died: $!";
    $thsim->processResults(\@res,'q0');
}

#--------------------------------------------------
# Perform 1st to nth integrations.
# Integration intervals were determined in processInput, so here we retrieve
# them and call the solver.
#--------------------------------------------------
my $counts = $thsim->getIntCount();
foreach my $count (@$counts) {
    my $start = $thsim->toHour($thsim->getIntStart('thisStep',$count));
    my $end   = $thsim->toHour($thsim->getIntBound('thisStep',$count));
    my $ICstr = $thsim->getICString('q'.$count);
    my $u     = $thsim->getInfValue('q'.$count);

    my $cmd = "$command $ICstr $start $end $dials $u $thysim";
    my @res = `$cmd` or die "died: $!";
    $thsim->processResults(\@res,'q'.$count);
}

# Post process to create the JSON object
my $JSONObj = $thsim->postProcess();

# Print to log file.
# Make sure to set toShow to 'all' if you want non-standard compartments.
#--------------------------------------------------
# my $log = $ENV{DOCUMENT_ROOT}."/$F_ROOT/tmp/log";
# open my $fh, '>', $log;
# say $fh Dumper($thsim->{data}->{ft4}->{values});
# $thsim->printLog($fh,"t","q1","q4","q7","ft4","ft3");
# close $fh;
#-------------------------------------------------- 

# Convert to JSON and print to browser
print "content-type:text/html\n\n";
print JSON::Syck::Dump($JSONObj)."\n";
