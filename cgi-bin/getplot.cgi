#!/usr/bin/perl
use v5.10; use strict; use warnings;
#==============================================================================
# FILE:         getplot.cgi
# AUTHOR:       Simon X. Han
# DESCRIPTION:
#   The main function that:
#   1. Takes input from the browser
#   2. Sends commands out to the Octave ODE solver
#   3. Collects results to send back to the browser
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

# New CGI object
my $cgi = new CGI;

# Create THYROSIM object
# TODO make jr a parameter from the website
my $thsim = THYROSIM->new(toShow  => 'default',
                          docRoot => $ENV{DOCUMENT_ROOT},
                          fRoot   => $F_ROOT,
                          jr      => 1);

# Process inputs
my $inputs = $cgi->param('data'); # Inputs are passed as 1 string

# For testing, can use a custom input. See $thsim->customInput().
#--------------------------------------------------
# $inputs = $thsim->customInput("3");
#-------------------------------------------------- 

$thsim->processInputs(\$inputs);

# Define command. Currently using Java ODE solver.
my $command = $thsim->getCommand("java");
my $getinit = $thsim->getCommand("java","getinit");

#--------------------------------------------------
# Perform 0th integration or skip it if the end value is already known.
# The 0th integration runs the model to SS using clinically derived initial
# conditions (IC), q0. This step is important because it allows material to
# enter the delay compartments. The end values of the 0th integration is used as
# the basis of the IC of the next integration.
# By Professor DiStefano, the 0th integration runs from 0-1000 hours.
# We changed t to 1008, so that it's a multiple of 24. This solved an issue
# where the initial day didn't start at exactly steady state.
# Currently using Lu Chen's IC, which fixed an issue with q4 starting too low.
#-------------------------------------------------- 
my $secAbs = $thsim->getDialString(); # Only needed once
my $icKey = $thsim->getICKey();
if ($thsim->hasICKey($icKey) || !$thsim->recalcIC()) {
    $thsim->processKeyVal($icKey,'q0');
} else {
    my $ICstr = $thsim->getICString('q0');
    my @results = `$getinit $ICstr 0 1008 $secAbs 0 0 ThyrosimJr` or die "died : $!";

    # Process the results of the 0th integration. Will also save the end values
    # as IC for the next integration, q1.
    $thsim->processResults(\@results,'q0');
}

#--------------------------------------------------
# Perform 1st to nth integrations.
# Integration intervals were determined in processInput, so here we retrieve
# them and call Octave.
#--------------------------------------------------
my $counts = $thsim->getIntCount();
foreach my $count (@$counts) {
    my $start = $thsim->toHour($thsim->getIntStart('thisStep',$count));
    my $end   = $thsim->toHour($thsim->getIntBound('thisStep',$count));
    my $ICstr = $thsim->getICString('q'.$count);
    my $u     = $thsim->getInfValue('q'.$count);

    my @results = `$command $ICstr $start $end $secAbs $u ThyrosimJr` or die "died : $!";
    $thsim->processResults(\@results,'q'.$count);
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
