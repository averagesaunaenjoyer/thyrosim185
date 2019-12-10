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

    #--------------------------------------------------
    # hello
    #--------------------------------------------------

    bless $self, $class;

    return $self;
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

-title      => "THYROSIM by UCLA Biocybernetics Lab",
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
        #'../css/fonts-min.css',
        #'../css/ui-lightness/jquery-ui.min.css',
        '../css/bootstrap.min.css'
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
        -src  => '../js/bootstrap.bundle.min.js'
    },
#--------------------------------------------------
#     {
#         -type => 'text/javascript',
#         -src  => '../js/jquery-ui.min.js'
#     },
#-------------------------------------------------- 
    {
        -type => 'text/javascript',
        -src  => '../js/d3.min.js'
    },
#--------------------------------------------------
#     {
#         -type => 'text/javascript',
#         -src  => '../js/content.js'
#     },
#-------------------------------------------------- 
#--------------------------------------------------
#     {
#         -type => 'text/javascript',
#         -src  => '../js/ajaxfun.js'
#     },
#-------------------------------------------------- 
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
# SUBROUTINE:
# DESCRIPTION:
#====================================================================
sub genericFunction {
}

1;
