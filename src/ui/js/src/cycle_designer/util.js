function getCircleWithID(id, selection) {
  const circles = selection.filter(circle => circle.id === id);
  if (!circles.empty()) {
    return circles.data()[0];
  }
  return null;
}

function distanceBetweenTwoPoints(x1, y1, x2, y2) {
  const a = x1 - x2;
  const b = y1 - y2;

  return Math.sqrt(a * a + b * b);
}

export { getCircleWithID, distanceBetweenTwoPoints };
