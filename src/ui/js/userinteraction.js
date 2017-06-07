$(document).ready(function() {
    sketchup.document_ready();
    $("button").click(function() {
        button_clicked(this.id);
    });
});

/* FUNCTIONS CALLED BY RUBY */

function deselect_all_tools() {
    $(".tool").removeClass('active');
}

function select_tool(id) {
    $("#" + id).addClass('active');
}

function button_clicked(id) {
    if (id === 'timeline_panel') {
        sketchup.open_timeline_panel();
    } else {
        sketchup.button_clicked(id);
    }
}
