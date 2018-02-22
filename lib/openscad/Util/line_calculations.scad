// some helper functions when dealing with lines in 2d and 3d

// normalize vector
function norm_v(v) = v / norm(v);


// 2d line intersection
function get_line_intersection_x(m1, t1, m2, t2,) = (t2 - t1) / (m1 - m2);
function get_line_intersection_y(m1, t1, m2, t2,) = (m1 * t2 - m2 * t1) / (m1 - m2);

function get_line_intersection_2d(m1, t1, m2, t2) =
  [get_line_intersection_x(m1, t1, m2, t2), get_line_intersection_y(m1, t1, m2, t2)];


// 3d line intersection
function _get_line_intersection_3d_a(p1, p2, v1, v2) = ((p2 - p1) * v2) / (v1 * v2);

function get_line_intersection_3d(p1, p2, v1, v2) =
  p1 + _get_line_intersection_3d_a(p1, p2, v1, v2) * v1;


// the middle / average between vectors
function _get_average_vector(vectors, i, dim) = i == len(vectors) ?
  0 :
  _get_average_vector(vectors, i + 1, dim) + vectors[i][dim] / len(vectors);

function get_average_vector(vectors) =
  [_get_average_vector(vectors, 0, 0), _get_average_vector(vectors, 0, 1), _get_average_vector(vectors, 0, 2)];


// all credits to Philipp Otto2, used by function below
function _otto2_s(b_v, a_v, d) = d / (b_v * a_v);
function _otto2_p_m(b_v, a_v, d) = _otto2_s(b_v, a_v, d) * b_v;
function _otto2_offset(b_v, a_v, d) = norm_v(d * a_v - _otto2_p_m(b_v, a_v, d));

// There are two position vectors 'a' and 'b' and a distance to the origin 'd'. We want to translate the vector 'a' and
// this translation has to happen in regard to vector 'b'. So the translation vector is orthogonal to 'a' and goes through 'a' and 'b'.
// In other words, we want to push 'a' towards 'b' or away from it. But 'a' must not change the an
// @param b_v: normalized vector of b
// @param a_v: normalized vector of a
// @param d: distance to the origin to both position vectors
// @param factor: how far to translate (in mm)
// @return: [the translation vector (or in other words, the point [0, 0, 0] translated), the translated vector]
function translate_vector_in_regard_to_other(b_v, a_v, d, factor) =
  [factor * _otto2_offset(b_v, a_v, d) + [0, 0, 0], factor * _otto2_offset(b_v, a_v, d) + (d * a_v)];
