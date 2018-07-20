/* FUNCTIONS CALLED BY RUBY */

devMode = false;

function deselectAllTools() {
  $('.tool').removeClass('active');
}

function selectTool(id) {
  $(`#${id}`).addClass('active');
}

function buttonClicked(id) {
  sketchup.buttonClicked(id);
}

function toggleDevMode() {
  devMode = !devMode;
  document.getElementById('generic_physics_link_tool').style.display = devMode
    ? 'inline'
    : 'none';
  document.getElementById('pid_controller_tool').style.display = devMode
    ? 'inline'
    : 'none';
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
      // $('.card').find('.collapse').not('.show').addClass('show');
    }
  });
});

function fixFooter() {
  const heightWindow = $(window).outerHeight();
  const heightBody = $('#accordion').outerHeight() + $('footer').outerHeight();

  if (heightBody > heightWindow) {
    $('footer').removeClass('stickBottom');
  } else {
    $('footer').addClass('stickBottom');
  }
}

window.addEventListener('resize', fixFooter, true);
window.addEventListener('load', fixFooter, true);
