#!/usr/bin/perl
#==============================================================================
# FILE:         getplot.cgi
# AUTHOR:       Simon X. Han
# DESCRIPTION:
#   The main function that:
#   1. Takes input from the browser
#   2. Sends commands out to the Octave ODE solver
#   3. Collects results to send back to the browser
#==============================================================================
use strict;
use warnings;
use CGI qw/:standard/;
use JSON::Syck; # Convert between JSON and Perl objects

# Set document root and folder root at compile time
my @S_NAME;
my $F_ROOT;
BEGIN {

    # Folder root
    @S_NAME = split(/\//, $ENV{'SCRIPT_NAME'});
    $F_ROOT = $S_NAME[1];

    # Document root
    if(!$ENV{'DOCUMENT_ROOT'}) {
        $ENV{'DOCUMENT_ROOT'} = '/home/simon/www';
    }
}

use lib $ENV{'DOCUMENT_ROOT'}."/$F_ROOT/pm";
use THYROSIM;

# Testing/Debug
my $DEBUG = 0; # See below for what DEBUG does. Default: 0

# New CGI object
my $cgi = new CGI;

# Create thsim object
# TODO adultChild value to be derived from browser at some point
my $thsim = THYROSIM->new('adultChild' => 1);

# Set the results to send to the browser.
my $toShow = {
    't'   => 1,
    'q1'  => 1,
    'q4'  => 1,
    'q7'  => 1
};

$thsim->setLvl1('toShow',$toShow);

# Process inputs
my $inputs;
if (!$DEBUG) {
    $inputs = $cgi->param('data'); # Inputs are passed as 1 string
}

if ($DEBUG == 1) {
    $inputs = 'dialinput1=100&dialinput2=88&dialinput3=100&dialinput4=88'
            . '&simtime=5'
            . '&type-1=1&hormone-1=4&disabled-1=0&dose-1=1'
            .  '&int-1=1&start-1=1&end-1=2'
            . '&type-2=2&hormone-2=4&disabled-2=0&dose-2=2&start-2=2'
            . '&type-3=3&hormone-3=4&disabled-3=0&dose-3=3&start-3=3'
            .  '&end-3=4'
            . '&type-4=1&hormone-4=4&disabled-4=0&dose-4=4'
            .  '&singledose-4=1&start-4=4';
}

# Oral 400 mg T4 repeating dose day 1 to 5
if ($DEBUG == 2) {
    $inputs = 'dialinput1=100&dialinput2=88&dialinput3=100&dialinput4=88'
            . '&simtime=5'
            . '&hormone-1=4&type-1=1&disabled-1=0&dose-1=400&int-1=1'
            .  '&start-1=1&end-1=5';
}

# Single 400 mg T4 dose
if ($DEBUG == 3) {
    $inputs = 'dialinput1=100&dialinput2=88&dialinput3=100&dialinput4=88'
            . '&simtime=3'
            . '&hormone-1=4&type-1=1&disabled-1=0&dose-1=400'
            .  '&singledose-1=1&start-1=1';
}

# No inputs
if ($DEBUG == 4) {
    $inputs = 'dialinput1=100&dialinput2=88&dialinput3=100&dialinput4=88'
            . '&simtime=1';
}

# 2 infusion inputs
if ($DEBUG == 5) {
    $inputs = 'dialinput1=100&dialinput2=88&dialinput3=100&dialinput4=88'
            . '&simtime=5'
            . '&hormone-1=4&type-1=3&disabled-1=0&dose-1=400'
            .  '&start-1=1&end-1=4'
            . '&hormone-2=4&type-2=3&disabled-2=0&dose-2=400'
            .  '&start-2=2&end-2=6';
}

$thsim->processInputs(\$inputs);

# Define command root
my $command = "octave -q ".$ENV{'DOCUMENT_ROOT'}."/$F_ROOT/octave/thyrosim.m";
my $getinit = "octave -q ".$ENV{'DOCUMENT_ROOT'}."/$F_ROOT/octave/getinit.m";

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
    my @results = `$getinit $ICstr 0 1008 $secAbs 0 0` or die "died : $!";

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

    my @results = `$command $ICstr $start $end $secAbs $u` or die "died : $!";
    $thsim->processResults(\@results,'q'.$count);
}

# Post process to create the JSON object
my $JSONObj = $thsim->postProcess();

# Convert to JSON and print to browser
print "content-type:text/html\n\n";
print JSON::Syck::Dump($JSONObj)."\n";
