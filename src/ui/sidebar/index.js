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

  $('footer button, .btn').click(event =>
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

function updateFabricationData(fabricationData) {
  data = JSON.parse(fabricationData)
  var remainingSlots = parseInt(data.remaining_slots);

  $("#needed_material_length").html(data.material_length);
  $("#needed_material_cost").html(data.material_cost);
  $("#available_slots").html(remainingSlots);

  $("#slot_5").show();
  $("#slot_4").show();
  $("#slot_3").show();
  $("#slot_2").show();
  $("#slot_1").show();


  if (remainingSlots < 5) {
    $("#slot_5").hide();
  }
  if (remainingSlots < 4) {
    $("#slot_4").hide();
  }
  if (remainingSlots < 3) {
    $("#slot_3").hide();
  }
  if (remainingSlots < 2) {
    $("#slot_2").hide();
  }
  if (remainingSlots < 1) {
    // $("#slot_1").hide();
    $("#slot_1").addClass("st6");
    $("#slot_1").removeClass("st0");
    $("svg tspan").addClass("colorInvalid")
  } else {
    $("#slot_1").addClass("st0");
    $("#slot_1").removeClass("st6");
    $("svg tspan").removeClass("colorInvalid")
  }

}

window.addEventListener('resize', fixFooter, true);
window.addEventListener('load', fixFooter, true);
