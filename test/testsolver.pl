#!/usr/bin/perl
use v5.10; use strict; use warnings;
#==============================================================================
# FILE:         testsolver.pl
# AUTHOR:       Simon X. Han
# DESCRIPTION:
#   Test the server side solver by executing it on the command line.
#
#   Make sure docRoot and fRoot are correct. 
#==============================================================================

use Data::Dumper;

use lib "../pm";
use THYROSIM;

my $thsim = THYROSIM->new(setshow => 'default',
                          docRoot => '/home/www',
                          fRoot   => 'thyrosimon');

my $cmd = "java -cp .:/home/www/thyrosimon/java/commons-math3-3.6.1.jar:"
        . "/home/www/thyrosimon/java/ "
        . "edu.ucla.distefanolab.thyrosim.algorithm.Thyrosim"
        . " 0.322114215761171 0.201296960359917 0.63896741190756"
        . " 0.00663104034826483 0.0112595761822961 0.0652960640300348"
        . " 1.7882958476437 7.05727560072869 7.05714474742141 0 0 0 0"
        . " 3.34289716182018 3.69277248068433 3.87942133769244"
        . " 3.90061903207543 3.77875734283571 3.55364471589659"
        . " 0 24 1 1 1 1 0 0 ThyrosimJr noinit";

my @res = `$cmd`;
$thsim->processResults(\@res,'1');
$thsim->getBrowserObj();

# Note that printLog() here is only going to print mols. This is because
# conversion factors have not been loaded yet. Alternatively, I can use a custom
# experiment and force a processing of form inputs.
my $log = "../tmp/log";
open my $fh, '>', $log;
$thsim->printLog($fh,"t","1","4","7","ft4","ft3");
close $fh;
