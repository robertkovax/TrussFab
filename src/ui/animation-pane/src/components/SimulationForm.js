import React from 'react';

import {
  setBreakingForce,
  changeHighestForceMode,
  setStiffness,
  changePeakForceMode,
  changeDisplayValues,
} from '../sketchup-integration';

class SimulationForm extends React.Component {
  render() {
    const {
      startedSimulationCycle,
      startedSimulationOnce,
      setContainerState,
      highestForceMode,
      peakForceMode,
      displayVol,
      seconds,
      breakingForce,
      stiffness,
    } = this.props;
    const simulationIsRunning = startedSimulationCycle || startedSimulationOnce;
    return (
      <form>
        <div className="form-check">
          <input
            className="form-check-input"
            type="checkbox"
            id="defaultCheck1"
            value={highestForceMode}
            onChange={event => {
              setContainerState({ highestForceMode: event.target.value });
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
            id="defaultCheck1"
            value={peakForceMode}
            onChange={event => {
              setContainerState({ peakForceMode: event.target.value });
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
            id="defaultCheck1"
            value={displayVol}
            onChange={event => {
              setContainerState({ displayVol: event.target.value });
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
              value={seconds}
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

                setContainerState({
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
              value={breakingForce}
              onChange={event => {
                setContainerState({ breakingForce: event.target.value });
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
              value={stiffness}
              onChange={event => {
                setContainerState({ stiffness: event.target.value });
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
  }
}

export default SimulationForm;
