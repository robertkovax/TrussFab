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
      breakingForce,
      displayVal,
      highestForceMode,
      keyframesMap,
      peakForceMode,
      seconds,
      setContainerState,
      stiffness,
    } = this.props;

    return (
      <form>
        <div className="form-check">
          <input
            className="form-check-input"
            type="checkbox"
            id="highestForceCheck"
            checked={highestForceMode}
            onChange={event => {
              setContainerState({ highestForceMode: event.target.checked });
              changeHighestForceMode(event.target.checked);
            }}
          />
          <label className="form-check-label">
            Highest Force
          </label>
        </div>
        <div className="form-check">
          <input
            className="form-check-input"
            type="checkbox"
            id="peakForceModeCheck"
            checked={peakForceMode}
            onChange={event => {
              setContainerState({ peakForceMode: event.target.checked });
              changePeakForceMode(event.target.checked);
            }}
          />
          <label className="form-check-label">
            Peak Force
          </label>
        </div>
        <div className="form-check">
          <input
            className="form-check-input"
            type="checkbox"
            id="displayValuesCheck"
            checked={displayVal}
            onChange={event => {
              setContainerState({ displayVal: event.target.checked });
              changeDisplayValues(event.target.checked);
            }}
          />
          <label className="form-check-label">
            Display Values
          </label>
        </div>
        <div className="form-group row no-gutters">
          <label className="col-sm-6 col-form-label">
            Cycle Length
          </label>
          <div className="input-group input-group-sm col-sm-6">
            <input
              type="number"
              className="form-control form-control-sm"
              id="cycleLengthInput"
              placeholder="6"
              value={seconds}
              onChange={event => {
                const newSeconds = parseFloat(event.target.value);
                if (newSeconds == null || isNaN(newSeconds)) return;
                const ratio = newSeconds / seconds;
                // fix old values
                const newKeyframes = new Map();
                const oldKeyframes = keyframesMap;

                oldKeyframes.forEach((value, key) => {
                  const updatedValues = value.map(oneKeyframe => {
                    if (oneKeyframe.time === seconds) {
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
                  keyframesMap: newKeyframes,
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
          <label className="col-sm-6 col-form-label">
            Breaking Force
          </label>
          <div className="input-group input-group-sm col-sm-6">
            <input
              type="number"
              className="form-control form-control-sm"
              id="breakingForceInput"
              placeholder="300"
              value={breakingForce}
              onChange={event => {
                setContainerState({ breakingForce: event.target.value });
                setBreakingForce(event.target.value);
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
          <label className="col-sm-6 col-form-label">
            Stiffness
          </label>
          <div className="input-group input-group-sm col-sm-6">
            <input
              type="number"
              className="form-control form-control-sm"
              id="stiffnessInput"
              placeholder="Stiffness"
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
