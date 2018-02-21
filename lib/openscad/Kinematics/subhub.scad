use <../Util/maths.scad>
use <util.scad>

// some small value
fix_rounding_issue = 0.001;

function norm_v(v) = v / norm(v);

function _get_middle(vectors, i, dim) = i == len(vectors) ? 0 : _get_middle(vectors, i + 1, dim) + vectors[i][dim] / len(vectors);

function get_middle(vectors) = [_get_middle(vectors, 0, 0), _get_middle(vectors, 0, 1), _get_middle(vectors, 0, 2)];

function otto2_s(uv, nv, d) = d / (uv * nv);

function otto2_p_m(uv, nv, d) = otto2_s(uv, nv, d) * uv;

function otto2_offset(uv, nv, d) = norm_v(d * nv - otto2_p_m(uv, nv, d));

function otto2_translate_point(uv, nv, d, factor) = [factor * otto2_offset(uv, nv, d) + [0, 0, 0], factor * otto2_offset(uv, nv, d) + (d * nv)];

function _otto2_each(vectors, middle, l12, factor, i) = i == len(vectors) ? [] : concat([otto2_translate_point(norm_v(middle), norm_v(vectors[i]), l12, factor)], _otto2_each(vectors, middle, l12, factor, i + 1));

function otto2_each(vectors, l12, factor) = _otto2_each(vectors, get_middle(vectors), l12, factor, 0);


module construct_intersection_poly(vectors, flag=true) {
  hull() {    
    for(p = vectors) {
  
      if (flag) {
        translate(p[0])
        sphere(r = 0.00001, center=true);
      } else {
        sphere(r = 0.00001, center=true);
      }
    
      translate(p[1])
      sphere(r = 0.00001, center=true);
    }
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
  difference() {
    intersection() {
      pushed1 = otto2_each(vectors, (l1 + l2) * 2, 12);
      construct_intersection_poly(pushed1);
      construct_spheres(outer_radius=l1 + l2, inner_radius=l1);
    }
    pushed2 = otto2_each(vectors, (l1 + l2) * 2, -24);
    construct_intersection_poly(pushed2, false);
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

module construct_cube_at_position(vector, distance, x, y, z) {
  translating_vector = vector * distance  + vector * z / 2;
  start_position_vector = [0, 0, 1]; // starting position of the vector

  q = getQuatWithCrossproductCheck(start_position_vector,vector);
  qmat = quat_to_mat4(q);

  translate(translating_vector)
  multmatrix(qmat) // rotation for connection vector
  cube(size=[x, y, z], center=true);
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
module construct_screw_hole(vector, l1, l2, l3, connector_end_extra_height, hole_size) {
  construct_cylinder_at_position(vector, 0, l1 + l2 + l3 + connector_end_extra_height + fix_rounding_issue, hole_size);
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
  vectors = 2 * (l1 + l2) * normal_vectors;

  middle = get_middle(normal_vectors);


  echo(middle);
//  vv = normal_vectors[0] * 100;
//    echo(vv);
//  rotate(a=[0, 10, 0], v=vv)
//  construct_cube_at_position(normal_vectors[0], 50, 20, 20, 30);

//  cylinder(h=20, r=10);
//  cube(size=[20, 20, 30], center=true);

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
          construct_screw_hole(normal_vectors[i], l1, l2, l3[i], connector_end_extra_height, hole_size);
          construct_a_gap(normal_vectors[i], l1, l2, gap_epsilon, gap_extra_round_size, round_size);
        }
        if (gap_types[i] == "b") {
          construct_screw_hole(normal_vectors[i], l1, l2, l3[i], connector_end_extra_height, hole_size);
          construct_b_gap(normal_vectors[i], l1, l2, gap_epsilon, gap_extra_round_size, round_size);
        }
      }
    }
  }
}

// for dev only

//l1 = 30;
//l2 = 40;
//
//normal_vectors = [[-0.9948266171932849, -0.00015485714145741815, 0.1015872912476312],
//[-0.3984857593670732, -0.28854789426039135, 0.8706027867515364],
//[-0.4641256842132446, -0.883604515803502, 0.06189029734333352]];
//
//gap_types = ["b", "a", undef];
//connector_types = [undef, "bottle", "bottle"];
//
//l3 = [undef, 10, 10];
//
//gap_epsilon=0.8000000000000002;
//gap_extra_round_size = 3;
//
//draw_subhub(normal_vectors, gap_types, connector_types, l1, l2, l3, 12, 3, gap_epsilon, gap_extra_round_size,
//connector_end_round=15.0,
//connector_end_heigth=3.7,
//connector_end_extra_round=9.95,
//connector_end_extra_height=3.9999999999999996);


draw_subhub(
normal_vectors = [
- [0.9906250734578931, -0.02591247775002514, -0.13412869690486925],
- [0.6035773980223504, -0.13727568779890292, 0.7853978037503716],
- [0.5134913486004344, -0.8229693719656428, 0.242998040566138]],
gap_types = [
"b",
"a",
"a"],
connector_types = [
"none",
"bottle",
"bottle"],
l1 = 40.0,
l3 = [
14.036058111910798,
14.36289336298551,
14.851815572367414],
round_size=12.0,
gap_epsilon=0.8000000000000002,
connector_end_round=15.0,
connector_end_heigth=3.7,
connector_end_extra_round=11.45,
connector_end_extra_height=7.0,
gap_extra_round_size=3.0,
hole_size=3.2000000000000006,
l2=40.0);

