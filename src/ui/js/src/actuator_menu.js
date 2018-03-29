function showManualActuatorSettings(pistons, breakingForce, maxSpeed) {
  const elements = [];

  const form = $('<div class="form-row"/>');

  const breakingForceElement = $(`<div class="col-4">
      <div class="input-group input-group-sm">
         <div class="input-group-prepend">
          <span class="input-group-text">Breaking Force</span>
        </div>
        <input class="form-control form-control-sm" type="number" min = "0" value="${
                                                                                     breakingForce
                                                                                   }" step="1">
        <div class="input-group-append">
          <span class="input-group-text">N</span>
        </div>
      </div>
    </div>`);
  breakingForceElement.find('input').on(
      'change', event => setBreakingForce(event.currentTarget.value));

  form.append(breakingForceElement);

  const maxSpeedElement = $(`<div class="col-4">
      <div class="input-group input-group-sm">
         <div class="input-group-prepend">
          <span class="input-group-text">Max. Speed</span>
        </div>
        <input class="form-control form-control-sm" type="number" min = "0" value="${
                                                                                     maxSpeed
                                                                                   }" step="1">
        <div class="input-group-append">
          <span class="input-group-text">m/s</span>
        </div>
      </div>
    </div>`);
  maxSpeedElement.find('input').on(
      'change', event => setMaxSpeed(event.currentTarget.value));

  form.append(maxSpeedElement);

  const col = $(`<div class="col-auto"/>)`);
  const highestForceModeElement = $(`<div class="col-auto">
      <div class="form-check">
        <input class="form-check-input" id="force_mode_checkbox" type="checkbox">
        <label class="form-check-label" for="force_mode_checkbox">Highest Force Mode</label>
      </div>
    </div>`);

  highestForceModeElement.find('input').on(
      'change', event => changeHighestForceMode(event.currentTarget.checked));

  col.append(highestForceModeElement);

  const peakForceModeElement = $(`<div class="col-auto">
  	  <div class="form-check">
        <input class="form-check-input" id="peak_force_mode_checkbox" type="checkbox">
        <label class="form-check-label" for="peak_force_mode_checkbox">Peak Force Mode</label>
      </div>
    </div>`);

  peakForceModeElement.find('input').on(
      'change', event => changePeakForceMode(event.currentTarget.checked));

  col.append(peakForceModeElement);

  const applyForceElement = $(`<div class="col-auto">
    <div class="form-check">
      <button class="form-check-input" id="apply_force_button">
      <label class="form-check-label" for="apply_force_button">Apply Force</label>
    </div>
  </div>`);

  applyForceElement.find('button').on('click', event => applyForce());

  col.append(applyForceElement);

  form.append(col);

  elements.push($('<form />').append(form));

  const pistonContainer = $('<div class="piston-container form-row"/>');

  pistons.forEach((pistonId, index) => {
    const divOuter = $('<div class="col-4" />');
    const divInner = $('<div />');

    divInner.append(`<span>Actuator ${index + 1}`);

    const pistonElement = $(
        `<input class="piston" type="range" min="0" max="1" value="0.5" step="0.01">`);
    pistonElement.on('input', event => changePistonValue(
                                  pistonId, event.currentTarget.value));
    divInner.append(pistonElement);

    const pistonTestButton = $(`<button>Test</button>`);

    pistonTestButton.click(() => testPiston(pistonId));

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
    sketchup.set_dialog_size($('.simulation-control').outerWidth(),
                             42 * 3 + 28);
  } else {
    sketchup.set_dialog_size(600, 300);
  }
}

function toggleSimulation() {
  const showStartButton = toggleStartStopSimulationButton();
  expandCollaps(showStartButton);
  startStopCycle();
  sketchup.toggle_simulation();
}

function togglePauseSimulation(event) {
  if (event.currentTarget.disabled == null)
    event.stopPropagation();

  togglePauseUnpauseSimulationButton();
  pauseUnpauseCycle();
  sketchup.toggle_pause_simulation();
}

function restartSimulation(event) {
  if (event.currentTarget.disabled == null)
    event.stopPropagation();

  // reset piston sliders
  $('.piston').val(0.5);

  // restarting the simulation also unpauses it
  $('.pause-button').text('Pause');

  sketchup.restart_simulation();
}

function changePistonValue(id, newValue) {
  sketchup.change_piston_value(id, newValue);
}

function testPiston(id) { sketchup.test_piston(id); }

function setBreakingForce(value) { sketchup.set_breaking_force(value); }

function setMaxSpeed(value) { sketchup.set_max_speed(value); }

function changeHighestForceMode(checked) {
  sketchup.change_highest_force_mode(checked);
}

function changePeakForceMode(checked) {
  sketchup.change_peak_force_mode(checked);
}

function applyForce() { sketchup.apply_force(); }

function release_force() { sketchup.release_force(); }

$(() => {
  $('.pause-button').attr('disabled', true).click(togglePauseSimulation);

  $('.restart-button').attr('disabled', true).click(restartSimulation);

  $('.start-button').click(toggleSimulation);

  expandCollaps(true);

  // stop simulation when dialog is in focus and ESC pressed
  $(document).keyup(e => {
    if (e.keyCode === 27) {
      if ($('.start-button').text() === 'Stop') {
        toggleSimulation();
      }
    }
  });
});
