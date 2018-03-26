function toggleSimulation() {
  window.sketchup.toggle_simulation();
}

function togglePauseSimulation() {
  window.sketchup.toggle_pause_simulation();
}

function restartSimulation() {
  window.sketchup.restart_simulation();
}

function moveJoint(id, newValue, duration) {
  window.sketchup.move_joint(id, newValue, duration);
}

export {
  toggleSimulation,
  togglePauseSimulation,
  restartSimulation,
  moveJoint,
};
