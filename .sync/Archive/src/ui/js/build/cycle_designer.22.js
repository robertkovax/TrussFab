'use strict';

var paused = false;
var max_x = 5;
var min_x = 1;

var tabBarHeight = d3.select('#actuators-tab').node().getBoundingClientRect().height;
var bodyHeight = document.body.clientHeight;
console.log(tabBarHeight);
console.log(bodyHeight);

var schedulingElement = d3.select('#scheduling');
// const schedulingElementHeight = schedulingElement.node().getBoundingClientRect().height;
var schedulingElementHeight = bodyHeight - tabBarHeight - 4; // magic number 4, padding?
var schedulingElementWidth = schedulingElement.node().getBoundingClientRect().width;

console.log(schedulingElementHeight);

var svg = schedulingElement.append("svg").attr("width", schedulingElementWidth).attr("height", schedulingElementHeight);
var margin = { top: 10, right: 10, bottom: 15, left: 10 };
var width = +svg.attr('width') - margin.left - margin.right;
var height = +svg.attr('height') - margin.top - margin.bottom;
var g = svg.append('g').attr('transform', 'translate(' + margin.left + ',' + margin.top + ')');

var datas = [];
var paths = new Map();
var dots = {};

var x = d3.scaleLinear().domain([0, 10]).range([0, width]);

var y = d3.scaleLinear().range([height, 0]);

var drag = d3.drag().on('start', dragstarted).on('drag', dragged).on('end', dragended);

var closestLeft = { point: null, distance: Infinity, id: 0 };
var closestRight = { point: null, distance: Infinity, id: 0 };
var dragLine = d3.drag().on('start', function (d, i) {
  var dots = d3.select(this).datum();
  var event = d3.event;
  dots.forEach(function (dot) {
    var distance = distanceBetweenTwoPoints(event.x, event.y, x(dot[0]), y(dot[1]));
    if (event.x < x(dot[0])) {
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
}).on('drag', function (d, i) {
  var new_x_left = movePoint(closestLeft.point, x(closestLeft.point[0]) + d3.event.dx, 0, closestLeft.point[3]);
  var leftPoint = d3.select(this).datum()[closestLeft.id];

  dots[d3.select(this).attr('id')].filter(function (d, i) {
    return i === closestLeft.point[2] - 1;
  }).attr('cx', x(new_x_left)).attr('cy', y(closestLeft.point[1]));

  var new_x_right = movePoint(closestRight.point, x(closestRight.point[0]) + d3.event.dx, 0, closestRight.point[3]);
  var rightPoint = d3.select(this).datum()[closestRight.id];

  dots[d3.select(this).attr('id')].filter(function (d, i) {
    return i === closestRight.point[2] - 1;
  }).attr('cx', x(new_x_right)).attr('cy', y(closestRight.point[1]));

  d3.select(this).attr('d', line);
}).on('end', function (d, i) {
  closestLeft.point = null;
  closestLeft.distance = Infinity;
  closestRight.point = null;
  closestRight.distance = Infinity;
});

var scrub = d3.drag().on('drag', function (d, i) {
  var new_x = d3.event.x;
  if (new_x > x(max_x)) {
    new_x = x(max_x);
  }
  if (new_x < x(min_x)) {
    new_x = x(min_x);
  }
  d3.select(this).attr('x1', new_x).attr('x2', new_x);
});

// the red vertical line indicating the current progression in the cycle
var line = d3.line().x(function (d) {
  return x(d[0]);
}).y(function (d) {
  return y(d[1]);
});

var brush = d3.brushX().extent([[0, 0], [width, height]]).on('start brush', brushed);

function addData(piston_id) {
  var high = 0.9 + 0.1 * datas.length;
  var low = 0.1 + 0.1 * datas.length;
  datas[piston_id] = [[1, high, 1, piston_id], [2, low, 2, piston_id], [3, low, 3, piston_id], [4, high, 4, piston_id], [5, high, 5, piston_id]];
  return datas[piston_id];
}

function addPath(color, id) {
  var path_data = addData(id);
  paths[id] = g.append('path').datum(path_data).attr('fill', 'none').attr('stroke', color).attr('stroke-linejoin', 'round').attr('stroke-linecap', 'round').attr('stroke-width', 3).attr('d', line).attr('id', id).call(dragLine);
  dots[id] = addDots(path_data, id);
}

function addDots(dot_data, id) {
  return g.append('g').attr('fill-opacity', 1).selectAll('circle').data(dot_data).enter().append('circle').attr('id', id).attr('cx', function (d) {
    return x(d[0]);
  }).attr('cy', function (d) {
    return y(d[1]);
  }).attr('r', 3.5).call(drag);
}

var colors = ['#FF6633', '#FFB399', '#FF33FF', '#FFFF99', '#00B3E6', '#E6B333', '#3366E6', '#999966', '#99FF99', '#B34D4D', '#80B300', '#809900', '#E6B3B3', '#6680B3', '#66991A', '#FF99E6', '#CCFF1A', '#FF1A66', '#E6331A', '#33FFCC', '#66994D', '#B366CC', '#4D8000', '#B33300', '#CC80CC', '#66664D', '#991AFF', '#E666FF', '#4DB3FF', '#1AB399', '#E666B3', '#33991A', '#CC9999', '#B3B31A', '#00E680', '#4D8066', '#809980', '#E6FF80', '#1AFF33', '#999933', '#FF3380', '#CCCC00', '#66E64D', '#4D80CC', '#9900B3', '#E64D66', '#4DB380', '#FF4D4D', '#99E6E6', '#6666FF'];

g.append('line').attr('x1', x(min_x)).attr('y1', 0).attr('x2', x(min_x)).attr('y2', 100).style('stroke-width', 2).style('stroke', 'red').style('fill', 'none').call(scrub);

g.append('g').attr('transform', 'translate(0,' + height + ')').call(d3.axisBottom(x));

function updateData() {
  if (paused) {
    return;
  }
  var line = d3.select('line');
  var old_x = x.invert(line.attr('x1'));
  var new_x = x(min_x);
  if (old_x <= max_x) {
    var new_x = x(old_x + 0.01);
  }
  d3.selectAll('circle').each(function (circle) {
    if (circle != d3.selectAll('circle')[0]) {
      var diff = Math.abs(new_x - x(circle[0]));
      if (diff < 0.2) {
        if (circle[2] == 1) {
          retract(circle[3]);
        } else if (circle[2] == 3) {
          expand(circle[3]);
        } else if (circle[2] == 2 || circle[2] == 4) {
          stop(circle[3]);
        }
      }
    }
  });
  line.attr('x1', new_x);
  line.attr('x2', new_x);
}

var inter = setInterval(function () {
  updateData();
}, 10);

function beforebrushed() {
  d3.event.stopImmediatePropagation();
  d3.select(this.parentNode).transition().call(brush.move, x.range());
}

function brushed() {
  var extent = d3.event.selection.map(x.invert, x);
  dot.classed('selected', function (d) {
    return extent[0] <= d[0] && d[0] <= extent[1];
  });
}

function dragstarted(d) {
  d3.select(this).raise().classed('active', true);
}

function getCircleWithID(id, selection) {
  return selection.filter(function (circle, i) {
    return i == id - 1;
  });
}

function distanceBetweenTwoPoints(x1, y1, x2, y2) {
  var a = x1 - x2;
  var b = y1 - y2;

  return Math.sqrt(a * a + b * b);
}

function movePoint(point, x_pos, y_pos, id) {
  var next = getCircleWithID(point[2] + 1, dots[id]);
  if (!next.empty()) {
    max_x = next.data()[0][0] - 0.05;
  }
  var prev = getCircleWithID(point[2] - 1, dots[id]);
  if (!prev.empty()) {
    min_x = prev.data()[0][0] + 0.05;
  }

  var new_x = Math.min(Math.max(min_x, x.invert(x_pos)), max_x);
  point[0] = new_x;
  return new_x;
}

function dragged(d) {
  new_x = movePoint(d, d3.event.x, d3.event.y, d[3]);
  d3.select(this).attr('cx', x(new_x)).attr('cy', y(d[1]));
  paths[d[3]].attr('d', line);
}

function dragended(d) {
  d3.select(this).classed('active', false);
}

function expand(id) {
  sketchup.expand_actuator(id);
}

function retract(id) {
  sketchup.retract_actuator(id);
}

function stop(id) {
  sketchup.stop_actuator(id);
}

function pause_unpause() {
  paused = !paused;
}

function update_pistons(id) {
  console.log("Updating pistons");
  if (!paths.has(id)) {
    addPath(colors[datas.length], id);
  }
}