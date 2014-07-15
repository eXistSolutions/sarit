/*!
* put application-specific JavaScript code
*/
'use strict';

$(document).ready(function() {
    $("#toc-toggle").click(function(ev) {
        $(".sidebar-offcanvas").parent().toggleClass("active");
    });
});