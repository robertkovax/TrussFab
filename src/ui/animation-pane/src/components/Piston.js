import React from 'react';

import { xAxis, yAxis, timelineStepSeconds, FACTOR, DEV } from './config';

class Piston extends React.Component {
  _mapPointsToChart = kf => {
    return [
      kf.time * xAxis / this.state.seconds,
      (1 - kf.value) * (yAxis - 8) + 4,
    ];
  };

  renderGraph = id => {
    const { keyframes } = this.props;

    const keyframes = this.state.keyframes.get(id) || [];

    const points = keyframes.map(this._mapPointsToChart);

    const viewBox = `0 0 ${xAxis} ${yAxis}`;
    const pointsString = points.map(p => p.join(',')).join('\n');

    const oldKeyframesMap = this.state.keyframes;

    const deleteCircle = keyframeIndex => {
      this.setState({
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
        fill="#0074d9"
      />
    ));

    const greyOutPoints =
      this.state.oldKeyframesUIST &&
      this.state.oldKeyframesUIST.get(id) &&
      this.state.oldKeyframesUIST.get(id).map(this._mapPointsToChart);

    let greyOutPointsString = null;
    if (greyOutPoints != null)
      greyOutPointsString = greyOutPoints.map(p => p.join(',')).join('\n');

    return (
      <div style={{ position: 'relative' }}>
        {this.state.simluationBrokeAt !== null && (
          <div
            className="broken-time-line"
            style={{ left: this.state.simluationBrokeAt / 1000 / 5 * xAxis }}
          />
        )}
        <svg viewBox={viewBox} className="chart" id={`svg-${id}`}>
          {greyOutPoints != null && (
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
            stroke="#0074d9"
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
          {this.state.seconds / 2}s
        </span>
        <span
          style={{ position: 'absolute', bottom: 0, right: 0, fontSize: 10 }}
        >
          {this.state.seconds}s
        </span>
      </div>
    );
  };

  addKeyframe = event => {
    const pistonId = parseInt(event.currentTarget.id, 10);
    const value = event.currentTarget.previousSibling.value / 100;
    const time = parseFloat(
      event.currentTarget.previousSibling.previousSibling.value
    );

    const oldKeyframes = this.state.keyframes;
    const oldKeyframesPiston = oldKeyframes.get(pistonId) || [];
    const keyframes = oldKeyframes.set(
      pistonId,
      oldKeyframesPiston.concat({ time, value }).sort((a, b) => a.time - b.time)
    );
    this.setState({ keyframes });
  };

  render() {
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
    );
  }
}

export default Piston;
