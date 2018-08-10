import React from 'react';
import * as d3 from 'd3';

import {
  changePistonValue,
  startSimulation,
  persistKeyframes,
} from '../utils/sketchup-integration';
import { X_AXIS, Y_AXIS } from '../config';
import colors from '../utils/colors';

class Piston extends React.Component {
  _mapKeyframeToCoordinates = keyframe => {
    return [
      keyframe.time * X_AXIS / this.props.timelineSeconds,
      (1 - keyframe.value) * (Y_AXIS - 8) + 4,
    ];
  };

  removeTimeSelectionForNewKeyFrame = id => {
    const { setContainerState, timeSelection } = this.props;
    d3
      .select('#svg-' + id)
      .select('line.timeSelection')
      .remove();
    const oldTimeSelection = timeSelection;
    setContainerState({
      timeSelection: oldTimeSelection.set(
        id,
        this.initialSecondsForTimeSelection()
      ),
    });
  };

  initialSecondsForTimeSelection = () => {
    return 0;
  };

  renderGraph = id => {
    const {
      keyframesMap,
      previousKeyframesMap,
      timelineSimluationBrokeAt,
      timelineSeconds,
      setContainerState,
    } = this.props;

    const keyframes = keyframesMap.get(id) || [];

    const points = keyframes.map(this._mapKeyframeToCoordinates);

    const viewBox = `0 0 ${X_AXIS} ${Y_AXIS}`;
    const pointsString = points.map(p => p.join(',')).join('\n');

    const deleteCircle = keyframeIndex => {
      setContainerState({
        keyframes: keyframesMap.set(
          id,
          keyframesMap.get(id).filter((_, index) => index !== keyframeIndex)
        ),
      });
    };

    const circles = points.map((x, index) => (
      <circle
        key={index}
        onClick={() => deleteCircle(index)}
        cx={x[0]}
        cy={x[1]}
        r="4"
        fill={colors[id]}
      />
    ));

    // get the points or null/false if theren't any
    const greyedOutPoints =
      previousKeyframesMap &&
      previousKeyframesMap.get(id) &&
      previousKeyframesMap.get(id).map(this._mapKeyframeToCoordinates);

    let greyOutPointsString = null;
    if (greyedOutPoints != null)
      greyOutPointsString = greyedOutPoints.map(p => p.join(',')).join('\n');

    return (
      <div style={{ position: 'relative' }}>
        {timelineSimluationBrokeAt !== null && (
          <div
            className="broken-time-line"
            style={{ left: timelineSimluationBrokeAt / 1000 / 5 * X_AXIS }}
          />
        )}
        <svg viewBox={viewBox} className="chart" id={`svg-${id}`}>
          {greyedOutPoints != null && (
            <polyline
              className="grey-out-line"
              fill="none"
              stroke="#D3D3D3"
              strokeWidth="2"
              points={greyOutPointsString}
            />
          )}
          <polyline
            fill="none"
            stroke={colors[id]}
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
            right: X_AXIS / 2,
            fontSize: 10,
          }}
        >
          {timelineSeconds / 2}s
        </span>
        <span
          style={{ position: 'absolute', bottom: 0, right: 0, fontSize: 10 }}
        >
          {timelineSeconds}s
        </span>
      </div>
    );
  };

  addKeyframe = event => {
    const { keyframesMap, setContainerState } = this.props;

    const pistonId = parseInt(event.currentTarget.id, 10);
    const value = event.currentTarget.previousSibling.value / 100;
    const time = parseFloat(
      event.currentTarget.previousSibling.previousSibling.value
    );

    const oldKeyframesMap = keyframesMap;
    const oldKeyframes = oldKeyframesMap.get(pistonId) || [];
    const keyframes = oldKeyframesMap.set(
      pistonId,
      oldKeyframes.concat({ time, value }).sort((a, b) => a.time - b.time)
    );
    persistKeyframes(JSON.stringify([...keyframes]));
    setContainerState({ keyframes });
  };

  render() {
    const {
      id,
      index,
      simulationIsRunning,
      timelineSeconds,
      timeSelection,
      timelineSimulationIsOnForValueTesting,
      setContainerState,
    } = this.props;
    return (
      <div>
        <div
          style={{
            display: 'flex',
            alignContent: 'flex-start',
            alignItems: 'flex-start',
          }}
        >
          <div
            style={{ marginTop: Y_AXIS / 3, marginLeft: 3, marginRight: 3 }}
          >{`#${index + 1}`}</div>
          {this.renderGraph(id)}
          <div id={`add-kf-${id}`}>
            <input
              hidden
              type="number"
              step="0.1"
              min="0"
              max={timelineSeconds}
              value={
                timeSelection.get(id) || this.initialSecondsForTimeSelection()
              }
              onChange={event =>
                this.onTimeSelectionInputChange(id, event.currentTarget.value)
              }
            />
            <input
              type="range"
              onChange={event => {
                const fixedValue = parseFloat(event.target.value) / 100;
                if (simulationIsRunning) {
                  changePistonValue(id, fixedValue);
                } else {
                  if (!timelineSimulationIsOnForValueTesting) {
                    setContainerState({
                      timeline: { simulationIsOnForValueTesting: true },
                    });
                    startSimulation();
                  }
                  changePistonValue(id, fixedValue);
                }
              }}
            />
            <button onClick={this.addKeyframe} className="add-new-kf" id={id}>
              <img
                alt="rhomus"
                style={{ height: 15, width: 15 }}
                src="../../trussfab-globals/assets/icons/rhombus.png"
              />
            </button>
          </div>
        </div>
      </div>
    );
  }
}

export default Piston;
