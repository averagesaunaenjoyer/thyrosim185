#!/usr/bin/perl
#==============================================================================
# FILE:         THYROSIM.pm
# AUTHOR:       Simon X. Han
# DESCRIPTION:
#   Package where the bulk of Thyroid SIM related subroutines lives.
#==============================================================================

use strict;

package THYROSIM;

#====================================================================
# SUBROUTINE:   new
# DESCRIPTION:
#   Returns an object of THYROSIM.
#   TODO:
#   1.  Make adultChild something passed into new. new will load the correct
#       set of parameters based on adultChild, probably in another function.
#====================================================================
sub new {
    my ($class,%params) = @_;
    my $self;

    # 1 for adult, 0 for child, default adult
    $self->{'adultChild'} = $params{'adultChild'}
                          ? $params{'adultChild'} 
                          : 1;

    # SS values, calculated using Marisa's IC, running for 1008 hours,
    # and taking final values.
    # See fullmodelV2.m
#--------------------------------------------------
#     $self->{'ICKey'}->{'1000088010000880'}->{1}     = 0.32211503553749;
#     $self->{'ICKey'}->{'1000088010000880'}->{2}     = 0.20129760792015;
#     $self->{'ICKey'}->{'1000088010000880'}->{3}     = 0.63896956238422;
#     $self->{'ICKey'}->{'1000088010000880'}->{4}     = 0.00563704586667;
#     $self->{'ICKey'}->{'1000088010000880'}->{5}     = 0.01222846569077;
#     $self->{'ICKey'}->{'1000088010000880'}->{6}     = 0.06533441744367;
#     $self->{'ICKey'}->{'1000088010000880'}->{7}     = 1.78828690438010;
#     $self->{'ICKey'}->{'1000088010000880'}->{8}     = 7.05857005668430;
#     $self->{'ICKey'}->{'1000088010000880'}->{9}     = 7.05694991894698;
#     $self->{'ICKey'}->{'1000088010000880'}->{10}    = 0;
#     $self->{'ICKey'}->{'1000088010000880'}->{11}    = 0;
#     $self->{'ICKey'}->{'1000088010000880'}->{12}    = 0;
#     $self->{'ICKey'}->{'1000088010000880'}->{13}    = 0;
#     $self->{'ICKey'}->{'1000088010000880'}->{14}    = 3.34289826438784;
#     $self->{'ICKey'}->{'1000088010000880'}->{15}    = 3.69277254249145;
#     $self->{'ICKey'}->{'1000088010000880'}->{16}    = 3.87942103614693;
#     $self->{'ICKey'}->{'1000088010000880'}->{17}    = 3.90061836747638;
#     $self->{'ICKey'}->{'1000088010000880'}->{18}    = 3.77875640793801;
#     $self->{'ICKey'}->{'1000088010000880'}->{19}    = 3.55364361682626;
#-------------------------------------------------- 

    # Trying out Lu Chen's IC
    $self->{'ICKey'}->{'1000088010000880'}->{1}     = 0.322114215761171;
    $self->{'ICKey'}->{'1000088010000880'}->{2}     = 0.201296960359917;
    $self->{'ICKey'}->{'1000088010000880'}->{3}     = 0.638967411907560;
    $self->{'ICKey'}->{'1000088010000880'}->{4}     = 0.00663104034826483;
    $self->{'ICKey'}->{'1000088010000880'}->{5}     = 0.0112595761822961;
    $self->{'ICKey'}->{'1000088010000880'}->{6}     = 0.0652960640300348;
    $self->{'ICKey'}->{'1000088010000880'}->{7}     = 1.78829584764370;
    $self->{'ICKey'}->{'1000088010000880'}->{8}     = 7.05727560072869;
    $self->{'ICKey'}->{'1000088010000880'}->{9}     = 7.05714474742141;
    $self->{'ICKey'}->{'1000088010000880'}->{10}    = 0;
    $self->{'ICKey'}->{'1000088010000880'}->{11}    = 0;
    $self->{'ICKey'}->{'1000088010000880'}->{12}    = 0;
    $self->{'ICKey'}->{'1000088010000880'}->{13}    = 0;
    $self->{'ICKey'}->{'1000088010000880'}->{14}    = 3.34289716182018;
    $self->{'ICKey'}->{'1000088010000880'}->{15}    = 3.69277248068433;
    $self->{'ICKey'}->{'1000088010000880'}->{16}    = 3.87942133769244;
    $self->{'ICKey'}->{'1000088010000880'}->{17}    = 3.90061903207543;
    $self->{'ICKey'}->{'1000088010000880'}->{18}    = 3.77875734283571;
    $self->{'ICKey'}->{'1000088010000880'}->{19}    = 3.55364471589659;

    # Define type ID and hormone ID
    $self->{'type'}->{1} = "Oral";
    $self->{'type'}->{2} = "IV";
    $self->{'type'}->{3} = "Infusion";

    $self->{'type'}->{'Oral'}     = 1;
    $self->{'type'}->{'IV'}       = 2;
    $self->{'type'}->{'Infusion'} = 3;

    $self->{'hormone'}->{3} = "T3";
    $self->{'hormone'}->{4} = "T4";

    $self->{'hormone'}->{'T3'} = 3;
    $self->{'hormone'}->{'T4'} = 4;

    # Default dial values
    $self->{'dials'}->{1} = 100; # T4 Secretion
    $self->{'dials'}->{2} = 88;  # T4 Absorption
    $self->{'dials'}->{3} = 100; # T3 Secretion
    $self->{'dials'}->{4} = 88;  # T3 Absorption

    # Default simulation time (days)
    $self->{'simTime'} = 5;

    # Conversion factor of T3, T4, and TSH from mcg/dL to mols
    $self->{'CF'}->{'3'}   = 651/3;
    $self->{'CF'}->{'4'}   = 777/30;
    $self->{'CF'}->{'T3'}  = 651/3;
    $self->{'CF'}->{'T4'}  = 777/30;
    $self->{'CF'}->{'TSH'} = 5.6/3.5;

    # Molecular weight of T3&T4. Used as conversion factor from mcg to mols
    $self->{'toMols'}->{'3'}  = 651;
    $self->{'toMols'}->{'4'}  = 777;
    $self->{'toMols'}->{'T3'} = 651;
    $self->{'toMols'}->{'T4'} = 777;

    # 0th integration is always 0-1008 hours and uses q0
    # This part isn't currently used b/c 0th integration is defined in
    # getplot.cgi.
    $self->{'integration'}->{1}->{'start'} = 0;
    $self->{'integration'}->{1}->{'end'}   = 1008;
    $self->{'integration'}->{1}->{'IC'}    = 'q0';

    bless $self, $class;

    # Load parameter list. Currently doesn't do anything.
    $self->loadParams();

    # Build $self->{IC}->{q0}. Only needed when recalculating IC.
    $self->setInitialIC();

    return $self;
}

#====================================================================
# SUBROUTINE:   processInputs
# DESCRIPTION:
#   Loop through all simulation conditions and organize them:
#     Total simulation time:
#       $self->{simTime}        = $number
#     Recalculate initial conditions:
#       $self->{recalcIC}       = $number (1 for yes)
#     Dials (secretion/absorption):
#       $self->{dials}->{$dial} = $number
#     Simulation conditions (each input has some of the below):
#       $self->{inputs}->{$num}->{dose}       = $number
#       $self->{inputs}->{$num}->{int}        = $number
#       $self->{inputs}->{$num}->{singledose} = $number
#       $self->{inputs}->{$num}->{start}      = $number
#       $self->{inputs}->{$num}->{end}        = $number
#       $self->{inputs}->{$num}->{disabled}   = $number
#       $self->{inputs}->{$num}->{hormone}    = $number
#       $self->{inputs}->{$num}->{type}       = $number
# NOTE: $num is the $num-th input
#====================================================================
sub processInputs {
    my ($self,$inputs) = @_;

    my $simCond;

    # Breakup the input string and save to $simCond
    my @inputs = split(/&/,$$inputs); # $inputs is a ref. Deref.
    foreach my $pair (@inputs) {
        my ($name,$value) = split(/=/,$pair);
        $simCond->{$name} = $value;
    }

    # Save the inputs
    foreach my $name (keys %$simCond) {

        # Total simulation time
        if ($name =~ m/simtime/) {
            $self->setLvl1('simTime',$simCond->{$name});
        # Recalculate IC
        } elsif ($name =~ m/recalcIC/) {
            $self->setLvl1('recalcIC',$simCond->{$name});
        # Dials
        } elsif ($name =~ m/dialinput(\d)/) {
            $self->{'dials'}->{$1} = $simCond->{$name};
        # Rest of the inputs
        } else {
            my ($inputName,$num) = split(/-/,$name);
            $self->setLvl3('inputs',$num,$inputName,$simCond->{$name});
        }
    }

    # Determine intergration steps
    $self->detIntSteps();
}

#====================================================================
# SUBROUTINE:   processResults
# DESCRIPTION:
#   Processes Octave results 1 compartment at a time. For each comp:
#     - Saves comp name
#     - Saves all result values for comps set to show
#     - Saves total number of results
#     - Saves max/min values
#     - Saves the end value as the initial condition for next run
#   After all comp results are processed, make adjustments to IC based on
#   inputs.
#====================================================================
sub processResults {
    my ($self,$results,$iter) = @_;

    # Get results from current simulation
    while (my $compData = $self->getCompData($results)) {

        my $comp = $compData->{'name'};

        # For hormones set toShow, saves hormone name and all result values.
        # Compare current and previous max/min & count. Update as necessary.
        # Results from 0th iteration is not saved because it is not shown to
        # users.
        $self->addTHData($comp,$compData)
            if (($self->getLvl2('toShow',$comp)) && ($iter ne "q0"));

        # Save the end values of $iter as the next IC
        $self->setEVasIC($compData,$iter);
    }

    # Make adjustment to IC based on inputs
    $self->setAdjustedIC($iter);
}

#====================================================================
# SUBROUTINE:   processKeyVal
# DESCRIPTION:
#   A pseudo-processResults.
#   1. One of the main functions of processResults is to set end values of the
#   Octave result as the IC for the next iteration. Here, IC is set from a
#   pre-calculated value.
#   2. After all ICs are set from pre-calculated values, make adjustments to IC
#   based on inputs.
#====================================================================
sub processKeyVal {
    my ($self,$icKey,$iter) = @_;

    my $keyRef = $self->getLvl2('ICKey',$icKey);
    $iter =~ s/q//;             # ie. q0 => 0
    my $nextIter = $iter + 1;   # ie.  0 => 1
    # Loop through all compartments as defined by $icKey
    foreach my $comp (sort {$a <=> $b} keys %$keyRef) {
        $self->{'IC'}->{'q'.$nextIter}->{$comp} = $keyRef->{$comp};
    }
    $self->setAdjustedIC('q'.$iter);
}

#====================================================================
# SUBROUTINE:   detIntSteps
# DESCRIPTION:
#   Determine integration steps. Everytime an input is given, integration must
#   be stopped, initial conditions updated to reflect the input, and
#   re-submitted to Octave.
#   For example, if an oral dose is given at times 0 and 2 days, Octave needs to
#   be called for the following time intervals:
#   1. A time interval so the system reaches steady state. This is the 0th
#   integration and should already be done by this point.
#   2. [0 48] hours for the 1st input between times 0 and 2 days
#   3. [0 simtim-48] for the 2nd input between times 2 and end of simulation
#
#   In case of infusion, integration must also restart at end times.
#
#   First, keeps track that at a certain time, what inputs are relevant and
#   whether the time is a start time or end time:
#     $self->{inputTime}->{$time}->{$input_num} = start or end
#   NOTE: $time can be either $starttime or $endtime. This hash table will be
#   looked at by setAdjustedIC subroutine to adjust initial conditions. In
#   general, $endtime will only be noted if it is the end of an infusion.
#
#   Second, the above is looped through to determine integration steps.
#   Integration steps is organized as follows:
#     $self->{thisStep}->{$iter}->[0] = $starttime
#     $self->{thisStep}->{$iter}->[1] = $endtime
#   NOTE: $iter is the nth iteration, ie. '1', '2', etc and will correspond with
#   initial condition 'q1', 'q2', etc.
#   NOTE2: $iter is the time of introduction of an input, so therefore should
#   always be a "start" time. If an input is given at simulation start, it would
#   be the 1st integration. If an input is given at some time after simulation
#   start, it would be >= 2nd integration, since the 1st integration, in this
#   case, would be the time between simulation start and when the 1st input is
#   given.
#====================================================================
sub detIntSteps {
    my ($self) = @_;

    my $simtime = $self->getLvl1('simTime');

    # Loop through all inputs to find start/end times
    my $inputs = $self->{'inputs'}; # Save typing

    # No inputs? Run simulation from 0 to simtime
    if (!$inputs) {
        $self->setIntStart('thisStep',1,0);
        $self->setIntStart('trueStep',1,0);
        $self->setIntBound('thisStep',1,$simtime);
        $self->setIntBound('trueStep',1,$simtime);
        return 1;
    }

    # Initialize inputTime 0. If there is an input at t=0, this initialization
    # will not do anything. If there isn't one, this serves as a placeholder
    # for determining intergration intervals.
    $self->{'inputTime'}->{0}->{0} = "start";

    foreach my $inputNum (keys %$inputs) {
        my $thisInput = $inputs->{$inputNum}; # Save typing
        my $type  = $self->getLvl3('inputs',$inputNum,'type');
        my $start = $self->getLvl3('inputs',$inputNum,'start');
        my $end   = $self->getLvl3('inputs',$inputNum,'end');
        my $int   = $self->getLvl3('inputs',$inputNum,'int');

        # Oral
        if ($type == 1) {
            if ($self->getLvl3('inputs',$inputNum,'singledose')) {
                $self->{'inputTime'}->{$start}->{$inputNum} = "start";

            # Not singledose? Create input based on once every X interval
            } else {
                my $thisStart = $start;
                while ($thisStart <= $end) {
                    $self->{'inputTime'}->{$thisStart}->{$inputNum} = "start";
                    $thisStart+=$int;
                }
            }
        }

        # IV Pulse
        if ($type == 2) {
            $self->{'inputTime'}->{$start}->{$inputNum} = "start";
        }

        # Infusion
        if ($type == 3) {
            $self->{'inputTime'}->{$start}->{$inputNum} = "start";
            $self->{'inputTime'}->{$end}->{$inputNum}   = "end";

            # Figure/set infusion quantity
            my $duration = $end - $start;
            my $hours    = $self->toHour($duration);
            my $mcg      = $self->getLvl3('inputs',$inputNum,'dose');
            my $hormone  = $self->getLvl3('inputs',$inputNum,'hormone');
            my $toMols   = $self->getLvl2('toMols',$hormone);

            my $infValue = $mcg / $toMols / 24; # Dose is per day

            # T3
            if ($hormone == 3) {
                $self->setLvl3('infusion',$inputNum,'u4',$infValue);
            }

            # T4
            if ($hormone == 4) {
                $self->setLvl3('infusion',$inputNum,'u1',$infValue);
            }
        }
    }

    # After building all relevant times, determine integration intervals
    my ($count,$prior,$reqToSimTime) = (0,0,1);
    foreach my $time (sort {$a <=> $b} keys %{$self->{'inputTime'}}) {

        if ($count > 0) {
            # Integration always start at t = 0
            $self->setIntStart('thisStep',$count,0);
            $self->setIntStart('trueStep',$count,$prior);

            # Determine integration end time
            # Check total simulation against current time. Cut integration
            # interval short if necessary.
            if ($time >= $simtime) {
                $time = $simtime;
                $reqToSimTime = 0;
            }

            $time = $time > $simtime ? $simtime : $time;
            my $intEnd = $time - $prior;
            $self->setIntBound('thisStep',$count,$intEnd);
            $self->setIntBound('trueStep',$count,$time);
        }

        # Update variables for determining next interval
        $prior = $time;
        $count++;
        last if !$reqToSimTime; # Skip all other inputs if $simtime is reached.
    }

    # Determine last interval here. Should be $time to $simtime
    if ($reqToSimTime) {
        my $intEnd = $simtime - $prior;
        $self->setIntStart('thisStep',$count,0);
        $self->setIntStart('trueStep',$count,$prior);

        $self->setIntBound('thisStep',$count,$intEnd);
        $self->setIntBound('trueStep',$count,$simtime);
    }
}

#====================================================================
# SUBROUTINE:   loadParams
# DESCRIPTION:
#   Loads a list of adult/child parameters based on "adultChild".
#   TODO:
# NOTE: Currently does nothing.
#====================================================================
sub loadParams {
    my ($self) = @_;
}

#====================================================================
# SUBROUTINE:   addTHData
# DESCRIPTION:
#   Saves the comp name and array of values in the following fashion:
#   $self->{data}->{$comp}->{values} = $array;
#   $self->{data}->{$comp}->{count}  = $number;
#   Note: $array is an array ref.
#   Note2: $compData is a hash ref containing the above elements.
#====================================================================
sub addTHData {
    my ($self,$comp,$compData) = @_;

    # Push new values to the end of the old values array, but time t needs to
    # be adjusted, ie: 0 1 2 3 0 1 2 3 => 0 1 2 3 4 5 6 7
    if ($comp eq "t") {
        my $lastT = $self->{'data'}->{$comp}->{'values'}->[-1];
        foreach my $time (@{$compData->{'values'}}) {
            my $thisT = $lastT + $time;
            push(@{$self->{'data'}->{$comp}->{'values'}},$thisT);
        }
    } else {
        push(@{$self->{'data'}->{$comp}->{'values'}},
             @{$compData->{'values'}});
    }

    # Update count
    $self->{'data'}->{$comp}->{'count'} += $compData->{'count'};
}

#====================================================================
# SUBROUTINE:   setEVasIC
# DESCRIPTION:
#   Save the end values of $iter as the next IC.
#====================================================================
sub setEVasIC {
    my ($self,$compData,$iter) = @_;

    $iter =~ s/q//;             # ie. q0 => 0
    my $nextIter = $iter + 1;   # ie.  0 => 1
    my $comp = $compData->{'name'};
    $comp =~ s/q//;
    return 1 if $comp eq "t";

    # Copy end values from $iter over
    $self->{'IC'}->{'q'.$nextIter}->{$comp} = $compData->{'end'}->{$comp};
}

#====================================================================
# SUBROUTINE:   setInitialIC
# DESCRIPTION:
#   Take values from the default ICKEY and put it into the object that keeps
#   initial conditions, for q0.
#====================================================================
sub setInitialIC {
    my ($self) = @_;

    my $defaultKey = $self->getICKey('default');
    my $keyRef = $self->getLvl2('ICKey',$defaultKey);
    # Loop through all compartments
    foreach my $comp (sort {$a <=> $b} keys %$keyRef) {
        $self->{'IC'}->{'q0'}->{$comp} = $keyRef->{$comp};
    }
}

#====================================================================
# SUBROUTINE:   setAdjustedIC
# DESCRIPTION:
#   Adjust IC with input quantity as appropriate.
#====================================================================
sub setAdjustedIC {
    my ($self,$iter) = @_;

    $iter =~ s/q//;             # ie. q0 => 0
    my $nextIter = $iter + 1;   # ie.  0 => 1

    # Find all inputs given at $trueStart
    my $trueStart = $self->getIntStart('trueStep',$nextIter);

    foreach my $inputNum (keys %{$self->{'inputTime'}->{$trueStart}}) {

        # Get hormone's info
        my $hormone = $self->getLvl3('inputs',$inputNum,'hormone');
        my $type    = $self->getLvl3('inputs',$inputNum,'type');
        my $dose    = $self->getLvl3('inputs',$inputNum,'dose');

        # Get the conversion factor
        my $toMols = $self->getLvl2('toMols',$hormone);

        # Initialize newIC variables
        my $newIC = 0;

        # T3 input
        if ($hormone == 3) {

            # Update T3 oral compartment
            if ($type == 1) {
                $newIC = $self->getLvl3('IC','q'.$nextIter,12) + $dose/$toMols;
                $self->setLvl3('IC','q'.$nextIter,12,$newIC);
            }

            # Update T3 IV compartment
            if ($type == 2) {
                $newIC = $self->getLvl3('IC','q'.$nextIter,4) + $dose/$toMols;
                $self->setLvl3('IC','q'.$nextIter,4,$newIC);
            }
        }

        # T4 input
        if ($hormone == 4) {

            # Update T4 oral compartment
            if ($type == 1) {
                $newIC = $self->getLvl3('IC','q'.$nextIter,10) + $dose/$toMols;
                $self->setLvl3('IC','q'.$nextIter,10,$newIC);
            }

            # Update T4 IV compartment
            if ($type == 2) {
                $newIC = $self->getLvl3('IC','q'.$nextIter,1) + $dose/$toMols;
                $self->setLvl3('IC','q'.$nextIter,1,$newIC);
            }
        }
    }
}
# Note to self:
# type: 1: oral; 2: IV; 3: Infusion
# hormone: 3: T3; 4: T4

#====================================================================
# SUBROUTINE:   postProcess
# DESCRIPTION:
#   The front end needs the simTime, data, count, max, and min values to
#   display the graphs. Create a new object with just these items.
#   1. Loop through all data values
#     a. Convert from mols to display units
#     b. Determine max value (min value is always 0)
#   2. Copy count to new obj
#   3. TODO - It is here that we can apply resolution rules, to decrease
#      the number of points if needed.
#====================================================================
sub postProcess {
    my ($self) = @_;
    my $retObj;

    # Copy simTime over
    $retObj->{'simTime'} = $self->getLvl1('simTime');

    # For now, save conv factors here:
    my $convObj;
    my $p47 = 3.2;
    my $p48 = 5.2;
    $convObj->{'q1'} = 777/$p47; # T4
    $convObj->{'q4'} = 651/$p47; # T3
    $convObj->{'q7'} = 5.6/$p48; # TSH

    # TEST
#--------------------------------------------------
#     $convObj->{'q5'} = 100;
#     $convObj->{'q6'} = 100;
#-------------------------------------------------- 

    # Loop through all data
    foreach my $comp (keys %{$self->{'data'}}) {
        # Copy all of time over
        if ($comp eq "t") {
            $retObj->{'data'}->{$comp} = $self->{'data'}->{$comp};
            next;
        }

        # Copy count over
        $retObj->{'data'}->{$comp}->{'count'}
            = $self->getLvl3('data',$comp,'count');

        # Set min and max to 0
        $retObj->{'data'}->{$comp}->{'min'} = 0;
        $retObj->{'data'}->{$comp}->{'max'} = 0;

        # Loop through all values and apply conversion factor
        my $conv = $convObj->{$comp};
        $conv = 1 if !$conv;
        foreach my $val (@{$self->{'data'}->{$comp}->{'values'}}) {
            my $newVal = sprintf("%.4f",$val * $conv); # 4 decimal places
            $newVal = 0 if $newVal < 0;

            # Check for new max
            if ($newVal > $retObj->{'data'}->{$comp}->{'max'}) {
                $retObj->{'data'}->{$comp}->{'max'} = $newVal;
            }

            # Push new val to new array
            push(@{$retObj->{'data'}->{$comp}->{'values'}},$newVal);
        }
    }

    return $retObj;
}

#====================================================================
# SUBROUTINE:   setLvl1
# DESCRIPTION:
#   Save a value 1 level after $self.
# USES:
#   toShow: selects which outputs to send to the browser.
#     $self->{toShow} = $value
#     NOTE: $value is a hashRef with hormone name key and boolean value.
#   simTime: total simulation time
#     $self->{simTime} = $value
#====================================================================
sub setLvl1 {
    $_[0]->{$_[1]} = $_[2];
}

#====================================================================
# SUBROUTINE:   setLvl3
# DESCRIPTION:
#   Save a value 3 levels after $self.
# USES:
#   inputs: saves $value of input parameter $name given $inputNum
#     $self->{inputs}->{$inputNum}->{$name} = $value
#====================================================================
sub setLvl3 {
    $_[0]->{$_[1]}->{$_[2]}->{$_[3]} = $_[4];
}

#====================================================================
# SUBROUTINE:   setIntStart
# DESCRIPTION:
#   Set the start time.
# USES:
#   thisStep: refers to 'this' interval's start time.
#     $self->{thisStep}->{$count}->[0] = $value
#   trueStep: refers to 'true' interval's start time.
#     $self->{trueStep}->{$count}->[0] = $value
# NOTE: $count is an integer that correponds with nth integration.
#====================================================================
sub setIntStart {
    $_[0]->{$_[1]}->{$_[2]}->[0] = $_[3];
}

#====================================================================
# SUBROUTINE:   setIntBound
# DESCRIPTION:
#   Set the end time (bound).
# USES:
#   thisStep: refers to 'this' interval's end time.
#     $self->{thisStep}->{$count}->[1] = $value
#   trueStep: refers to 'true' interval's end time.
#     $self->{trueStep}->{$count}->[1] = $value
# NOTE: $count is an integer that correponds with nth integration.
#====================================================================
sub setIntBound {
    $_[0]->{$_[1]}->{$_[2]}->[1] = $_[3];
}

#====================================================================
# SUBROUTINE:   getCompData
# DESCRIPTION:
#   Returns results 1 compartment at a time. Makes use the knowledge that
#   compartment results end at END_.*_END.
#   Note: Must return an obj, otherwise the parent sub never end.
#   Note: Uses shift, so @results gets reduced and no extra data is kept in
#         memory.
#====================================================================
sub getCompData {
    my ($self, $results) = @_;
    my ($compData, $comp, @values);

    while(@{$results}) {
        my $ele = shift(@{$results}); # Get element
        $ele =~ s/[\r\n]*$//; # Remove newline

        # Start line. Use it to get the comp name
        if ($ele =~ m/^START_(.*)_START$/) {
            $comp = $1;
            next;
        }

        # End line. Return the object
        if ($ele =~ m/^END_${comp}_END$/) {
            $compData->{'name'}   = $comp; # name is saved as ie, 'q1'
            $compData->{'values'} = \@values;
            $compData->{'count'}  = $#values + 1;   

            # Save last value in @values as 'end' value
            $comp =~ s/q//; # ie. q1 => 1
            $compData->{'end'}->{$comp} = $values[-1];

            return $compData;
        }

        push(@values,$ele);
    }

    return undef;
}

#====================================================================
# SUBROUTINE:   getCompNames
# DESCRIPTION:
#   Returns an array ref of hormone names. Builds the array ref the first
#   time called.
#====================================================================
sub getCompNames {
    my ($self) = @_;
    if (!$self->{'THNames'}) {
        foreach my $comp (keys %{$self->{'data'}}) {
            push(@{$self->{'THNames'}},$comp);
        }
    }
    return $self->{'THNames'};
}

#====================================================================
# SUBROUTINE:   getIntCount
# DESCRIPTION:
#   returns an arrayRef of $count
# NOTE: $count is an integer that corresponds with nth integration
#====================================================================
sub getIntCount {
    my ($self) = @_;
    my @counts;

    foreach my $count (sort {$a <=> $b} keys %{$self->{'thisStep'}}) {
        push(@counts,$count);
    }

    return \@counts;
}

#====================================================================
# SUBROUTINE:   getICKey
# DESCRIPTION:
#   Retrieve the initial condition 'key' which is just all the dial values in
#   sequence. For default dial values, the key would be '1000088010000880'.
#====================================================================
sub getICKey {
    my ($self,$default) = @_;

    # If user selected to not recalculate IC, return default icKey
    if ($default || !$self->recalcIC()) {
        return "1000088010000880";
    }

    # Get the dial values
    return sprintf("%04d",$self->getLvl2('dials',1) * 10)
         . sprintf("%04d",$self->getLvl2('dials',2) * 10)
         . sprintf("%04d",$self->getLvl2('dials',3) * 10)
         . sprintf("%04d",$self->getLvl2('dials',4) * 10);
}

#====================================================================
# SUBROUTINE:   getICString
# DESCRIPTION:
#   Turn initial conditions into a string that can be passed to Octave
#====================================================================
sub getICString {
    my ($self, $IC) = @_;

    my $returnString = "";

    foreach my $key (sort { $a <=> $b } keys %{$self->{'IC'}->{$IC}}) {
        $returnString .= $self->{'IC'}->{$IC}->{$key}." ";
    }

    return $returnString;
}

#====================================================================
# SUBROUTINE:   getDialString
# DESCRIPTION:
#   Get approximate secretion/absorption multipliers. These values are
#   calculated here so that the Octave file is only used for integrations.
#   $dial1 = T4 secretion multiplier
#     Multiplies the 'SR4' equation as a 0-1 value. Default is 1.
#   $dial2 = T4 absorption multiplier
#     Multiplies the 'k4excrete' parameter to make the following true:
#       k4absorb/(k4absorb+k4excrete) = absorb%
#       absorb% is between 0-2 and default is 0.88
#   $dial3 = T3 secretion multiplier
#     Multiplies the 'SR3' equation as a 0-1 value. Default is 1.
#   $dial4 = T3 absorption multiplier
#     Multiplies the 'k3excrete' parameter to make the following true:
#       k3absorb/(k3absorb+k3excrete) = absorb%
#       absorb% is between 0-2 and default is 0.88
# NOTE: $dialx here corresponds to varaible name in Octave file
#====================================================================
sub getDialString {
    my ($self) = @_;

    # Dial values are saved as percentages. Convert to decimal.
    my $dial1 = $self->getLvl2('dials',1) / 100;
    my $dial2 = $self->getLvl2('dials',2) / 100;
    my $dial3 = $self->getLvl2('dials',3) / 100;
    my $dial4 = $self->getLvl2('dials',4) / 100;

    # Calculate absorption multipliers
    my $T4absorb;
    my $T3absorb;

    if ($dial2 == 0) {
        $T4absorb = 0;
    } else {
        $T4absorb = ((0.88*(1-$dial2))/$dial2)/0.12;
    }

    if ($dial4 == 0) {
        $T3absorb = 0;
    } else {
        $T3absorb = ((0.88*(1-$dial4))/$dial4)/0.12;
    }

    return "$dial1 $T4absorb $dial3 $T3absorb";
}

#====================================================================
# SUBROUTINE:   getInfValue
# DESCRIPTION:
#   Get infusion (u1 and u4) values.
#   1. Loop through all infusion inputs
#   2. See which one(s) fall between $trueStart
#   3. Sum infusion values for the respective hormone
# NOTE: $iter is 'q1', 'q2', etc.
# NOTE2: u1 is T4; u4 is T3
#====================================================================
sub getInfValue {
    my ($self,$iter) = @_;

    $iter =~ s/q//;             # ie. q0 => 0
    my $trueStart = $self->getIntStart('trueStep',$iter);

    my ($u1,$u4) = (0,0); # Initialize u1 and u4

    # Loop through all inputs
    my $inputs = $self->{'inputs'}; # Save typing
    foreach my $inputNum (keys %$inputs) {

        # Skip non-infusion inputs
        next if ($self->getLvl3('inputs',$inputNum,'type') != 3);

        my $start = $self->getLvl3('inputs',$inputNum,'start');
        my $end   = $self->getLvl3('inputs',$inputNum,'end');

        # Sum infusion dose only if $trueStart is within the infusion interval
        if ($trueStart >= $start && $trueStart < $end) {
            $u1 += $self->getLvl3('infusion',$inputNum,'u1');
            $u4 += $self->getLvl3('infusion',$inputNum,'u4');
        }
    }

    return "$u1 $u4";
}

#====================================================================
# SUBROUTINE:   getLvl1
# DESCRIPTION:
#   Retrieve a value 1 level after $self
# USES:
#   simTime: total simulation time
#     $self->{simTime} = $value
#====================================================================
sub getLvl1 {
    return $_[0]->{$_[1]};
}

#====================================================================
# SUBROUTINE:   getLvl2
# DESCRIPTION:
#   Retrieve a value 2 levels after $self
# USES:
#   toShow: checks whether $hormone ist to be sent to the browser.
#     $self->{toShow}->{$hormone} = $value
#   dials:
#     $self->{dials}->{$dialNum} = $value
#   toMols:
#     $self->{toMols}->{$hormone} = $value
#====================================================================
sub getLvl2 {
    return $_[0]->{$_[1]}->{$_[2]};
}

#====================================================================
# SUBROUTINE:   getLvl3
# DESCRIPTION:
#   Retrieve a value 3 levels after $self
# USES:
#   data-$name-values: returns an arrayRef of all values for a hormone $name.
#     $self->{data}->{$name}->{values} = $arrayRef
#   inputs: returns $value of an input parameter $name given $inputNum
#     $self->{inputs}->{$inputNum}->{$name} = $value
#   infusion: returns infusion $value for u1 or u4
#     $self->{infusion}->{$inputNum}->{$uX} = $value
#====================================================================
sub getLvl3 {
    return $_[0]->{$_[1]}->{$_[2]}->{$_[3]};
}

#====================================================================
# SUBROUTINE:   getIntStart
# DESCRIPTION:
#   Get the start time.
# USES:
#   thisStep: refers to 'this' interval's start time.
#     $self->{thisStep}->{$count}->[0] = $value
#   trueStep: refers to 'true' interval's start time
#     $self->{trueStep}->{$count}->[0] = $value
# NOTE: $count is an integer that corresponds with nth integration
#====================================================================
sub getIntStart {
    return $_[0]->{$_[1]}->{$_[2]}->[0];
}

#====================================================================
# SUBROUTINE:   getIntBound
# DESCRIPTION:
#   Get the end time (bound).
# USES:
#   thisStep: refers to 'this' interval's end time.
#     $self->{thisStep}->{$count}->[1] = $value
#   trueStep: refers to 'true' interval's end time
#     $self->{trueStep}->{$count}->[1] = $value
# NOTE: $count is an integer that corresponds with nth integration
#====================================================================
sub getIntBound {
    return $_[0]->{$_[1]}->{$_[2]}->[1];
}

#====================================================================
# SUBROUTINE:   toHour
# DESCRIPTION:
#   Multiply a number by 24
#====================================================================
sub toHour {
    return $_[1]*24;
}

#====================================================================
# SUBROUTINE:   hasICKey
# DESCRIPTION:
#   Checks whether a initial condition key exists
#====================================================================
sub hasICKey {
    my ($self,$icKey) = @_;
    return $self->{'ICKey'}->{$icKey} ? 1 : 0;
}

#====================================================================
# SUBROUTINE:   recalcIC
# DESCRIPTION:
#   Checks whether to recalculate initial conditions
#====================================================================
sub recalcIC {
    my ($self) = @_;
    return $self->{'recalcIC'} ? 1 : 0;
}

#====================================================================
# SUBROUTINE:
# DESCRIPTION:
#====================================================================
sub genericFunction {
}







1;