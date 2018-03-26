'use strict';

var paused = true;
var started = false;
var max_x = 5;
var min_x = 1;

var STATES = Object.freeze({ LOW: 0, HIGH: 1 });
var state = STATES.HIGH;

var tabBarHeight = d3.select('#actuators-tab').node().getBoundingClientRect().height;

var bodyHeight = d3.select('body').node().getBoundingClientRect().height;

var schedulingElement = d3.select('#scheduling');
var schedulingElementHeight = bodyHeight - tabBarHeight - 6; // magic number 4, padding?
var schedulingElementWidth = schedulingElement.node().getBoundingClientRect().width;

var svg = schedulingElement.append('svg').attr('width', schedulingElementWidth).attr('height', schedulingElementHeight);
var margin = {
  top: 10,
  right: 10,
  bottom: 20,
  left: 10
};
var width = +svg.attr('width') - margin.left - margin.right;
var height = +svg.attr('height') - margin.top - margin.bottom;
var g = svg.append('g').attr('transform', 'translate(' + margin.left + ',' + margin.top + ')');

var datas = [];
var paths = new Map();
var dots = {};

// converts data to pixels or pixels to data (using {x, y}.invert())
var x = d3.scaleLinear().domain([0, 10]).range([0, width]);
var y = d3.scaleLinear().range([height, 0]);

// creates a line using the x and y conversion functions
var line = d3.line().x(function (d) {
  return x(d.x);
}).y(function (d) {
  return y(d.y);
});

var brush = d3.brushX().extent([[0, 0], [width, height]]).on('start brush', brushed);

var dragDot = d3.drag().on('start', dragDotStarted).on('drag', draggingDot).on('end', dragDotEnded);

var dragLine = d3.drag().on('start', dragLineStarted).on('drag', draggingLine).on('end', dragLineEnded);

var scrub = d3.drag().on('drag', scrubLine);

// the red vertical line that indicates time
g.append('line').attr('x1', x(min_x)).attr('y1', 0).attr('x2', x(min_x)).attr('y2', 100).style('stroke-width', 3).style('stroke', 'red').style('fill', 'none').call(scrub);

var colors = ['#FF6633', '#FFB399', '#FF33FF', '#FFFF99', '#00B3E6', '#E6B333', '#3366E6', '#999966', '#99FF99', '#B34D4D', '#80B300', '#809900', '#E6B3B3', '#6680B3', '#66991A', '#FF99E6', '#CCFF1A', '#FF1A66', '#E6331A', '#33FFCC', '#66994D', '#B366CC', '#4D8000', '#B33300', '#CC80CC', '#66664D', '#991AFF', '#E666FF', '#4DB3FF', '#1AB399', '#E666B3', '#33991A', '#CC9999', '#B3B31A', '#00E680', '#4D8066', '#809980', '#E6FF80', '#1AFF33', '#999933', '#FF3380', '#CCCC00', '#66E64D', '#4D80CC', '#9900B3', '#E64D66', '#4DB380', '#FF4D4D', '#99E6E6', '#6666FF'];

g.append('g').attr('transform', 'translate(0,' + height + ')').call(d3.axisBottom(x));

function movePistons(new_x) {
  d3.selectAll('circle').each(function (circle) {
    if (circle != d3.selectAll('circle').x) {
      if (circle.id == 5) {
        // we don't care about the last circle
        return;
      }
      var diff = Math.abs(new_x - x(circle.x));
      if (diff < 1) {
        var nextCircle = getCircleWithID(circle.id + 1, dots[circle.piston_id]).data()[0];
        switch (circle.state) {
          case STATES.HIGH:
            if (nextCircle.state == STATES.LOW) {
              retract(circle.piston_id);
            } else {
              stop(circle.piston_id);
            }
            break;
          case STATES.LOW:
            if (nextCircle.state == STATES.LOW) {
              stop(circle.piston_id);
            } else {
              expand(circle.piston_id);
            }
        }
      }
    }
  });
}

function moveTimeline(timeline, new_x) {
  timeline.attr('x1', new_x);
  timeline.attr('x2', new_x);
}

function updateData() {
  if (!started) {
    return;
  }
  var timelineStep = 0.01;
  var timeline = d3.select('line');
  var old_x = x.invert(timeline.attr('x1'));
  var new_x = x(min_x);
  if (old_x <= max_x) {
    var new_x = x(old_x + timelineStep);
  }

  movePistons(new_x);
  if (!paused) {
    moveTimeline(timeline, new_x);
  }
}

setInterval(function () {
  updateData();
}, 10);

function getCircleWithID(id, selection) {
  return selection.filter(function (circle, i) {
    return circle.id == id;
  });
}

function distanceBetweenTwoPoints(x1, y1, x2, y2) {
  var a = x1 - x2;
  var b = y1 - y2;

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
  var timeLine = d3.select('line');
  timeLine.attr('x1', x(min_x));
  timeLine.attr('x2', x(min_x));
}

// Event handling

function beforebrushed() {
  d3.event.stopImmediatePropagation();
  d3.select(this.parentNode).transition().call(brush.move, x.range());
}

function brushed() {
  var extent = d3.event.selection.map(x.invert, x);
  dot.classed('selected', function (d) {
    return extent[0] <= d.x && d.x <= extent[1];
  });
}

var closestLeft = { point: null, distance: Infinity, id: 0 };
var closestRight = { point: null, distance: Infinity, id: 0 };

// returns the new x position of the moved point in "data space"
function movePoint(point, x_pos, y_pos, piston_id) {
  var prev_x = 0;
  var next_x = 0;

  var next = getCircleWithID(point.id + 1, dots[piston_id]);
  if (!next.empty()) {
    next_x = next.data()[0].x - 0.01;
  } else {
    // this most probably means that we want to move the last point
    next_x = max_x;
  }

  var prev = getCircleWithID(point.id - 1, dots[piston_id]);
  if (!prev.empty()) {
    prev_x = prev.data()[0].x + 0.01;
  } else {
    // this most probably means that we want to move the first point
    prev_x = min_x;
  }

  var new_x = Math.min(Math.max(prev_x, x.invert(x_pos)), next_x);
  var new_y = 0;

  if (y_pos > y(midPoint(point.piston_id))) {
    new_y = low(point.piston_id);
    point.state = STATES.LOW;
  } else {
    new_y = high(point.piston_id);
    point.state = STATES.HIGH;
  }

  point.x = new_x;
  point.y = new_y;
  return { x: new_x, y: new_y };
}

function dragLineStarted(d, i) {
  var dots = d3.select(this).datum();
  var coords = d3.mouse(this);
  dots.forEach(function (dot) {
    var distance = distanceBetweenTwoPoints(coords[0], coords[1], x(dot.x), y(dot.y));
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

function draggingLine(d, i) {
  var new_pos_left = movePoint(closestLeft.point, x(closestLeft.point.x) + d3.event.dx, y(closestLeft.point.y) + d3.event.dy, closestLeft.point.piston_id);
  var new_x_left = new_pos_left.x;
  var new_y_left = new_pos_left.y;

  var leftPoint = d3.select(this).datum()[closestLeft.id];

  dots[d3.select(this).attr('id')].filter(function (d, i) {
    return i === closestLeft.point.id - 1;
  }).attr('cx', x(new_x_left)).attr('cy', y(new_y_left));

  var new_pos_right = movePoint(closestRight.point, x(closestRight.point.x) + d3.event.dx, y(closestRight.point.y) + d3.event.dy, closestRight.point.piston_id);
  var new_x_right = new_pos_right.x;
  var new_y_right = new_pos_right.y;

  var rightPoint = d3.select(this).datum()[closestRight.id];

  dots[d3.select(this).attr('id')].filter(function (d, i) {
    return i === closestRight.point.id - 1;
  }).attr('cx', x(new_x_right)).attr('cy', y(new_y_right));

  d3.select(this).attr('d', line);
}

function dragLineEnded(d) {
  closestLeft.point = null;
  closestLeft.distance = Infinity;
  closestRight.point = null;
  closestRight.distance = Infinity;
}

function dragDotStarted(d) {
  d3.select(this).raise().classed('active', true);
}

function draggingDot(d) {
  var coords = d3.mouse(this);
  var new_x = movePoint(d, coords[0], coords[1], d.piston_id).x;
  d3.select(this).attr('cx', x(new_x)).attr('cy', y(d.y));
  paths[d.piston_id].attr('d', line);
}

function dragDotEnded(d) {
  d3.select(this).classed('active', false);
}

function scrubLine(d) {
  var new_x = d3.event.x;
  if (new_x > x(max_x + 0.2)) {
    new_x = x(max_x + 0.2);
  }
  if (new_x < x(min_x - 0.2)) {
    new_x = x(min_x - 0.2);
  }
  d3.select(this).attr('x1', new_x).attr('x2', new_x);
}

// setup logic

function high(piston_id) {
  return 0.4 + 0.05 * piston_id;
}
function low(piston_id) {
  return 0.1 + 0.05 * piston_id;
}
function midPoint(piston_id) {
  return (high(piston_id) + low(piston_id)) / 2;
}

function addData(piston_id) {
  datas[piston_id] = [{
    x: 1,
    y: high(piston_id),
    id: 1,
    piston_id: piston_id,
    state: STATES.HIGH
  }, {
    x: 2,
    y: low(piston_id),
    id: 2,
    piston_id: piston_id,
    state: STATES.LOW
  }, {
    x: 3,
    y: low(piston_id),
    id: 3,
    piston_id: piston_id,
    state: STATES.LOW
  }, {
    x: 4,
    y: high(piston_id),
    id: 4,
    piston_id: piston_id,
    state: STATES.HIGH
  }, {
    x: 5,
    y: high(piston_id),
    id: 5,
    piston_id: piston_id,
    state: STATES.HIGH
  }];
  return datas[piston_id];
}

function addPath(color, id) {
  var path_data = addData(id);
  paths[id] = g.append('path').datum(path_data).attr('fill', 'none').attr('stroke', color).attr('stroke-linejoin', 'round').attr('stroke-linecap', 'round').attr('stroke-width', 3).attr('d', line).attr('id', id).call(dragLine);
  dots[id] = addDots(path_data, id);
}

function addDots(dot_data, id) {
  return g.append('g').attr('fill-opacity', 1).selectAll('circle').data(dot_data).enter().append('circle').attr('id', id).attr('cx', function (d) {
    return x(d.x);
  }).attr('cy', function (d) {
    return y(d.y);
  }).attr('r', 3.5).call(dragDot);
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

function update_pistons(id) {
  if (!paths.has(id)) {
    addPath(colors[datas.length], id);
  }
}