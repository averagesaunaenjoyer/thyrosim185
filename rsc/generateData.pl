#!/usr/bin/perl

use strict;
use warnings;
use JSON::Syck;
use List::Util 'max';

# simTime is in days
my $simTime = 1.08333;
my $sizeOfArray = 10;

# q7 (TSH) is in mU/L
my @q7vals  = (0) x $sizeOfArray;
my $q7count = $sizeOfArray;
my $q7min   = 0;
my $q7max   = max(@q7vals);

# q4 (T3) is in mcg/L
my @q4vals  = (
    1.420,
    2.982,
    5.583,
    5.677,
    5.440,
    3.798,
    3.304,
    3.102,
    1.910,
    1.945
);
my $q4count = $sizeOfArray;
my $q4min   = 0;
my $q4max   = max(@q4vals);

# q1 (T4) is in mcg/L
my @q1vals  = (0) x $sizeOfArray;
my $q1count = $sizeOfArray;
my $q1min   = 0;
my $q1max   = max(@q1vals);

# t is in hours
my $tcount  = $sizeOfArray;
my @tvals   = (
    0,
    1,
    2,
    3,
    4,
    6,
    8,
    10,
    24,
    26
);

my $data;
$data->{q7}->{count}    = $q7count;
$data->{q7}->{min}      = $q7min;
$data->{q7}->{max}      = $q7max;
$data->{q7}->{'values'} = \@q7vals;
$data->{q4}->{count}    = $q4count;
$data->{q4}->{min}      = $q4min;
$data->{q4}->{max}      = $q4max;
$data->{q4}->{'values'} = \@q4vals;
$data->{q1}->{count}    = $q1count;
$data->{q1}->{min}      = $q1min;
$data->{q1}->{max}      = $q1max;
$data->{q1}->{'values'} = \@q1vals;
$data->{t}->{count}     = $tcount;
$data->{t}->{'values'}  = \@tvals;

my $obj;
$obj->{simTime} = $simTime;
$obj->{data}    = $data;

print STDOUT JSON::Syck::Dump($obj)."\n";
