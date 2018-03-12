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
  $('button').click(event => buttonClicked(event.currentTarget.id));

  // this forces that always one card is not collapsed
  $('.card-header a').click(function(e) {
    if (!$(this).hasClass('collapsed')) {
      e.stopPropagation();
    }
  });
});
