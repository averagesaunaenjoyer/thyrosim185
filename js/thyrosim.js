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

    // Needed variables
    var msgBoxId = getMsgBoxId();

    // Display loading message
    showLoadingMsg(msgBoxId);

    //---------------------------------------------------------
    // Validate form
    //---------------------------------------------------------
    var hasFormError = validateForm();
    if (hasFormError) {
        hideLoadingMsg(msgBoxId);
        return false;
    }

    //---------------------------------------------------------
    // Generate form data for processing server side. For specific experiments,
    // return a predefined string. Otherwise serialize form inputs.
    //---------------------------------------------------------
    var formdata;
    if (exp) {
        formdata = getExperimentStr(exp);
        executeExperiment(exp);
    } else {
        formdata = $("form").serialize();
    }

    //---------------------------------------------------------
    // Submit to server and process response
    //---------------------------------------------------------
    var start = new Date().getTime();
    $.post( "ajax_getplot.cgi", { data: formdata })
      .done(function( data ) {

        // Graph results from this run
        var rdata = jQuery.parseJSON(data); // Run data
        var color = $('input:radio[name=runRadio]:checked').val();
        ThyrosimGraph.setRun(color,rdata);
        graphAll();

        // Finish up
        hideLoadingMsg(msgBoxId); // Hide loading message
        var end = new Date().getTime();
        var time = Math.floor((end - start)/1000);
        alert('Execution time (sec): '+time);
        runRadioNext();
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
    // correctly, the pop-up when hovering over graph values does not update.
}

//===================================================================
// DESC:    While the ajax call is running, display a 'wait' message box.
//          Depending on dial values and whether recalculate IC is checked, the
//          message is different. The message box follows the cursor. This
//          function returns the id of the selected message.
//===================================================================
function getMsgBoxId() {
    var s = '#dialinput';
    if ($(s+'1').prop('defaultValue') == $(s+'1').prop('value') &&
        $(s+'2').prop('defaultValue') == $(s+'2').prop('value') &&
        $(s+'3').prop('defaultValue') == $(s+'3').prop('value') &&
        $(s+'4').prop('defaultValue') == $(s+'4').prop('value')) {
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

    // For inputs, look at the "End Day" and update simulation time
    // with the highest "End Day"
    $.each($("form").serializeArray(), function(i, field) {
        if (field.name.match(/^end-/)) {
            if (parseFloat(field.value) > parseFloat($("#simtime").val())) {
                $("#simtime").val(field.value);
            }
        }
    });

    // Make sure simulation time is <100 days
    if ($('#simtime').prop('value') > 100) {
        $('#simtime').addClass('error');
        fail = 1;
    }
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
// DESC:    Change the UI to match the experiment ran.
// ARGS:
//   exp:   The experiment name
//===================================================================
function executeExperiment(exp) {
    // Clear the input space
    $('#footer-input').empty();

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
    var parsedID = $('#footer-input').children().last().attr('id').split("-");
    var idNum = parsedID[1];
    $('#dose-' + idNum).val(dose);
    $('#int-'  + idNum).val(interval);
    $('#start-'+ idNum).val(start);
    $('#end-'  + idNum).val(end);
    if (singledose) {
        $('#singledose-'+idNum).prop('checked', true);
        useSingleDose(idNum);
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
    // Note that ymin values are rounded up by the largest digit. See
    // getEndVal().
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
            unit: '\u03BCg/L',
            ymin: { Thyrosim: 110, ThyrosimJr: 110 },
            bounds: {
                Thyrosim:   { lo: 45, hi: 105 },
                ThyrosimJr: { lo: 45, hi: 105 },
            }
        },
        T3: {
            comp: '4',
            unit: '\u03BCg/L',
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

    // Get the "End" value by increasing the largest digit by 1
    // 1.1 => 2
    // 1.9 => 3
    // 9.9 => 11
    // 12.1 => 13
    // 20 => 30
    // 90 => 100
    // 99 => 110
    // 100 => 110
    // 500 => 510
    // 900 => 910
    // 1000 => 1100
    // 1100 => 1200
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
//   name:  Name of the input, e.g., "T4-Oral".
//===================================================================
function addInput(name) {

    var nextId = getNextInputId();    // Next input span id
    var rClass = getRowClass(nextId); // Next input span row class
    var footer = "#footer-input";     // Input container div id

    // Create a new input span object
    var span = $(document.createElement('span')).attr({id:'input-'+nextId});
    span.addClass(rClass).addClass("inputcontainer");

    //---------------------------------------------------------
    // Append the new input span to the end of footer
    //---------------------------------------------------------
    var input = parseInputName(name);
    if (input.type == "Oral")     span.append(    OralInput(input,nextId));
    if (input.type == "IV")       span.append( IVPulseInput(input,nextId));
    if (input.type == "Infusion") span.append(InfusionInput(input,nextId));

    span.append(addDeleteIcon("input-" + nextId), "<br />");
    span.appendTo(footer);

    // Show/Hide animating gifs. 3200 ms because each gif has 8 frames and each
    // frame is 0.4 seconds.
    var aCat = animeObj.getAnimationCat(input.type);
    var aEle = animeObj.getAnimationEle(input.type,input.hormone);
    var id   = animeObj.showAnimation(aCat,aEle);
    setTimeout(function() {animeObj.hideAnimation(aCat,id)},3200);
}

//===================================================================
// DESC:    Generate html for a repeating/single oral dose.
// ARGS:
//   parsed:    An input object
//   id:        The number the input should have
//===================================================================
function mytest(id) {
//$('<input/>').attr({ type: 'text', id: 'test', name: 'test'}).appendTo('#form');
}
function OralInput(parsed,id) {
    return '<span class="inputs" id="label-' + id + '" name="label-' + id + '">Input ' + id + ' (' + parsed.hormone + '-' + parsed.type + '):</span><br />'
         + '<input type="hidden" class="inputs" name="hormone-' + id + '"id="hormone-' + id + '" value="' + parsed.hormoneId + '" />'
         + '<input type="hidden" class="inputs" name="type-' + id + '"id="type-' + id + '" value="' + parsed.typeId + '" />'
         + addEnable(id)
         + 'Dose: <input size="5" class="inputs" type="text" id="dose-' + id + '" name="dose-' + id + '" /> \u03BCg' + '&nbsp&nbsp&nbsp&nbsp&nbsp'
         + 'Dosing Interval: <input size="5" class="inputs" type="text" id="int-' + id + '" name="int-' + id + '" /> Days' + '&nbsp&nbsp&nbsp&nbsp&nbsp'
         + '<input class="inputs" type="checkbox" value="1" id="singledose-' + id + '" name="singledose-' + id + '" onclick="javascript:useSingleDose(\'' + id + '\')" /> Single Dose<br />'
         + 'Start Day: <input size="5" class="inputs" type="text" id="start-' + id + '" name="start-' + id + '" />' + '&nbsp&nbsp&nbsp&nbsp&nbsp'
         + 'End Day: <input size="5" class="inputs" type="text" id="end-' + id + '" name="end-' + id + '" />' + '&nbsp&nbsp&nbsp&nbsp&nbsp';
}

//--------------------------------------------------
// Input for IV pulse dose
// It is expected to have dose and start day
//-------------------------------------------------- 
function IVPulseInput(parsed,id) {
    return '<span class="inputs" id="label-' + id + '" name="label-' + id +'">Input ' + id + ' (' + parsed.hormone + '-' + parsed.type + '):</span><br />'
         + '<input type="hidden" class="inputs" name="hormone-' + id + '"id="hormone-' + id + '" value="' + parsed.hormoneId + '" />'
         + '<input type="hidden" class="inputs" name="type-' + id + '"id="type-' + id + '" value="' + parsed.typeId + '" />'
         + addEnable(id)
         + 'Dose: <input size="5" class="inputs" type="text" id="dose-' + id + '" name="dose-' + id + '" /> \u03BCg' + '&nbsp&nbsp&nbsp&nbsp&nbsp'
         + 'Start Day: <input size="5" class="inputs" type="text" id="start-' + id + '" name="start-' + id + '" />' + '&nbsp&nbsp&nbsp&nbsp&nbsp';
}

//--------------------------------------------------
// Input for constant infusion
// It is expected to have dose per day, start, and end days
//-------------------------------------------------- 
function InfusionInput(parsed,id) {
    return '<span class="inputs" id="label-' + id + '" name="label-' + id +'">Input ' + id + ' (' + parsed.hormone + '-' + parsed.type + '):</span><br />'
         + '<input type="hidden" class="inputs" name="hormone-' + id + '"id="hormone-' + id + '" value="' + parsed.hormoneId + '" />'
         + '<input type="hidden" class="inputs" name="type-' + id + '"id="type-' + id + '" value="' + parsed.typeId + '" />'
         + addEnable(id)
         + 'Dose: <input size="5" class="inputs" type="text" id="dose-' + id + '" name="dose-' + id + '" /> \u03BCg/day' + '&nbsp&nbsp&nbsp&nbsp&nbsp'
         + 'Start Day: <input size="5" class="inputs" type="text" id="start-' + id + '"name="start-' + id + '" />' + '&nbsp&nbsp&nbsp&nbsp&nbsp'
         + 'End Day: <input size="5" class="inputs" type="text" id="end-' + id + '" name="end-' + id + '" />' + '&nbsp&nbsp&nbsp&nbsp&nbsp';
}

//--------------------------------------------------
// This function deletes an input. If the input is in the middle of the list,
// then rename all the ids to be continuous.
//-------------------------------------------------- 
function deleteInput(id) {

    //--------------------------------------------------
    // Loop through the children of #footer-input to build
    // a list of existing inputs.
    //-------------------------------------------------- 
    var allInputs = new Array;
    $("#footer-input").children().each(function() {
        var child = $(this);

        // attr id is in the form: input-X
        // [0] is 'input'; [1] is the number
        var parsedID = child.attr('id').split("-");
        allInputs.push(parsedID[1]);
    });

    // Delete the input element
    $('#'+id).remove();

    //--------------------------------------------------
    // Outer loop.
    // Loop through all inputs whose numbers > the deleted one
    //-------------------------------------------------- 
    var delParsedID = id.split("-");
    var start       = parseInt(delParsedID[1]);

    for (var i=start;i<allInputs.length;i++) {
        //--------------------------------------------------
        // Inner loop.
        // Loop through the children of an input.
        // Find children with class 'inputs', and rename attributes.
        // Attributes to rename: id and name
        //-------------------------------------------------- 
        $('#'+delParsedID[0]+'-'+allInputs[i]).children('.inputs')
        .each(function(key, value) {
            var child = $(this);

            // Rename by subtracting the number by one, ie:
            // input-3 => input-2
            var parsed = parseInput(child.attr('name'));
            child.attr('id'  ,parsed[0]+'-'+parseInt(parsed[1]-1));
            child.attr('name',parsed[0]+'-'+parseInt(parsed[1]-1));

            //--------------------------------------------------
            // By this point, all names of elements have been renamed, but a
            // few special cases remain.
            //-------------------------------------------------- 

            // The element with name 'label-X' contains a brief description of
            // what this input is. Change text that says 'Input X (type)'
            if (child.attr('name').match(/label/)) {
                var text = child.text();
                text = text.replace(/Input \d+/,
                                    "Input " + parseInt(parsed[1]-1));
                child.text(text);
            }

            // The element with id/name 'enabled-X' contains a javascript
            // argument that needs to be changed.
            if (child.attr('name').match(/enabled/)) {
                var text = child.attr('onClick');
                text = text.replace(/\(.*\)/,
                                    "('" + parseInt(parsed[1]-1)+"')");
                child.attr('onClick',text);
            }

            // The delete button has name 'delete-X'. Change the javascript
            // argument in name 'href'.
            if (child.attr('name').match(/delete/)) {
                var text = child.attr('href');
                text = text.replace(/\(.*\)/,
                                    "('input-" + parseInt(parsed[1]-1)+"')");
                child.attr('href',text);
            }

            // The checkbox with id/name 'singledose-X' contains a javascript
            // argument that needs to be changed.
            if (child.attr('name').match(/singledose/)) {
                var text = child.attr('onClick');
                text = text.replace(/\(.*\)/,
                                    "('" + parseInt(parsed[1]-1)+"')");
                child.attr('onClick',text);
            }
        }); // Inner loop end.

        // All child elements of input span fixed? Fix the row colors.
        var rowColor = $("#"+delParsedID[0]+'-'+allInputs[i]).attr('class');
        rowColor = (rowColor == "row0" ? "row1" : "row0");
        $("#"+delParsedID[0]+'-'+allInputs[i]).attr('class',rowColor);

        // Finally, let's fix the input span id.
        $("#"+delParsedID[0]+'-'+allInputs[i])
        .attr('id',delParsedID[0]+'-'+parseInt(allInputs[i]-1));
    } // Outer loop end.
}

//===================================================================
// DESC:    Given an input name, parse it and build an object
// ARGS:
//   name:  Name of the input, e.g., "T4-Oral".
//===================================================================
function parseInputName(name) {
    var split = name.split("-");
    var o = {
        hormone:   split[0],                 // T4 or T3
        hormoneId: split[0].replace("T",""), // 4 or 3
        type:      split[1],                 // Oral/IV/Infusion
        typeId:    getInputTypeId(split[1])  // See the function
    };
    return o;
}

//===================================================================
// DESC:    Given an input type, return corresponding type id.
// ARGS:
//   type:  Type of input, Oral/IV/Infusion
//===================================================================
function getInputTypeId(type) {
    if (type == "Oral")     return 1;
    if (type == "IV")       return 2;
    if (type == "Infusion") return 3;
}

//--------------------------------------------------
// Parses inputtype type and returns an object with the hormone (T3/T4)
// and type (pill, iv dose, infusion).
// Hormone name and type are converted to an ID to facilitate passing and
// processing on server-side.
// T3 => 3, T4 => 4, Oral => 1, IV => 2, Infusion => 3
//-------------------------------------------------- 
function parseInput(type) {
    var inputSplit = type.split("-");
    var hormoneID  = inputSplit[0].replace("T","");

    var typeID;
    if (inputSplit[1] == "Oral") {
        typeID = 1;
    } else if (inputSplit[1] == "IV") {
        typeID = 2;
    } else if (inputSplit[1] == "Infusion") {
        typeID = 3;
    } else {
    }

    var inputFields = {
        TH   : inputSplit[0], // hormone
        type : inputSplit[1], // type
        ID   : hormoneID,     // hormoneId
        tID  : typeID         // typeId
    };

    // Secondary function: save the split values in an array. This function is
    // called in other places where it is more sensible to use the index.
    inputFields[0] = inputSplit[0];
    inputFields[1] = inputSplit[1];

    return inputFields;
}

//===================================================================
// DESC:    Count the number of input spans and add 1. That is the id the next
//          input should have. Input ids start at 1.
//===================================================================
function getNextInputId() {
    return $("#footer-input").children().length + 1;
}

//===================================================================
// DESC:    Determine row color based on position.
// ARGS:
//   n:     a number indicating the element is in the nth position.
//===================================================================
function getRowClass(n) {
    return 'row' + n % 2;
}

//--------------------------------------------------
// Adds a clickable enable/disable input box
// Button initializes as enabled. A hidden input named
// "disabled-X" is used to store whether the input is enabled/disabled.
// value of 1 means disabled and value of 0 means enabled.
//-------------------------------------------------- 
function addEnable(id) {
    var enable = "<span title=\"Click to disable input\" class=\"enabledInput inputs unselectable\" id=\"enabled-" + id + "\" name=\"enabled-" + id + "\" onClick=\"javascript:enDisInput(\'" + id + "\')\">"
  + "ENABLED</span>&nbsp&nbsp&nbsp&nbsp&nbsp"
  + "<input type=\"hidden\" class=\"inputs\" id=\"disabled-" + id + "\" name=\"disabled-" + id + "\" value=\"0\">";
    return enable;
}

//--------------------------------------------------
// Adds x.png so that it can be used to delete an input
//-------------------------------------------------- 
function addDeleteIcon(id) {
    var parsed = parseInput(id);
    var delImg = "<a class=\"img-input bank-right inputs\" name=\"delete-" + parsed[1] + "\" href=\"javascript:deleteInput(\'" + id + "\')\">"
  + "<img src=\"../img/x.png\" alt=\"Delete this input\" /></a>";
    return delImg;
}

//--------------------------------------------------
// Detects the current value in element named "enabled-X" and
// "disabled-X" and change them. If function is called while an
// input is enabled, then "enabled-X"'s text changes to "disabled"
// and "disabled-X"'s value changes to 1. Opposite occurs if the
// function is called while an input is disabled.
//-------------------------------------------------- 
function enDisInput(id) {
    var enabled  = $('#enabled-'  + id);
    var disabled = $('#disabled-' + id);
    // Disable an input
    if (enabled.attr('class') == "enabledInput inputs unselectable") {
        enabled.attr('class','disabledInput inputs unselectable');
        enabled.attr('title','Click to enable input');
        enabled.text('DISABLED');
        disabled.attr('value','1');
        // Gray out this input's other input boxes
        $('#input-'+id).children('.inputs')
        .each(function(key, value) {
            var child = $(this);
            // Add the 'disabled' attribute
            child.attr('disabled',true);
        });
    // Enable an input
    } else {
        enabled.attr('class','enabledInput inputs unselectable');
        enabled.text('ENABLED');
        enabled.attr('title','Click to disable input');
        disabled.attr('value','0');
        // Un-gray out this input's other input boxes
        $('#input-'+id).children('.inputs')
        .each(function(key, value) {
            var child = $(this);
            // Remove the 'disabled' attribute unless "Single Dose" is checked
            var atLeastOneIsChecked = $('input[name="singledose-' + id + '"]:checked').length > 0;
            if ((atLeastOneIsChecked && (child.attr('id') == 'int-'+id)) ||
                (atLeastOneIsChecked && (child.attr('id') == 'end-'+id)) ) {
                // Do nothing here
            } else {
                child.attr('disabled',false);
            }
        });
    }
}

//===================================================================
// DESC:    Show/Hide the scroll bars for secretion/absorption adjustment.
//===================================================================
function showhidescrollbars() {
    if ($(".slidercontainer").css("display") == "none") {
        $(".slidercontainer").css("display","block");
        $("#showhidescrollbar").attr("src","../img/minus.png")
                               .attr("alt","hide scroll bars");
    } else {
        $(".slidercontainer").css("display","none");
        $("#showhidescrollbar").attr("src","../img/plus.png")
                               .attr("alt","show scroll bars");
    }
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

//--------------------------------------------------
// Tells the oral input to use only a single dose. In addition,
// 1. Gray out the "Dosing Interval" and "End Day" boxes
// 2. Fills "Dosing Interval" and "End Day" with a "0" if blank
//--------------------------------------------------
function useSingleDose(id) {
    var atLeastOneIsChecked = $('input[name="singledose-' + id + '"]:checked').length > 0;
    var endDay         = $('#end-' + id);
    var dosingInterval = $('#int-' + id);
    if (atLeastOneIsChecked) { // If true
        // Gray out "Dosing Interval" and "End Day" boxes
        endDay.prop('disabled',true);
        dosingInterval.prop('disabled',true);
        // Fill value as 0 if blank
        if (!endDay.attr('value')) {
            endDay.attr('value','0');
        }
        if (!dosingInterval.attr('value')) {
            dosingInterval.attr('value','0');
        }
    } else {
        endDay.prop('disabled',false);
        dosingInterval.prop('disabled',false);
    }
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
// DESC:    Required for jQuery UI tooltips.
//===================================================================
$(function() {
    $( document ).tooltip();
});

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
$(function() {
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
// DESC:    Function to show/hide list of hormone input icons.
//===================================================================
function show_hide(H) {
    if($('#'+H+'input').css("display") == "block") {
        $('#'+H+'input').css("display","none");
        $('#'+H+'display').text("Show "+H+" input");
    } else {
        $('#'+H+'input').css("display","block");
        $('#'+H+'display').text("Hide "+H+" input");
    }
}

//===================================================================
// DESC:    Function to show/hide navbar divs.
//===================================================================
function clickInfoButton(id) {
    if ($('#button-'+id).hasClass('infoButton-clicked')) {
        $('#button-'+id).removeClass('infoButton-clicked');
        $('#link-'+id).removeClass('color-white');
    } else {
        $('#button-'+id).addClass('infoButton-clicked');
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
// Section
//===================================================================
//---------------------------------------------------------
// Sub-section
//---------------------------------------------------------

