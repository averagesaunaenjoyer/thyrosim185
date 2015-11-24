//--------------------------------------------------
// FILE:        content.js
// AUTHOR:      Simon X. Han
// DESCRIPTION:
//   This file deals with user interactions and animation effects on the main
//   page.
//-------------------------------------------------- 

"use strict"; // enable strict mode

// Animation object
var animeObj = new animation();

//--------------------------------------------------
// Uses JQuery to dynamically add a span that contains
// simulation conditions.
//-------------------------------------------------- 
function addInput(type) {

    // Get the ID the next input should have
    var nextID = getNextID();

    // Get the class the new input should have
    var rowClass = getRowClass(nextID);

    // Create a new input span object
    var newInputSpan = $(document.createElement('span')).attr({
        'id': 'input-' + nextID,
        'class': rowClass
    });

    var parsed = parseInput(type);
    var footer = "#footer-input";

    //-------------------------------------------------- 
    // Append the new input span to the end of footer.
    // When adding inputs, the BR element must be inside the input span.
    // Otherwise, BR will be counted as an element of footer.
    //-------------------------------------------------- 

    // Add oral input
    if (parsed.type == "Oral") {
        newInputSpan.html(OralInput(parsed,nextID)
          + addDeleteIcon("input-" + nextID)
          + "<br />");
        newInputSpan.appendTo(footer);

    // Add intravenous input
    } else if (parsed.type == "IV") {
        newInputSpan.html(IVPulseInput(parsed,nextID)
          + addDeleteIcon("input-" + nextID)
          + "<br />");
        newInputSpan.appendTo(footer);

    // Add infusion input
    } else if (parsed.type == "Infusion") {
        newInputSpan.html(InfusionInput(parsed,nextID)
          + addDeleteIcon("input-" + nextID)
          + "<br />");
        newInputSpan.appendTo(footer);

    // Error message
    } else {
        // The professor likes an "uh-oh!" sound when there is an error.
        // This may be a good place for one.
    }

    // Append/remove animating gifs
    var aEle = animeObj.getAnimationEle(parsed.TH,parsed.type);
    var aCat = animeObj.getAnimationCat(parsed.type);
    var id = animeObj.showAnimation(aCat,aEle);
    setTimeout(function() {animeObj.hideAnimation(aCat,id)},3200);
    // 3200 ms because each gif has 8 frames of 0.4 sec each
}

//--------------------------------------------------
// Input for repeating oral dose
// It is expected to have dose, dosing interval, start, and end days
//-------------------------------------------------- 
function OralInput(parsed,id) {
    return '<span class="inputs" id="label-' + id + '" name="label-' + id + '">Input ' + id + ' (' + parsed.TH + '-' + parsed.type + '):</span><br />'
         + '<input type="hidden" class="inputs" name="hormone-' + id + '" id="hormone-' + id + '" value="' + parsed.ID + '" />'
         + '<input type="hidden" class="inputs" name="type-' + id + '" id="type-' + id + '" value="' + parsed.tID + '" />'
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
    return '<span class="inputs" id="label-' + id + '" name="label-' + id + '">Input ' + id + ' (' + parsed.TH + '-' + parsed.type + '):</span><br />'
         + '<input type="hidden" class="inputs" name="hormone-' + id + '" id="hormone-' + id + '" value="' + parsed.ID + '" />'
         + '<input type="hidden" class="inputs" name="type-' + id + '" id="type-' + id + '" value="' + parsed.tID + '" />'
         + addEnable(id)
         + 'Dose: <input size="5" class="inputs" type="text" id="dose-' + id + '" name="dose-' + id + '" /> \u03BCg' + '&nbsp&nbsp&nbsp&nbsp&nbsp'
         + 'Start Day: <input size="5" class="inputs" type="text" id="start-' + id + '" name="start-' + id + '" />' + '&nbsp&nbsp&nbsp&nbsp&nbsp';
}

//--------------------------------------------------
// Input for constant infusion
// It is expected to have dose per day, start, and end days
//-------------------------------------------------- 
function InfusionInput(parsed,id) {
    return '<span class="inputs" id="label-' + id + '" name="label-' + id + '">Input ' + id + ' (' + parsed.TH + '-' + parsed.type + '):</span><br />'
         + '<input type="hidden" class="inputs" name="hormone-' + id + '" id="hormone-' + id + '" value="' + parsed.ID + '" />'
         + '<input type="hidden" class="inputs" name="type-' + id + '" id="type-' + id + '" value="' + parsed.tID + '" />'
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
        TH   : inputSplit[0],
        type : inputSplit[1],
        ID   : hormoneID,
        tID  : typeID
    };

    // Secondary function: save the split values in an array. This function is
    // called in other places where it is more sensible to use the index.
    inputFields[0] = inputSplit[0];
    inputFields[1] = inputSplit[1];

    return inputFields;
}

//--------------------------------------------------
// Count the number of spans in #footer-input and returns the id the next input
// should have. Currently, each input has 3 spans within.
//-------------------------------------------------- 
function getNextID() {
    return $("#footer-input span").length / 3 + 1;
}

//--------------------------------------------------
// Determine row color based on NextID.
//-------------------------------------------------- 
function getRowClass(nextID) {
    return 'row' + nextID % 2;
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
  + "<img src=\"img/x.png\" alt=\"Delete this input\" /></a>";
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

//--------------------------------------------------
// Show or hide the scroll bars for secretion/absorption adjustment
//--------------------------------------------------
function showhidescrollbars() {
    if ($(".slidercontainer").css("display") == "none") {
        $(".slidercontainer").css("display","block");
        $("#showhidescrollbar").attr("src","img/minus.png")
                               .attr("alt","hide scroll bars");
    } else {
        $(".slidercontainer").css("display","none");
        $("#showhidescrollbar").attr("src","img/plus.png")
                               .attr("alt","show scroll bars");
    }
}
//--------------------------------------------------
// highlight or un-highlight the corresponding black dot in the diagram
// when mousing over a T4/3 secretion/absorption edit box.
//--------------------------------------------------
function hilite(id) {
    var ele = "#hilite" + id;
    $(ele).css("display","block");
}
function lolite(id) {
    var ele = "#hilite" + id;
    $(ele).css("display","none");
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

function showAnimation(hormoneID,inputID) {
    if (hormoneID == 3) {
        var ele = "#spill1";
        if (inputID == 1) $(ele).css("display","block");
    } else if (hormoneID == 4) {
        var ele = "#spill2";
        if (inputID == 1) $(ele).css("display","block");
    }
}
function hideAnimation(hormoneID,inputID) {
    if (hormoneID == 3) {
        var ele = "#spill1";
        if (inputID == 1) $(ele).css("display","none");
    } else if (hormoneID == 4) {
        var ele = "#spill2";
        if (inputID == 1) $(ele).css("display","none");
    }
}

//--------------------------------------------------
// Maintain an animation object to help organize the show/hide animation logic.
//--------------------------------------------------
function animation() {

    // Define animation element ids based on hormone and type here
    // hormones: T3/T4, types: Oral/IV/Infusion
    this.element = new Array();
    this.element.Oral = new Array();
    this.element.IV = new Array();
    this.element.Infusion = new Array();
    this.element.Oral.T3 = 'spill1';
    this.element.Oral.T4 = 'spill2';
    this.element.Oral.cat = 'spill'; // category
    this.element.IV.T3 = 'inject1';
    this.element.IV.T4 = 'inject2';
    this.element.IV.cat = 'inject';
    this.element.Infusion.T3 = 'infuse1';
    this.element.Infusion.T4 = 'infuse2';
    this.element.Infusion.cat = 'infuse';

    //--------------------------------------------------
    // Create a container div and append an image (animation) in it. Then,
    // append the container div to #diagram.
    // The image src has a '?+id', this is so browsers are forced to reload the
    // image. Otherwise, they will use a cached image and the animation will
    // appear out of sync.
    //--------------------------------------------------
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
                                'src'   : 'img/'+ele+'.gif?'+id
                               })
                            .appendTo(div);
        return id;
    }

    //--------------------------------------------------
    // Removes the container div ('hiding' the image)
    //--------------------------------------------------
    this.hideAnimation = hideAnimation;
    function hideAnimation(cat,id) {
        $('#'+cat+'-'+id).remove();
    }

    //--------------------------------------------------
    // For a given hormone and input type, get the gif file name (without file
    // extension)
    //--------------------------------------------------
    this.getAnimationEle = getAnimationEle;
    function getAnimationEle(hormone,type) {
        return this.element[type][hormone];
    }

    //--------------------------------------------------
    // Get the animation category for the input type.
    // Oral is always 'spill' (swallow pill)
    // IV is always 'ivenous' (intravenous)
    // Infusion is always 'infus'
    //--------------------------------------------------
    this.getAnimationCat = getAnimationCat;
    function getAnimationCat(type) {
        return this.element[type]['cat'];
    }
}

//--------------------------------------------------
// jQuery function required to make tooltips work
//--------------------------------------------------
function loadToolTip() {
    $(function() {
        $( document ).tooltip();
    });
}

//--------------------------------------------------
// Functions that define the sliders.
// sliderObj defines slider properties and the function sets them.
//-------------------------------------------------- 
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

//--------------------------------------------------
// Function to show/hide inputs
//--------------------------------------------------
function show_hide(H) {
    if($('#'+H+'input').css("display") == "block") {
        $('#'+H+'input').css("display","none");
        $('#'+H+'display').text("Show "+H+" input");
    } else {
        $('#'+H+'input').css("display","block");
        $('#'+H+'display').text("Hide "+H+" input");
    }
}

//--------------------------------------------------
// Function to show/hide rollover divs
//--------------------------------------------------
function clickInfoButton(id) {
    if ($('#button-'+id).hasClass('infoButton-clicked')) {
        $('#button-'+id).removeClass('infoButton-clicked');
        $('#link-'+id).removeClass('color-white');
    } else {
        $('#button-'+id).addClass('infoButton-clicked');
        $('#link-'+id).addClass('color-white');
    }
}
