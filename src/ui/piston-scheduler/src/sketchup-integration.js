function toggleSimulation() {
  sketchup.toggle_simulation();
}

function togglePauseSimulation() {
  sketchup.toggle_pause_simulation();
}

function restartSimulation() {
  sketchup.restart_simulation();
}

function changePistonValue(id, newValue, duration) {
  sketchup.move_joint(id, newValue, duration);
}

export {
  toggleSimulation,
  togglePauseSimulation,
  restartSimulation,
  changePistonValue,
};
