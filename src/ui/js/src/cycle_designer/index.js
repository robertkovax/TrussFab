import * as d3 from 'd3';

import colors from './colors';

let paused = true;
let started = false;
const MAX_X = 5;
const MIN_X = 1;

let STATES = Object.freeze({ LOW: 0, HIGH: 1 });
let state = STATES.HIGH;

const datas = [];
const paths = new Map();
const dots = {};

const margin = {
  top: 10,
  right: 10,
  bottom: 20,
  left: 10,
};

const tabBarHeight = d3
  .select('#actuators-tab')
  .node()
  .getBoundingClientRect().height;

const bodyHeight = d3
  .select('body')
  .node()
  .getBoundingClientRect().height;

const schedulingElement = d3.select('#scheduling');
const schedulingElementHeight = bodyHeight - tabBarHeight - 6; // magic number 4, padding?
const schedulingElementWidth = schedulingElement.node().getBoundingClientRect()
  .width;

const svg = schedulingElement
  .append('svg')
  .attr('width', schedulingElementWidth)
  .attr('height', schedulingElementHeight);

const width = svg.attr('width') - margin.left - margin.right;
const height = svg.attr('height') - margin.top - margin.bottom;

const g = svg
  .append('g')
  .attr('transform', `translate(${margin.left},${margin.top})`);

// converts data to pixels or pixels to data (using {x, y}.invert())
const x = d3
  .scaleLinear()
  .domain([0, 10])
  .range([0, width]);
const y = d3.scaleLinear().range([height, 0]);

// creates a line using the x and y conversion functions
const line = d3
  .line()
  .x(d => x(d.x))
  .y(d => y(d.y));

const brush = d3
  .brushX()
  .extent([[0, 0], [width, height]])
  .on('start brush', brushed);

const dragDot = d3
  .drag()
  .on('start', dragDotStarted)
  .on('drag', draggingDot)
  .on('end', dragDotEnded);

const dragLine = d3
  .drag()
  .on('start', dragLineStarted)
  .on('drag', draggingLine)
  .on('end', dragLineEnded);

const scrub = d3.drag().on('drag', scrubLine);

// the red vertical line that indicates time
g
  .append('line')
  .attr('x1', x(MIN_X))
  .attr('y1', 0)
  .attr('x2', x(MIN_X))
  .attr('y2', 100)
  .style('stroke-width', 3)
  .style('stroke', 'red')
  .style('fill', 'none')
  .call(scrub);

g
  .append('g')
  .attr('transform', `translate(0,${height})`)
  .call(d3.axisBottom(x));

function movePistons(newX) {
  d3.selectAll('circle').each(circle => {
    if (circle != d3.selectAll('circle').x) {
      if (circle.id === 5) {
        // we don't care about the last circle
        return;
      }
      const diff = Math.abs(newX - x(circle.x));
      if (diff < 1) {
        const nextCircle = getCircleWithID(
          circle.id + 1,
          dots[circle.pistonId]
        ).data()[0];
        switch (circle.state) {
          case STATES.HIGH:
            if (nextCircle.state == STATES.LOW) {
              retract(circle.pistonId);
            } else {
              stop(circle.pistonId);
            }
            break;
          case STATES.LOW:
            if (nextCircle.state == STATES.LOW) {
              stop(circle.pistonId);
            } else {
              expand(circle.pistonId);
            }
        }
      }
    }
  });
}

function moveTimeline(timeline, newX) {
  timeline.attr('x1', newX);
  timeline.attr('x2', newX);
}

function updateData() {
  if (!started) {
    return;
  }
  const timelineStep = 0.01;
  const timeline = d3.select('line');
  const oldX = x.invert(timeline.attr('x1'));
  let newX = x(MIN_X);
  if (oldX <= MAX_X) {
    newX = x(oldX + timelineStep);
  }

  movePistons(newX);
  if (!paused) {
    moveTimeline(timeline, newX);
  }
}

setInterval(() => {
  updateData();
}, 10);

function getCircleWithID(id, selection) {
  return selection.filter(circle => circle.id === id);
}

function distanceBetweenTwoPoints(x1, y1, x2, y2) {
  const a = x1 - x2;
  const b = y1 - y2;

  return Math.sqrt(a * a + b * b);
}

// Play/Pause Logic

function startStopCycle() {
  if (started) {
    paused = true;
    started = false;
    resetTimeline();
  } else {
    paused = false;
    started = true;
  }
}

function pauseUnpauseCycle() {
  paused = !paused;
}

function resetTimeline() {
  const timeLine = d3.select('line');
  timeLine.attr('x1', x(MIN_X));
  timeLine.attr('x2', x(MIN_X));
}

// Event handling

function beforebrushed() {
  d3.event.stopImmediatePropagation();
  d3
    .select(this.parentNode)
    .transition()
    .call(brush.move, x.range());
}

function brushed() {
  const extent = d3.event.selection.map(x.invert, x);
  // what is 'dot'?
  dot.classed('selected', d => {
    return extent[0] <= d.x && d.x <= extent[1];
  });
}

const closestLeft = { point: null, distance: Infinity, id: 0 };
const closestRight = { point: null, distance: Infinity, id: 0 };

// returns the new x position of the moved point in "data space"
function movePoint(point, xPos, yPos, pistonId) {
  let prevX = 0;
  let nextX = 0;

  const next = getCircleWithID(point.id + 1, dots[pistonId]);
  if (!next.empty()) {
    nextX = next.data()[0].x - 0.01;
  } else {
    // this most probably means that we want to move the last point
    nextX = MAX_X;
  }

  const prev = getCircleWithID(point.id - 1, dots[pistonId]);
  if (!prev.empty()) {
    prevX = prev.data()[0].x + 0.01;
  } else {
    // this most probably means that we want to move the first point
    prevX = MIN_X;
  }

  const newX = Math.min(Math.max(prevX, x.invert(xPos)), nextX);
  let newY = 0;

  if (yPos > y(midPoint(point.pistonId))) {
    newY = low(point.pistonId);
    point.state = STATES.LOW;
  } else {
    newY = high(point.pistonId);
    point.state = STATES.HIGH;
  }

  point.x = newX;
  point.y = newY;
  return { x: newX, y: newY };
}

function dragLineStarted(d, i) {
  const dots = d3.select(this).datum();
  const coords = d3.mouse(this);
  dots.forEach(dot => {
    const distance = distanceBetweenTwoPoints(
      coords[0],
      coords[1],
      x(dot.x),
      y(dot.y)
    );
    if (coords[0] < x(dot.x)) {
      if (distance < closestRight.distance) {
        closestRight.point = dot;
        closestRight.distance = distance;
        closestRight.id = i;
      }
    } else {
      if (distance < closestLeft.distance) {
        closestLeft.point = dot;
        closestLeft.distance = distance;
        closestLeft.id = i;
      }
    }
  });
}

function draggingLine() {
  const newPostLeft = movePoint(
    closestLeft.point,
    x(closestLeft.point.x) + d3.event.dx,
    y(closestLeft.point.y) + d3.event.dy,
    closestLeft.point.pistonId
  );
  const newXLeft = newPostLeft.x;
  const newYLeft = newPostLeft.y;

  // ?
  const leftPoint = d3.select(this).datum()[closestLeft.id];

  dots[d3.select(this).attr('id')]
    .filter((d, i) => i === closestLeft.point.id - 1)
    .attr('cx', x(newXLeft))
    .attr('cy', y(newYLeft));

  const newPostRight = movePoint(
    closestRight.point,
    x(closestRight.point.x) + d3.event.dx,
    y(closestRight.point.y) + d3.event.dy,
    closestRight.point.pistonId
  );
  const newXRight = newPostRight.x;
  const newYRight = newPostRight.y;

  // ?
  const rightPoint = d3.select(this).datum()[closestRight.id];

  dots[d3.select(this).attr('id')]
    .filter((d, i) => i === closestRight.point.id - 1)
    .attr('cx', x(newXRight))
    .attr('cy', y(newYRight));

  d3.select(this).attr('d', line);
}

function dragLineEnded() {
  closestLeft.point = null;
  closestLeft.distance = Infinity;
  closestRight.point = null;
  closestRight.distance = Infinity;
}

function dragDotStarted() {
  d3
    .select(this)
    .raise()
    .classed('active', true);
}

function draggingDot(d) {
  const coords = d3.mouse(this);
  const newX = movePoint(d, coords[0], coords[1], d.pistonId).x;
  d3
    .select(this)
    .attr('cx', x(newX))
    .attr('cy', y(d.y));
  paths[d.pistonId].attr('d', line);
}

function dragDotEnded() {
  d3.select(this).classed('active', false);
}

function scrubLine() {
  let newX = d3.event.x;
  if (newX > x(MAX_X + 0.2)) {
    newX = x(MAX_X + 0.2);
  }
  if (newX < x(MIN_X - 0.2)) {
    newX = x(MIN_X - 0.2);
  }
  d3
    .select(this)
    .attr('x1', newX)
    .attr('x2', newX);
}

// setup logic

function high(pistonId) {
  return 0.4 + 0.05 * pistonId;
}

function low(pistonId) {
  return 0.1 + 0.05 * pistonId;
}

function midPoint(pistonId) {
  return (high(pistonId) + low(pistonId)) / 2;
}

function addData(pistonId) {
  datas[pistonId] = [
    {
      x: 1,
      y: high(pistonId),
      id: 1,
      pistonId,
      state: STATES.HIGH,
    },
    {
      x: 2,
      y: low(pistonId),
      id: 2,
      pistonId,
      state: STATES.LOW,
    },
    {
      x: 3,
      y: low(pistonId),
      id: 3,
      pistonId,
      state: STATES.LOW,
    },
    {
      x: 4,
      y: high(pistonId),
      id: 4,
      pistonId,
      state: STATES.HIGH,
    },
    {
      x: 5,
      y: high(pistonId),
      id: 5,
      pistonId,
      state: STATES.HIGH,
    },
  ];
  return datas[pistonId];
}

function addPath(color, id) {
  const pathData = addData(id);
  paths[id] = g
    .append('path')
    .datum(pathData)
    .attr('fill', 'none')
    .attr('stroke', color)
    .attr('stroke-linejoin', 'round')
    .attr('stroke-linecap', 'round')
    .attr('stroke-width', 3)
    .attr('d', line)
    .attr('id', id)
    .call(dragLine);
  dots[id] = addDots(pathData, id);
}

function addDots(dotData, id) {
  return g
    .append('g')
    .attr('fill-opacity', 1)
    .selectAll('circle')
    .data(dotData)
    .enter()
    .append('circle')
    .attr('id', id)
    .attr('cx', d => {
      return x(d.x);
    })
    .attr('cy', d => {
      return y(d.y);
    })
    .attr('r', 3.5)
    .call(dragDot);
}

// called by Sketchup

function update_pistons(id) {
  if (!paths.has(id)) {
    addPath(colors[datas.length], id);
  }
}

// Sketchup Logic

function expand(id) {
  sketchup.expand_actuator(id);
}

function retract(id) {
  sketchup.retract_actuator(id);
}

function stop(id) {
  sketchup.stop_actuator(id);
}

// expose functions to global scope

window.startStopCycle = startStopCycle;
window.pauseUnpauseCycle = pauseUnpauseCycle;
window.update_pistons = update_pistons;
