import { linear } from "everpolate";

const getInterpolationForTime = (timeInSeconds, points) => {
  const X = points.map(x => x.time);
  const Y = points.map(x => x.value);
  return linear(timeInSeconds, X, Y);
};

export { getInterpolationForTime };
