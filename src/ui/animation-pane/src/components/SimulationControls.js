import React from 'react';
import * as d3 from 'd3';

import SimulationForm from './SimulationForm';
import {
  X_AXIS,
  Y_AXIS,
  UPDATE_INTERVALL,
  TIMELINE_TIME_FACTOR,
} from '../config';

import {
  togglePane,
  restartSimulation,
  moveJoint,
  pauseSimulation,
  unpauseSimulation,
  startSimulation,
  stopSimulation,
} from '../utils/sketchup-integration';

class SimulationControls extends React.Component {
  timelineInterval = null;

  /**
   * add new timeline interval, clears old if present
   * @param {Function} playOneTimelineStep function that plays one step
   */
  static addTimelineInterval = playOneTimelineStep => {
    if (this.timelineInterval != null) {
      SimulationControls.clearTimelineInterval();
    }

    // save interval to class variable so we can clear it later
    this.timelineInterval = setInterval(playOneTimelineStep, UPDATE_INTERVALL);
  };

  /**
   * clear timeline interval
   */
  static clearTimelineInterval = () => clearInterval(this.timelineInterval);

  componentDidMount() {
    document.addEventListener('keyup', e => {
      // ESC
      if (e.keyCode === 27) {
        this.triggerStopSimulation();
      }
    });
  }

  componentWillUnmount() {
    document.removeEventListener('keyup', this.triggerStopSimulation);
  }

  toggleSimulation = playOnce => {
    const {
      timeline: { startedSimulationOnce, startedSimulationCycle },
    } = this.props;

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

  /**
   * Checks if we reached the timeline end and also updates state accordingly
   * @returns adjusted timeline time in milliseconds
   */
  _checkIfReachedTimelineEnd = () => {
    const {
      timeline: { seconds, startedSimulationOnce, currentCycle },
      setContainerState,
    } = this.props;

    let {
      timeline: { currentTime: actualTimelineMilliSeconds },
    } = this.props;

    if (actualTimelineMilliSeconds / 1000 > seconds) {
      if (startedSimulationOnce) {
        // we reached the end of the cycle and we only wanted to play on cycle
        // thus, pause the simulation and reset the state
        SimulationControls.clearTimelineInterval();
        SimulationControls.removeLines();

        setContainerState({
          timeline: {
            startedSimulationOnce: false,
            startedSimulationCycle: false,
            simulationPaused: true,
            simulationIsPausedAfterOnce: true,
            currentCycle: 0,
          },
        });
      } else {
        // set current time to 0 because reached the end of a cycle
        actualTimelineMilliSeconds = 0;
        setContainerState({
          timeline: { currentCycle: currentCycle + 1 },
        });
      }
    }

    setContainerState({
      timeline: {
        currentTime:
          actualTimelineMilliSeconds + UPDATE_INTERVALL * TIMELINE_TIME_FACTOR,
      },
    });

    return actualTimelineMilliSeconds;
  };

  /**
   * sets the current time for the timeline indicator
   * @param {number} actualTimelineSeconds
   */
  _setTimelineTimeIndicator = actualTimelineSeconds => {
    const {
      timeline: { seconds },
    } = this.props;

    const newX = actualTimelineSeconds * X_AXIS / seconds;

    d3
      .selectAll('line.timeline')
      .attr('x1', newX)
      .attr('x2', newX);
  };

  /**
   * Only play the timeline once and pause the simulation afterwards.
   */
  playOneTimelineStep = () => {
    const { keyframesMap } = this.props;

    const actualTimelineMilliSeconds = this._checkIfReachedTimelineEnd();
    const actualTimelineSeconds = actualTimelineMilliSeconds / 1000;

    keyframesMap.forEach((keyframes, jointId) => {
      for (let i = 0; i < keyframes.length; i++) {
        const currentKeyframe = keyframes[i];
        if (actualTimelineSeconds === currentKeyframe.time) {
          // Since the first and the last keyframe are 'special' and should
          // always have the same value, we must not move the joint for the last
          // keyframe.
          if (i === keyframes.length - 1) {
            continue;
          }
          const newValue = keyframes[i + 1].value;
          const duration = keyframes[i + 1].time - currentKeyframe.time;
          moveJoint(jointId, newValue, duration);
        }
      }
    });

    this._setTimelineTimeIndicator(actualTimelineSeconds);
  };

  _addLines = () => {
    d3
      .selectAll('svg')
      .append('line')
      .classed('timeline', true)
      .attr('x1', 0)
      .attr('y1', 0)
      .attr('x2', 0)
      .attr('y2', Y_AXIS)
      .style('stroke-width', 3)
      .style('stroke', 'grey')
      .style('fill', 'none');
  };

  static removeLines = () => d3.selectAll('line.timeline').remove();

  _togglePause = () => {
    const {
      timeline: { simulationPaused },
      setContainerState,
    } = this.props;
    if (simulationPaused) {
      unpauseSimulation();
      setContainerState({ timeline: { simulationPaused: !simulationPaused } });

      this._addLines();
      SimulationControls.addTimelineInterval(this.playOneTimelineStep);
    } else {
      pauseSimulation();
      SimulationControls.clearTimelineInterval();
      SimulationControls.removeLines();
      setContainerState({ timeline: { simulationPaused: !simulationPaused } });
    }
  };

  _startSimulation = playOnce => {
    const {
      setContainerState,
      timeline: { simulationIsPausedAfterOnce, simulationIsOnForValueTesting },
    } = this.props;

    SimulationControls.removeLines();
    this._addLines();

    SimulationControls.addTimelineInterval(this.playOneTimelineStep);

    this._removeAllTimeselection();

    if (simulationIsPausedAfterOnce) {
      restartSimulation();
    } else {
      if (simulationIsOnForValueTesting) {
        restartSimulation();
        setContainerState({
          timeline: { simulationIsOnForValueTesting: false },
        });
      } else {
        startSimulation();
      }
    }

    if (playOnce) {
      setContainerState({
        timeline: {
          startedSimulationOnce: true,
          startedSimulationCycle: false,
          simulationPaused: false,
          currentTime: 0,
          currentCycle: 0,
        },
      });
    } else {
      setContainerState({
        timeline: {
          startedSimulationCycle: true,
          startedSimulationOnce: false,
          simulationPaused: false,
          currentTime: 0,
          currentCycle: 0,
        },
      });
    }
  };

  _addAllTimeSelectionLines = () => {
    [...this.props.keyframesMap.keys()].forEach(x =>
      this.props.addTimeSelectionForNewKeyFrame(x)
    );
  };

  triggerStopSimulation = () => {
    const {
      timeline: {
        startedSimulationOnce,
        startedSimulationCycle,
        simulationIsPausedAfterOnce,
        simulationIsOnForValueTesting,
      },
      setContainerState,
      resetState,
    } = this.props;

    if (simulationIsOnForValueTesting) {
      stopSimulation();
      setContainerState({ timeline: { simulationIsOnForValueTesting: false } });
      return;
    }

    if (
      !(startedSimulationOnce || startedSimulationCycle) &&
      !simulationIsPausedAfterOnce
    ) {
      return;
    }

    this._addAllTimeSelectionLines();
    stopSimulation();
    resetState();
  };

  _removeAllTimeselection = () => d3.selectAll('line.timeSelection').remove();

  render() {
    const {
      devMode,
      windowCollapsed,
      timeline: {
        startedSimulationOnce,
        simulationPaused,
        startedSimulationCycle,
        seconds,
      },
      simulationSettings,
      setContainerState,
      keyframesMap,
    } = this.props;

    return (
      <div
        className={devMode ? 'col-4' : ''}
        style={{
          borderRight: '1px solid lightgrey',
          height: '100%',
          paddingRight: '3px',
          width: devMode ? '40px' : 'auto',
        }}
      >
        <div
          className={
            devMode ? 'row no-gutters control-buttons' : 'control-buttons'
          }
        >
          <div className={devMode ? 'col' : ''}>
            <button onClick={() => this.toggleSimulation(true)}>
              <img
                alt="pause play"
                style={devMode ? {} : { height: 25, width: 25 }}
                src={
                  startedSimulationOnce && !simulationPaused
                    ? '../../trussfab-globals/assets/icons/pause.png'
                    : '../../trussfab-globals/assets/icons/play.png'
                }
              />
            </button>
          </div>
          <div className={devMode ? 'col' : 'some-padding-top'}>
            <button onClick={() => this.toggleSimulation(false)}>
              <img
                alt="pause cycle play"
                style={devMode ? {} : { height: 25, width: 25 }}
                src={
                  startedSimulationCycle && !simulationPaused
                    ? '../../trussfab-globals/assets/icons/pause.png'
                    : '../../trussfab-globals/assets/icons/cycle.png'
                }
              />
            </button>
          </div>
          <div className={devMode ? 'col' : 'some-padding-top'}>
            <button onClick={this.triggerStopSimulation}>
              <img
                alt="stop"
                style={devMode ? {} : { height: 25, width: 25 }}
                src="../../trussfab-globals/assets/icons/stop.png"
              />
            </button>
          </div>
          <div className={devMode ? 'col' : 'some-padding-top'}>
            <button
              onClick={() => {
                if (windowCollapsed) {
                  setTimeout(() => {
                    this._addAllTimeSelectionLines();
                  }, 100);
                } else {
                  this._removeAllTimeselection();
                }
                setContainerState({ windowCollapsed: !windowCollapsed });
                togglePane();
              }}
            >
              {windowCollapsed ? 'show' : 'hide'}
            </button>
          </div>
        </div>
        {devMode && (
          <SimulationForm
            keyframesMap={keyframesMap}
            simulationSettings={simulationSettings}
            setContainerState={setContainerState}
            timelineSeconds={seconds}
            startedSimulationCycle={startedSimulationCycle}
            startedSimulationOnce={startedSimulationOnce}
          />
        )}
      </div>
    );
  }
}

export default SimulationControls;
