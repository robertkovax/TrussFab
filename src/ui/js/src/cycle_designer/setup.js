import { select } from 'd3';

const margin = {
  top: 10,
  right: 10,
  bottom: 20,
  left: 10,
};

function buildSVG() {
  const tabBarHeight = select('#actuators-tab')
    .node()
    .getBoundingClientRect().height;

  const bodyHeight = select('body')
    .node()
    .getBoundingClientRect().height;

  const schedulingElement = select('#scheduling');
  const schedulingElementHeight = bodyHeight - tabBarHeight - 6; // magic number 4, padding?
  const schedulingElementWidth = schedulingElement
    .node()
    .getBoundingClientRect().width;

  const svg = schedulingElement
    .append('svg')
    .attr('width', schedulingElementWidth)
    .attr('height', schedulingElementHeight);

  const width = svg.attr('width') - margin.left - margin.right;
  const height = svg.attr('height') - margin.top - margin.bottom;

  const g = svg
    .append('g')
    .attr('transform', `translate(${margin.left},${margin.top})`);

  return { g, width, height };
}

export { buildSVG };
