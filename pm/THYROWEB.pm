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
    $self->initHormoneMenu();

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
                    thyroid function) is given 123 &micro;g
                    T<span class="textsub">4</span> and 6.5 &micro;g
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
    To see normal thyroid hormone behavior: click "Simulate".
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
        <img class="info-icon-m" src="../img/pill1.png"
             alt="Oral Input">
        <img class="info-icon-m" src="../img/pill2.png"
             alt="Oral Input">
        <img class="info-icon-m" src="../img/syringe1.png"
             alt="IV Input">
        <img class="info-icon-m" src="../img/syringe2.png"
             alt="IV Input">
        or
        <img class="info-icon-m" src="../img/infusion1.png"
             alt="Infusion Input">
        <img class="info-icon-m" src="../img/infusion2.png"
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
    <img class="info-icon-m" src="../img/x.png" alt="x">
    icon: click to delete an input.
  </li>
  <li>
    <span class="tog-in tog-in-1">ON</span>
    <span class="tog-in tog-in-2">OFF</span>
    icons: click to turn input on or off for the next run.
  </li>
  <li>
    <img class="info-icon-m" src="../img/plus.png"  alt="plus">
    <img class="info-icon-m" src="../img/minus.png" alt="minus">
    icons: click to show or hide scrollbars.
  </li>
  <li>
    <img class="info-icon-m" src="../img/info.svg" alt="info">
    icon: hover mouse over to see additional info.
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
# SUBROUTINE:   initHormoneMenu
# DESCRIPTION:
#   Initialize hormone menu. See getHormoneMenu().
#====================================================================
sub initHormoneMenu {
    my ($self) = @_;

    $self->{hormoneMenu}->{T3} = {
        head_id => 'T3-menu-head',
        menu_id => 'T3-menu',
        button  => 'btn-icon-t3',
        in_or_name => 'T3-Oral',
        in_iv_name => 'T3-IV',
        in_in_name => 'T3-Infusion',
        in_or_src => '../img/pill1.png',
        in_iv_src => '../img/syringe1.png',
        in_in_src => '../img/infusion1.png'
    };

    $self->{hormoneMenu}->{T4} = {
        head_id => 'T4-menu-head',
        menu_id => 'T4-menu',
        button  => 'btn-icon-t4',
        in_or_name => 'T4-Oral',
        in_iv_name => 'T4-IV',
        in_in_name => 'T4-Infusion',
        in_or_src => '../img/pill2.png',
        in_iv_src => '../img/syringe2.png',
        in_in_src => '../img/infusion2.png'
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
    'viewport'  => 'width=device-width, initial-scale=1, shrink-to-fit=no',
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
        '../css/thyrosim.css',
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
    my $footer = $self->getFooter();

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

  <!-- Footer -->
$footer
  <!-- Footer end -->

  <!-- Follow -->
  <div id="follow" class="follow">
    <img class="info-icon-fw floatL" src="../img/spinner.svg">
    <span class="floatL">
      Please wait while your experiment is running.<br>
      This may take up to 30 seconds.
    </span>
  </div>
  <!-- Follow end -->

  <!-- Overlay -->
  <div id="overlay">
    <div>
      <button id="overlay-button" type="button" class="btn-anchor floatR"
              onclick="toggle('overlay',100);">
        Close
      </button>
      <div id="overlay-content"></div>
    </div>
  </div>
  <!-- Overlay end -->

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

    my $menuT3 = $self->getHormoneMenu('T3');
    my $menuT4 = $self->getHormoneMenu('T4');

    # Parameter list only for advanced
    my $paramList = "";
    my $paramTogg = "";
    if ($self->{showParams}) {
        $paramList = $self->printParams();
        $paramTogg = <<EOF
Toggle:
<button class="btn btn-teal" type="button" onclick="toggle('parameters',200);">
  Parameters
</button>
EOF
;
    }
    my $paramEditor = <<EOF
<div class="container button-row">$paramTogg</div>
<div class="container" id="parameters">$paramList</div>
EOF
;

    my $sliderButton = <<EOF
<button type="button" class="btn-icon" onclick="togScrollBars();">
  <img id="scrollbar" class="info-icon-m"
       src="../img/minus.png" alt="Hide scrollbars">
  Secretion/Absorption Rates:
</button>
EOF
;

    my $sliders = <<EOF
<div class="container slider-row"
     onmouseover="toggle('hilite1',1);" onmouseout="toggle('hilite1',1);">
  <div class="grid-2-5">
    T<span class="textsub">4</span> Secretion (0-200%):
  </div>
  <div class="grid-1-5">
    <input type="text" id="dialinput1" name="dialinput1"> %
  </div>
  <div class="grid-2-5">
    <div id="slidercontainer1" class="sliders"><div id="slider1"></div></div>
  </div>
</div>

<div class="container slider-row"
     onmouseover="toggle('hilite2',1);" onmouseout="toggle('hilite2',1);">
  <div class="grid-2-5">
    T<span class="textsub">4</span> Absorption (0-100%):
  </div>
  <div class="grid-1-5">
    <input type="text" id="dialinput2" name="dialinput2"> %
  </div>
  <div class="grid-2-5">
    <div id="slidercontainer2" class="sliders"><div id="slider2"></div></div>
  </div>
</div>

<div class="container slider-row"
     onmouseover="toggle('hilite3',1);" onmouseout="toggle('hilite3',1);">
  <div class="grid-2-5">
    T<span class="textsub">3</span> Secretion (0-200%):
  </div>
  <div class="grid-1-5">
    <input type="text" id="dialinput3" name="dialinput3"> %
  </div>
  <div class="grid-2-5">
    <div id="slidercontainer3" class="sliders"><div id="slider3"></div></div>
  </div>
</div>

<div class="container slider-row"
     onmouseover="toggle('hilite4',1);" onmouseout="toggle('hilite4',1);">
  <div class="grid-2-5">
    T<span class="textsub">3</span> Absorption (0-100%):
  </div>
  <div class="grid-1-5">
    <input type="text" id="dialinput4" name="dialinput4"> %
  </div>
  <div class="grid-2-5">
    <div id="slidercontainer4" class="sliders"><div id="slider4"></div></div>
  </div>
</div>
EOF
;

    my $simtime = <<EOF
Simulation Time:
<input type="text" id="simtime" name="simtime" value="5">
Days
<label title="Simulation Time must be &le; 100 days.">
  <img class="info-icon-l" src="../img/info.svg" alt="info">
</label>
EOF
;

    my $recalcIC = <<EOF
<span class="switch">
  Recalculate Initial Conditions:
  <label>
    Off
    <input type="checkbox" value="1" id="recalcIC" name="recalcIC" checked>
    <span class="lever"></span>
    On
  </label>
</span>
<span>
  <label title="When this switch is on, the initial conditions (IC) are
  recalculated when secretion/absorption values are changed from the default
  (100, 88, 100, 88). Turn this switch off to always use euthyroid IC.">
    <img class="info-icon-l" src="../img/info.svg" alt="info">
  </label>
</span>
EOF
;

    my $nextRunColor = <<EOF
Set Next Run Color:
<span class="btn-group">
  <label class="btn btn-blue">
    <input type="radio" name="runRadio" id="runRadioBlue" value="Blue" checked>
    Blue
  </label>
  <label class="btn btn-green">
    <input type="radio" name="runRadio" id="runRadioGreen" value="Green">
    Green
  </label>
</span>
<label title="Simulation results are by default alternately graphed between Blue
and Green lines. However, you may override this functionality by manually
setting the color of the next run. Please note that only 1 line per color is
allowed and subsequent runs replace any existing lines of that color. Please
also note that example runs are always graphed as Blue.">
  <img class="info-icon-l" src="../img/info.svg" alt="info">
</label>
EOF
;

    my $buttonControls = <<EOF
<button class="btn btn-blue" type="button" onclick="ajax_getplot();">
  Simulate
</button>
<button class="btn btn-red"  type="button" onclick="location.reload();">
  Reset All
</button>
<button class="btn btn-yellow" type="button" onclick="resetRun('Blue');">
  <img class="info-icon-s" src="../img/x.png" alt="Delete">
  Blue Run
</button>
<button class="btn btn-yellow" type="button" onclick="resetRun('Green');">
  <img class="info-icon-s" src="../img/x.png" alt="Delete">
  Green Run
</button>
EOF
;

    my $hiddenInputs = <<EOF
<input type="hidden" name="thysim" id="thysim" value="$self->{thysim}">
EOF
;

    return <<EOF
<main class="select-none floatL">

  <!-- Container (top) -->
  <div id="container-top" class="container">

    <!-- Panel Left -->
    <div class="grid-1-2">

      <div id="sidebar" class="floatL">
$menuT3
$menuT4
      </div>

      <!-- Diagram and Parameters -->
      <div id="img-param" class="floatL">
$paramEditor
      </div>
      <!-- Diagram and Parameters end -->

      <img id="hilite1" src="../img/hilite.png" class="hide">
      <img id="hilite2" src="../img/hilite.png" class="hide">
      <img id="hilite3" src="../img/hilite.png" class="hide">
      <img id="hilite4" src="../img/hilite.png" class="hide">

    </div>
    <!-- Panel Left end -->

    <!-- Panel Right -->
    <div class="grid-1-2">

      <!-- Button Row -->
      <div class="container button-row">
        Toggle:
        <button class="btn btn-teal" type="button" onclick="togFreeHormone();">
          Free Hormone Values
        </button>
        <button class="btn btn-teal" type="button" id="togNormRange">
          Normal Range
        </button>
      </div>
      <!-- Button Row end -->

      <!-- Graphs -->
      <div class="textcenter">
        <div id="FT4graph" class="hide d3chart"></div>
        <div id="FT3graph" class="hide d3chart"></div>
        <div id="T4graph"  class="show d3chart"></div>
        <div id="T3graph"  class="show d3chart"></div>
        <div id="TSHgraph" class="show d3chart"></div>
      </div>
      <!-- Graphs end -->

    </div>
    <!-- Panel Right end -->

  </div>
  <!-- Container (top) end -->

  <div class="bar-h-gold floatL"></div>

  <!-- Container (bot) -->
  <div id="container-bot" class="container">

    <!-- Input Panel -->
    <div id="input-panel" class="grid-1-2">

      <div class="container textcenter">
        <span class="title"><b>Input Manager</b></span>
      </div>

      <div class="container textcenter pad-t-1em">
        Add
        T<span class="textsub">3</span> and
        T<span class="textsub">4</span> inputs
        to adjust quantity and frequency:
      </div>

      <div id="input-manager" class="container pad-t-1em"></div>

    </div>
    <!-- Input Panel end -->

    <!-- Control Panel -->
    <div id="control-panel" class="grid-1-2">

      <div class="container textcenter">
        <span class="title"><b>Control Panel</b></span>
      </div>

      <div class="container textcenter pad-t-1em">$simtime</div>

      <div class="container textcenter pad-t-1em">$sliderButton</div>

      <div class="container pad-t-1em">$sliders</div>

      <div class="container textcenter pad-t-1em">$recalcIC</div>

      <div class="container textcenter pad-t-1em">$nextRunColor</div>

      <div class="container textcenter pad-t-1em">$buttonControls</div>

      <div>$hiddenInputs</div>

    </div>
    <!-- Control Panel end -->

  </div>
  <!-- Container (bot) end -->

  <div class="bar-h-gold floatL"></div>

</main>
EOF
}

#====================================================================
# SUBROUTINE:   getFooter
# DESCRIPTION:
#   Semantic element: Header.
#====================================================================
sub getFooter {
    my ($self) = @_;

    my $jr_ack   = $self->juniorAcknowledge();

    return <<EOF
<footer class="select-none floatL">

  <!-- Container (top) -->
  <div class="container textcenter pad-t-1em">
    <b>$self->{thysimD} 3.0</b> &copy; 2013 by
    <a href="http://biocyb0.cs.ucla.edu/wp/"
       target="_blank">UCLA Biocybernetics Laboratory</a>
  </div>
  <!-- Container (top) end -->

  <!-- Container (mid) -->
  <div class="container pad-t-2em">

    <!-- References -->
    <div class="grid-1-3">
      <div class="footer-title textcenter">References*</div>
      <div class="footer-list">

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
    <div class="grid-1-3">
      <div class="footer-title textcenter">Recent Updates</div>
      <div class="footer-list">

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
    <div class="grid-1-3">
      <div class="footer-title textcenter">People & Acknowledgement</div>
      <div class="footer-list">

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
  <!-- Container (mid) end -->

  <!-- Container (bot) -->
  <div class="container textcenter pad-t-1em pad-b-2em">
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
  <!-- Container (bot) end -->

</footer>
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
    return <<EOF
<!-- Example $exp->{name} -->
<span class="floatL example">
  <span class="floatL example-wrp">
    <span class="example-txt"><b>$exp->{bold}</b> $exp->{text}</span>
    <button class="btn btn-blue" type="button"
            onclick="ajax_getplot('$exp->{name}');togInfoBtn('Example');">
      Run Example
    </button>
  </span>
  <a target="_blank" href="$exp->{img}">
    <img src="$exp->{img}" alt="$exp->{alt}" class="example-tbn">
  </a>
</span>
<!-- Example $exp->{name} end -->
EOF
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
<span>$p:</span>
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
          onclick="togInfoBtn('$key');">
    $val
  </button>
  <div id="info-btn-c-$key" class="info-btn-c">
    <button type="button" class="btn-anchor floatR"
            onclick="togInfoBtn('$key');">
      Close
    </button>
    <div>
$content
    </div>
  </div>
</div>
EOF
}

#====================================================================
# SUBROUTINE:   getHormoneMenu
# DESCRIPTION:
#   Generate hormone menu snp.
#
#   h:  Hormone, T3 or T4
#====================================================================
sub getHormoneMenu {
    my ($self,$h) = @_;

    my $s = $self->{hormoneMenu}->{$h}; # Shorthand

    return <<EOF
<div id="$s->{head_id}" class="T-menu-head">
  <button type="button" onclick="togHormoneMenu('$s->{menu_id}');">
    T<span class="textsub">3</span><i class="arrow arrow-u"></i>Inputs
  </button>
</div>
<div id="$s->{menu_id}" class="T-menu show">
  <button type="button" class="btn-icon $s->{button}"
          onclick="addInput('$s->{in_or_name}');">
    <img src="$s->{in_or_src}">
  </button>
  <button type="button" class="btn-icon $s->{button}"
          onclick="addInput('$s->{in_iv_name}');">
    <img src="$s->{in_iv_src}">
  </button>
  <button type="button" class="btn-icon $s->{button}"
          onclick="addInput('$s->{in_in_name}');">
    <img src="$s->{in_in_src}">
  </button>
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
