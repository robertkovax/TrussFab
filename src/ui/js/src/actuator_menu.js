function addActuator(id) {
  console.log('test');
  const slider = $(
    `<input id="${id}" type="range" min="0" max="1" value="0.5" step="0.01">`
  );

  slider.on('change', function() {
    onInput(id, this.value);
  });

  $('#manual').append(slider);
}

function removeActuator(id) {}

function onInput(id, newValue) {
  console.log(id, newValue);
  // sketchup.change_piston(id, newValue);
}

function startSimulation() {
  console.log('start simulation');
  sketchup.start_simulation();
}

function onClick(id) {
  sketchup.test_piston(id);
}

function set_breaking_force(value) {
  sketchup.set_breaking_force(value);
}

function set_max_speed(value) {
  sketchup.set_max_speed(value);
}

function play_pause_simulation() {
  sketchup.play_pause_simulation();
}

function restart_simulation() {
  sketchup.restart_simulation();
}

function change_highest_force_mode() {
  sketchup.change_highest_force_mode(force_mode_checkbox.checked);
}

// function reset_sliders() {
//   <% for piston_id in @pistons.keys %>
//       document.getElementById("<%= piston_id %>").value = "0.5";
//   <% end %>
// }

function apply_force() {
  sketchup.apply_force();
}

function release_force() {
  sketchup.release_force();
}

$(() => {
  $('.start-button').click(() => startSimulation());
  // startSimulation();
});
