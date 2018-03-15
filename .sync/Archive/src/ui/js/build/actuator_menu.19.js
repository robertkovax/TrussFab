'use strict';

function showManualActuatorSettings(pistons, breakingForce, maxSpeed) {
  $('#manual').empty();
  var elements = [];

  var breakingForceElement = $('<input type="number" min = "0" value="' + breakingForce + '" step="1"> N');
  breakingForceElement.on('change', function (event) {
    return setBreakingForce(event.currentTarget.value);
  });

  elements.push(breakingForceElement);

  var maxSpeedElement = $('<input type="number" min = "0" value="' + maxSpeed + '" step="1"> m/s');
  maxSpeedElement.on('change', function (event) {
    return setMaxSpeed(event.currentTarget.value);
  });

  elements.push(maxSpeedElement);

  var highestForceModeElement = $('<input id="force_mode_checkbox" type="checkbox"">');

  highestForceModeElement.on('change', function (event) {
    return changeHighestForceMode(event.currentTarget.checked);
  });

  elements.push(highestForceModeElement);

  pistons.forEach(function (pistonId) {
    var pistonElement = $('<input class="piston" type="range" min="0" max="1" value="0.5" step="0.01">');
    pistonElement.on('input', function (event) {
      return changePistonValue(pistonId, event.currentTarget.value);
    });
    elements.push(pistonElement);

    var pistonTestButton = $('<button>Test</button>');

    pistonTestButton.click(function () {
      return testPiston(pistonId);
    });

    elements.psuh(pistonTestButton);
  });

  $('#manual').append(elements);
}

function toggleStartStopSimulationButton() {
  if ($('.start-button').text() === 'Start') {
    $('.start-button').text('Stop');
    $('.pause-button').attr('disabled', false);
    $('.restart-button').attr('disabled', false);
  } else {
    $('.start-button').text('Start');
    $('.pause-button').attr('disabled', true);
    $('.restart-button').attr('disabled', true);
  }
}

function togglePauseUnpauseSimulationButton() {
  if ($('.pause-button').text() === 'Pause') {
    $('.pause-button').text('Unpause');
  } else {
    $('.pause-button').text('Pause');
  }
}

function toggleSimulation() {
  toggleStartStopSimulationButton();
  sketchup.toggle_simulation();
}

function togglePauseSimulation(event) {
  if (event.currentTarget.disabled == null) event.stopPropagation();

  togglePauseUnpauseSimulationButton();
  sketchup.toggle_pause_simulation();
}

function restartSimulation(event) {
  if (event.currentTarget.disabled == null) event.stopPropagation();

  $('.piston').val(0.5); // resetting

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

function apply_force() {
  sketchup.apply_force();
}

function release_force() {
  sketchup.release_force();
}

$(function () {
  $('.pause-button').attr('disabled', true).click(togglePauseSimulation);

  $('.restart-button').attr('disabled', true).click(restartSimulation);

  $('.start-button').click(toggleSimulation);
});