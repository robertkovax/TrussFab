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
  togglePauseSimulation,
  toggleSimulation,
  moveJoint,
} from '../utils/sketchup-integration';

class SimulationControls extends React.Component {
  componentDidMount() {
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

  toggleSimulation = playOnce => {
    const { startedSimulationOnce, startedSimulationCycle } = this.props;

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

  playOneTimelineStep = () => {
    const { timeline, setContainerState, keyframesMap } = this.props;

    let timelineCurrentTimeAdjusted = timeline.currentTime;

    if (timelineCurrentTimeAdjusted / 1000 > timeline.seconds) {
      if (timeline.startedSimulationOnce) {
        console.log('here)');
        this._removeInterval();
        SimulationControls.removeLines();
        // toggleSimulation();
        togglePauseSimulation();

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
        timelineCurrentTimeAdjusted = 0;
        setContainerState({
          timeline: { currentCycle: timeline.currentCycle + 1 },
        });
      }
    }

    const timelinecurrentTimeInSeconds = timelineCurrentTimeAdjusted / 1000;

    keyframesMap.forEach((keyframes, jointId) => {
      for (let i = 0; i < keyframes.length; i++) {
        const currentKeyframe = keyframes[i];
        if (timelinecurrentTimeInSeconds === currentKeyframe.time * 1000) {
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

    const newX = timelinecurrentTimeInSeconds * X_AXIS / timeline.seconds;

    d3
      .selectAll('line.timeline')
      .attr('x1', newX)
      .attr('x2', newX);

    setContainerState({
      timeline: {
        currentTime:
          timelineCurrentTimeAdjusted + UPDATE_INTERVALL * TIMELINE_TIME_FACTOR,
      },
    });
  };

  _addInterval = () => {
    const interval = setInterval(this.playOneTimelineStep, UPDATE_INTERVALL);
    this.props.setContainerState({ timeline: { interval } });
  };

  _removeInterval = () => {
    clearInterval(this.props.timeline.interval);
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
    const { simulationPaused, setContainerState } = this.props;
    if (simulationPaused) {
      togglePauseSimulation();
      setContainerState({ simulationPaused: !simulationPaused });

      this._addLines();
      this._addInterval();
    } else {
      togglePauseSimulation();
      this._removeInterval();
      SimulationControls.removeLines();

      setContainerState({ simulationPaused: !simulationPaused });
    }
  };

  _startSimulation = playOnce => {
    const {
      setContainerState,
      simulationIsPausedAfterOnce,
      simulationIsOnForValueTesting,
    } = this.props;

    SimulationControls.removeLines();
    this._addLines();

    this._removeInterval();
    this._addInterval();

    this._removeAllTimeselection();

    if (simulationIsPausedAfterOnce) {
      restartSimulation();
    } else {
      if (simulationIsOnForValueTesting) {
        restartSimulation();
        setContainerState({ simulationIsOnForValueTesting: false });
      } else {
        toggleSimulation();
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

  stopSimulation = () => {
    const { timeline, setContainerState, resetState } = this.props;

    const {
      startedSimulationOnce,
      startedSimulationCycle,
      simulationIsPausedAfterOnce,
      simulationIsOnForValueTesting,
    } = timeline;

    if (simulationIsOnForValueTesting) {
      toggleSimulation();
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
    toggleSimulation();
    resetState();
  };

  _removeAllTimeselection = () => d3.selectAll('line.timeSelection').remove();

  render() {
    const {
      devMode,
      windowCollapsed,
      timeline,
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
                  timeline.startedSimulationOnce && !timeline.simulationPaused
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
                  timeline.startedSimulationCycle && !timeline.simulationPaused
                    ? '../../trussfab-globals/assets/icons/pause.png'
                    : '../../trussfab-globals/assets/icons/cycle.png'
                }
              />
            </button>
          </div>
          <div className={devMode ? 'col' : 'some-padding-top'}>
            <button onClick={this.stopSimulation}>
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
            timelineSeconds={timeline.seconds}
            startedSimulationCycle={timeline.startedSimulationCycle}
            startedSimulationOnce={timeline.startedSimulationOnce}
          />
        )}
      </div>
    );
  }
}

export default SimulationControls;
