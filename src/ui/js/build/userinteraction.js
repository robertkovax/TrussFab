$(document).ready(function () {
    sketchup.document_ready();
    $("button").click(function () {
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
    sketchup.button_clicked(id);
}
// -------------------
// FOR REFERENCE
// -------------------
// function callback(name, data) {
//   if (!data) data = '';
//   window.location.href = 'skp:' + name + '@' + data;
// }

// function open_link(ref) {
//   callback('open_link', ref);
//   return false;
// }

// function test(str){
//   $('#position-number').val(str);
// }

// Tell sketchup window is closing
// function windowClosing(){
//   //Call the Sketchup callback
//   window.location='skp:windowClosed@';
// }