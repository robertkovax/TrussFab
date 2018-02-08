use <../Util/maths.scad>
use <../Util/lists.scad>
use <util.scad>

module construct_intersection_poly(vectors) {
  points = concat_lists([[0, 0, 0]], vectors);

  // NB: The order of the faces must be clock-wise (looking from the outside towards the face)

  // the top face depends on the number of input vector (points)
  top = [[for(i=[1:len(vectors)]) i ]];
  // always triangles, first get the easy sides
  side_all_but_not_last = [for(i=[1:len(vectors) - 1]) [i + 1, i, 0]];
  // the last to connect to the first one
  side_last = [[0, 1, len(vectors)]];

  // concat all together
  faces = concat_lists(top, concat_lists(side_all_but_not_last, side_last));

  // TODO: make it properly. the hull solved out problem of finding a convex hull around some points. we constructurd the poins
  hull() {
    polyhedron( points, faces );
  }
}

module construct_spheres(outer_radius, inner_radius) {
  difference() {
    mirror([0, 0, 1])
    sphere(r=outer_radius, center=true);

    union() {
      sphere(r=inner_radius, center=true);
    }
  }
}

module construct_base_model(vectors, l1, l2) {
  intersection() {
    construct_intersection_poly(vectors);
    construct_spheres(outer_radius=l1 + l2, inner_radius=l1);
  }
}

module construct_cylinder_at_position(vector, distance, h, r) {
  translating_vector = vector * distance  + vector * h / 2;
  start_position_vector = [0, 0, 1]; // starting position of the vector

  q = getQuatWithCrossproductCheck(start_position_vector,vector);
  qmat = quat_to_mat4(q);

  translate(translating_vector)
  multmatrix(qmat) // rotation for connection vector
  difference() {
    cylinder(h=h, r=r, center=true);
  }
}

// construct to later substract
module construct_a_gap(vector, gap_height, gap_epsilon, round_size) {
  union() {
    for (i = [0:1]) {
      gap_distance_from_origin = hinge_a_y_gap(l1, gap_height, gap_epsilon, i);
      construct_cylinder_at_position(vector, gap_distance_from_origin, gap_height, round_size + 3);
    }
  }
}

// construct to later substract
module construct_b_gap(vector, gap_height, gap_epsilon, round_size) {
  union() {
    for (i = [0:1]) {
      gap_distance_from_origin = hinge_b_y_gap(l1, gap_height, gap_epsilon, i);
      construct_cylinder_at_position(vector, gap_distance_from_origin, gap_height, round_size + 3);
    }
  }
}

// construct to later substract
module construct_screw_holes(normal_vectors, l1, l2, hole_size) {
  for(n_v = normal_vectors) {
    construct_cylinder_at_position(n_v, l1 / 2, l2 * 2, hole_size);
  }
}

module construct_hubless(
  normal_vectors, // array of vectors
  types, // array of types
  l1,
  l2,
  l3, // array of l3
  round_size,
  hole_size,
  gap_height,
  gap_epsilon
  ) {
  vectors = 1.5 * (l1 + l2) * normal_vectors;

  difference() {
    union() {
      construct_base_model(vectors, l1, l2);

      for (i=[0:len(normal_vectors)]) {
        if (types[i] == "a_gap" || types[i] == "b_gap") {
          construct_cylinder_at_position(normal_vectors[i], l1, l2, round_size);
        } else  if (types[i] == "bottle_connector") {
          // TODO: REAL_CONNECTOR
          construct_cylinder_at_position(normal_vectors[i], l1, l2, round_size);
        }
      }
    }
    union() {
      construct_screw_holes(normal_vectors, l1, l2, hole_size);
      for (i=[0:len(normal_vectors)]) {
        if (types[i] == "a_gap") {
          construct_a_gap(normal_vectors[i], gap_height, gap_epsilon, round_size);
        } else if (types[i] == "b_gap") {
          construct_b_gap(normal_vectors[i], gap_height, gap_epsilon, round_size);
        }
      }
    }
  }
}

// for dev only

l1 = 30;
l2 = 41.199999999999996;

normal_vectors = [[-0.9948266171932849, -0.00015485714145741815, 0.1015872912476312],
[-0.3984857593670732, -0.28854789426039135, 0.8706027867515364],
[-0.4641256842132446, -0.883604515803502, 0.06189029734333352],
[-0.026760578914151064, -0.01836892195863407, -0.9994730882431289]];

types = ["a_gap", "b_gap", "bottle_connector", "bottle_connector"];
l3 = [0, 0, 0, 0];

construct_hubless(normal_vectors, types, l1, l2, l3, 12, 3, 10, 0.1);
