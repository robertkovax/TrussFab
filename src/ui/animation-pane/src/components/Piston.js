import React from 'react';
import * as d3 from 'd3';

import { changePistonValue, toggleSimulation } from '../sketchup-integration';
import { xAxis, yAxis, DEV } from '../config';
import colors from '../utils/colors';

class Piston extends React.Component {
  _mapPointsToChart = kf => {
    return [
      kf.time * xAxis / this.props.seconds,
      (1 - kf.value) * (yAxis - 8) + 4,
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
      oldKeyframesUIST,
      simluationBrokeAt,
      seconds,
      setContainerState,
    } = this.props;

    const keyframes = keyframesMap.get(id) || [];

    const points = keyframes.map(this._mapPointsToChart);

    const viewBox = `0 0 ${xAxis} ${yAxis}`;
    const pointsString = points.map(p => p.join(',')).join('\n');

    const oldKeyframesMap = keyframesMap;

    const deleteCircle = keyframeIndex => {
      setContainerState({
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
        fill={colors[id]}
      />
    ));

    const greyedOutPoints =
      oldKeyframesUIST &&
      oldKeyframesUIST.get(id) &&
      oldKeyframesUIST.get(id).map(this._mapPointsToChart);

    let greyOutPointsString = null;
    if (greyedOutPoints != null)
      greyOutPointsString = greyedOutPoints.map(p => p.join(',')).join('\n');

    return (
      <div style={{ position: 'relative' }}>
        {simluationBrokeAt !== null && (
          <div
            className="broken-time-line"
            style={{ left: simluationBrokeAt / 1000 / 5 * xAxis }}
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
            right: xAxis / 2,
            fontSize: 10,
          }}
        >
          {seconds / 2}s
        </span>
        <span
          style={{ position: 'absolute', bottom: 0, right: 0, fontSize: 10 }}
        >
          {seconds}s
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
    setContainerState({ keyframes });
  };

  render() {
    const {
      x,
      index,
      simulationIsRunning,
      seconds,
      timeSelection,
      simulationIsOnForValueTesting,
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
            style={{ marginTop: yAxis / 3, marginLeft: 3, marginRight: 3 }}
          >{`#${index + 1}`}</div>
          {this.renderGraph(x)}
          <div id={`add-kf-${x}`}>
            <input
              hidden
              type="number"
              step="0.1"
              min="0"
              max={seconds}
              value={
                timeSelection.get(x) || this.initialSecondsForTimeSelection()
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
                  if (!simulationIsOnForValueTesting) {
                    setContainerState({ simulationIsOnForValueTesting: true });
                    toggleSimulation();
                  }
                  changePistonValue(x, fixedValue);
                }
              }}
            />
            <button onClick={this.addKeyframe} className="add-new-kf" id={x}>
              <img
                alt="rhomus"
                style={DEV ? {} : { height: 15, width: 15 }}
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
