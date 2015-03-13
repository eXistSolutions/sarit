/*!
* put application-specific JavaScript code
*/
'use strict';

$(document).ready(function() {
    $("#toc-toggle").click(function(ev) {
        $(".sidebar-offcanvas").parent().toggleClass("active");
        $("html, body").animate({ scrollTop: 0 }, "fast");
    });
    
    // table of contents tree
    
    // expand current item
    $(".contents .current").parents("ul").each(function() {
        $(this).show().prevAll(".toc-toggle").find("i").removeClass("glyphicon-plus").addClass("glyphicon-minus");
        $(this).parent().addClass("open");
    });
    
    // handle click on +/-
    $(".toc-toggle").click(function(ev) {
        ev.preventDefault();
        var link = $(this);
        if (link.parent().is(".open")) {
            link.nextAll("ul").hide(200);
            link.find("i").removeClass("glyphicon-minus").addClass("glyphicon-plus");
        } else {
            link.nextAll("ul").show(200);
            link.find("i").removeClass("glyphicon-plus").addClass("glyphicon-minus");
        }
        link.parent().toggleClass("open");
    });
    
    // search form
    var select = $("select[name='index']");
    
    // hide mode selection unless lucene index is chosen
    function initIndexSelectMode() {
        if (select.length == 0) {
            return;
        }
        var index = select.val();
        $("#mode-selection").hide();
        if (index === "lucene") {
            $("#mode-selection").show();
        }
    }

    select.change(function(ev) {
        initIndexSelectMode();
        initIndexSelectBool();
    });
    initIndexSelectMode();
    initIndexSelectBool();
    
    $('.popover-dismiss').popover({
        html:true,
        placement:"auto top",
        content:function(note)
        {
            $(note).next(".note-contents").html()
        }
    });
    
    var downloadCheck;
    
    $(".pdf-link").click(function(ev) {
        $("#pdf-info").modal({
            show: true
        });
        var token = $(this).attr("data-token");
        downloadCheck = window.setInterval(function() {
            var cookieValue = $.macaroon("sarit.token");
            if (cookieValue == token) {
                window.clearInterval(downloadCheck);
                $.macaroon("sarit.token", null);
                $("#pdf-info").modal("hide");
            }
        });
    });
});