const STATES = Object.freeze({ LOW: 0, HIGH: 1 });
const state = STATES.HIGH;

// setup logic

function high(pistonId) {
  return 0.4 + 0.05 * pistonId;
}
function low(pistonId) {
  return 0.1 + 0.05 * pistonId;
}

// ??
function midPoint(pistonId) {
  return (high(pistonId) + low(pistonId)) / 2;
}

function addInitalPistonDataToGraph(timeSteps, pistonId) {
  // first, create a sequence in the form 'high low low high high low low ...'
  const lowHigh = Array.from(new Array(timeSteps), (_, index) => [
    index % 2 === 0,
    index % 2 === 0,
  ]);

  // flatten
  const lowHightFlat = lowHigh.reduce((a, b) => a.concat(b), []);

  // remove first element
  lowHightFlat.shift();
  // console.log('lowHightFlat', lowHightFlat);

  // then, create position of dots
  return Array.from(new Array(timeSteps), (_, index) => ({
    x: index,
    y: lowHightFlat[index] ? high(pistonId) : low(pistonId),
    id: index,
    pistonId,
    state: lowHightFlat[index] ? STATES.HIGH : STATES.LOW,
  }));
}

export { addInitalPistonDataToGraph, midPoint, STATES, low, high };
