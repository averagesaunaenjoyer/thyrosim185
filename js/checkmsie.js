//--------------------------------------------------
// Check userAgent for 'msie' and display warning message.
// This function sits its own file to ensure it gets loaded without
// interference from errors in other JavaScript files.
// NOTE: This may not work all the time because browsers 
// have the ability to spoof their userAgent.
//--------------------------------------------------
function checkMSIE() {
    if (navigator.userAgent.match(/msie/i)) {
        $('#nonIEMsgDiv').css("display","block");
    }
}
