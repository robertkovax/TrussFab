import React, { Component } from 'react';
import * as d3 from 'd3';

import './css/App.css';
import { toggleDiv } from './utils/dom';
import { setStiffness, persistKeyframes } from './utils/sketchup-integration';
import Piston from './components/Piston';
import SimulationControls from './components/SimulationControls';
import { X_AXIS, Y_AXIS } from './config';

class App extends Component {
  constructor(props) {
    super(props);
    this.state = {
      breakingForce: 1000,
      currentCycle: 0,
      devMode: false,
      displayVol: false,
      highestForceMode: false,
      groupVisible: {}, // group id => bool
      keyframesMap: new Map(), // maps from piston id to array of keyframes
      peakForceMode: false,
      pistons: [], // this is not actually needed because we have `keyframesMap`
      previousKeyframesMap: null, // use for greyed points when something broke
      seconds: 8,
      simluationBrokeAt: null,
      simulationIsOnForValueTesting: false,
      simulationIsPausedAfterOnce: false,
      simulationPaused: true,
      startedSimulationCycle: false,
      startedSimulationOnce: false,
      stiffness: 92, // gets ignored if not changed
      timelineCurrentTime: 0,
      timeSelection: new Map(), // map from piston id
      timlineInterval: null,
      windowCollapsed: true,
    };
  }

  initState = (breakingForce, stiffness) => {
    this.setState({ breakingForce, stiffness });
  };

  componentDidMount() {
    window.addPiston = this.addPiston;
    window.addPistonWithAnimation = this.addPistonWithAnimation;
    window.persistKeyframes = this.persistKeyframes;
    window.cleanupUiAfterStoppingSimulation = this.cleanupUiAfterStoppingSimulation;
    window.simulationJustBroke = this.simulationJustBroke;
    window.fixBrokenModelByReducingSpeed = this.fixBrokenModelByReducingSpeed;
    window.fixBrokenModelByReducingMovement = this.fixBrokenModelByReducingMovement;
    window.initState = this.initState;
    window.syncHiddenStatus = this.syncHiddenStatus;

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

  cleanupUiAfterStoppingSimulation = () => {
    this.resetState();
  };

  syncHiddenStatus = newGroupVisible => {
    this.setState({
      groupVisible: newGroupVisible,
    });
  };

  addPiston = id => {
    if (this.state.pistons.includes(id)) {
      return;
    }
    const oldKeyframes = this.state.keyframesMap;
    const oldPistons = this.state.pistons;
    this.setState({
      pistons: oldPistons.concat(id),
      keyframesMap: oldKeyframes.set(id, [
        { time: 0, value: 0.5 },
        { time: this.state.seconds, value: 0.5 },
      ]), // init
    });
    persistKeyframes(JSON.stringify([...this.state.keyframesMap]));
    setTimeout(() => {
      this.addTimeSelectionForNewKeyFrame(id);
    }, 100);
  };

  addPistonWithAnimation = animation => {
    const animationMap = new Map(animation);
    animationMap.forEach((keyframes, id) => {
      if (this.state.pistons.includes(id)) {
        return;
      }
      this.setState({
        pistons: this.state.pistons.concat(id),
        keyframes: this.state.keyframesMap.set(id, keyframes),
      });
      setTimeout(() => {
        this.addTimeSelectionForNewKeyFrame(id);
      }, 100);
    });
    persistKeyframes(JSON.stringify([...this.state.keyframes]));
  };

  addTimeSelectionForNewKeyFrame = id => {
    const self = this;

    function scrubLine() {
      let newX = d3.event.x;
      newX = Math.min(Math.max(0, newX), X_AXIS);

      const oldTimeSelection = self.state.timeSelection;

      self.setState({
        timeSelection: oldTimeSelection.set(
          id,
          (newX / X_AXIS * self.state.seconds).toFixed(1)
        ),
      });

      d3
        .select(this)
        .attr('x1', newX)
        .attr('x2', newX);
    }

    const scrub = d3.drag().on('drag', scrubLine);

    // the vertical timeline
    d3
      .select('#svg-' + id)
      .append('line')
      .classed('timeSelection', true)
      .attr('x1', 0)
      .attr('y1', 0)
      .attr('x2', 0)
      .attr('y2', Y_AXIS)
      .style('stroke-width', 3)
      .style('stroke', 'grey')
      .style('fill', 'none')
      .call(scrub);
  };

  fixBrokenModelByReducingMovement = () => {
    const previousKeyframesMap = new Map();
    const keyframesMap = this.state.keyframesMap;

    this.state.pistons.forEach((pistonId, id) => {
      const oldKeyframe = this.state.keyframesMap.get(id);
      previousKeyframesMap.set(id, oldKeyframe);

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
    this.setState({ previousKeyframesMap, keyframesMap });
  };

  fixBrokenModelByReducingSpeed = () => {
    const previousKeyframesMap = new Map();
    const keyframesMap = this.state.keyframesMap;

    this.state.pistons.forEach((pistonId, id) => {
      const oldKeyframe = this.state.keyframesMap.get(id);
      previousKeyframesMap.set(id, oldKeyframe);

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
    this.setState({ previousKeyframesMap, keyframesMap });
  };

  resetState = () => {
    SimulationControls.removeLines();
    clearInterval(this.state.timlineInterval);
    // some race condition with the 'broken sim' requires this
    setTimeout(() => {
      this.setState({
        currentCycle: 0,
        previousKeyframesMap: null,
        simluationBrokeAt: null,
        simulationIsPausedAfterOnce: false,
        simulationPaused: true,
        startedSimulationCycle: false,
        startedSimulationOnce: false,
        timelineCurrentTime: 0,
      });
    }, 100);
  };

  newKeyframeToggle = id => {
    toggleDiv(`add-kf-${id}`);
    toggleDiv(`new-kf-${id}`);
  };

  onTimeSelectionInputChange = (id, value) => {
    this.setState({ timeSelection: this.state.timeSelection.set(id, value) });

    const newX = value / this.state.seconds * X_AXIS;

    d3
    .select('#svg-' + id)
    .select('line')
    .attr('x1', newX)
    .attr('x2', newX);
  };

  render() {
    const {
      currentCycle,
      devMode,
      keyframesMap,
      pistons,
      previousKeyframesMap,
      seconds,
      simluationBrokeAt,
      simulationIsOnForValueTesting,
      simulationIsPausedAfterOnce,
      simulationPaused,
      startedSimulationCycle,
      startedSimulationOnce,
      timelineCurrentTime,
      timeSelection,
      timlineInterval,
      windowCollapsed,
    } = this.state;

    const simulationIsRunning = startedSimulationCycle || startedSimulationOnce;
    const pistonElements = pistons
      .filter(x => this.state.groupVisible[x] === true) // filter out hidden ids
      .map((id, index) => (
        <Piston
          currentCycle={currentCycle}
          devMode={devMode}
          id={id}
          index={index}
          key={id}
          keyframesMap={keyframesMap}
          previousKeyframesMap={previousKeyframesMap}
          seconds={seconds}
          setContainerState={this.setContainerState}
          simluationBrokeAt={simluationBrokeAt}
          simulationIsOnForValueTesting={simulationIsOnForValueTesting}
          simulationIsRunning={simulationIsRunning}
          startedSimulationOnce={startedSimulationOnce}
          timelineCurrentTime={timelineCurrentTime}
          timeSelection={timeSelection}
        />
      ));

    return (
      <div className="row no-gutters">
        <SimulationControls
          addTimeSelectionForNewKeyFrame={this.addTimeSelectionForNewKeyFrame}
          devMode={devMode}
          keyframesMap={keyframesMap}
          pistons={pistons}
          resetState={this.resetState}
          seconds={seconds}
          setContainerState={this.setContainerState}
          simulationIsOnForValueTesting={simulationIsOnForValueTesting}
          simulationIsPausedAfterOnce={simulationIsPausedAfterOnce}
          simulationPaused={simulationPaused}
          startedSimulationCycle={startedSimulationCycle}
          startedSimulationOnce={startedSimulationOnce}
          timelineCurrentTime={timelineCurrentTime}
          timlineInterval={timlineInterval}
          windowCollapsed={windowCollapsed}
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
