#!/usr/bin/perl
use v5.10; use strict; use warnings;
#==============================================================================
# FILE:         THYROWEB.pm
# AUTHOR:       Simon X. Han
# DESCRIPTION:
#   Helper package for generating dynamic Thyrosim websites.
#==============================================================================

package THYROWEB;

use CGI qw/:standard/;
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

#====================================================================
# SUBROUTINE:   new
# DESCRIPTION:
#   Returns an object of THYROSIM.
#====================================================================
sub new {
    my ($class,%params) = @_;
    my $self = {};

    $self->{ts} = $params{THYROSIM};
    $self->{showParams} = $params{showParams} // 0;

    bless $self, $class;

    #--------------------------------------------------
    # Post-bless initializations
    #--------------------------------------------------

    $self->initDisplay();
    $self->initExamples();
    $self->initInfoBtns();

    return $self;
}

#====================================================================
# SUBROUTINE:   initDisplay
# DESCRIPTION:
#   Based on thysim, initialize customizations.
#====================================================================
sub initDisplay {
    my ($self) = @_;

    # Thyrosim
    if ($self->{ts}->{thysim} eq "Thyrosim") {
        $self->{thysim}  = "Thyrosim";
        $self->{thysimD} = "THYROSIM";
        $self->{headerstyle} = "";
        $self->{examples} = ['experiment-default','experiment-DiJo19-1'];
    }

    # ThyrosimJr
    if ($self->{ts}->{thysim} eq "ThyrosimJr") {
        $self->{thysim}  = "ThyrosimJr";
        $self->{thysimD} = "THYROSIM Jr";
        $self->{headerstyle} = "background-color: #CCFFE5";
        $self->{examples} = ['experiment-default-jr'];
    }

}

#====================================================================
# SUBROUTINE:   initExamples
# DESCRIPTION:
#   Initialize examples. See insertExample() for example snippet structure.
#====================================================================
sub initExamples {
    my ($self) = @_;

    $self->{experiments}->{'experiment-default'} = {
        name    => 'experiment-default',
        bold    => 'The Euthyroid Example',
        text    => 'uses default thyroid hormone secretion/absorption values
                    without any input doses. Simulated for 5 days.',
        img     => '../img/experiment-default.png',
        alt     => 'Default Example',
    };

    $self->{experiments}->{'experiment-default-jr'} = {
        name    => 'experiment-default-jr',
        bold    => 'The Junior Euthyroid Example',
        text    => 'uses default thyroid hormone secretion/absorption values
                    without any input doses. Simulated for 5 days.',
        img     => '../img/experiment-default.png',
        alt     => 'Default Junior Example',
        # TODO
        # Since Junior parameters are being tuned, we do not have an image for
        # the junior example. So, use the default image for now.
    };

    $self->{experiments}->{'experiment-DiJo19-1'} = {
        name    => 'experiment-DiJo19-1',
        bold    => 'The DiStefano-Jonklaas 2019 Example-1',
        text    => 'reproduces Figure 1 of the DiStefano-Jonklaas 2019 paper.
                    Specifically, the simulated hypothyroidic individual (25%
                    thyroid function) is given 123 &microg
                    T<span class="textsub">4</span> and 6.5 &microg
                    T<span class="textsub">3</span> daily for 30 days.',
        img     => '../img/experiment-DiJo19-1.png',
        alt     => 'DiStefano-Jonklass Example 1',
    };

}

#====================================================================
# SUBROUTINE:   initInfoBtns
# DESCRIPTION:
#   Initialize info boxes. See getInfoBtn() and _getInfoBtn().
#====================================================================
sub initInfoBtns {
    my ($self) = @_;

    $self->{infoBtns}->{About} = {
        key     => 'About',
        val     => 'DIRECTIONS',
        content => <<EOF

<span style="color:red">$self->{thysimD}</span> is a tool for simulating a
well-validated human thyroid hormone (TH) feedback regulation system model*.

Users can simulate common thyroid system maladies by adjusting TH
secretion/absorption rates on the interface.

Oral input regimens, also selectable on the interface, simulate common hormone
treatment options.

Bolus and intravenous infusion inputs also can be added, for exploratory
research and teaching demonstrations.

For easy comparisons, the interface includes facility for superimposing two sets
of simulation results.
<br>
<br>
Minimum Usage:
<ol>
  <li>
    To see normal thyroid hormone behavior: click "RUN".
  </li>
  <li>
    To simulate hypo/hyperthyroidism: change
    T<span class="textsub">3</span>/T<span class="textsub">4</span>
    secretion.
  </li>
  <li>
    To modify oral input absorption: change
    T<span class="textsub">3</span>/T<span class="textsub">4</span>
    absorption.
  </li>
  <li>
    Simulate treatment options:
    <ol>
      <li>
        Click the
        <img class="info-icon" src="../img/pill1.png"
             alt="Oral Input">
        <img class="info-icon" src="../img/pill2.png"
             alt="Oral Input">
        <img class="info-icon" src="../img/syringe1.png"
             alt="IV Input">
        <img class="info-icon" src="../img/syringe2.png"
             alt="IV Input">
        or
        <img class="info-icon" src="../img/infusion1.png"
             alt="Infusion Input">
        <img class="info-icon" src="../img/infusion2.png"
             alt="Infusion Input">
        icons to add as input.
      </li>
      <li>
        Fill in the required dosage, start and end times.
      </li>
    </ol>
  </li>
</ol>
Features:
<ol>
  <li>
    <img class="info-icon" src="../img/x.png" alt="x">
    icon: click to delete an input.
  </li>
  <li>
    <span class="tog-in tog-in-1">ON</span>
    <span class="tog-in tog-in-2">OFF</span>
    icons: click to turn input on or off for the next run.
  </li>
  <li>
    <img class="info-icon" src="../img/plus.png" alt="plus">
    icon: click to modify secretion/absorption via scrollbars.
  </li>
</ol>

EOF
    };

    $self->{infoBtns}->{Example} = {
        key     => 'Example',
        val     => 'EXAMPLES',
        content => $self->insertExamples()
    };

    $self->{infoBtns}->{Disclaimer} = {
        key     => 'Disclaimer',
        val     => 'DISCLAIMER',
        content => <<EOF
<span style="color:red">$self->{thysimD}</span> is intended as an educational
and research tool only.

Information provided is not a substitute for medical advice and you should
contact your doctor regarding any medical conditions or medical questions that
you have.

EOF
    };
}

#====================================================================
# SUBROUTINE:   ga
# DESCRIPTION:
#   Google Analytics code.
#====================================================================
sub ga {
    return <<END
  (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
  (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
  m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
  })(window,document,'script','//www.google-analytics.com/analytics.js','ga');

  ga('create', 'UA-69059862-1', 'auto');
  ga('send', 'pageview');
END
}

#====================================================================
# SUBROUTINE:   getHead
# DESCRIPTION:
#   Get contents for <head></head>.
#====================================================================
sub getHead {
    my ($self) = @_;

    my %head = (

-title => "$self->{thysimD} by UCLA Biocybernetics Lab",
-meta  => {
    'charset'   => 'utf-8',
    'content'   => 'width=device-width, initial-scale=1, shrink-to-fit=no',
    'keywords'  => 'thyrosim thyroid simulator',
    'copyright' => 'Copyright 2013 by UCLA Biocybernetics Laboratory'
},
-head => Link({
    -rel  => 'shortcut icon',
    -href => '../favicon.ico'
}),
-style => {
    'src'           => [
        '../css/ui-lightness/jquery-ui.min.css',
        '../css/thyrosim2.css',
        #'../css/bootstrap.min.css'
    ]
},
-script => [
    {
        # Must be loaded before D3
        -type => 'text/javascript',
        -src  => '../js/checkmsie.js'
    },
    {
        -type => 'text/javascript',
        -src  => '../js/jquery.min.js'
    },
#--------------------------------------------------
#     {
#         -type => 'text/javascript',
#         -src  => '../js/bootstrap.bundle.min.js'
#     },
#-------------------------------------------------- 
    {
        -type => 'text/javascript',
        -src  => '../js/jquery-ui.min.js'
    },
    {
        -type => 'text/javascript',
        -src  => '../js/d3.min.js'
    },
    {
        -type => 'text/javascript',
        -src  => '../js/thyrosim.js'
    },
    {
        -type => 'text/javascript',
        -code => $self->ga()
    },
],
-onload => '',
-ontouchstart => ''

);

return \%head;

}

#====================================================================
# SUBROUTINE:   insertForm
# DESCRIPTION:
#====================================================================
sub insertForm {
    my ($self) = @_;

    my $header = $self->getHeader();
    my $main   = $self->getMain();
    my $footer = "";

    # Things to put into the form
    my $jr_ack   = $self->juniorAcknowledge();

    # Put form together
    return <<END

<!-- Wrapper -->
<div id="wrapper">
<form name="form">

  <!-- Header -->
$header
  <!-- Header end -->

  <!-- Main -->
$main
  <!-- Main end -->

  <!-- Secretion/Absorption (lower div) -->
  <div id="content-lower" class="select-none">
    <div class="textaligncenter">
      <a class="img-input" href="javascript:showhidescrollbars();">
        <img class="textaligntop relative scrollbars" id="showhidescrollbar"
             src="../img/plus.png" alt="show scroll bars" />
      </a>
      Adjust secretion/absorption rates:<br>
      <label for="recalcIC" class="cursor-pointer">
        <input type="checkbox" value="1" id="recalcIC" name="recalcIC" checked>
        Recalculate Initial Conditions
      </label>
      <label title="When this box is checked, initial conditions (IC) are
      recalculated when secretion/absorption values are changed from default
      (100, 88, 100, 88). Uncheck this box to always use euthyroid IC.">
        <img class="info-icon" src="../img/info.svg" />
      </label>
    </div>

    <!-- T4 Secretion -->
    <div class="adjuster" onmouseover="hilite('1');" onmouseout="lolite('1');">
      T<span class="textsub">4</span> Secretion (0-200%):
      <input type="text" size="5" id="dialinput1" name="dialinput1"> %
      <div id="slidercontainer1" class="slidercontainer">
        <div id="slider1"></div>
      </div>
    </div>
    <!-- T4 Secretion end -->

    <!-- T4 Absorption -->
    <div class="adjuster" onmouseover="hilite('2');" onmouseout="lolite('2');">
      T<span class="textsub">4</span> Absorption (0-100%):
      <input type="text" size="5" id="dialinput2" name="dialinput2"> %
      <div id="slidercontainer2" class="slidercontainer">
        <div id="slider2"></div>
      </div>
    </div>
    <!-- T4 Absorption end -->

    <!-- T3 Secretion -->
    <div class="adjuster" onmouseover="hilite('3');" onmouseout="lolite('3');">
      T<span class="textsub">3</span> Secretion (0-200%):
      <input type="text" size="5" id="dialinput3" name="dialinput3"> %
      <div id="slidercontainer3" class="slidercontainer">
        <div id="slider3"></div>
      </div>
    </div>
    <!-- T3 Secretion end -->

    <!-- T3 Absorption -->
    <div class="adjuster" onmouseover="hilite('4');" onmouseout="lolite('4');">
      T<span class="textsub">3</span> Absorption (0-100%):
      <input type="text" size="5" id="dialinput4" name="dialinput4"> %
      <div id="slidercontainer4" class="slidercontainer">
        <div id="slider4"></div>
      </div>
    </div>
    <!-- T3 Absorption end -->

  </div>
  <!-- Secretion/Absorption end -->

  <!-- Input Adjustments (footer) -->
  <div class="footer select-none">

    <div class="textaligncenter">
      Simulation time:
      <input type="text" id="simtime" name="simtime" size="1" value="5">
      Days
      <label title="Simulation time must be <= 100 days.">
        <img class="info-icon" src="../img/info.svg" />
      </label>
      <br>
      Adjust pill quantity and frequency:
    </div>

    <!-- Placeholder for Inputs -->
    <div id="footer-input"></div>
    <br>
    <!-- Placeholder for Inputs end -->

    <!-- Blue/Green Simulation Manager -->
    <div id="compPanel" class="textaligncenter">

      Set next simulation results as Blue or Green

      <label for="compPanel" title="Simulation results are by default
      alternately graphed between Blue and Green lines. However, you may
      override this functionality by manually setting the color of the next run.
      Please note that only 1 line per color is allowed and subsequent runs
      replace any existing lines of that color. Please also note that example
      runs are always graphed as Blue.">
        <img class="info-icon" src="../img/info.svg" />
      </label>

      <br>

      <input type="radio" name="runRadio" id="runRadioBlue" value="Blue" checked>
      <label for="runRadioBlue">Blue</label>

      <input type="radio" name="runRadio" id="runRadioGreen" value="Green">
      <label for="runRadioGreen">Green</label>

      <br>

      <button id="resetBlueRun" type="button" onclick="resetRun('Blue');">
        Delete Blue Run
      </button>
      <button id="resetGreenRun" type="button" onclick="resetRun('Green');">
        Delete Green Run
      </button>

    </div>
    <br>
    <!-- Blue/Green Simulation Manager end -->

    <!-- Last Row of Buttons -->
    <div class="textaligncenter">
      <input type="hidden" name="thysim" id="thysim" value="$self->{thysim}">
    </div>
    <div class="textaligncenter">
      <button type="button" onclick="ajax_getplot();">SIMULATE</button>
      <button type="button" onclick="location.reload();">RESET ALL</button>
    </div>
    <!-- Last Row of Buttons end -->

  </div>
  <!-- Input Adjustments end -->

  <!-- Bottom (footer) -->
  <div class="footer">

    <div class="textaligncenter">
      <b>$self->{thysimD} 2.1</b> &copy; 2013 by
      <a href="http://biocyb0.cs.ucla.edu/wp/"
         target="_blank">UCLA Biocybernetics Laboratory</a><br>
    </div>

    <!-- References -->
    <div class="subdiv">
      <span class="subdivtitle">References*</span>
      <div class="subdivlist">
        <ol>
          <li>
            <a target="_blank"
               href="https://doi.org/10.3389/fendo.2019.00746">
                 DiStefano & Jonklaas 2019
            </a>
          </li>
          <li>
            <a target="_blank"
               href="https://www.liebertpub.com/doi/10.1089/thy.2015.0373">
                 Han et al., 2016
            </a>
          </li>
          <li>
            <a target="_blank"
               href="https://www.liebertpub.com/doi/10.1089/thy.2011.0355">
                 Ben-Shachar et al., 2012
            </a>
          </li>
          <li>
            <a target="_blank"
               href="https://www.liebertpub.com/doi/10.1089/thy.2009.0349">
                 Eisenberg et al., 2010
            </a>
          </li>
          <li>
            <a target="_blank"
               href="https://www.liebertpub.com/doi/10.1089/thy.2008.0148">
                 Eisenberg et al., 2009
            </a>
          </li>
          <li>
            <a target="_blank"
               href="https://www.liebertpub.com/doi/10.1089/thy.2007.0388">
                 Eisenberg et al., 2008
            </a>
          </li>
          <li>
            <a target="_blank"
               href="https://www.liebertpub.com/doi/10.1089/thy.2006.0144">
                 Eisenberg et al., 2006
            </a>
          </li>
        </ol>
      </div>
    </div>
    <!-- References end -->

    <!-- Recent Updates -->
    <div class="subdiv">
      <span class="subdivtitle">Recent Updates</span>
      <div class="subdivlist">
        <ol>
          <li>
            December 2019: Added parameter editor (Toggle: Parameters)
          </li>
          <li>
            January 2019: Added
            Free T<span class="textsub">4</span> and
            Free T<span class="textsub">3</span> alternatives to Total
            T<span class="textsub">4</span> and
            T<span class="textsub">3</span>
            (Toggle: Free Hormone Values)
          </li>
        </ol>
      </div>
    </div>
    <!-- Recent Updates end -->

    <!-- People and Acknowledgement -->
    <div class="subdiv">
      <span class="subdivtitle">People & Acknowledgement</span>
      <div class="subdivlist">
        <ol>
          <li>
            JJ DiStefano III, Director
          </li>
          <li>
            Web App Design and Implementation by Simon X. Han
          </li>
          <li>
            Modeling and Analysis by Marisa Eisenberg, Rotem Ben-Shachar & the
            DiStefano Lab Team
          </li>
          $jr_ack
        </ol>
      </div>
    </div>
    <!-- People and Acknowledgement end -->

  </div>
  <!-- Bottom end -->

  <!-- Bottom 2 (footer) -->
  <div class="footer">
    <div class="textaligncenter">
      Please send comments, bugs, criticisms to:
      <a href="mailto:joed\@ucla.edu">joed\@ucla.edu</a>
      <a href="mailto:joed\@ucla.edu">
        <span class="ui-icon ui-icon-mail-closed"></span>
      </a>
      <br>
      Code repository:
      <a href="https://bitbucket.org/DistefanoLab/thyrosim/overview"
         target="_blank">click here</a>
    </div>
  </div>
  <!-- Bottom 2 end -->

  <!-- Follows the cursor while simulator is running -->
  <div id="follow1" class="follow">
    <img class="followimg" src="../img/loading.gif" />
    Please wait while your experiment<br>
    is running.
  </div>
  <div id="follow2" class="follow">
    <img class="followimg" src="../img/loading.gif" />
    Please wait ~30 secs to establish new<br>
    initial conditions for your experiment.
  </div>
  <!-- Follow end -->

</form>
</div>
<!-- Wrapper end -->

END
}

#====================================================================
# SUBROUTINE:   getHeader
# DESCRIPTION:
#   Semantic element: Header.
#====================================================================
sub getHeader {
    my ($self) = @_;

    # Generate info buttons
    my $infoBtn_About = $self->getInfoBtn('About');
    my $infoBtn_Examp = $self->getInfoBtn('Example');
    my $infoBtn_Discl = $self->getInfoBtn('Disclaimer');

    return <<EOF
<header style="$self->{headerstyle}" class="select-none">

  <!-- Logos and Info -->
  <div id="ucla" class="floatL">
    <span>UCLA</span>
  </div>
$infoBtn_About
$infoBtn_Examp
$infoBtn_Discl
  <div id="biocyb" class="floatR">
    <span>Biocybernetics Laboratory</span>
  </div>
  <!-- Logos and Info end -->

  <div class="bar-h-gold floatL"></div>

  <!-- Not-for-IE Warning -->
  <div id="non-ie-warn" class="hide floatL non-ie-warn">
    It appears that you are using Internet Explorer (IE). If you are using IE,
    please use version 9 or above. Otherwise, to see the web-app as intended,
    please use a free and supported browser, such as
    <a target="_blank" href="https://www.google.com/chrome/">
      Google Chrome</a> or
    <a target="_blank" href="https://www.mozilla.org/en-US/firefox/new/">
      Mozilla Firefox</a>.
  </div>
  <script>
  checkMSIE(); // D3 only supports IE9+
  </script>
  <!-- Not-for-IE Warning end -->

</header>
EOF
}

#====================================================================
# SUBROUTINE:   getMain
# DESCRIPTION:
#   Semantic element: Header.
#====================================================================
sub getMain {
    my ($self) = @_;

    # Parameter list only for advanced
    my $paramEditor = "";
    if ($self->{showParams}) {
        my $paramList = $self->printParams();
        $paramEditor = <<EOF
Toggle:
<button class="btn btn-toggle" type="button" 
        onclick="toggle('parameters',200);">
  Parameters
</button>
<div id="parameters">$paramList</div>
EOF
;

    }
    return <<EOF
<main class="select-none">

  <!-- Container (top) -->
  <div class="container floatL width-100">

    <!-- Panel Left -->
    <section class="panel panelL floatL">

      <!-- Sidebar -->
      <div id="sidebar" class="floatL">

        <!-- T3 Inputs Menu -->
        <div id="T3-menu-head" class="T-menu-head">
          <button type="button" onclick="togHormoneMenu('T3-menu');">
            T<span class="textsub">3</span><i class="arrow arrow-u"></i>Inputs
          </button>
        </div>

        <div id="T3-menu" class="T-menu show">
          <button type="button" class="btn-icon btn-icon-t3"
                  onclick="addInput('T3-Oral');">
            <img src="../img/pill1.png">
          </button>
          <button type="button" class="btn-icon btn-icon-t3"
                  onclick="addInput('T3-IV');">
            <img src="../img/syringe1.png">
          </button>
          <button type="button" class="btn-icon btn-icon-t3"
                  onclick="addInput('T3-Infusion');">
            <img src="../img/infusion1.png">
          </button>
        </div>
        <!-- T3 Inputs Menu end -->

        <!-- T4 Inputs Menu -->
        <div id="T4-menu-head" class="T-menu-head">
          <button type="button" onclick="togHormoneMenu('T4-menu');">
            T<span class="textsub">4</span><i class="arrow arrow-u"></i>Inputs
          </button>
        </div>

        <div id="T4-menu" class="T-menu show">
          <button type="button" class="btn-icon btn-icon-t4"
                  onclick="addInput('T4-Oral');">
            <img src="../img/pill2.png">
          </button>
          <button type="button" class="btn-icon btn-icon-t4"
                  onclick="addInput('T4-IV');">
            <img src="../img/syringe2.png">
          </button>
          <button type="button" class="btn-icon btn-icon-t4"
                  onclick="addInput('T4-Infusion');">
            <img src="../img/infusion2.png">
          </button>
        </div>
        <!-- T4 Inputs Menu end -->

      </div>
      <!-- Sidebar end -->

      <!-- Diagram and Parameters -->
      <div id="img-param" class="floatL height-32">
$paramEditor
        <img id="hilite1" src="../img/hilite.png" class="hilite hide">
        <img id="hilite2" src="../img/hilite.png" class="hilite hide">
        <img id="hilite3" src="../img/hilite.png" class="hilite hide">
        <img id="hilite4" src="../img/hilite.png" class="hilite hide">
      </div>
      <!-- Diagram and Parameters end -->

    </section>
    <!-- Panel Left end -->

    <!-- Panel Right -->
    <section class="panel panelR floatL">

      <!-- Graphs -->
      Toggle:
      <button class="btn btn-toggle" type="button" onclick="togFreeHormone();">
        Free Hormone Values
      </button>
      <button class="btn btn-toggle" type="button" id="togNormRange">
        Normal Range
      </button>
      <div id="FT4graph" class="hide d3chart"></div>
      <div id="FT3graph" class="hide d3chart"></div>
      <div id="T4graph"  class="show d3chart"></div>
      <div id="T3graph"  class="show d3chart"></div>
      <div id="TSHgraph" class="show d3chart"></div>
      <!-- Graphs end -->

    </section>
    <!-- Panel Right end -->

  </div>
  <!-- Container (top) end -->

  <!-- Container (mid - secretion/absorption) -->
  <div class="container floatL width-100">

    <div class="">
      <button type="button" class="btn-icon" onclick="togScrollBars();">
        <img id="scrollbar" class="info-icon" 
             src="../img/plus.png" alt="Show scroll bars">
        Adjust secretion/absorption rates:
      </button>
    </div>

  </div>
  <!-- Container (mid - secretion/absorption) end -->

</main>
EOF
}

#====================================================================
# SUBROUTINE:   insertExamples
# DESCRIPTION:
#   Insert examples associated with $thysim.
#====================================================================
sub insertExamples {
    my ($self) = @_;
    my $snp = "";
    foreach my $key (@{$self->{examples}}) {
        $snp .= $self->insertExample($self->{experiments}->{$key});
    }
    return $snp;
}

#====================================================================
# SUBROUTINE:   insertExample
# DESCRIPTION:
#   Insert Example snippet.
#====================================================================
sub insertExample {
    my ($self,$exp) = @_;
    my $snp = <<EOF

<!-- Example $exp->{name} -->
<span class="floatL example">
  <span class="floatL example-wrp">
    <span class="example-txt"><b>$exp->{bold}</b> $exp->{text}</span>
    <button class="btn btn-submit" type="button"
            onclick="ajax_getplot('$exp->{name}');togInfoBtn('Example')">
      Simulate
    </button>
  </span>
  <img src="$exp->{img}" alt="$exp->{alt}" class="example-tbn" />
</span>
<!-- Example $exp->{name} end -->

EOF
;

    return $snp;
}

#====================================================================
# SUBROUTINE:   printParams
# DESCRIPTION:
#   Generate list of parameter inputs. Requires THYROSIM object for its
#   THYROSIM::sortParams().
#====================================================================
sub printParams {
    my ($self) = @_;
    my $snp = "";
    my $tmp = "";
    my $mod = 3; # Want kdelay to be in its own row
    foreach my $p (@{$self->{ts}->sortParams()}) {
        $tmp .= "<div class=\"paramcol\">"
             .  $self->getParamInput($p,$self->{ts}->{params}->{$p})
             .  "</div>";
        if ($mod % 3 == 0) { # 3 per row
            $snp .= "<div class=\"paramrow\">$tmp</div>";
            $tmp = "";
        }
        $mod++;
    }
    return $snp;
}

#====================================================================
# SUBROUTINE:   getParamInput
# DESCRIPTION:
#   Helper function to generate an input for a given parameter.
#====================================================================
sub getParamInput {
    my ($self,$p,$v) = @_;
    return <<EOF
<label>$p:</label>
<input type="text" id="$p" name="$p" value="$v">
EOF
}

#====================================================================
# SUBROUTINE:   juniorAcknowledge
# DESCRIPTION:
#   The bottom portion includes contacts and acknowledgements. Only include
#   Junior credit in the Junior page.
#====================================================================
sub juniorAcknowledge {
    my ($self) = @_;
    if ($self->{thysim} eq "ThyrosimJr") {
        return "<li>"
             . "  Junior Model by Doug Dang, Aaron Hui, Sandy Kim,"
             . "  and Amanda Tsao"
             . "</li>";
    }
    return "";
}

#====================================================================
# SUBROUTINE:   getInfoBtn
# DESCRIPTION:
#   Wrapper for generating info button with content.
#====================================================================
sub getInfoBtn {
    my ($self,$key) = @_;
    my $infoBtn = $self->_getInfoBtn(
        $key,
        $self->{infoBtns}->{$key}->{val},
        $self->{infoBtns}->{$key}->{content}
    );
    return $infoBtn;
}

#====================================================================
# SUBROUTINE:   _getInfoBtn
# DESCRIPTION:
#   Generate info button snp.
#
#   key:        Unique infoBtns key
#   val:        Button's display value
#   content:    Content to be shown when button is clicked
#====================================================================
sub _getInfoBtn {
    my ($self,$key,$val,$content) = @_;

    return <<EOF
<div class="floatL">
  <button id="info-btn-$key" type="button" class="info-btn floatL"
          onclick="togInfoBtn('$key');">$val</button>
  <div id="info-btn-c-$key" class="info-btn-c">
    <button type="button" class="btn-anchor floatR"
            onclick="togInfoBtn('$key');">
      Close
    </button>
    <p>
$content
    </p>
  </div>
</div>
EOF
}

#====================================================================
# SUBROUTINE:
# DESCRIPTION:
#====================================================================
sub genericFunction {
}

1;
