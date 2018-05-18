import React from 'react';
import * as d3 from 'd3';

import SimulationForm from './SimulationForm';
import { xAxis, yAxis, timelineStepSeconds, FACTOR } from '../config';

import {
  togglePane,
  restartSimulation,
  togglePauseSimulation,
  toggleSimulation,
  moveJoint,
} from '../sketchup-integration';

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

  toggelSimulation = playOnce => {
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
    const {
      seconds,
      setContainerState,
      currentCycle,
      startedSimulationOnce,
      keyframesMap,
    } = this.props;

    let { timelineCurrentTime } = this.props;

    if (timelineCurrentTime / 1000 > seconds) {
      if (startedSimulationOnce) {
        this._removeInterval();
        SimulationControls.removeLines();
        // toggleSimulation();
        togglePauseSimulation();

        setContainerState({
          startedSimulationOnce: false,
          startedSimulationCycle: false,
          simulationPaused: true,
          timelineCurrentTime: 0,
          currentCycle: 0,
          simulationIsPausedAfterOnce: true,
        });
      } else {
        timelineCurrentTime = 0;
        setContainerState({ currentCycle: currentCycle + 1 });
      }
    }

    const timelineCurrentTimeSeconds = timelineCurrentTime / 1000;

    keyframesMap.forEach((keyframes, jointId) => {
      for (let i = 0; i < keyframes.length; i++) {
        const currentKeyframe = keyframes[i];
        if (timelineCurrentTime === currentKeyframe.time * 1000) {
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

    const newX = timelineCurrentTimeSeconds * xAxis / seconds;

    d3
      .selectAll('line.timeline')
      .attr('x1', newX)
      .attr('x2', newX);

    setContainerState({
      timelineCurrentTime: timelineCurrentTime + timelineStepSeconds * FACTOR,
    });
  };

  _addInterval = () => {
    const timlineInterval = setInterval(
      this.playOneTimelineStep,
      timelineStepSeconds
    );
    this.props.setContainerState({ timlineInterval });
  };

  _removeInterval = () => {
    clearInterval(this.props.timlineInterval);
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
        startedSimulationOnce: true,
        startedSimulationCycle: false,
        simulationPaused: false,
        timelineCurrentTime: 0,
        currentCycle: 0,
      });
    } else {
      setContainerState({
        startedSimulationCycle: true,
        startedSimulationOnce: false,
        simulationPaused: false,
        timelineCurrentTime: 0,
        currentCycle: 0,
      });
    }
  };

  _addAllTimeSelectionLines = () => {
    this.props.pistons.forEach(x =>
      this.props.addTimeSelectionForNewKeyFrame(x)
    );
  };

  stopSimulation = () => {
    const {
      startedSimulationOnce,
      startedSimulationCycle,
      simulationIsPausedAfterOnce,
      simulationIsOnForValueTesting,
      setContainerState,
      resetState,
    } = this.props;

    console.log('simulationIsOnForValueTesting', simulationIsOnForValueTesting);
    if (simulationIsOnForValueTesting) {
      toggleSimulation();
      setContainerState({ simulationIsOnForValueTesting: false });
      return;
    }

    console.log('startedSimulationOnce', startedSimulationOnce);
    console.log('startedSimulationCycle', startedSimulationCycle);
    if (
      !(startedSimulationOnce || startedSimulationCycle) &&
      !simulationIsPausedAfterOnce
    ) {
      return;
    }

    this._addAllTimeSelectionLines();
    toggleSimulation();
    console.log('resetting state');
    resetState();
  };

  _removeAllTimeselection = () => d3.selectAll('line.timeSelection').remove();

  render() {
    const {
      startedSimulationCycle,
      startedSimulationOnce,
      simulationPaused,
      devMode,
      windowCollapsed,
      setContainerState,
      seconds,
      breakingForce,
      stiffness,
      displayVol,
      peakForceMode,
      highestForceMode,
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
            <button onClick={() => this.toggelSimulation(true)}>
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
            <button onClick={() => this.toggelSimulation(false)}>
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
            setContainerState={setContainerState}
            stiffness={stiffness}
            breakingForce={breakingForce}
            seconds={seconds}
            displayVol={displayVol}
            peakForceMode={peakForceMode}
            highestForceMode={highestForceMode}
          />
        )}
      </div>
    );
  }
}

export default SimulationControls;
