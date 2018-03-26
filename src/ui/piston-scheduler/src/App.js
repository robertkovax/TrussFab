import React, { Component } from 'react';
import * as d3 from 'd3';

import logo from './logo.svg';
import './App.css';
import { toggleDiv } from './util';
import { getInterpolationForTime } from './serious-math';

const xAxis = 300;
const yAxis = 50;
const timelineStepSeconds = 10;

class App extends Component {
  constructor(props) {
    super(props);
    this.state = {
      pistons: [],
      keyframes: new Map(),
      seconds: 5,
      timeSelection: new Map(),
      simulationPaused: true,
      timlineInterval: null,
      timelineCurrentTime: 0,
    };
  }

  componentDidMount() {
    window.addPiston = this.addPiston;
  }

  addPiston = id => {
    console.log('id', id);

    // const id = this.state.pistons.length;
    const oldKeyframes = this.state.keyframes;
    this.setState({
      pistons: this.state.pistons.concat(id),
      keyframes: oldKeyframes.set(id, [
        { time: 0, value: 1 },
        { time: this.state.seconds, value: 1 },
      ]), // init
    });
  };

  addKeyframe = event => {
    const pistonId = parseInt(event.currentTarget.id);
    const value = event.currentTarget.previousSibling.value / 100;
    const time = parseFloat(
      event.currentTarget.previousSibling.previousSibling.previousSibling.value
    );

    const oldKeyframes = this.state.keyframes;
    const oldKeyframesPiston = oldKeyframes.get(pistonId) || [];
    const keyframes = oldKeyframes.set(
      pistonId,
      oldKeyframesPiston.concat({ time, value }).sort((a, b) => a.time - b.time)
    );
    this.setState({ keyframes });
  };

  renderGraph = id => {
    const keyframes = this.state.keyframes.get(id) || [];

    const points = keyframes.map(kf => {
      return [kf.time * xAxis / this.state.seconds, (1 - kf.value) * yAxis];
    });

    const viewBox = `0 0 ${xAxis} ${yAxis}`;
    const pointsString = points.map(p => p.join(',')).join('\n');

    const oldKeyframesMap = this.state.keyframes;

    const deleteCircle = keyframeIndex => {
      this.setState({
        keyframes: oldKeyframesMap.set(
          id,
          oldKeyframesMap.get(id).filter((_, index) => index !== keyframeIndex)
        ),
      });
    };

    const circles = points.map((x, index) => (
      <circle
        onClick={() => deleteCircle(index)}
        cx={x[0]}
        cy={x[1]}
        r="4"
        fill="#0074d9"
      />
    ));

    return (
      <div style={{ position: 'relative' }}>
        <svg viewBox={viewBox} className="chart" id={`svg-${id}`}>
          <polyline
            fill="none"
            stroke="#0074d9"
            strokeWidth="3"
            points={pointsString}
          />
          {circles}
        </svg>
        <span
          style={{ position: 'absolute', bottom: 0, left: 0, fontSize: 10 }}
        >
          0s
        </span>
        <span
          style={{
            position: 'absolute',
            bottom: 0,
            right: xAxis / 2,
            fontSize: 10,
          }}
        >
          {this.state.seconds / 2}s
        </span>
        <span
          style={{ position: 'absolute', bottom: 0, right: 0, fontSize: 10 }}
        >
          {this.state.seconds}s
        </span>
      </div>
    );
  };

  addTimeSelectionForNewKeyFrame = id => {
    const self = this;
    function scrubLine() {
      let newX = d3.event.x;
      newX = Math.min(Math.max(0, newX), xAxis);

      const oldTimeSelection = self.state.timeSelection;

      self.setState({
        timeSelection: oldTimeSelection.set(
          id,
          (newX / xAxis * self.state.seconds).toFixed(1)
        ),
      });

      d3
        .select(this)
        .attr('x1', newX)
        .attr('x2', newX);
    }

    const scrub = d3.drag().on('drag', scrubLine);

    d3
      .select('#svg-' + id)
      .append('line')
      .classed('timeSelection', true)
      .attr('x1', xAxis / 2)
      .attr('y1', 0)
      .attr('x2', xAxis / 2)
      .attr('y2', yAxis)
      .style('stroke-width', 3)
      .style('stroke', 'red')
      .style('fill', 'none')
      .call(scrub);
  };

  playOneTimelineStep = () => {
    let timelineCurrentTime =
      this.state.timelineCurrentTime + timelineStepSeconds;

    if (timelineCurrentTime / 1000 > this.state.seconds) {
      timelineCurrentTime = 0;
    }

    const timelineCurrentTimeSeconds = timelineCurrentTime / 1000;

    this.state.keyframes.forEach((value, key) => {
      const bla = getInterpolationForTime(timelineCurrentTimeSeconds, value);
      console.log(key, bla[0]);
      // TODO move actuators
    });

    const newX = timelineCurrentTimeSeconds * xAxis / this.state.seconds;

    d3
      .selectAll('line.timeline')
      .attr('x1', newX)
      .attr('x2', newX);

    this.setState({
      timelineCurrentTime,
    });
  };

  toggelSimulation = () => {
    const { simulationPaused } = this.state;

    if (simulationPaused) {
      const timlineInterval = setInterval(
        this.playOneTimelineStep,
        timelineStepSeconds
      );
      this.setState({ timlineInterval });

      d3
        .selectAll('svg')
        .append('line')
        .classed('timeline', true)
        .attr('x1', 0)
        .attr('y1', 0)
        .attr('x2', 0)
        .attr('y2', yAxis)
        .style('stroke-width', 1)
        .style('stroke', '#D3D3D3')
        .style('fill', 'none');
    } else {
      clearInterval(this.state.timlineInterval);

      d3.selectAll('line.timeline').remove();
    }

    this.setState({ simulationPaused: !simulationPaused });
  };

  resetSimulation = () => {
    return;
  };

  removeTimeSelectionForNewKeyFrame = id => {
    d3
      .select('#svg-' + id)
      .select('line.timeSelection')
      .remove();
    const oldTimeSelection = this.state.timeSelection;
    this.setState({
      timeSelection: oldTimeSelection.set(id, this.state.seconds / 2),
    });
  };

  newKeyframeToggle = id => {
    toggleDiv(`add-kf-${id}`);
    toggleDiv(`new-kf-${id}`);
  };

  onTimeSelectionInputChange = (id, value) => {
    this.setState({ timeSelection: this.state.timeSelection.set(id, value) });

    const newX = value / this.state.seconds * xAxis;

    const line = d3
      .select('#svg-' + id)
      .select('line')
      .attr('x1', newX)
      .attr('x2', newX);
  };

  render() {
    const pistons = this.state.pistons.map(x => (
      <div>
        <div
          style={{
            display: 'flex',
            alignContent: 'flex-start',
            alignItems: 'flex-start',
          }}
        >
          <div>Piston {x}</div>
          {this.renderGraph(x)}
          <button
            id={`new-kf-${x}`}
            onClick={() => {
              this.newKeyframeToggle(x);
              this.addTimeSelectionForNewKeyFrame(x);
            }}
          >
            new keyframe
          </button>
        </div>
        <div id={`add-kf-${x}`} style={{ display: 'none' }}>
          Time:
          <input
            type="number"
            step="0.1"
            min="0"
            max={this.state.seconds}
            value={this.state.timeSelection.get(x) || this.state.seconds / 2}
            onChange={event =>
              this.onTimeSelectionInputChange(x, event.currentTarget.value)
            }
          />
          Position: <input type="range" />
          <button onClick={this.addKeyframe} id={x}>
            add keyframe
          </button>
          <button
            onClick={() => {
              this.newKeyframeToggle(x);
              this.removeTimeSelectionForNewKeyFrame(x);
            }}
          >
            cancel
          </button>
        </div>
      </div>
    ));
    return (
      <div className="App">
        Seconds
        <input
          type="number"
          value={this.state.seconds}
          onChange={event => this.setState({ seconds: event.target.value })}
        />
        <button onClick={this.toggelSimulation}>
          {this.state.simulationPaused ? 'Start' : 'Pause'}
        </button>
        {!this.state.simulationPaused && (
          <span>{(this.state.timelineCurrentTime / 1000).toFixed(1)}s</span>
        )}
        {pistons}
        {/* <button onClick={this.addPiston}>Add Piston</button> */}
      </div>
    );
  }
}

export default App;
