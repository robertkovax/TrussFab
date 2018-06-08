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

  static clearTimelineInterval = () => clearInterval(this.timelineInterval);

  componentDidMount() {
    document.addEventListener('keyup', e => {
      // ESC
      if (e.keyCode === 27) {
        this.stopSimulationClick();
      }
    });
  }

  componentWillUnmount() {
    document.removeEventListener('keyup', this.stopSimulationClick);
  }

  toggleSimulation = playOnce => {
    const {
      timeline: { startedSimulationOnce, startedSimulationCycle },
    } = this.props;
    console.log('startedSimulationCycle', startedSimulationCycle);
    console.log('startedSimulationOnce', startedSimulationOnce);

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
   * Checks if we reached the timeline end
   * @returns adjusted time in seconds
   */
  _checkIfReachedTimelineEnd = () => {
    const { timeline, setContainerState } = this.props;

    let actualTimelineMiliSeconds = timeline.currentTime;

    if (actualTimelineMiliSeconds / 1000 > timeline.seconds) {
      if (timeline.startedSimulationOnce) {
        SimulationControls.clearTimelineInterval();
        SimulationControls.removeLines();

        // pause the sim
        pauseSimulation();

        setContainerState({
          timeline: {
            startedSimulationOnce: false,
            startedSimulationCycle: false,
            simulationPaused: true,
            simulationIsPausedAfterOnce: true,
            currentCycle: 0,
            currentTime: 0,
          },
        });
      } else {
        // reset current time to 0 because we start a new cycle
        actualTimelineMiliSeconds = 0;
        setContainerState({
          timeline: { currentCycle: timeline.currentCycle + 1 },
        });
      }
    }

    return actualTimelineMiliSeconds;
  };

  /**
   * Only play the timeline once and pause the simulation afterwards.
   */
  playOneTimelineStep = () => {
    const { timeline, setContainerState, keyframesMap } = this.props;

    const actualTimelineMiliSeconds = this._checkIfReachedTimelineEnd();
    const actualTimelineSeconds = actualTimelineMiliSeconds / 1000;
    console.log('actualTimelineSeconds', actualTimelineSeconds);

    keyframesMap.forEach((keyframes, jointId) => {
      for (let i = 0; i < keyframes.length; i++) {
        const currentKeyframe = keyframes[i];
        if (actualTimelineSeconds === currentKeyframe.time * 1000) {
          console.log('move joint');
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

    const newX = actualTimelineSeconds * X_AXIS / timeline.seconds;

    d3
      .selectAll('line.timeline')
      .attr('x1', newX)
      .attr('x2', newX);

    setContainerState({
      timeline: {
        currentTime:
          actualTimelineMiliSeconds + UPDATE_INTERVALL * TIMELINE_TIME_FACTOR,
      },
    });
  };

  _addInterval = () => {
    console.log('added interval');
    const interval = setInterval(this.playOneTimelineStep, UPDATE_INTERVALL);
    this.interval = interval;
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
    console.log('simulationPaused', simulationPaused);
    if (simulationPaused) {
      unpauseSimulation();
      setContainerState({ simulationPaused: !simulationPaused });

      this._addLines();
      this._addInterval();
    } else {
      pauseSimulation();
      this._removeInterval();
      SimulationControls.removeLines();

      setContainerState({ simulationPaused: !simulationPaused });
    }
  };

  _startSimulation = playOnce => {
    const {
      setContainerState,
      timeline: { simulationIsPausedAfterOnce, simulationIsOnForValueTesting },
    } = this.props;

    SimulationControls.removeLines();
    this._addLines();

    SimulationControls.clearTimelineInterval();
    this._addInterval();

    this._removeAllTimeselection();

    // just start?

    if (simulationIsPausedAfterOnce) {
      restartSimulation();
    } else {
      if (simulationIsOnForValueTesting) {
        restartSimulation();
        setContainerState({ simulationIsOnForValueTesting: false });
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
    this.props.pistons.forEach(x =>
      this.props.addTimeSelectionForNewKeyFrame(x)
    );
  };

  stopSimulationClick = () => {
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
      setContainerState({ timline: { simulationIsOnForValueTesting: false } });
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
            <button onClick={this.stopSimulationClick}>
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
