$(document).ready(function () {
  sketchup.documentReady();
  $('button').click(function () {
    buttonClicked(this.id);
  });
});

/* FUNCTIONS CALLED BY RUBY */

function deselectAllTools() {
  $('.tool').removeClass('active');
}

function selectTool(id) {
  $(`#${id}`).addClass('active');
}

function buttonClicked(id) {
  sketchup.buttonClicked(id);
}