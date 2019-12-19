"use strict";
//=============================================================================
// FILE:        thyrosim.js
// AUTHOR:      Simon X. Han
// DESCRIPTION:
//   Javascript functions in Thyrosim.
//=============================================================================

//========================================================================
// TASK:    Functions for ajax calls.
//========================================================================

var ThyrosimGraph = new ThyrosimGraph();

//===================================================================
// DESC:    Validate and submit form. Retrieve JSON plotting data and graph.
// ARGS:
//   exp:   An optional experiment
//===================================================================
function ajax_getplot(exp) {

    //---------------------------------------------------------
    // Generate form data for processing server side. For specific experiments,
    // return a predefined string. Otherwise serialize form inputs.
    //---------------------------------------------------------
    var formdata;
    if (exp) {
        formdata = getExperimentStr(exp);
        executeExperiment(exp);
    } else {
        //---------------------------------------------------------
        // Validate form
        //---------------------------------------------------------
        var hasFormError = validateForm();
        if (hasFormError) {
            return false;
        }
        formdata = $("form").serialize();
    }

    //---------------------------------------------------------
    // Submit to server and process response
    //---------------------------------------------------------
    var msgBoxId = getMsgBoxId();
    showLoadingMsg(msgBoxId);

    var msg;
    var time1 = new Date().getTime();
    $.ajaxSetup({timeout:120000}); // No run should take more than 2 mins
    $.post( "ajax_getplot.cgi", { data: formdata })
      .done(function( data ) {

        // Graph results from this run
        var rdata = jQuery.parseJSON(data); // Run data
        var color = $('input:radio[name=runRadio]:checked').val();
        ThyrosimGraph.setRun(color,rdata);
        graphAll();
        runRadioNext();

        msg = "Execution time (sec):";
      })
      .fail(function (data ) {
        msg = "Operation timed out (sec):";
      })
      .always(function() {
        hideLoadingMsg(msgBoxId); // Hide loading message
        var time2 = new Date().getTime();
        var timeE = Math.floor((time2 - time1)/1000);
        alert(msg + ' ' + timeE); // Elapsed
      });
}

//========================================================================
// TASK:    Functions for graphing.
//========================================================================

//===================================================================
// DESC:    Wrapper to call the graphing function for each hormone.
//===================================================================
function graphAll() {

    // Need to initialize the graph?
    if (ThyrosimGraph.initGraph) {
        graph("FT4","" ,"1");
        graph("FT3","" ,"1");
        graph("T4" ,"" ,"1");
        graph("T3" ,"" ,"1");
        graph("TSH","1","1");
        ThyrosimGraph.initGraph = false;
    // Plot the graph
    } else {
        graph("FT4","" );
        graph("FT3","" );
        graph("T4" ,"" );
        graph("T3" ,"" );
        graph("TSH","1");
    }
}

//===================================================================
// DESC:    Use d3 to graph a hormone.
// ARGS:
//   hormone:   Hormone name
//   addlabel:  Binary for whether to include x-axis label
//   initgraph: Binary for whether to initialize
//===================================================================
function graph(hormone,addlabel,initgraph) {

    var thysim = $('#thysim').val();
    var comp = ThyrosimGraph.settings[hormone].comp;
    var unit = ThyrosimGraph.settings[hormone].unit;
    var eRLo = ThyrosimGraph.settings[hormone].bounds[thysim].lo;
    var eRHi = ThyrosimGraph.settings[hormone].bounds[thysim].hi;

    // Graph size
    var w = 350; // width in pixels of the graph
    var h = 130; // height in pixels of the graph

    // Scales
    var xVal = ThyrosimGraph.getXVal(comp);
    var yVal = ThyrosimGraph.getYVal(hormone,comp);
    var yEnd = ThyrosimGraph.getEndVal(yVal);
    var x = d3.scale.linear().domain([0,xVal]).range([0,w]);
    var y = d3.scale.linear().domain([0,yEnd]).range([h,0]);

    // Axes - large axes use SI units, ie 1,200 -> 1.2k
    var xAxis = d3.svg.axis().scale(x).orient("bottom")
        .tickSize(-h,0,0);
    var yAxis = d3.svg.axis().scale(y).orient("left")
        .tickSize(-w,0,0);
    if (parseFloat(yEnd) > 1000) {yAxis.tickFormat(d3.format(".2s"));}

    // Default scale is in days, here we create the scales in hours
    var xVal2 = xVal * 24;
    var x2 = d3.scale.linear().domain([0,xVal2]).range([0,w]);
    var xAxis2 = d3.svg.axis().scale(x2).orient("bottom")
        .tickSize(-h,0,0);

    // Graph svg + tooltip
    var graph = d3.select("#"+hormone+"graph");
    var tooltip;
    var f = d3.format(".2f");

    // Initialize the graph
    // Graph is initialized once per instance of loading.
    var xT = 45; // x direction translate
    var yT = 10; // y direction translate
    if (initgraph) {
        tooltip = graph.append("div")
            .attr("class","tooltip")
            .style("opacity",0);

        graph = d3.select("#"+hormone+"graph").append("svg:svg")
            .attr("width",w+60)
            .attr("height",function(d) {return addlabel?h+50:h+20})
          .append("svg:g")
            .attr("transform","translate("+xT+","+yT+")");

        // Add a border around the graph
        var borderPath = graph.append("rect")
            .attr("x",0)
            .attr("y",0)
            .attr("width",w)
            .attr("height",h)
            .attr("shape-rendering","crispEdges")
            .style("stroke","#d7d7d7")
            .style("fill","none")
            .style("stroke-width",2);

        // Add range box here
        var rangeVals = normRangeCalc(yEnd,eRHi,eRLo);
        var rangeBox = graph.append("rect")
            .attr("class","rangeBox")
            .attr("x",0)
            .attr("y",h-y(rangeVals.offset))
            .attr("width",x(xVal))
            .attr("height",h-y(rangeVals.height))
            .attr("shape-rendering","crispEdges")
            .attr("stroke","none")
            .attr("fill","none")
            .style("opacity",0.6);

        // Add title to the side of the graph
        graph.append("text")
            .attr("text-anchor","middle")
            .attr("transform","translate(-30,"+h/2+")rotate(-90)")
            .style("font","16px sans-serif")
            .text(hormone+' '+unit);

        // Add unit to the bottom of the last graph
        if (addlabel) {
            var xT2 = w/2;
            var yT2 = h+30;
            graph.append("text")
                .attr("class","x-axis-label")
                .attr("text-anchor","middle")
                .attr("transform","translate("+xT2+","+yT2+")")
                .style("font","16px sans-serif")
                .text("Days");
        }

        // Add x-axis to graph
        graph.append("svg:g")
            .attr("class","x-axis")
            .attr("stroke","#eee")
            .attr("transform","translate(0,"+h+")")
            .attr("shape-rendering","crispEdges")
            .call(xAxis)
                .selectAll("text")
                .style("display",function(d) {
                    return addlabel?"block":"none";
                });

        // Add y-axis to graph
        graph.append("svg:g")
            .attr("class","y-axis")
            .attr("stroke","#eee")
            .attr("transform","translate(0,0)")
            .attr("shape-rendering","crispEdges")
            .call(yAxis);

        // Add hidden paths to graph
        $.each(ThyrosimGraph.colors,function(color) {
            // Empty data values
            var data = [0];

            // Line
            var line = d3.svg.line()
                .x(function(d,i) {return x(i);})
                .y(function(d,i) {return y(d);});

            // Append dummy line
            graph.append("svg:path")
                .data([data])
                .attr("d",line)
                .attr("class","line"+color)
                .attr("stroke",color)
                .attr("stroke-width","1.5")
                .attr("fill","none")
                .style("stroke-dasharray",ThyrosimGraph.getLinestyle(color));

            // Append dummy circle for tooltip
            graph.selectAll("circle.dot"+color)
                .data(data).enter().append("circle")
                .attr("class","dot"+color)
                .attr("fill","none")
                .attr("r",1)
                .attr("cx",function(d,i) {return x(i);})
                .attr("cy",function(d,i) {return y(d);});
        });

        // Turn range values on by default
        toggleRangeBox();

    // Update the graph
    } else {
        // Select tooltip
        tooltip = graph.select("div.tooltip");

        // Update x-axis
        graph.selectAll("g.x-axis")
            .call(xAxis)
                .selectAll("text")
                .style("display",function(d) {
                    return addlabel?"block":"none";
                });

        // Update y-axis
        graph.selectAll("g.y-axis")
            .call(yAxis);

        // Update range box
        var rangeVals = normRangeCalc(yEnd,eRHi,eRLo);
        graph.selectAll("rect.rangeBox")
            .attr("y",h-y(rangeVals.offset))
            .attr("width",x(xVal))
            .attr("height",h-y(rangeVals.height));

        // Update data points for each color
        $.each(ThyrosimGraph.colors,function(color) {
            // Empty data values
            var valuesD = [0];
            var valuesT = [0];

            // Remove old circles
            graph.select("svg").select("g").selectAll(".dot"+color)
                .data(valuesD).exit().remove();

            if (ThyrosimGraph.checkRunColorExist(color)) {
                // Real data values
                valuesD = ThyrosimGraph.getRunValues(color,comp);
                valuesT = ThyrosimGraph.getRunValues(color,"t");
            }

            // Line
            var line = d3.svg.line()
                .x(function(d,i) {return x(valuesT[i]/24);})
                .y(function(d,i) {return y(d);});

            // Update line
            graph.selectAll("path.line"+color)
                .data([valuesD])
                .attr("d",line);

            // Update circles
            // Repeating selection here because d3 doesn't update the old
            // points otherwise.
            var circle = graph
                .select("svg").select("g")
                .selectAll(".dot"+color);

            circle.data(valuesD).enter().append("circle")
                .attr("class","dot"+color)
                .attr("fill","transparent")
                .attr("r",5)
                .attr("cx",function(d,i) {return x(valuesT[i]/24);})
                .attr("cy",function(d,i) {return y(d);})
                .on("mouseover",function(d,i) {
                    var thisX = valuesT[i]/24;
                    var dL = d3.event.pageX+12;
                    var dT = d3.event.pageY;

                    // Bank top/bottom left/right depending on location
                    if (parseFloat(thisX) > parseFloat(0.71*xVal)) {
                        dL = dL - 108;
                    }
                    if (parseFloat(d)     < parseFloat(0.31*yEnd)) {
                        dT = dT - 32;
                    }

                    $(this).attr("fill",color);
                    tooltip.transition()
                        .duration(200)
                        .style("opacity",0.8);
                    tooltip.html(hormone+': '+f(d)+'<br>'
                                +'Time: '+f(thisX))
                        .style("left",dL+"px")
                        .style("top", dT+"px");
                })
                .on("mouseout",function(d) {
                    $(this).attr("fill","transparent");
                    tooltip.transition()
                        .duration(500)
                        .style("opacity",0);
                });
        });
    }

    // Toggle range box on and off
    function toggleRangeBox() {
        var rangeBox = d3.selectAll("rect.rangeBox");
        var fill = rangeBox.attr("fill");
        rangeBox.attr("fill",function(d) {
            return fill == "none" ? "yellow" : "none";
        });
    }

    // Toggle x-axis day or hour
    function toggleXAxis() {
        var curXAxis = d3.selectAll("text.x-axis-label");
        var curLabel = curXAxis.text();
        var thisXAxis;
        var thisXLabel;
        if (curLabel == "Days") {
            thisXAxis = xAxis2;
            thisXLabel = "Hours";
        } else {
            thisXAxis = xAxis;
            thisXLabel = "Days";
        }

        // Update x-axis
        d3.selectAll("g.x-axis")
            .call(thisXAxis)
                .selectAll("text")
                .style("display","none");

        // Only show axis values for bottom graph
        d3.selectAll("#TSHgraph text")
            .style("display","block");

        // Update x-axis label
        d3.selectAll("text.x-axis-label")
            .text(thisXLabel);
    }

    d3.select("#togNormRange").on("click",toggleRangeBox);
    d3.select("#togXAxisDisp").on("click",toggleXAxis);
    // Currently, not using this toggle button. While the graph labels change
    // correctly, the pop-up when hovering over graph values does not update. To
    // get this to work properly would require converting all x-axis values to
    // days and re-graph.
}

//===================================================================
// DESC:    While the ajax call is running, display a 'wait' message box that
//          follows the cursor. Depending on whether dial values are default or
//          whether recalculate IC is checked, the message is different. This
//          function returns the id of the selected message.
//===================================================================
function getMsgBoxId() {
    var d = '#dialinput';
    if ($(d+'1').prop('defaultValue') == $(d+'1').prop('value') &&
        $(d+'2').prop('defaultValue') == $(d+'2').prop('value') &&
        $(d+'3').prop('defaultValue') == $(d+'3').prop('value') &&
        $(d+'4').prop('defaultValue') == $(d+'4').prop('value')) {
        return 'follow1';
    }
    return $('#recalcIC').prop('checked') ? 'follow2' : 'follow1';
}

//===================================================================
// DESC:    Show/Hide the loading message box. The +5 offsets the box so that it
//          doesn't interfere with mouse clicks.
// ARGS:
//   mid:   Message box id
//===================================================================
function showLoadingMsg(mid) {
    $(window).click(function(e){
        $('#'+mid).css('display','block')
                  .css('top',    e.pageY + 5)
                  .css('left',   e.pageX + 5);
    });
    $(window).mousemove(function(e){
        $('#'+mid).css('display','block')
                  .css('top',    e.pageY + 5)
                  .css('left',   e.pageX + 5);
    });
}
function hideLoadingMsg(mid) {
    $(window).unbind();
    $('#'+mid).css('display','none');
}

//===================================================================
// DESC:    Validate the form. Returns 1 if validation fails.
//===================================================================
function validateForm() {
    var fail = 0;
    var maxDay = parseFloat(100.0);

    // Make sure each input is a number. Decimals okay.
    $.each($("form").serializeArray(), function(i, field) {

        // Skip checking for 'runRadio'
        if (field.name == 'runRadio') {
            return true;
        }
        // Skip checking for 'thysim'
        if (field.name == 'thysim') {
            return true;
        }

        // Checking for numeric
        if (field.value.match(/^-?\+?[0-9]*\.?[0-9]+$/)) {
            $('#'+field.name).removeClass('error');
        } else {
            $('#'+field.name).addClass('error');
            fail = 1;
        }
    });

    // For inputs, check the following:
    // 1. Check that start, end, and simulation time are <= maxDay.
    // 2. Update simulation time with the highest end day.
    $.each($("form").serializeArray(), function(i, field) {
        if (field.name.match(/^start-/) ||
            field.name.match(/^end-/)   ||
            field.name.match(/^simtime/)) {
            if (parseFloat(field.value) > maxDay) {
                $('#'+field.name).addClass('error');
                fail = 1;
            } else if (parseFloat(field.value) >
                       parseFloat($("#simtime").val())) {
                $("#simtime").val(field.value);
            }
        }
    });

    return fail;
}

//===================================================================
// DESC:    Get predefined string for a specific experiment.
// ARGS:
//   exp:   The experiment name
//===================================================================
function getExperimentStr(exp) {

    // The default Thyrosim example.
    if (exp == "experiment-default") {
        return "experiment="+exp+"&thysim=Thyrosim";
    }

    // The default ThyrosimJr example.
    if (exp == "experiment-default-jr") {
        return "experiment="+exp+"&thysim=ThyrosimJr";
    }

    // The DiStefano-Jonklaas 2019 Example-1. Only relevant for Thyrosim.
    if (exp == "experiment-DiJo19-1") {
        return "experiment="+exp+"&thysim=Thyrosim";
    }

    return false;
}

//===================================================================
// DESC:    Change the UI to match the experiment ran. When running experiments,
//          clear results and only graph experiment results in Blue.
// ARGS:
//   exp:   The experiment name
//===================================================================
function executeExperiment(exp) {
    $('#footer-input').empty();                  // Clear the input space
    ThyrosimGraph.setRun("Green",undefined);     // Delete the Green run
    $('input[name=runRadio]')[0].checked = true; // Set Blue as exp run

    if (exp == "experiment-default") {
        $('#simtime').val(5);
        tuneDials(100,88,100,88);
    }

    if (exp == "experiment-DiJo19-1") {
        $('#simtime').val(30);
        tuneDials(25,88,25,88);
        addInputOral('T4',123,1,false,1,30);
        addInputOral('T3',6.5,1,false,1,30);
    }

}

//===================================================================
// DESC:    Helper function to change dialinput and slider values.
// ARGS:
//   a:     Dial/Slider 1 value
//   b:     Dial/Slider 2 value
//   c:     Dial/Slider 3 value
//   d:     Dial/Slider 4 value
//===================================================================
function tuneDials(a,b,c,d) {
    $('#dialinput1').val(a); $('#slider1').slider('value',a);
    $('#dialinput2').val(b); $('#slider2').slider('value',b);
    $('#dialinput3').val(c); $('#slider3').slider('value',c);
    $('#dialinput4').val(d); $('#slider4').slider('value',d);
}

//===================================================================
// DESC:    Helper function to add oral inputs.
// ARGS:
//   hormone:   'T4' or 'T3'
//   dose:      Dose
//   interval:  Dosing interval
//   singledose: Whether to use a single dose - true/false value
//   start:     Start time
//   end:       End time
// NOTE:
//   When singledose is true, interval and end can be ''.
//===================================================================
function addInputOral(hormone,dose,interval,singledose,start,end) {
    addInput(hormone+'-Oral');
    var pin = parseInputName($('#footer-input').children().last().attr('id'));
    $('#dose-' + pin[1]).val(dose);
    $('#int-'  + pin[1]).val(interval);
    $('#start-'+ pin[1]).val(start);
    $('#end-'  + pin[1]).val(end);
    if (singledose) {
        $('#singledose-'+pin[1]).prop('checked', true);
        useSingleDose(pin[1]);
    }
}

//===================================================================
// DESC:    Helper function to add IV inputs.
//===================================================================

//===================================================================
// DESC:    Helper function to add infusion inputs.
//===================================================================

//===================================================================
// DESC:    Manages plotting data as Blue or Green plots.
//===================================================================
function ThyrosimGraph() {
    this.initGraph = true;

    // Default color settings
    var colors = {
        Blue:  { linestyle: "",    rdata: undefined, exist: false },
        Green: { linestyle: "5,3", rdata: undefined, exist: false }
    };
    this.colors = colors;

    // Default graph settings
    //   comp:  Comparment name. Server-side data use this name for reference
    //   unit:  Comparment display unit
    //   ymin:  Y-axis value. ymin values are rounded up by a digit. See
    //          getEndVal()
    //   bounds: Normal range
    var settings = {
        FT4: {
            comp: 'ft4',
            unit: 'ng/L',
            ymin: { Thyrosim: 17, ThyrosimJr: 17 },
            bounds: {
                Thyrosim:   { lo: 8, hi: 17 },
                ThyrosimJr: { lo: 8, hi: 17 }
            }
        },
        FT3: {
            comp: 'ft3',
            unit: 'ng/L',
            ymin: { Thyrosim: 4, ThyrosimJr: 4 },
            bounds: {
                Thyrosim:   { lo: 2.2, hi: 4.4 },
                ThyrosimJr: { lo: 2.2, hi: 4.4 },
            }
        },
        T4: {
            comp: '1',
            unit: '\u03BCg/L', // mcg
            ymin: { Thyrosim: 110, ThyrosimJr: 110 },
            bounds: {
                Thyrosim:   { lo: 45, hi: 105 },
                ThyrosimJr: { lo: 45, hi: 105 },
            }
        },
        T3: {
            comp: '4',
            unit: '\u03BCg/L', // mcg
            ymin: { Thyrosim: 1, ThyrosimJr: 2 },
            bounds: {
                Thyrosim:   { lo: 0.6, hi: 1.8 },
                ThyrosimJr: { lo: 0.6, hi: 1.8 },
            }
        },
        TSH: {
            comp: '7',
            unit: 'mU/L',
            ymin: { Thyrosim: 4, ThyrosimJr: 4 },
            bounds: {
                Thyrosim:   { lo: 0.4, hi: 4 },
                ThyrosimJr: { lo: 0.4, hi: 4 },
            }
        },
    };
    this.settings = settings;

    // Set run data
    this.setRun = setRun;
    function setRun(color,rdata) {
        this.colors[color].rdata = rdata;
        if (typeof rdata !== 'undefined') {
            this.colors[color].exist = true;
        } else {
            this.colors[color].exist = false;
        }
    }

    // Get run data's values
    this.getRunValues = getRunValues;
    function getRunValues(color,comp) {
        return this.colors[color].rdata.data[comp].values;
    }

    // Check whether the run data of color exists
    this.checkRunColorExist = checkRunColorExist;
    function checkRunColorExist(color) {
        return this.colors[color].exist;
    }

    // Get the max X value over all colors
    this.getXVal = getXVal;
    function getXVal(comp) {
        var maxX = 0;
        $.each(colors,function(color,o) {
            if (o.exist) {
                if (parseFloat(o.rdata.simTime) > maxX) {
                    maxX = o.rdata.simTime;
                }
            }
        });

        if (maxX) {return maxX;}

        // Default simTime to 5 days
        return "5";
    }

    // Get the max Y value over all colors
    this.getYVal = getYVal;
    function getYVal(hormone,comp) {
        // Retrieve the initial ymin value
        var thysim = $('#thysim').val();
        var maxY = settings[hormone].ymin[thysim];

        $.each(colors,function(color,o) {
            if (o.exist) {
                if (parseFloat(o.rdata.data[comp].max) > maxY) {
                    maxY = o.rdata.data[comp].max;
                }
            }
        });

        return maxY;
    }

    // Get the "End" value by increasing a digit by 1. See the following:
    //   1.1  => 2
    //   1.9  => 3
    //   9.9  => 11
    //   12.1 => 13
    //   20   => 30
    //   90   => 100
    //   99   => 110
    //   100  => 110
    //   500  => 510
    //   900  => 910
    //   1000 => 1100
    //   1100 => 1200
    this.getEndVal = getEndVal;
    function getEndVal(n) {
        var roundRule = 8;
        var num1 = parseInt(n);
        var numL = parseInt(num1.toString().length);
        if (num1 <= 15) { // Grow by 1
            var zero = this.repeat("0",numL-1); // 0
            var mFac = parseInt("1"+zero); // 1
            var numR = this.roundX(n,roundRule);
            numR = numR + 1;
            return numR;
        }
        if (num1 <= 99) {
            var zero = this.repeat("0",numL-1);
            var mFac = parseInt("1"+zero);
            var numR = this.roundX(n/mFac,roundRule)*mFac;
            numR = numR + mFac;
            return numR;
        }
        var zero = this.repeat("0",numL-2);
        var mFac = parseInt("1"+zero);
        var numR = this.roundX(n/mFac,roundRule)*mFac;
        numR = numR + mFac;
        return numR;
    }

    this.getLinestyle = getLinestyle;
    function getLinestyle(color) {
        return this.colors[color].linestyle;
    }

    // Function to repeat a string. Essentially, "n" x 3 = "nnn".
    this.repeat = repeat;
    function repeat(pattern,count) {
        if (count < 1) return '';
        var returnVal = '';
        while (count > 0) {
            returnVal+=pattern;
            count--;
        }
        return returnVal;
    }

    // Round by certain rules
    // rule can be: 7, 7.5.
    // if 7: 1.7 => 2, 1.69 => 1
    this.roundX = roundX;
    function roundX(n,rule) {
        var n1 = parseFloat(n)*10;
        var nS = n1.toString();
        var nC = parseFloat(nS[1]);
        if (nC >= parseFloat(rule)) return Math.ceil(parseFloat(n));
        return Math.floor(parseFloat(n));
    }
}

//===================================================================
// DESC:    Range box
//===================================================================
function normRangeCalc(yMax,y2,y1) {

    if (y1 > yMax) {
        return { y2: 0, y1: 0, height: 0, offset: 0 };
    }
    if (y2 > yMax) {
        var height = yMax - y1;
        return { y2: yMax, y1: y1, height: height, offset: 0 };
    }

    var height = y2 - y1;
    var offset = yMax - y2;
    return { y2: y2, y1: y1, height: height, offset: offset };
}

//===================================================================
// DESC:    Erase a drawn line
//===================================================================
function resetRun(color) {
    ThyrosimGraph.setRun(color,undefined);
    graphAll();
}

//===================================================================
// DESC:    Select the next run color. Since we only have 2 colors, this works.
//===================================================================
function runRadioNext() {
    var runRadio = $('input[name=runRadio]');
    if (runRadio[0].checked == true) {
        runRadio[1].checked = true;
    } else {
        runRadio[0].checked = true;
    }
}

//========================================================================
// TASK:    Functions for UI interactions and animations.
//========================================================================

var animeObj = new animation();

//===================================================================
// DESC:    Create an input and append to footer.
// ARGS:
//   title: Title of the input, e.g., "T4-Oral"
//===================================================================
function addInput(title) {

    var iNum = getNextInputNum(); // Next input number
    var rowN = getRowClass(iNum); // Next input span row class
    var footer = "#footer-input"; // Input container div id

    // Create a new input span object
    var span = $(document.createElement('span')).attr({id:'input-'+iNum});
    span.addClass(rowN).addClass("inputcontainer");

    //---------------------------------------------------------
    // Append the new input span to the end of footer
    //---------------------------------------------------------
    var pit = parseInputTitle(title);
    if (pit.type == "Oral")     span.append(    OralInput(pit,iNum));
    if (pit.type == "IV")       span.append( IVPulseInput(pit,iNum));
    if (pit.type == "Infusion") span.append(InfusionInput(pit,iNum));

    span.append(addDeleteIcon(iNum));
    span.appendTo(footer);

    // Show/Hide animating gifs. 3200 ms because each gif has 8 frames and each
    // frame is 0.4 seconds.
    var aCat = animeObj.getAnimationCat(pit.type);
    var aEle = animeObj.getAnimationEle(pit.type,pit.hormone);
    var id   = animeObj.showAnimation(aCat,aEle);
    setTimeout(function() {animeObj.hideAnimation(aCat,id)},3200);
}

//===================================================================
// DESC:    Generate html for a repeating/single oral dose.
// ARGS:
//   pit:   A parseInputTitle object
//   n:     The input number
//===================================================================
function OralInput(pit,n) {
    return '<img src="'+pit.src+'" class="inputimg" />'

         + '<span class="inputs" id="label-'+n+'" name="label-'+n+'">'
         + '  Input '+n+' ('+pit.hormone+'-'+pit.type+'):'
         + '</span>'
         + '<br />'

         + '<input type="hidden" class="inputs" id="hormone-'+n+'"'
         + '       name="hormone-'+n+'" value="'+pit.hormoneId +'" />'
         + '<input type="hidden" class="inputs" id="type-'   +n+'"'
         + '       name="type-'   +n+'" value="'+pit.typeId    +'" />'

         + addEnable(n)

         + 'Dose: '
         + '<input size="5" class="inputs" type="text"'
         + '       id="dose-'+n+'" name="dose-'+n+'" /> \u03BCg'
         + '      '

         + 'Dosing Interval: '
         + '<input size="5" class="inputs" type="text"'
         + '       id="int-'+n+'" name="int-'+n+'" /> Days'
         + '      '

         + '<input class="inputs" type="checkbox" value="1"'
         + '       id="singledose-'+n+'" name="singledose-'+n+'"'
         + '       onclick="useSingleDose('+n+');" /> Single Dose'
         + '<br />'

         + '                        '
         + 'Start Day: '
         + '<input size="5" class="inputs" type="text"'
         + '       id="start-'+n+'" name="start-'+n+'" />'
         + '      '

         + 'End Day: '
         + '<input size="5" class="inputs" type="text"'
         + '       id="end-'+n+'" name="end-'+n+'" />'

         + '';
}

//===================================================================
// DESC:    Generate html for an IV pulse dose.
// ARGS:
//   pit:   A parseInputTitle object
//   n:     The input number
//===================================================================
function IVPulseInput(pit,n) {
    return '<img src="'+pit.src+'" class="inputimg" />'

         + '<span class="inputs" id="label-'+n+'" name="label-'+n+'">'
         + '  Input '+n+' ('+pit.hormone+'-'+pit.type+'):'
         + '</span>'
         + '<br />'

         + '<input type="hidden" class="inputs" id="hormone-'+n+'"'
         + '       name="hormone-'+n+'" value="'+pit.hormoneId +'" />'
         + '<input type="hidden" class="inputs" id="type-'   +n+'"'
         + '       name="type-'   +n+'" value="'+pit.typeId    +'" />'

         + addEnable(n)

         + 'Dose: '
         + '<input size="5" class="inputs" type="text"'
         + '       id="dose-'+n+'" name="dose-'+n+'" /> \u03BCg'
         + '      '

         + 'Start Day: '
         + '<input size="5" class="inputs" type="text"'
         + '       id="start-'+n+'" name="start-'+n+'" />'

         + '';
}

//===================================================================
// DESC:    Generate html for a constant infusion dose.
// ARGS:
//   pit:   A parseInputTitle object
//   n:     The input number
//===================================================================
function InfusionInput(pit,n) {
    return '<img src="'+pit.src+'" class="inputimg" />'

         + '<span class="inputs" id="label-'+n+'" name="label-'+n+'">'
         + '  Input '+n+' ('+pit.hormone+'-'+pit.type+'):'
         + '</span>'
         + '<br />'

         + '<input type="hidden" class="inputs" id="hormone-'+n+'"'
         + '       name="hormone-'+n+'" value="'+pit.hormoneId +'" />'
         + '<input type="hidden" class="inputs" id="type-'   +n+'"'
         + '       name="type-'   +n+'" value="'+pit.typeId    +'" />'

         + addEnable(n)

         + 'Dose: '
         + '<input size="5" class="inputs" type="text"'
         + '       id="dose-'+n+'" name="dose-'+n+'" /> \u03BCg/day'
         + '      '

         + 'Start Day: '
         + '<input size="5" class="inputs" type="text"'
         + '       id="start-'+n+'" name="start-'+n+'" />'
         + '      '

         + 'End Day: '
         + '<input size="5" class="inputs" type="text"'
         + '       id="end-'+n+'" name="end-'+n+'" />'

         + '';
}

//===================================================================
// DESC:    Delete an input and rename remaining input ids to be continuous.
// ARGS:
//   n:     The input number
//===================================================================
function deleteInput(n) {

    n = parseInt(n); // Treat as integer

    // Get the number of inputs before this deletion
    var end = $('#footer-input').children().length;

    // Delete the input element
    $('#input-'+n).remove();

    //---------------------------------------------------------
    // Outer loop.
    // Loop through all inputs whose n > the deleted one's
    //---------------------------------------------------------
    for (var i = n + 1; i <= end; i++) {

        var j = parseInt(i-1); // New num

        //---------------------------------------------------------
        // Inner loop.
        // Loop through the children of an inputcontainer. Find children with
        // class 'inputs' and rename attributes: id, name.
        //---------------------------------------------------------
        $('#input-'+i).children('.inputs').each(function() {
            var child = $(this);

            // Rename by subtracting the number by one, ie:
            // input-3 => input-2
            var pin = parseInputName(child.attr('name'));
            child.attr('id'  ,pin[0]+'-'+j);
            child.attr('name',pin[0]+'-'+j);

            //---------------------------------------------------------
            // By this point, ids and names of elements have been renamed, but a
            // few special cases remain.
            //---------------------------------------------------------

            // The element with name 'label-X' contains a brief description of
            // what this input is. Change text that says 'Input X (type)'
            if (child.attr('name').match(/label/)) {
                child.text(child.text().replace(/Input \d+/,"Input "+j));
            }

            // The element with id/name 'enabled-X' or 'singledose-X' contain a
            // javascript argument that need to be changed.
            if (child.attr('name').match(/enabled|singledose/)) {
                child.attr('onclick',child.attr('onclick').replace(/\d+/,j));
            }

            // The delete button has name 'delete-X'. Change the javascript
            // argument in name 'href'.
            if (child.attr('name').match(/delete/)) {
                child.attr('href',child.attr('href').replace(/\d+/,j));
            }
        }); // Inner loop end.

        // Change the row colors
        $("#input-"+i).removeClass("row0 row1");
        $("#input-"+i).addClass(getRowClass(j));

        // Rename the inputcontainer's span id at the end
        $("#input-"+i).attr('id','input-'+j);

    } // Outer loop end.
}

//===================================================================
// DESC:    Given an input id/name, parse it and build an object.
// ARGS:
//   name:  Input id/name, e.g., "label-1"
// NOTE:    Return object customarily called 'pin'.
//===================================================================
function parseInputName(name) {
    return name.split("-");
}

//===================================================================
// DESC:    Given an input title, parse it and build an object.
// ARGS:
//   title: Input title, e.g., "T4-Oral"
// NOTE:    Return object customarily called 'pit'.
//===================================================================
function parseInputTitle(title) {
    var split = title.split("-");
    var o = {
        hormone:   split[0],                 // T4 or T3
        hormoneId: split[0].replace("T",""), // 4 or 3
        type:      split[1],                 // Oral/IV/Infusion
        typeId:    getInputTypeId(split[1]), // See the function
        src:       getInputImgSrc(title)     // Image src
    };
    return o;
}

//===================================================================
// DESC:    Given an input type, return corresponding type id.
// ARGS:
//   type:  Input type, e.g., Oral/IV/Infusion
//===================================================================
function getInputTypeId(type) {
    if (type == "Oral")     return 1;
    if (type == "IV")       return 2;
    if (type == "Infusion") return 3;
}

//===================================================================
// DESC:    Given an input title, return image source.
// ARGS:
//   title: Input title, e.g., "T4-Oral"
//===================================================================
function getInputImgSrc(title) {
    if (title == "T3-Oral")     return '../img/pill1.png';
    if (title == "T3-IV")       return '../img/syringe1.png';
    if (title == "T3-Infusion") return '../img/infusion1.png';
    if (title == "T4-Oral")     return '../img/pill2.png';
    if (title == "T4-IV")       return '../img/syringe2.png';
    if (title == "T4-Infusion") return '../img/infusion2.png';
}

//===================================================================
// DESC:    Count the number of input spans and add 1. This is the number the
//          next input should have. Input numbers start at 1.
//===================================================================
function getNextInputNum() {
    return $("#footer-input").children().length + 1;
}

//===================================================================
// DESC:    Determine row color based on position.
// ARGS:
//   n:     A number indicating the element is in the nth position
//===================================================================
function getRowClass(n) {
    return 'row' + n % 2;
}

//===================================================================
// DESC:    Add a clickable enable/disable input box. The button initializes as
//          enabled. A hidden input named "disabled-X" is used to store whether
//          the input is enabled/disabled. Value of 1 means disabled and value
//          of 0 means enabled.
// ARGS:
//   n:     The input number
//===================================================================
function addEnable(n) {
    return '<span title="Click to disable input"'
         + '      class="bank-left enaInput enDisInput inputs unselectable"'
         + '      id="enabled-'+n+'" name="enabled-'+n+'"'
         + '      onclick="enDisInput('+n+');">'
         + 'ENABLED'
         + '</span>'
         + '    '
         + '<input type="hidden" class="inputs" id="disabled-'+n+'"'
         + '       name="disabled-'+n+'" value="0">'
         + '';
}

//===================================================================
// DESC:    Add x.png so that it can be used to delete an input.
// ARGS:
//   n:     The input number
//===================================================================
function addDeleteIcon(n) {
    return '<a class="img-input inputs"'
         + '   name="delete-'+n+'" href="javascript:deleteInput('+n+');">'
         + '  <img class="bank-right delete-icon"'
         + '       src="../img/x.png" alt="Delete this input">'
         + '</a>'
         + '';
}

//===================================================================
// DESC:    Detect value in element enabled-X/disabled-X and change them:
//          1. When input is enabled
//            a. "enabled-X"'s text changes to "disabled"
//            b. "disabled-X"'s value changes to 1
//          2. When input is disabled: opposite of the above
// ARGS:
//   n:     The input number
//===================================================================
function enDisInput(n) {
    var ena = $('#enabled-' +n);
    var dis = $('#disabled-'+n);
    // Disable an input
    if (ena.hasClass('enaInput')) {
        ena.removeClass('enaInput').addClass('disInput');
        ena.attr('title','Click to enable input');
        ena.text('DISABLED');
        dis.attr('value','1');
        // Gray out this input's other input boxes
        $('#input-'+n).children('.inputs').each(function() {
            $(this).attr('disabled',true);
        });
    // Enable an input
    } else {
        ena.removeClass('disInput').addClass('enaInput');
        ena.text('ENABLED');
        ena.attr('title','Click to disable input');
        dis.attr('value','0');
        // Un-gray out this input's other input boxes
        $('#input-'+n).children('.inputs').each(function() {
            var child = $(this);
            // Remove the 'disabled' attribute unless "Single Dose" is checked
            var sd = $('input[name="singledose-'+n+'"]:checked').length > 0;
            if ((sd && (child.attr('id') == 'int-'+n)) ||
                (sd && (child.attr('id') == 'end-'+n)) ) {
                // Do nothing here
            } else {
                child.attr('disabled',false);
            }
        });
    }
}

//===================================================================
// DESC:    Tell the oral input to use only a single dose. In addition:
//          1. Gray out the "Dosing Interval" and "End Day" inputs.
//          2. Fill "Dosing Interval" and "End Day" with a "0" if blank.
// ARGS:
//   n:     The input number
//===================================================================
function useSingleDose(n) {
    var isChecked = $('input[name="singledose-'+n+'"]:checked').length > 0;
    var endE = $('#end-'+n); // E for element
    var intE = $('#int-'+n);
    if (isChecked) {
        endE.prop('disabled',true); // Gray out input boxes
        intE.prop('disabled',true);
        if (!endE.attr('value')) endE.attr('value','0'); // Fill with 0
        if (!intE.attr('value')) intE.attr('value','0');
    } else {
        endE.prop('disabled',false);
        intE.prop('disabled',false);
    }
}

//===================================================================
// DESC:    Show/Hide the scroll bars for secretion/absorption adjustment.
//===================================================================
function showhidescrollbars() {
    $('.slidercontainer').toggle("blind",function() {
        if ($(".slidercontainer").css("display") == "none") {
            $("#showhidescrollbar").attr("src","../img/plus.png")
                                   .attr("alt","show scroll bars");
        } else {
            $("#showhidescrollbar").attr("src","../img/minus.png")
                                   .attr("alt","hide scroll bars");
        }
    });
}

//===================================================================
// DESC:    Highlight or un-highlight the corresponding black dot in the diagram
//          when mousing over a T4/3 secretion/absorption edit box.
//===================================================================
function hilite(id) {
    $('#hilite'+id).css("display","block");
}
function lolite(id) {
    $('#hilite'+id).css("display","none");
}

//===================================================================
// DESC:    Animation manager.
//===================================================================
function animation() {

    // Define animation element ids based on hormone and type here
    // hormones: T3/T4, types: Oral/IV/Infusion, cat: category
    var element = {
        Oral:     { T3: 'spill1',  T4: 'spill2',  cat: 'spill'  },
        IV:       { T3: 'inject1', T4: 'inject2', cat: 'inject' },
        Infusion: { T3: 'infuse1', T4: 'infuse2', cat: 'infuse' }
    };
    this.element = element;

    //---------------------------------------------------------
    // 1. Create a container div and append an image (animation) in it. Then,
    //    append the container div to #diagram.
    // 2. The image src has a '?+id', this is so browsers are forced to reload
    //    the image. Otherwise, the browser uses a cached image and the
    //    animation will appear out of sync.
    // 3. Animation positions are defined in thyrosim.css under the category's
    //    name.
    //---------------------------------------------------------
    this.showAnimation = showAnimation;
    function showAnimation(cat,ele) {
        var id = new Date().getTime().toString();
        var div = $('<div>').attr({
                                'id'    : cat+'-'+id, // spill-12345
                                'class' : 'imgcontainer '+cat // spill
                               })
                            .appendTo('#diagram');
        var img = $('<img>').attr({
                                'id'    : cat+'img-'+id, // spillimg-12345
                                'src'   : '../img/'+ele+'.gif?'+id
                               })
                            .appendTo(div);
        return id;
    }

    //---------------------------------------------------------
    // Remove the container div ('hiding' the image)
    //---------------------------------------------------------
    this.hideAnimation = hideAnimation;
    function hideAnimation(cat,id) {
        $('#'+cat+'-'+id).remove();
    }

    //---------------------------------------------------------
    // For a given hormone and input type, get the file name
    //---------------------------------------------------------
    this.getAnimationEle = getAnimationEle;
    function getAnimationEle(type,hormone) {
        return this.element[type][hormone];
    }

    //---------------------------------------------------------
    // Get the animation category for the input type
    //---------------------------------------------------------
    this.getAnimationCat = getAnimationCat;
    function getAnimationCat(type) {
        return this.element[type]['cat'];
    }
}

//===================================================================
// DESC:    Define sliders and tie slider values to dial input values.
//===================================================================
var sliderObj = {
    // T4 Secretion
    '1': { 'range' : 'min',
           'value' : 100,
           'min'   : 0,
           'max'   : 200 },
    // T4 Absorption
    '2': { 'range' : 'min',
           'value' : 88,
           'min'   : 0,
           'max'   : 100 },
    // T3 Secretion
    '3': { 'range' : 'min',
           'value' : 100,
           'min'   : 0,
           'max'   : 200 },
    // T3 Absorption
    '4': { 'range' : 'min',
           'value' : 88,
           'min'   : 0,
           'max'   : 100 }
};

//===================================================================
// DESC:    Function to show/hide list of hormone input icons.
//===================================================================
function show_hide(H) {
    $('#'+H+'input').toggle("blind");
}

//===================================================================
// DESC:    Function to show/hide navbar divs.
//===================================================================
function clickInfoButton(id) {
    if ($('#button-'+id).hasClass('infoButton-clicked')) {
        $('#button-'+id).removeClass('infoButton-clicked');
        $('#link-'+id).removeClass('color-white');
        $('#link-'+id).addClass('color-black');
    } else {
        $('#button-'+id).addClass('infoButton-clicked');
        $('#link-'+id).removeClass('color-black');
        $('#link-'+id).addClass('color-white');
    }
}

//===================================================================
// DESC:    Function to toggle free hormone graph divs.
//===================================================================
function togFreeHormoneButton() {
    if ($('#FT4graph').hasClass('displaynone')) {
        $('#FT4graph').removeClass('displaynone');
        $('#FT3graph').removeClass('displaynone');
        $('#T4graph').addClass('displaynone');
        $('#T3graph').addClass('displaynone');
    } else {
        $('#FT4graph').addClass('displaynone');
        $('#FT3graph').addClass('displaynone');
        $('#T4graph').removeClass('displaynone');
        $('#T3graph').removeClass('displaynone');
    }
}

//===================================================================
// DESC:    Function to toggle parameter list on and off.
//===================================================================
function togParamListButton() {
    if ($('#parameditdiv').hasClass('displaynone')) {
        $('#parameditdiv').removeClass('displaynone');
    } else {
        $('#parameditdiv').addClass('displaynone');
    }
}

//===================================================================
// DESC:    jQuery $(document).ready() functions.
//===================================================================
$(function() {

    $(document).tooltip(); // Required for jQuery UI tooltips
    graphAll();            // Initialize graphs

    // Initialize slider objects
    $.each(sliderObj,function(k,o) {
        var s = '#slider'+k;
        var d = '#dialinput'+k;
        $(s).slider({
            range: o.range,
            value: o.value,
            min:   o.min,
            max:   o.max,
            // Change dialinput's value to match slider's value
            slide: function(event,ui) { $(d).val(ui.value); }
        });
        // Set defaultValue property
        $(d).prop('defaultValue',$(s).slider('value'));
        // Changes slider value when changing dialinput
        $(d).change(function() {
            $(s).slider('value',this.value);
        });
    });
});

//===================================================================
// Section
//===================================================================
//---------------------------------------------------------
// Sub-section
//---------------------------------------------------------

