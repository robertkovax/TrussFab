import React, { Component } from 'react';
import * as d3 from 'd3';

import './App.css';
import { toggleDiv } from './util';
import { getInterpolationForTime } from './serious-math';
import {
  togglePane,
  toggleSimulation,
  moveJoint,
  togglePauseSimulation,
  setBreakingForce,
  getBreakingForce,
  setMaxSpeed,
  changeHighestForceMode,
  setStiffness,
  getStiffness,
  changePeakForceMode,
  changeDisplayValues,
  changePistonValue,
} from './sketchup-integration';

import Piston from './components/Piston';
import SimulationControls from './components/SimulationControls';

import { xAxis, yAxis, timelineStepSeconds, FACTOR } from './config';

class App extends Component {
  constructor(props) {
    super(props);
    this.state = {
      pistons: [],
      keyframesMap: new Map(),
      seconds: 8,
      timeSelection: new Map(),
      simulationPaused: true,
      timlineInterval: null,
      timelineCurrentTime: 0,
      startedSimulationCycle: false,
      startedSimulationOnce: false,
      simulationIsPausedAfterOnce: false,
      currentCycle: 0,
      highestForceMode: false,
      peakForceMode: false,
      displayVol: false,
      breakingForce: 1000,
      stiffness: 92, // get ignored if not changed
      simluationBrokeAt: null,
      simulationIsOnForValueTesting: false,
      oldKeyframesUIST: null,
      windowCollapsed: true,
      devMode: false,
    };
  }

  initState = (breakingForce, stiffness) => {
    this.setState({ breakingForce, stiffness });
  };

  componentDidMount() {
    window.addPiston = this.addPiston;
    window.cleanupUiAfterStoppingSimulation = this.cleanupUiAfterStoppingSimulation;
    window.simulationJustBroke = this.simulationJustBroke;
    window.fixBrokenModelByReducingSpeed = this.fixBrokenModelByReducingSpeed;
    window.fixBrokenModelByReducingMovement = this.fixBrokenModelByReducingMovement;
    window.initState = this.initState;

    setStiffness(this.state.stiffness);
  }

  setContainerState = newState => {
    this.setState(newState);
  };

  simulationJustBroke = () => {
    if (this.state.simluationBrokeAt === null) {
      window.showModal();
      this.setState({ simluationBrokeAt: this.state.timelineCurrentTime });
    }
  };

  addPiston = id => {
    if (this.state.pistons.includes(id)) {
      return;
    }
    const oldKeyframes = this.state.keyframesMap;
    const oldPistons = this.state.pistons;
    this.setState({
      pistons: oldPistons.concat(id),
      keyframes: oldKeyframes.set(id, [
        { time: 0, value: 0.5 },
        { time: this.state.seconds, value: 0.5 },
      ]), // init
    });
    setTimeout(() => {
      this.addTimeSelectionForNewKeyFrame(id);
    }, 100);
  };

  cleanupUiAfterStoppingSimulation = () => {
    this.resetState();
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
      // .attr('x1', xAxis / 2) // for init in the middle
      .attr('x1', 0)
      .attr('y1', 0)
      // .attr('x2', xAxis / 2) // for init in the middle
      .attr('x2', 0)
      .attr('y2', yAxis)
      .style('stroke-width', 3)
      .style('stroke', 'grey')
      .style('fill', 'none')
      .call(scrub);
  };

  fixBrokenModelByReducingMovement = () => {
    const oldKeyframesUIST = new Map();
    const keyframesMap = this.state.keyframesMap;

    this.state.pistons.map((pistonId, id) => {
      const oldKeyframe = this.state.keyframesMap.get(id);
      oldKeyframesUIST.set(id, oldKeyframe);

      const newKeyframe = oldKeyframe.map((x, keyframeIndex) => {
        return {
          value:
            keyframeIndex === 0 || keyframeIndex === oldKeyframe.length - 1
              ? x.value
              : x.value * 0.8,
          time: x.time,
        };
      });

      keyframesMap.set(id, newKeyframe);
    });
    // finally update state
    this.setState({ oldKeyframesUIST, keyframesMap });
  };

  fixBrokenModelByReducingSpeed = () => {
    const oldKeyframesUIST = new Map();
    const keyframesMap = this.state.keyframesMap;

    this.state.pistons.map((pistonId, id) => {
      const oldKeyframe = this.state.keyframesMap.get(id);
      oldKeyframesUIST.set(id, oldKeyframe);

      const newKeyframe = oldKeyframe
        .map(x => {
          return {
            value: x.value,
            time:
              x.time * 2 < this.state.seconds
                ? x.time * 2
                : x.time === this.state.seconds
                  ? x.time
                  : null,
          };
        })
        .filter(x => x.time !== null);

      keyframesMap.set(id, newKeyframe);
    });
    // finally update state
    this.setState({ oldKeyframesUIST, keyframesMap });
  };

  resetState = () => {
    SimulationControls.removeLines();
    clearInterval(this.state.timlineInterval);
    // some race condition with the 'broken sim' requires this
    setTimeout(() => {
      this.setState({
        simulationPaused: true,
        timelineCurrentTime: 0,
        currentCycle: 0,
        startedSimulationOnce: false,
        startedSimulationCycle: false,
        simulationIsPausedAfterOnce: false,
        simluationBrokeAt: null,
        oldKeyframesUIST: null,
      });
    }, 100);
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
    const {
      startedSimulationCycle,
      startedSimulationOnce,
      seconds,
      timeSelection,
      simulationIsPausedAfterOnce,
      simulationIsOnForValueTesting,
      keyframesMap,
      simluationBrokeAt,
      simulationPaused,
      devMode,
      windowCollapsed,
      pistons,
      currentCycle,
      timelineCurrentTime,
      timlineInterval,
    } = this.state;

    const simulationIsRunning = startedSimulationCycle || startedSimulationOnce;
    const pistonElements = pistons.map((x, index) => (
      <Piston
        key={x.id}
        x={x}
        index={index}
        simulationIsRunning={simulationIsRunning}
        setContainerState={this.setContainerState}
        seconds={seconds}
        timeSelection={timeSelection}
        simulationIsOnForValueTesting={simulationIsOnForValueTesting}
        keyframesMap={keyframesMap}
        simluationBrokeAt={simluationBrokeAt}
        currentCycle={currentCycle}
        startedSimulationOnce={startedSimulationOnce}
        timelineCurrentTime={timelineCurrentTime}
      />
    ));

    return (
      <div className="row no-gutters">
        <SimulationControls
          seconds={seconds}
          timelineCurrentTime={timelineCurrentTime}
          keyframesMap={keyframesMap}
          setContainerState={this.setContainerState}
          resetState={this.resetState}
          pistons={pistons}
          addTimeSelectionForNewKeyFrame={this.addTimeSelectionForNewKeyFrame}
          startedSimulationCycle={startedSimulationCycle}
          startedSimulationOnce={startedSimulationOnce}
          simulationPaused={simulationPaused}
          devMode={devMode}
          windowCollapsed={windowCollapsed}
          timlineInterval={timlineInterval}
          simulationIsPausedAfterOnce={simulationIsPausedAfterOnce}
          simulationIsOnForValueTesting={simulationIsOnForValueTesting}
        />
        {!windowCollapsed && (
          <div className="col-8">
            <div className="App">{pistonElements}</div>
          </div>
        )}
      </div>
    );
  }
}

export default App;
