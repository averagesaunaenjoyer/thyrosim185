//--------------------------------------------------
// FILE:        ajaxfun.js
// AUTHOR:      Simon X. Han
// DESCRIPTION:
//   Functions relating to AJAX will go in here. Currently this involves sending
//   and receiving the request object and graphing related functions.
//--------------------------------------------------

// Required for ajax, so load on file load
var xmlhttp;
if (window.XMLHttpRequest) {
    // code for IE7+, Firefox, Chrome, Opera, Safari
    xmlhttp=new XMLHttpRequest();
} else {
    // code for IE6, IE5
    xmlhttp=new ActiveXObject("Microsoft.XMLHTTP");
}

// Run the server-side script and retrieve plotting data and configurations
// in a JSON data structure
var ThyrosimGraph = new ThyrosimGraph();
function loadXMLDoc(e) {
    var followId = getFollowId();
    startLoading(followId); // shows "loading.gif"

    // Validate form and stop if there are errors
    var nomatch = validateForm();
    if (nomatch) {
        stopLoading(followId);
        return false;
    }

    // Serialize form inputs and inputs are processed server side. JQuery can't
    // convert JS objects to JSON and would require an additional file that I
    // don't want to include.
    var formdata = $("form").serialize();
    // If the user selected to run default behavior, override formdata
    if (e == "TEST") {
      formdata="dialinput1=100&dialinput2=88&dialinput3=100&dialinput4=88&simtime=5&thysim="+$('#thysim').val();
    }

    var start = new Date().getTime();
    // Submit to server and process response
    $.ajax({
        type: "POST",
        url:  "cgi-bin/getplot.cgi",
        data: { data: formdata }
    }).done(function(msg) {
//        alert(msg);
        var responseObj = jQuery.parseJSON(msg);
        var runRadioVal = $('input:radio[name=runRadio]:checked').val();
        ThyrosimGraph.setObj(runRadioVal,responseObj);
        graphthis();
        stopLoading(followId); // hides "loading.gif"
        var end = new Date().getTime();
        var time = Math.floor((end - start)/1000);
        alert('Execution time (sec): '+time);
        runRadioNext();
    });
}

//--------------------------------------------------
// Wrapper to call the graphing function based on the hormone.
// Should be okay because JavaScript passes objects as references.
//--------------------------------------------------
function graphthis() {

    // Create hormone objects
    // Hormone, Compartment, Unit Label, Lower & Upper normal range
    var FT4 = new Hormone("FT4","ft4","ng/L"     ,"8"  ,"17");
    var FT3 = new Hormone("FT3","ft3","ng/L"     ,"2.2","4.4");
    var T4  = new Hormone("T4" ,"1"  ,"\u03BCg/L","45" ,"105");
    var T3  = new Hormone("T3" ,"4"  ,"\u03BCg/L",".6" ,"1.8");
    var TSH = new Hormone("TSH","7"  ,"mU/L"     ,".4" ,"4"  );

    // Need to initialize the graph?
    if (ThyrosimGraph.initGraph) {
        graph(FT4,"" ,"1");
        graph(FT3,"" ,"1");
        graph(T4 ,"" ,"1");
        graph(T3 ,"" ,"1");
        graph(TSH,"1","1");
        ThyrosimGraph.initGraph = false;
    // Plot the graph
    } else {
        graph(FT4,"" );
        graph(FT3,"" );
        graph(T4 ,"" );
        graph(T3 ,"" );
        graph(TSH,"1");
    }
}

//--------------------------------------------------
// d3 line graph
//--------------------------------------------------
//function graph(hormone,comp,unit,addlabel,initgraph) {
function graph(hormoneObj,addlabel,initgraph) {

    var hormone = hormoneObj.hormone;
    var comp = hormoneObj.comp;
    var unit = hormoneObj.unit;
    var eRLo = hormoneObj.lowerBound;
    var eRHi = hormoneObj.upperBound;

    // Graph size
    var w = 350; // width in pixels of the graph
    var h = 130; // height in pixels of the graph

    // Scales
    var xVal = ThyrosimGraph.getXVal(comp);
    var yVal = ThyrosimGraph.getYVal(comp);
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
        $.each(ThyrosimGraph.colors,function(idx,color) {
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
                .style("stroke-dasharray",ThyrosimGraph.lineStyle[color]);

            // Append dummy circle for tooltip
            graph.selectAll("circle.dot"+color)
                .data(data).enter().append("circle")
                .attr("class","dot"+color)
                .attr("fill","none")
                .attr("r",1)
                .attr("cx",function(d,i) {return x(i);})
                .attr("cy",function(d,i) {return y(d);});
        });

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
        $.each(ThyrosimGraph.colors,function(idx,color) {
            // Empty data values
            var valuesD = [0];
            var valuesT = [0];

            // Remove old circles
            graph.select("svg").select("g").selectAll(".dot"+color)
                .data(valuesD).exit().remove();

            if (ThyrosimGraph.checkObjTypeExist(color)) {
                // Real data values
                valuesD = ThyrosimGraph.getObjData(color,comp);
                valuesT = ThyrosimGraph.getObjData(color,"t");
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

    // Turn default range values on by default
    if (initgraph)
        toggleRangeBox();

    d3.select("#togNormRange").on("click",toggleRangeBox);
    d3.select("#thisistemp").on("click",toggleXAxis);
}

//--------------------------------------------------
// While the ajax call is being made, have loading.gif follow the mouse cursor.
// If dialinput values are default, show follow1 message. If not, check whether
// recalculate IC checkbox is checked.
// The +5 offsets the image so that the gif doesn't interfere with clicking. The
// image is hidden at first, so set css to block to show.
// The 'click' event is needed so loading.gif shows up when "Simulate" is
// pressed. Otherwise, loading.gif will only show after the mouse is moved.
//--------------------------------------------------
function getFollowId() {
    var s = '#dialinput';
    if ($(s+'1').prop('defaultValue') == $(s+'1').prop('value') &&
        $(s+'2').prop('defaultValue') == $(s+'2').prop('value') &&
        $(s+'3').prop('defaultValue') == $(s+'3').prop('value') &&
        $(s+'4').prop('defaultValue') == $(s+'4').prop('value')) {
        return 'follow1';
    }
    return $('#recalcIC').prop('checked') ? 'follow2' : 'follow1';
}
function startLoading(fid) {
    $(window).click(function(e){
        $('#'+fid).css('display','block')
                  .css('top',    e.pageY + 5)
                  .css('left',   e.pageX + 5);
    });
    $(window).mousemove(function(e){
        $('#'+fid).css('display','block')
                  .css('top',    e.pageY + 5)
                  .css('left',   e.pageX + 5);
    });
}

//--------------------------------------------------
// After the graph is loaded, unbind the events and hide "Loading" image.
//--------------------------------------------------
function stopLoading(fid) {
    $(window).unbind();
    $('#'+fid).css('display','none');
}

//--------------------------------------------------
// Validate form.
//--------------------------------------------------
function validateForm() {
    var nomatch = 0;

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
        if (field.value.match(/^\+?[0-9]*\.?[0-9]+$/)) {
            $('#'+field.name).removeClass('error');
        } else {
            $('#'+field.name).addClass('error');
            nomatch = 1;
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
        nomatch = 1;
    }
    return nomatch;
}

//--------------------------------------------------------------------
// Hormone object
//--------------------------------------------------------------------
function Hormone(hormone,comp,unit,lowerBound,upperBound) {
    this.hormone = hormone;
    this.comp = comp;
    this.unit = unit;
    this.lowerBound = lowerBound; // These are expected ranges
    this.upperBound = upperBound;
}

//--------------------------------------------------------------------
// Maintain both Blue and Green response objects
//--------------------------------------------------------------------
function ThyrosimGraph() {
    this.initGraph = true;

    // Colors
    var colors = ["Blue","Green"];
    this.colors = colors;

    // Line style
    var lineStyle = {Blue:"",Green:"5,3"};
    this.lineStyle = lineStyle;

    // Objects
    var objs = {Blue:undefined,Green:undefined};
    this.objs = objs;
    var exists = {Blue:false,Green:false};
    this.exists = exists;

    // Sets an obj
    this.setObj = setObj;
    function setObj(type,responseObj) {
        this.objs[type] = responseObj;
        if (typeof responseObj !== 'undefined') {
            this.exists[type] = true;
        } else {
            this.exists[type] = false;
        }
    }

    // Gets an obj
    this.getObj = getObj;
    function getObj(type) {
        return this.objs[type];
    }

    // Get an obj's data
    this.getObjData = getObjData;
    function getObjData(type,comp) {
        return this.objs[type].data[comp].values;
    }

    // Get an obj's max val
    this.getObjMaxVal = getObjMaxVal;
    function getObjMaxVal(type,comp) {
        return this.objs[type].data[comp].max;
    }

    // Get an obj's min val
    this.getObjMinVal = getObjMinVal;
    function getObjMinVal(type,comp) {
        return this.objs[type].data[comp].min;
    }

    // Checks whether an object of type exists
    this.checkObjTypeExist = checkObjTypeExist;
    function checkObjTypeExist(type) {
        return exists[type];
    }

    // Return max X value
    this.getXVal = getXVal;
    function getXVal(comp) {
        var maxX = 0;
        $.each(colors,function(idx,type) {
            if (checkObjTypeExist(type)) {
                if (parseFloat(objs[type].simTime) > maxX) {
                    maxX = objs[type].simTime;
                }
            }
        });

        if (maxX) {return maxX;}

        // Default simTime to 5 days
        return "5";
    }

    // Return max Y value
    this.getYVal = getYVal;
    function getYVal(comp) {
        // Minimum Y values
        var ft4min = 17;  // Rounds to 18
        var ft3min = 4;   // Rounds to 5
        var q1min  = 110; // Rounds to 120
        var q4min  = 1;   // Rounds to 2
        var q7min  = 4;   // Rounds to 5
        var maxY = 0;
        if (comp == "ft4") {maxY = ft4min;}
        if (comp == "ft3") {maxY = ft3min;}
        if (comp == "1")   {maxY = q1min; }
        if (comp == "4")   {maxY = q4min; }
        if (comp == "7")   {maxY = q7min; }

        $.each(colors,function(idx,type) {
            if (checkObjTypeExist(type)) {
                if (parseFloat(objs[type].data[comp].max) > maxY) {
                    maxY = objs[type].data[comp].max;
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

    // Function to repeat a string
    // Essentially, "n" x 3 = "nnn"
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

//--------------------------------------------------
// Range box
//--------------------------------------------------
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

//--------------------------------------------------
// Erase a drawn line
//--------------------------------------------------
function resetObj(type) {
    ThyrosimGraph.setObj(type,undefined);
    graphthis();
}

//--------------------------------------------------
// Select the next run color
// Since we only have 2 colors, this would work
//--------------------------------------------------
function runRadioNext() {
    var runRadio = $('input[name=runRadio]');
    if (runRadio[0].checked == true) {
        runRadio[1].checked = true;
    } else {
        runRadio[0].checked = true;
    }
}
