use <../Util/maths.scad>
use <../Util/lists.scad>
use <util.scad>

// some small value
fix_rounding_issue = 0.001;

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
  cylinder(h=h, r=r, center=true);
}

// construct to later substract
module construct_a_gap(vector, l1, l2, gap_epsilon, gap_extra_round_size, round_size) {
  union() {
    for (i = [0:1]) {
      first = i == 0;
      gap_offset = hinge_a_y_gap_offset(l1, l2, gap_epsilon, first);
      gap_height = hinge_a_y_gap_height(l2, gap_epsilon, first);
      if (first) {
        construct_cylinder_at_position(vector, 0, gap_height + gap_offset, round_size + gap_extra_round_size);
      } else {
        construct_cylinder_at_position(vector, gap_offset, gap_height, round_size + gap_extra_round_size);
      }
    }
  }
}

// construct to later substract
module construct_b_gap(vector, l1, l2, gap_epsilon, gap_extra_round_size, round_size) {
  union() {
    for (i = [0:1]) {
      gap_offset = hinge_b_y_gap_offset(l1, l2, gap_epsilon, i==0) ;
      gap_height = hinge_b_y_gap_height(l2, gap_epsilon, i==0);
      construct_cylinder_at_position(vector, gap_offset, gap_height + fix_rounding_issue, round_size + gap_extra_round_size);
    }
  }
}

module construct_bottle_connector(vector, l1, l2, l3, round_size, connector_end_round, connector_end_heigth, connector_end_extra_round, connector_end_extra_height) {
  construct_cylinder_at_position(vector, l1, l2 + l3, round_size);

  construct_cylinder_at_position(vector, l1 + l2 + l3 - connector_end_heigth, connector_end_heigth, connector_end_round);

  construct_cylinder_at_position(vector, l1 + l2 + l3, connector_end_extra_height, connector_end_extra_round);
}

// construct to later substract
module construct_screw_hole(vector, l1, l2, hole_size) {
  construct_cylinder_at_position(vector, l1 / 2, l2 * 2, hole_size);
}

module draw_subhub(
  normal_vectors, // array of vectors
  gap_types, // array o
  connector_types,
  l1,
  l2,
  l3, // array of l3
  round_size,
  hole_size,
  gap_epsilon,
  gap_extra_round_size,
  connector_end_round,
  connector_end_heigth,
  connector_end_extra_round,
  connector_end_extra_height
  ) {
  vectors = 1.5 * (l1 + l2) * normal_vectors;

  difference() {
    union() {
      construct_base_model(vectors, l1, l2);

      for (i=[0:len(normal_vectors)]) {
        if (gap_types[i] != undef) {
          construct_cylinder_at_position(normal_vectors[i], l1, l2, round_size);
        }
        if (connector_types[i] == "bottle") {
          construct_bottle_connector(normal_vectors[i], l1, l2, l3[i], round_size,
            connector_end_round, connector_end_heigth, connector_end_extra_round, connector_end_extra_height);
        }
      }
    }
    union() {
      for (i=[0:len(normal_vectors)]) {
        if (gap_types[i] == "a") {
          construct_screw_hole(normal_vectors[i], l1, l2, hole_size);
          construct_a_gap(normal_vectors[i], l1, l2, gap_epsilon, gap_extra_round_size, round_size);
        }
        if (gap_types[i] == "b") {
          construct_screw_hole(normal_vectors[i], l1, l2, hole_size);
          construct_b_gap(normal_vectors[i], l1, l2, gap_epsilon, gap_extra_round_size, round_size);
        }
      }
    }
  }
}

// for dev only

l1 = 30;
l2 = 40;

normal_vectors = [[-0.9948266171932849, -0.00015485714145741815, 0.1015872912476312],
[-0.3984857593670732, -0.28854789426039135, 0.8706027867515364],
[-0.4641256842132446, -0.883604515803502, 0.06189029734333352]];

gap_types = ["b", "a", undef];
connector_types = [undef, "bottle", "bottle"];

l3 = [undef, 10, 10];

gap_epsilon=0.8000000000000002;
gap_extra_round_size = 3;

draw_subhub(normal_vectors, gap_types, connector_types, l1, l2, l3, 12, 3, gap_epsilon, gap_extra_round_size,
connector_end_round=15.0,
connector_end_heigth=3.7,
connector_end_extra_round=9.95,
connector_end_extra_height=3.9999999999999996);
