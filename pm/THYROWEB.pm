#!/usr/bin/perl
use v5.10; use strict; use warnings;
#==============================================================================
# FILE:         THYROWEB.pm
# AUTHOR:       Simon X. Han
# DESCRIPTION:
#   Helper package for generating dynamic Thyrosim websites.
#==============================================================================
# TODO
# Differences between Thyrosim and ThyrosimJr:
# 1. Examples

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

    bless $self, $class;

    #--------------------------------------------------
    # Post-bless initializations
    #--------------------------------------------------

    $self->initDisplay();
    $self->initExamples();

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
                    Specifically, the simulated hypothyroidic individual is
                    given 123 &microg T<span class="textsub">4</span> and 6.5
                    &microg T<span class="textsub">3</span> daily for 30 days.',
        img     => '../img/experiment-DiJo19-1.png',
        alt     => 'DiStefano-Jonklass Example 1',
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

-title      => "$self->{thysimD} by UCLA Biocybernetics Lab",
-meta       => {
    'charset'       => 'utf-8',
    'content'       => 'width=device-width, initial-scale=1, shrink-to-fit=no',
    'keywords'      => 'thyrosim thyroid simulator',
    'copyright'     => 'Copyright 2013 by UCLA Biocybernetics Laboratory'
},
-head => Link({
    -rel  => 'shortcut icon',
    -href => '../favicon.ico'
}),
-style      => {
    'src'           => [
        '../css/thyrosim.css',
        '../css/fonts-min.css',
        '../css/ui-lightness/jquery-ui.min.css',
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
-onload     => 'graphthis();loadToolTip();',
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

    # Things to put into the form
    my $examples  = $self->insertExamples();
    my $paramList = $self->printParams();
    my $jr_ack    = $self->juniorAcknowledge();

    # Put form together
    return <<END

<form name="form">
<div id="wrapper">

  <!-- Header -->
  <div id="header" style="$self->{headerstyle}">
    <!-- About -->
    <div id="button-About" class="bank-left infoButton unselectable">
      <a id="link-About"
         class="color-black header-buttons-link"
         href="javascript:clickInfoButton('About');">DIRECTIONS</a>
      <div id="dp-About" class="popup-rollover">
        <p>
          <span class="infoButton-close bank-right"
                onClick="javascript:clickInfoButton('About');">close</span><br>
          <span style="color:red">$self->{thysimD}</span>

          is a tool for simulating a well-validated human thyroid hormone (TH)
          feedback regulation system model*.

          Users can simulate common thyroid system maladies by adjusting TH
          secretion/absorption rates on the interface.

          Oral input regimens, also selectable on the interface, simulate
          common hormone treatment options.

          Bolus and intravenous infusion inputs also can be added, for
          exploratory research and teaching demonstrations.

          For easy comparisons, the interface includes facility for
          superimposing two sets of simulation results.
          <br>
          <br>
          Minimum Usage:<br>
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
              <ol type="a">
                <li>
                  Click
                  "show T<span class="textsub">3</span> input" or
                  "show T<span class="textsub">4</span> input".
                </li>
                <li>
                  Click the
                  <img src="../img/pill1.png" alt="Pill Input">
                  <img src="../img/syringe1.png" alt="IV Pulse Dose">
                  or
                  <img src="../img/infusion1.png" alt="Infusion">
                  icons to add as input.
                </li>
                <li>
                  Fill in the required dosage, start and end times.
                </li>
              </ol>
            </li>
          </ol>
          Features:<br>
          <ol>
            <li>
              <img src="../img/x.png" alt="x"> icon: click to delete an input.
            </li>
            <li>
              <img src="../img/enabled.png" alt="enabled">
              <img src="../img/disabled.png" alt="disabled">
              icons: click to enable or disable an input for the next
              simulation.
            </li>
            <li>
              <img src="../img/plus.png" alt="plus"> icon: click to modify
              secretion/absorption via scrollbars.
            </li>
          </ol>
        </p>
      </div>
    </div>
    <!-- About end -->

    <!-- Example -->
    <div id="button-Example" class="bank-left infoButton unselectable">
      <a id="link-Example" class="color-black header-buttons-link" href="javascript:clickInfoButton('Example');">EXAMPLE</a>
      <div id="dp-Example" class="popup-rollover">
        <p>
          <span class="infoButton-close bank-right" onClick="javascript:clickInfoButton('Example');">close</span><br>

          $examples

        </p>
      </div>
    </div>
    <!-- Example end -->

    <!-- Disclaimer -->
    <div id="button-Disclaimer" class="bank-left infoButton unselectable">
      <a id="link-Disclaimer" class="color-black header-buttons-link" href="javascript:clickInfoButton('Disclaimer');">DISCLAIMER</a>
      <div id="dp-Disclaimer" class="popup-rollover">
        <p>
          <span class="infoButton-close bank-right" onClick="javascript:clickInfoButton('Disclaimer');">close</span><br>
          <span style="color:red">$self->{thysimD}</span>

          is intended as an educational and research tool only.

          Information provided is not a substitute for medical advice and you
          should contact your doctor regarding any medical conditions or
          medical questions that you have.
        </p>
      </div>
    </div>
    <!-- Disclaimer end -->

    &nbsp;
    Start by clicking
    "Show T<span class="textsub">3</span> input" or
    "Show T<span class="textsub">4</span> input"

    <br>

    <!-- Not-for-IE Message -->
    <div id="nonIEMsgDiv" class="displaynone">
      <br>
      <div class="nonIEMsg">
        It appears that you are using Internet Explorer (IE). If you are
        using IE, please use version 9 or above. Otherwise, to see the
        web-app as intended, please use a free and supported browser, such as
        <a href="http://www.google.com/chrome">Google Chrome</a> or
        <a href="http://www.mozilla.org/en-US/firefox/new/">Mozilla Firefox</a>.
      </div>
    </div>
    <script>
        // D3 only supports IE9+
        checkMSIE();
    </script>
    <!-- Not-for-IE Message end -->

  </div>
  <!-- Header end -->

  <!-- Content -->
  <div id="content">

    <!-- Interactive Interface -->
    <div id="interactive-interface">

      <!-- Inputs (left-most div) -->
      <div id="content-inputs" class="content-center">
        <!-- T3 Input -->
        <a id="T3display" class="showhide" href="javascript:show_hide('T3');">
          Show T<span class="textsub">3</span> input
        </a><br>
        <div id="T3input" class="interface-input-options">
          <a class="../img-input" href="javascript:addInput('T3-Oral');">
            <img src="../img/pill1.png" alt="T3 Pill Input" />
          </a>
          <br>
          <a class="../img-input" href="javascript:addInput('T3-IV');">
            <img src="../img/syringe1.png" alt="T3 IV Pulse Dose" />
          </a>
          <br>
          <a class="../img-input" href="javascript:addInput('T3-Infusion');">
            <img src="../img/infusion1.png" alt="T3 Infusion" />
          </a>
        </div>
        <!-- T3 Input end -->
        <br>
        <!-- T4 Input -->
        <a id="T4display" class="showhide" href="javascript:show_hide('T4');">
          Show T<span class="textsub">4</span> input
        </a><br>
        <div id="T4input" class="interface-input-options">
          <a class="../img-input" href="javascript:addInput('T4-Oral');">
            <img src="../img/pill2.png" alt="T4 Pill Input" />
          </a>
          <br>
          <a class="../img-input" href="javascript:addInput('T4-IV');">
            <img src="../img/syringe2.png" alt="T4 IV Pulse Dose" />
          </a>
          <br>
          <a class="../img-input" href="javascript:addInput('T4-Infusion');">
            <img src="../img/infusion2.png" alt="T4 Infusion" />
          </a>
        </div>
        <!-- T4 Input end -->
      </div>
      <!-- Inputs end -->

      <!-- Diagram (center div) -->
      <div id="diagram" class="interface-diagram relative">
        Toggle:
        <button type="button" onclick="togParamListButton();">Parameters</button>
        <div id="parameditdiv" class="parameditdiv displaynone">$paramList</div>
        <div id="hilite1" class="imgcontainer displaynone">
          <img src="../img/hilite.png">
        </div>
        <div id="hilite2" class="imgcontainer displaynone">
          <img src="../img/hilite.png">
        </div>
        <div id="hilite3" class="imgcontainer displaynone">
          <img src="../img/hilite.png">
        </div>
        <div id="hilite4" class="imgcontainer displaynone">
          <img src="../img/hilite.png">
        </div>
      </div>
      <!-- Diagram end -->
    </div>
    <!-- Interactive Interface end -->

    <!-- Graphs (right-most div) -->
    <div id="content-right">
      Toggle:
      <button type="button" onclick="togFreeHormoneButton();">Free Hormone Values</button>
      <!--<button type="button" id="togXAxisDisp">X-Axis Days/Hours</button>-->
      <div id="FT4graph" class="displaynone"></div>
      <div id="FT3graph" class="displaynone"></div>
      <div id="T4graph"></div>
      <div id="T3graph"></div>
      <div id="TSHgraph"></div>
    </div>
    <!-- Graphs end -->
  </div>
  <!-- Content end -->

  <!-- Secretion/Absorption (lower div) -->
  <div id="content-lower">
    <div class="textaligncenter">
      <a class="img-input" href="javascript:showhidescrollbars();">
        <img class="textaligntop relative scrollbars" id="showhidescrollbar" src="../img/plus.png" alt="show scroll bars" />
      </a>
      Adjust secretion/absorption rates:<br>
      <label title="Initial conditions are automatically recalculated when
      secretion/absorption values are changed. Uncheck this box to use
      euthyroid initial conditions.">
        <input type="checkbox" value="1" id="recalcIC" name="recalcIC" checked>
        Recalculate Initial Conditions
      </label>
    </div>

    <!-- T4 Secretion -->
    <div class="adjuster" onmouseover="hilite('1');" onmouseout="lolite('1');">
      T<span class="textsub">4</span> Secretion (0-200%):
      <input type="text" size="3" id="dialinput1" name="dialinput1">%
      <div id="slidercontainer1" class="slidercontainer">
        <div id="slider1"></div>
      </div>
    </div>
    <!-- T4 Secretion end -->

    <!-- T4 Absorption -->
    <div class="adjuster" onmouseover="hilite('2');" onmouseout="lolite('2');">
      T<span class="textsub">4</span> Absorption (0-100%):
      <input type="text" size="3" id="dialinput2" name="dialinput2">%
      <div id="slidercontainer2" class="slidercontainer">
        <div id="slider2"></div>
      </div>
    </div>
    <!-- T4 Absorption end -->

    <!-- T3 Secretion -->
    <div class="adjuster" onmouseover="hilite('3');" onmouseout="lolite('3');">
      T<span class="textsub">3</span> Secretion (0-200%):
      <input type="text" size="3" id="dialinput3" name="dialinput3">%
      <div id="slidercontainer3" class="slidercontainer">
        <div id="slider3"></div>
      </div>
    </div>
    <!-- T3 Secretion end -->

    <!-- T3 Absorption -->
    <div class="adjuster" onmouseover="hilite('4');" onmouseout="lolite('4');">
      T<span class="textsub">3</span> Absorption (0-100%):
      <input type="text" size="3" id="dialinput4" name="dialinput4">%
      <div id="slidercontainer4" class="slidercontainer">
        <div id="slider4"></div>
      </div>
    </div>
    <!-- T3 Absorption end -->

  </div>
  <!-- Secretion/Absorption end -->

  <!-- Input Adjustments (footer) -->
  <div id="footer">

    <div class="textaligncenter">
      <label title="Total simulation time must be < 100 days.">
        Simulation time:
        <input type="text" id="simtime" name="simtime" size="1" value="5">
        days
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

      <label for="compPanel" title="Simulation results are by default graphed in
      a Blue line. To superimpose two sets of results, set the next run to a
      different color. Please note that only 1 line per color is allowed and
      subsequent runs replace any existing lines of that color.">

        Set next simulation results as Blue or Green:
        <br>

        <input type="radio" name="runRadio" id="runRadioBlue" value="Blue" checked>
        <label for="runRadioBlue">Blue</label>

        <input type="radio" name="runRadio" id="runRadioGreen" value="Green">
        <label for="runRadioGreen">Green</label>

      </label>
      <br>

      <button id="resetBlueObj" type="button" onclick="resetObj('Blue');">
        Delete Blue Run
      </button>
      <button id="resetGreenObj" type="button" onclick="resetObj('Green');">
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
      <button type="button" onclick="loadXMLDoc();">SIMULATE</button>
      <button type="button" onclick="location.reload();">RESET ALL</button>
      <button type="button" id="togNormRange">TOGGLE NORMAL RANGE</button>
    </div>
    <!-- Last Row of Buttons end -->

  </div>
  <!-- Input Adjustments end -->

  <!-- Bottom (footer) -->
  <div id="footer">

    <div class="textaligncenter">
      <b>THYROSIM 2.1</b> &copy; 2013 by
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
            Parameter editor added December 2019 (Toggle Parameters)
          </li>
          <li>
            Free T<span class="textsub">4</span> and
            Free T<span class="textsub">3</span> alternatives to Total
            T<span class="textsub">4</span> and
            T<span class="textsub">3</span> added January 2019
            (Toggle Free Hormone Values)
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
  <div id="footer">
    <div class="textaligncenter">
      Please send comments, bugs, criticisms to:
      <a href="mailto:joed\@ucla.edu">joed\@ucla.edu</a><br>
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

&nbsp;

END
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
<span class="bank-left margin-bot-10">
  <span class="bank-left example-text">
    <b>$exp->{bold}</b> $exp->{text}
    <br>
    <button type="button" onclick="loadXMLDoc('$exp->{name}');
                                   clickInfoButton('Example');">
      Simulate
    </button>
  </span>
  <img src="$exp->{img}" alt="$exp->{alt}" class="example-image" />
</span>

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
<input size="8" type="text" id="$p" name="$p" value="$v" class="paraminput">
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
# SUBROUTINE:
# DESCRIPTION:
#====================================================================
sub genericFunction {
}

1;
