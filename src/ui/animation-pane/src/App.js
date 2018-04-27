import React, { Component } from 'react';
import * as d3 from 'd3';

import './App.css';
import { toggleDiv } from './util';
import { getInterpolationForTime } from './serious-math';
import {
  togglePane,
  toggleSimulation,
  moveJoint,
  restartSimulation,
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

import { xAxis, yAxis, timelineStepSeconds, FACTOR, DEV } from './config';

class App extends Component {
  constructor(props) {
    super(props);
    this.state = {
      pistons: [],
      keyframes: new Map(),
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
      collapsed: true,
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

    document.addEventListener('keyup', e => {
      // ESC
      if (e.keyCode === 27) {
        this.stopSimulation();
      }
    });
  }

  componentWillUnmount() {
    document.removeEventListener('keyup', this.stopSimulation);
  }

  simulationJustBroke = () => {
    if (this.state.simluationBrokeAt === null) {
      window.showModal();
      this.setState({ simluationBrokeAt: this.state.timelineCurrentTime });
    }
  };

  addPiston = id => {
    // const id = this.state.pistons.length;
    const oldKeyframes = this.state.keyframes;
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

  _addAllTimeSelectionLines = () => {
    this.state.pistons.forEach(x => this.addTimeSelectionForNewKeyFrame(x));
  };

  _removeAllTimeselection = () => d3.selectAll('line.timeSelection').remove();

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

  playOneTimelineStep = () => {
    let { timelineCurrentTime } = this.state;

    if (timelineCurrentTime / 1000 > this.state.seconds) {
      if (this.state.startedSimulationOnce) {
        this._removeInterval();
        this._removeLines();
        // toggleSimulation();
        togglePauseSimulation();

        this.setState({
          startedSimulationOnce: false,
          startedSimulationCycle: false,
          simulationPaused: true,
          timelineCurrentTime: 0,
          currentCycle: 0,
          simulationIsPausedAfterOnce: true,
        });
      } else {
        timelineCurrentTime = 0;
        this.setState({ currentCycle: this.state.currentCycle + 1 });
      }
    }

    const timelineCurrentTimeSeconds = timelineCurrentTime / 1000;

    this.state.keyframes.forEach((value, key) => {
      const keyframes = value;

      for (let i = 0; i < keyframes.length; i++) {
        const x = keyframes[i];
        if (timelineCurrentTime === x.time * 1000) {
          let duration;
          let newValue;
          // check if last one
          if (i === keyframes.length - 1) {
            // newValue = keyframes[0].value;
            // duration = this.state.seconds - x.time; // value until end
          } else {
            newValue = keyframes[i + 1].value;
            duration = keyframes[i + 1].time - x.time; // next

            // some hack because the inital value of the piston is 0
            // so we have to fix it here
            // if (
            //   i === 0 &&
            //   this.state.currentCycle === 0 &&
            //   keyframes[0].value !== keyframes[1].value
            // ) {
            //   console.log('fixing');
            //   if (keyframes[0].value > keyframes[1].value)
            //     newValue -= keyframes[0].value;
            //   else newValue += keyframes[0].value;
            // }
            moveJoint(key, newValue, duration);
          }
        }
      }
    });

    const newX = timelineCurrentTimeSeconds * xAxis / this.state.seconds;

    d3
      .selectAll('line.timeline')
      .attr('x1', newX)
      .attr('x2', newX);

    this.setState({
      timelineCurrentTime: timelineCurrentTime + timelineStepSeconds * FACTOR,
    });
  };

  _startSimulation = playOnce => {
    this._removeLines();
    this._addLines();

    this._removeInterval();
    this._addInterval();

    this._removeAllTimeselection();

    if (this.state.simulationIsPausedAfterOnce) {
      restartSimulation();
    } else {
      if (this.state.simulationIsOnForValueTesting) {
        restartSimulation();
        this.setState({ simulationIsOnForValueTesting: false });
      } else {
        toggleSimulation();
      }
    }

    // TODO
    setBreakingForce(this.state.breakingForce);

    if (playOnce) {
      this.setState({
        startedSimulationOnce: true,
        startedSimulationCycle: false,
        simulationPaused: false,
        timelineCurrentTime: 0,
        currentCycle: 0,
      });
    } else {
      this.setState({
        startedSimulationCycle: true,
        startedSimulationOnce: false,
        simulationPaused: false,
        timelineCurrentTime: 0,
        currentCycle: 0,
      });
    }
  };

  _addInterval = () => {
    const timlineInterval = setInterval(
      this.playOneTimelineStep,
      timelineStepSeconds
    );
    this.setState({ timlineInterval });
  };

  _removeInterval = () => {
    clearInterval(this.state.timlineInterval);
  };

  _addLines = () => {
    d3
      .selectAll('svg')
      .append('line')
      .classed('timeline', true)
      .attr('x1', 0)
      .attr('y1', 0)
      .attr('x2', 0)
      .attr('y2', yAxis)
      // .style('stroke-width', 1)
      .style('stroke-width', 3)
      // .style('stroke', '#D3D3D3')
      .style('stroke', 'grey')
      .style('fill', 'none');
  };

  _removeLines = () => d3.selectAll('line.timeline').remove();

  _togglePause = () => {
    const { simulationPaused } = this.state;
    if (simulationPaused) {
      togglePauseSimulation();
      this.setState({ simulationPaused: !simulationPaused });

      this._addLines();

      this._addInterval();
    } else {
      togglePauseSimulation();
      this._removeInterval();
      this.setState({ simulationPaused: !simulationPaused });
    }
  };

  toggelSimulation = playOnce => {
    const { startedSimulationOnce, startedSimulationCycle } = this.state;

    if (playOnce) {
      if (startedSimulationOnce) {
        this._togglePause();
      } else {
        this._startSimulation(playOnce);
      }
    } else {
      if (startedSimulationCycle) {
        this._togglePause();
      } else {
        this._startSimulation(playOnce);
      }
    }
  };

  fixBrokenModelByReducingMovement = () => {
    const oldKeyframesUIST = new Map();
    const keyframes = this.state.keyframes;

    this.state.pistons.forEach(pistonId => {
      const oldKeyframe = this.state.keyframes.get(pistonId);
      oldKeyframesUIST.set(pistonId, oldKeyframe);

      const newKeyframe = oldKeyframe.map((x, keyframeIndex) => {
        return {
          value:
            keyframeIndex === 0 || keyframeIndex === oldKeyframe.length - 1
              ? x.value
              : x.value * 0.8,
          time: x.time,
        };
      });

      keyframes.set(pistonId, newKeyframe);
    });
    // finally update state
    this.setState({ oldKeyframesUIST, keyframes });
  };

  fixBrokenModelByReducingSpeed = () => {
    const oldKeyframesUIST = new Map();
    const keyframes = this.state.keyframes;

    this.state.pistons.forEach(pistonId => {
      const oldKeyframe = this.state.keyframes.get(pistonId);
      oldKeyframesUIST.set(pistonId, oldKeyframe);

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

      keyframes.set(pistonId, newKeyframe);
    });
    // finally update state
    this.setState({ oldKeyframesUIST, keyframes });
  };

  resetState = () => {
    this._removeLines();
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

  stopSimulation = () => {
    const {
      startedSimulationOnce,
      startedSimulationCycle,
      simulationIsPausedAfterOnce,
    } = this.state;

    if (this.state.simulationIsOnForValueTesting) {
      toggleSimulation();
      this.setState({ simulationIsOnForValueTesting: false });
      return;
    }

    if (
      !(startedSimulationOnce || startedSimulationCycle) &&
      !simulationIsPausedAfterOnce
    ) {
      return;
    }

    this._addAllTimeSelectionLines();
    toggleSimulation();
    this.resetState();
  };

  removeTimeSelectionForNewKeyFrame = id => {
    d3
      .select('#svg-' + id)
      .select('line.timeSelection')
      .remove();
    const oldTimeSelection = this.state.timeSelection;
    this.setState({
      timeSelection: oldTimeSelection.set(
        id,
        this.initialSecondsForTimeSelection()
      ),
    });
  };

  initialSecondsForTimeSelection = () => {
    return 0;
    // return this.state.seconds / 2;
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

  renderForm = () => {
    const { startedSimulationCycle, startedSimulationOnce } = this.state;
    const simulationIsRunning = startedSimulationCycle || startedSimulationOnce;
    return (
      <form>
        <div className="form-check">
          <input
            className="form-check-input"
            type="checkbox"
            value=""
            id="defaultCheck1"
            value={this.state.highestForceMode}
            onChange={event => {
              this.setState({ highestForceMode: event.target.value });
              changeHighestForceMode(event.target.value);
            }}
          />
          <label className="form-check-label" for="defaultCheck1">
            Highest Force
          </label>
        </div>
        <div className="form-check">
          <input
            className="form-check-input"
            type="checkbox"
            value=""
            id="defaultCheck1"
            value={this.state.peakForceMode}
            onChange={event => {
              this.setState({ peakForceMode: event.target.value });
              changePeakForceMode(event.target.value);
            }}
          />
          <label className="form-check-label" for="defaultCheck1">
            Peak Force
          </label>
        </div>
        <div className="form-check">
          <input
            className="form-check-input"
            type="checkbox"
            value=""
            id="defaultCheck1"
            value={this.state.displayVol}
            onChange={event => {
              this.setState({ displayVol: event.target.value });
              changeDisplayValues(event.target.value);
            }}
          />
          <label className="form-check-label" for="defaultCheck1">
            Display Values
          </label>
        </div>
        <div className="form-group row no-gutters">
          <label for="inputEmail3" className="col-sm-6 col-form-label">
            Cycle Length
          </label>
          <div className="input-group input-group-sm col-sm-6">
            <input
              type="number"
              className="form-control form-control-sm"
              id="inputEmail3"
              placeholder="6"
              value={this.state.seconds}
              onChange={event => {
                const newSeconds = parseFloat(event.target.value);
                if (newSeconds == null || isNaN(newSeconds)) return;
                const ratio = newSeconds / this.state.seconds;
                // fix old values
                const newKeyframes = new Map();
                const oldKeyframes = this.state.keyframes;

                oldKeyframes.forEach((value, key) => {
                  const updatedValues = value.map(oneKeyframe => {
                    if (oneKeyframe.time === this.state.seconds) {
                      return { value: oneKeyframe.value, time: newSeconds };
                    } else
                      return {
                        value: oneKeyframe.value,
                        time: oneKeyframe.time * ratio,
                      };
                  });
                  newKeyframes.set(key, updatedValues);
                });

                this.setState({
                  seconds: newSeconds,
                  keyframes: newKeyframes,
                });
              }}
            />
            <div className="input-group-append">
              <span className="input-group-text" id="basic-addon2">
                s
              </span>
            </div>
          </div>
        </div>
        <div className="form-group row no-gutters">
          <label for="inputEmail3" className="col-sm-6 col-form-label">
            Breaking Force
          </label>
          <div className="input-group input-group-sm col-sm-6">
            <input
              type="number"
              className="form-control form-control-sm"
              id="inputEmail3"
              placeholder="300"
              value={this.state.breakingForce}
              onChange={event => {
                this.setState({ breakingForce: event.target.value });
                if (simulationIsRunning) {
                  setBreakingForce(event.target.value);
                }
              }}
            />
            <div className="input-group-append">
              <span className="input-group-text" id="basic-addon2">
                N
              </span>
            </div>
          </div>
        </div>
        <div className="form-group row no-gutters">
          <label for="inputEmail3" className="col-sm-6 col-form-label">
            Stiffness
          </label>
          <div className="input-group input-group-sm col-sm-6">
            <input
              type="number"
              className="form-control form-control-sm"
              id="inputEmail3"
              placeholder="Email"
              value={this.state.stiffness}
              onChange={event => {
                this.setState({ stiffness: event.target.value });
                setStiffness(event.target.value);
              }}
            />
            <div className="input-group-append">
              <span className="input-group-text" id="basic-addon2">
                %
              </span>
            </div>
          </div>
        </div>
      </form>
    );
  };

  renderControlls = () => {
    const { startedSimulationCycle, startedSimulationOnce } = this.state;
    const simulationIsRunning = startedSimulationCycle || startedSimulationOnce;
    return (
      <div
        className={DEV ? 'col-4' : ''}
        style={{
          borderRight: '1px solid lightgrey',
          height: '100%',
          paddingRight: '3px',
          width: DEV ? '40px' : 'auto',
        }}
      >
        <div
          className={DEV ? 'row no-gutters control-buttons' : 'control-buttons'}
        >
          <div className={DEV ? 'col' : ''}>
            <button onClick={() => this.toggelSimulation(true)}>
              <img
                style={DEV ? {} : { height: 25, width: 25 }}
                src={
                  this.state.startedSimulationOnce &&
                  !this.state.simulationPaused
                    ? '../../trussfab-globals/assets/icons/pause.png'
                    : '../../trussfab-globals/assets/icons/play.png'
                }
              />
            </button>
          </div>
          <div className={DEV ? 'col' : 'some-padding-top'}>
            <button onClick={() => this.toggelSimulation(false)}>
              <img
                style={DEV ? {} : { height: 25, width: 25 }}
                src={
                  this.state.startedSimulationCycle &&
                  !this.state.simulationPaused
                    ? '../../trussfab-globals/assets/icons/pause.png'
                    : '../../trussfab-globals/assets/icons/cycle.png'
                }
              />
            </button>
          </div>
          <div className={DEV ? 'col' : 'some-padding-top'}>
            <button onClick={this.stopSimulation}>
              <img
                style={DEV ? {} : { height: 25, width: 25 }}
                src="../../trussfab-globals/assets/icons/stop.png"
              />
            </button>
          </div>
          <div className={DEV ? 'col' : 'some-padding-top'}>
            <button
              onClick={() => {
                if (this.state.collapsed) {
                  setTimeout(() => {
                    this._addAllTimeSelectionLines();
                  }, 100);
                } else {
                  this._removeAllTimeselection();
                }

                this.setState({ collapsed: !this.state.collapsed });
                togglePane();
              }}
            >
              {this.state.collapsed ? 'show' : 'hide'}
            </button>
          </div>
        </div>
        {DEV && this.renderForm()}
      </div>
    );
  };

  render() {
    const { startedSimulationCycle, startedSimulationOnce } = this.state;
    const simulationIsRunning = startedSimulationCycle || startedSimulationOnce;
    const pistons = this.state.pistons.map((x, index) => (
      <div>
        <div
          style={{
            display: 'flex',
            alignContent: 'flex-start',
            alignItems: 'flex-start',
          }}
        >
          <div
            style={{ 'margin-top': yAxis / 3, marginLeft: 3, marginRight: 3 }}
          >{`#${index + 1}`}</div>
          {/* >{`#${x}`}</div> */}
          {this.renderGraph(x)}
          <div id={`add-kf-${x}`}>
            <input
              hidden
              type="number"
              step="0.1"
              min="0"
              max={this.state.seconds}
              value={
                this.state.timeSelection.get(x) ||
                this.initialSecondsForTimeSelection()
              }
              onChange={event =>
                this.onTimeSelectionInputChange(x, event.currentTarget.value)
              }
            />
            <input
              type="range"
              onChange={event => {
                const fixedValue = parseFloat(event.target.value) / 100;
                if (simulationIsRunning) {
                  changePistonValue(x, fixedValue);
                } else {
                  if (!this.state.simulationIsOnForValueTesting) {
                    this.setState({ simulationIsOnForValueTesting: true });
                    toggleSimulation();
                  }
                  changePistonValue(x, fixedValue);
                }
              }}
            />
            <button onClick={this.addKeyframe} className="add-new-kf" id={x}>
              <img
                style={DEV ? {} : { height: 15, width: 15 }}
                src="../../trussfab-globals/assets/icons/rhombus.png"
              />
            </button>
          </div>
        </div>
      </div>
    ));
    return (
      <div className="row no-gutters">
        {this.renderControlls()}
        {!this.state.collapsed && (
          <div className="col-8">
            <div className="App">
              {/* {this.state.startedSimulation && (
              <span>{(this.state.timelineCurrentTime / 1000).toFixed(1)}s</span>
            )} */}
              {pistons}
            </div>
          </div>
        )}
      </div>
    );
  }
}

export default App;
