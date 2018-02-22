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

$(() => {
  sketchup.documentReady();
  $('button').click(event => buttonClicked(event.target.id));
});
