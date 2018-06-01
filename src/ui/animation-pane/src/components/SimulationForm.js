import React from 'react';

import {
  setBreakingForce,
  changeHighestForceMode,
  setStiffness,
  changePeakForceMode,
  changeDisplayValues,
} from '../utils/sketchup-integration';

class SimulationForm extends React.Component {
  render() {
    const {
      startedSimulationCycle,
      startedSimulationOnce,
      simulationSettings,
      timelineSeconds,
      setContainerState,
    } = this.props;
    const simulationIsRunning = startedSimulationCycle || startedSimulationOnce;
    return (
      <form>
        <div className="form-check">
          <input
            className="form-check-input"
            type="checkbox"
            id="defaultCheck1"
            value={simulationSettings.highestForceMode}
            onChange={event => {
              setContainerState({
                simulationSettings: { highestForceMode: event.target.value },
              });
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
            value={simulationSettings.peakForceMode}
            onChange={event => {
              setContainerState({
                simulationSettings: { peakForceMode: event.target.value },
              });
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
            value={simulationSettings.displayVol}
            onChange={event => {
              setContainerState({
                simulationSettings: { displayVol: event.target.value },
              });
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
              value={timelineSeconds}
              onChange={event => {
                const newSeconds = parseFloat(event.target.value);
                if (newSeconds == null || isNaN(newSeconds)) return;
                const ratio = newSeconds / timelineSeconds;
                // fix old values
                const newKeyframes = new Map();
                const oldKeyframes = this.state.keyframes;

                oldKeyframes.forEach((value, key) => {
                  const updatedValues = value.map(oneKeyframe => {
                    if (oneKeyframe.time === timelineSeconds) {
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
                  timeline: { seconds: newSeconds },
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
              value={simulationSettings.breakingForce}
              onChange={event => {
                setContainerState({
                  simulationSettings: { breakingForce: event.target.value },
                });
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
              value={simulationSettings.stiffness}
              onChange={event => {
                setContainerState({
                  simulationSettings: { stiffness: event.target.value },
                });
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
