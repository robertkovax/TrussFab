'use strict';

function showManualActuatorSettings(pistons, breakingForce, maxSpeed) {
  var elements = [];

  var form = $('<div class="form-row"/>');

  var breakingForceElement = $('<div class="col-4">\n      <div class="input-group input-group-sm">\n         <div class="input-group-prepend">\n          <span class="input-group-text">Breaking Force</span>\n        </div>\n        <input class="form-control form-control-sm" type="number" min = "0" value="' + breakingForce + '" step="1">\n        <div class="input-group-append">\n          <span class="input-group-text">N</span>\n        </div>\n      </div>\n    </div>');
  breakingForceElement.find('input').on('change', function (event) {
    return setBreakingForce(event.currentTarget.value);
  });

  form.append(breakingForceElement);

  var maxSpeedElement = $('<div class="col-4">\n      <div class="input-group input-group-sm">\n         <div class="input-group-prepend">\n          <span class="input-group-text">Max. Speed</span>\n        </div>\n        <input class="form-control form-control-sm" type="number" min = "0" value="' + maxSpeed + '" step="1">\n        <div class="input-group-append">\n          <span class="input-group-text">m/s</span>\n        </div>\n      </div>\n    </div>');
  maxSpeedElement.find('input').on('change', function (event) {
    return setMaxSpeed(event.currentTarget.value);
  });

  form.append(maxSpeedElement);

  var col = $('<div class="col-auto"/>)');
  var highestForceModeElement = $('<div class="col-auto">\n      <div class="form-check">\n        <input class="form-check-input" id="force_mode_checkbox" type="checkbox">\n        <label class="form-check-label" for="force_mode_checkbox">Highest Force Mode</label>\n      </div>\n    </div>');

  highestForceModeElement.find('input').on('change', function (event) {
    return changeHighestForceMode(event.currentTarget.checked);
  });

  col.append(highestForceModeElement);

  var peakForceModeElement = $('<div class="col-auto">\n  \t  <div class="form-check">\n        <input class="form-check-input" id="peak_force_mode_checkbox" type="checkbox">\n        <label class="form-check-label" for="peak_force_mode_checkbox">Peak Force Mode</label>\n      </div>\n    </div>');

  peakForceModeElement.find('input').on('change', function (event) {
    return changePeakForceMode(event.currentTarget.checked);
  });

  col.append(peakForceModeElement);

  var applyForceElement = $('<div class="col-auto">\n    <div class="form-check">\n      <button class="form-check-input" id="apply_force_button">\n      <label class="form-check-label" for="apply_force_button">Apply Force</label>\n    </div>\n  </div>');

  applyForceElement.find('button').on('click', function (event) {
    return applyForce();
  });

  col.append(applyForceElement);

  form.append(col);

  elements.push($('<form />').append(form));

  var pistonContainer = $('<div class="piston-container form-row"/>');

  pistons.forEach(function (pistonId, index) {
    var divOuter = $('<div class="col-4" />');
    var divInner = $('<div />');

    divInner.append('<span>Actuator ' + (index + 1));

    var pistonElement = $('<input class="piston" type="range" min="0" max="1" value="0.5" step="0.01">');
    pistonElement.on('input', function (event) {
      return changePistonValue(pistonId, event.currentTarget.value);
    });
    divInner.append(pistonElement);

    var pistonTestButton = $('<button>Test</button>');

    pistonTestButton.click(function () {
      return testPiston(pistonId);
    });

    divInner.append(pistonTestButton);
    pistonContainer.append(divOuter.append(divInner));
  });

  elements.push(pistonContainer);

  $('#manual').empty().append(elements);
}

function toggleStartStopSimulationButton() {
  if ($('.start-button').text() === 'Start') {
    $('.start-button').text('Stop');
    $('.pause-button').attr('disabled', false);
    $('.restart-button').attr('disabled', false);
    return false;
  }
  $('.start-button').text('Start');
  $('.pause-button').attr('disabled', true);
  $('.restart-button').attr('disabled', true);
  return true;
}

function togglePauseUnpauseSimulationButton() {
  if ($('.pause-button').text() === 'Pause') {
    $('.pause-button').text('Unpause');
  } else {
    $('.pause-button').text('Pause');
  }
}

// called in Ruby when the simulation is stopped via ESC and the dialog is out
// of focous
function cleanupUiAfterStoppingSimulation() {
  $('#manual').empty();

  toggleStartStopSimulationButton();
  expandCollaps(true);
  startStopCycle();
}

function expandCollaps(showStartButton) {
  if (showStartButton) {
    sketchup.set_dialog_size($('.simulation-control').outerWidth(), 42 * 3 + 28);
  } else {
    sketchup.set_dialog_size(600, 300);
  }
}

function toggleSimulation() {
  var showStartButton = toggleStartStopSimulationButton();
  expandCollaps(showStartButton);
  startStopCycle();
  sketchup.toggle_simulation();
}

function togglePauseSimulation(event) {
  if (event.currentTarget.disabled == null) event.stopPropagation();

  togglePauseUnpauseSimulationButton();
  pauseUnpauseCycle();
  sketchup.toggle_pause_simulation();
}

function restartSimulation(event) {
  if (event.currentTarget.disabled == null) event.stopPropagation();

  // reset piston sliders
  $('.piston').val(0.5);

  // restarting the simulation also unpauses it
  $('.pause-button').text('Pause');

  sketchup.restart_simulation();
}

function changePistonValue(id, newValue) {
  sketchup.change_piston_value(id, newValue);
}

function testPiston(id) {
  sketchup.test_piston(id);
}

function setBreakingForce(value) {
  sketchup.set_breaking_force(value);
}

function setMaxSpeed(value) {
  sketchup.set_max_speed(value);
}

function changeHighestForceMode(checked) {
  sketchup.change_highest_force_mode(checked);
}

function changePeakForceMode(checked) {
  sketchup.change_peak_force_mode(checked);
}

function applyForce() {
  sketchup.apply_force();
}

function release_force() {
  sketchup.release_force();
}

$(function () {
  $('.pause-button').attr('disabled', true).click(togglePauseSimulation);

  $('.restart-button').attr('disabled', true).click(restartSimulation);

  $('.start-button').click(toggleSimulation);

  expandCollaps(true);

  // stop simulation when dialog is in focus and ESC pressed
  $(document).keyup(function (e) {
    if (e.keyCode === 27) {
      if ($('.start-button').text() === 'Stop') {
        toggleSimulation();
      }
    }
  });
});