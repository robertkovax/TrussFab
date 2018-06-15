import React, { Component } from 'react';
import * as d3 from 'd3';

import './css/App.css';
import { toggleDiv } from './utils/dom';
import { persistKeyframes } from './utils/sketchup-integration';
import Piston from './components/Piston';
import SimulationControls from './components/SimulationControls';
import { X_AXIS, Y_AXIS } from './config';

class App extends Component {
  constructor(props) {
    super(props);
    this.state = this.getIninitalState();
  }

  getIninitalState = () => ({
    windowCollapsed: true,
    devMode: false,
    simulationSettings: {
      breakingForce: null,
      stiffness: null,
      displayVol: null,
      highestForceMode: null,
      peakForceMode: null,
    },
    timeline: {
      currentCycle: 0,
      seconds: 8,
      currentTime: 0,
      simluationBrokeAt: null,
      simulationIsOnForValueTesting: false,
      simulationIsPausedAfterOnce: false,
      simulationPaused: true,
      startedSimulationCycle: false,
      startedSimulationOnce: false,
    },
    groupVisible: {}, // group id => bool
    keyframesMap: new Map(), // maps from piston id to array of keyframes
    previousKeyframesMap: null, // use for greyed points when something broke
    pistons: [], // this is not actually needed because we have `keyframesMap`
    timeSelection: new Map(), // map from piston id
  });

  componentDidMount() {
    window.addPiston = this.addPiston;
    window.addPistonWithAnimation = this.addPistonWithAnimation;
    window.persistKeyframes = this.persistKeyframes;
    window.cleanupUiAfterStoppingSimulation = this.cleanupUiAfterStoppingSimulation;
    window.simulationJustBroke = this.simulationJustBroke;
    window.fixBrokenModelByReducingSpeed = this.fixBrokenModelByReducingSpeed;
    window.fixBrokenModelByReducingMovement = this.fixBrokenModelByReducingMovement;
    window.initSimulationState = this.initSimulationState;
    window.syncHiddenStatus = this.syncHiddenStatus;
  }

  /**
   * Initialize the UI state with values from the backend.
   * @param {number} breakingForce
   * @param {number} stiffness
   * @param {boolean} displayVol
   * @param {boolean} highestForceMode
   * @param {boolean} peakForceMode
   */
  initSimulationState = (
    breakingForce,
    stiffness,
    displayVol,
    highestForceMode,
    peakForceMode
  ) => {
    this.setState({
      simulationSettings: {
        breakingForce,
        stiffness,
        displayVol,
        highestForceMode,
        peakForceMode,
      },
    });
  };

  syncHiddenStatus = newGroupVisible => {
    this.setState({
      groupVisible: newGroupVisible,
    });
  };

  setContainerState = newState => {
    const { timeline, simulationSettings } = newState;
    // delete nested state and update it separately
    delete newState.timeline;
    delete newState.simulationSettings;
    this.setState({
      ...newState,
      timeline: { ...this.state.timeline, ...timeline },
      simulationSettings: {
        ...this.state.simulationSettings,
        ...simulationSettings,
      },
    });
  };

  simulationJustBroke = () => {
    if (this.state.timline.simluationBrokeAt === null) {
      window.showModal();
      this.setContainerState({
        timeline: { simluationBrokeAt: this.state.timeline.currentTime },
      });
    }
  };

  cleanupUiAfterStoppingSimulation = () => {
    this.resetState();
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
        { time: this.state.timeline.seconds, value: 0.5 },
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

  /**
   * adds a timeline for a keyframe. NB: The coupling with d3 goes agains the
   * state management with React. For the future, try to get d3 fully out of the
   * project and connect the SVG elements to the state.
   * @param {number} id piston group id
   */
  addTimeSelectionForNewKeyFrame = id => {
    const self = this;

    /**
     * updates the timeline in the state and for the ui
     * @param {number} newX the new x coordinate relative to the SVG
     */
    function updateLine(newX) {
      const newXBounded = Math.min(Math.max(0, newX), X_AXIS);
      const oldTimeSelection = self.state.timeSelection;

      self.setState({
        timeSelection: oldTimeSelection.set(
          id,
          (newXBounded / X_AXIS * self.state.timeline.seconds).toFixed(1)
        ),
      });

      d3
        .select('#svg-' + id)
        .select('.timeSelection')
        .attr('x1', newXBounded)
        .attr('x2', newXBounded);
    }

    function scrubLine() {
      const newX = d3.event.x;
      updateLine(newX);
    }

    function moveTimelineByClicking() {
      const newX = d3.mouse(this)[0]; // get X relative to SVG
      updateLine(newX);
    }

    d3.select(`#svg-${id}`).on('click', moveTimelineByClicking);

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
    const { keyframesMap, timeline, pistons } = this.state;

    const previousKeyframesMap = new Map();

    pistons.forEach((pistonId, id) => {
      const oldKeyframe = keyframesMap.get(id);
      previousKeyframesMap.set(id, oldKeyframe);

      const newKeyframe = oldKeyframe
        .map(x => {
          return {
            value: x.value,
            time:
              x.time * 2 < timeline.seconds
                ? x.time * 2
                : x.time === timeline.seconds
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

    // the interval is a class variable so clear with a class method
    SimulationControls.clearTimelineInterval();

    // some race condition with the 'broken sim' requires the timeout
    setTimeout(() => {
      this.setState({
        timeline: { ...this.getIninitalState().timeline },
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
      timeline,
      simulationSettings,
      timeSelection,
      keyframesMap,
      devMode,
      windowCollapsed,
      pistons,
      previousKeyframesMap,
    } = this.state;

    const simulationIsRunning =
      timeline.startedSimulationCycle || timeline.startedSimulationOnce;
    const pistonElements = pistons
      .filter(x => this.state.groupVisible[x] === true) // filter out hidden ids
      .map((id, index) => (
        <Piston
          key={id}
          id={id}
          index={index}
          simulationIsRunning={simulationIsRunning}
          setContainerState={this.setContainerState}
          timelineSeconds={timeline.seconds}
          currentCycle={timeline.currentCycle}
          timelineCurrentTime={timeline.currentTime}
          timelineSimluationBrokeAt={timeline.simluationBrokeAt}
          timelineSimulationIsOnForValueTesting={
            timeline.simulationIsOnForValueTesting
          }
          timelineStartedSimulationOnce={timeline.startedSimulationOnce}
          timeSelection={timeSelection}
          keyframesMap={keyframesMap}
          devMode={devMode}
          previousKeyframesMap={previousKeyframesMap}
        />
      ));

    return (
      <div className="row no-gutters">
        <SimulationControls
          timeline={timeline}
          simulationSettings={simulationSettings}
          keyframesMap={keyframesMap}
          pistons={pistons}
          devMode={devMode}
          windowCollapsed={windowCollapsed}
          addTimeSelectionForNewKeyFrame={this.addTimeSelectionForNewKeyFrame}
          setContainerState={this.setContainerState}
          resetState={this.resetState}
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
