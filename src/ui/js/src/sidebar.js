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
  $('footer button, .tool').click(event =>
    buttonClicked(event.currentTarget.id)
  );

  // this forces that always one card is not collapsed
  $('.card').click(function(e) {
    if (
      $(this)
        .find('.collapse')
        .hasClass('show')
    ) {
      e.stopPropagation();
    }
  });
});
