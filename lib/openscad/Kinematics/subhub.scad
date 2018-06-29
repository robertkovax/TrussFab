use <../Util/line_calculations.scad>
use <../Util/construct_at_position.scad>
use <util.scad>

// some small value
fix_rounding_issue = 0.001;

small_point_radius = 0.00001;

// does not really matter, we just have to assigne some propery value to the vectors
vector_l12_distance_factor = 10;

// all credits Robert Kovacs
function angle_to_distance_to_pull(alpha, r) = sqrt(pow(r / sin((alpha * 1.2) / 2), 2) - pow(r, 2));

function prev_i(i, n) = i > 0 ? i - 1 : n - 1;
function next_i(i, n) = i == n - 1 ? 0 : i + 1;

function v1(vectors, i) = norm_v(vectors[prev_i(i, len(vectors))]) - norm_v(vectors[i]);
function v2(vectors, i) = norm_v(vectors[next_i(i, len(vectors))]) - norm_v(vectors[i]);


function _g_d_t_p_o(vectors, round_size, i) = i == len(vectors) ?
  [] :
  concat([angle_to_distance_to_pull(deg_between_3d_vectors(v1(vectors, i), v2(vectors, i)), round_size)], _g_d_t_p_o(vectors, round_size, i + 1));

function get_distance_to_pull_put(vectors, round_size) = _g_d_t_p_o(vectors, round_size, 0);

function _push_or_pull_each_vector(vectors, middle, l12, factors, i) = i == len(vectors) ?
  [] :
  concat(
    [translate_vector_in_regard_to_other(norm_v(middle), norm_v(vectors[i]), l12, factors[i])],
    _push_or_pull_each_vector(vectors, middle, l12, factors, i + 1)
  );

function push_or_pull_each_vector(vectors, l12, factors) =
  _push_or_pull_each_vector(vectors, get_average_vector(vectors), l12, factors, 0);

module construct_intersection_poly(vectors, flag=true) {
  average_point = norm_v(get_average_vector([vectors[0][1], vectors[1][1], vectors[2][1]]));
  hull() {
    for(p = vectors) {
  
      if (flag) {
        translate(p[0])
        sphere(r = small_point_radius, center=true);
      } else {

        i = get_line_intersection_3d([0, 0, 0], p[1], average_point, p[0]);
        translate(i)
        sphere(r = small_point_radius, center=true);        
      }
    
      translate(p[1])
      sphere(r = small_point_radius, center=true);
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


// idea:
// 1) from the given vectors, calculate vectors that are pushed inwards. That cut away a poligon bases on the pushed in values and substract it. 
// 2) Push vectors out so we have a wall (thickness: distance between pushed out and pushed in vectors).
module construct_base_model(vectors, l1, l2, round_size, bottom_radius_play, edge_sphere_push_out, edge_sphere_pull_in) {
  l12 = l1 + l2;
 
  push_out_distances =  edge_sphere_push_out != undef ? edge_sphere_push_out : get_distance_to_pull_put(vectors, round_size);
  pull_in_distances = edge_sphere_pull_in != undef ? edge_sphere_pull_in :  [ for(i = [0 : len(vectors) - 1]) push_out_distances[i] > round_size ? (-push_out_distances[i] - 1) : -round_size - 1];  echo(round_size);
  
  pushed_out = push_or_pull_each_vector(vectors, l12 * vector_l12_distance_factor, push_out_distances);
  pulled_in = push_or_pull_each_vector(vectors, l12 * vector_l12_distance_factor, pull_in_distances);

  difference() {
    intersection() {
      construct_intersection_poly(pushed_out);
      construct_spheres(outer_radius=l12, inner_radius=l1 + bottom_radius_play);
    }
    union() {
      for(i = [0 : len(vectors)]) {
        v = vectors[i];
        translate(pushed_out[i][0])
        construct_cylinder_at_position(norm_v(v), 0, l12, push_out_distances[i] - 0);
      }
      construct_intersection_poly(pulled_in, false);
    }
  }
}

function get_all_points_for_proper_cutout(normal_middle_vector, vector, gap_offset, gap_height, round_size, n_m_v, gap_cut_out_play) =
[
  translate_vector_in_regard_to_other(normal_middle_vector, vector, gap_offset, - round_size - gap_cut_out_play)[1],
  translate_vector_in_regard_to_other(normal_middle_vector, vector, gap_offset + gap_height, - round_size - gap_cut_out_play)[1],
  translate_vector_in_regard_to_other(normal_middle_vector, vector, gap_offset, 2 * round_size + gap_cut_out_play)[1],
  translate_vector_in_regard_to_other(normal_middle_vector, vector, gap_offset + gap_height, 2 * round_size + gap_cut_out_play)[1],
  vector * gap_offset + 2 * round_size * n_m_v,
  vector * gap_offset - 2 * round_size * n_m_v,
  vector * (gap_offset + gap_height) + 2 * round_size * n_m_v,
  vector * (gap_offset + gap_height) - 2 * round_size * n_m_v
];


module construct_points_for_cutout(normal_middle_vector, vector, gap_offset, gap_height, round_size, gap_cut_out_play, add_zero_point=false) {
  p1 = translate_vector_in_regard_to_other(normal_middle_vector, vector, gap_offset, - 1* round_size - gap_cut_out_play);
  p1_a_v = norm_v(p1[0]);
  n_m_v = cross(p1_a_v, p1[1]);
  points = get_all_points_for_proper_cutout(normal_middle_vector, vector, gap_offset, gap_height, round_size, n_m_v, gap_cut_out_play);
  hull() {
    if (add_zero_point) {
      sphere(r = small_point_radius, center=true);              
    }
    for (p = points) {
      translate(p)
      sphere(r = small_point_radius, center=true);              
    }
  }
}

// construct to later substract
module construct_a_gap(vector, l1, l2, gap_epsilon, gap_extra_round_size, round_size, normal_middle_vector, gap_cut_out_play) {
  union() {
    for (i = [0:1]) {
      first = i == 0;
      gap_offset = hinge_a_y_gap_offset(l1, l2, gap_epsilon, first);
      gap_height = hinge_a_y_gap_height(l2, gap_epsilon, first);
      
      construct_points_for_cutout(normal_middle_vector, vector, gap_offset, gap_height, round_size, gap_cut_out_play, first);
      
      if (first) {
        construct_cylinder_at_position(vector, 0, gap_height + gap_offset, round_size + gap_extra_round_size);
      } else {
        construct_cylinder_at_position(vector, gap_offset, gap_height, round_size + gap_extra_round_size);
      }
    }
  }
}

// construct to later substract
module construct_b_gap(vector, l1, l2, gap_epsilon, gap_extra_round_size, round_size, normal_middle_vector, gap_cut_out_play) {
  union() {
    for (i = [0:1]) {
      gap_offset = hinge_b_y_gap_offset(l1, l2, gap_epsilon, i==0) ;
      gap_height = hinge_b_y_gap_height(l2, gap_epsilon, i==0);
      construct_points_for_cutout(normal_middle_vector, vector, gap_offset, gap_height, round_size, gap_cut_out_play);

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

// connections are in arrays. The order within the array is crucial. Neighboring connectors have to also be neighbor in the array.
module draw_subhub(
  normal_vectors, // array of vectors
  gap_types, // array of gap types
  connector_types, // array of gap types
  l1, // number
  l2, // number
  l3, // array of numbers
  round_size, // number
  hole_size, // number
  gap_epsilon, // number
  gap_extra_round_size, // number
  connector_end_round, // number
  connector_end_heigth, // number
  connector_end_extra_round, // number
  connector_end_extra_height, // number
  gap_cut_out_play=1,
  bottom_radius_play=3,
  edge_sphere_push_out=undef,
  edge_sphere_pull_in=undef
  ) {
  vectors = vector_l12_distance_factor * (l1 + l2) * normal_vectors;

  normal_middle_vector = norm_v(get_average_vector(normal_vectors));

  difference() {
    union() {
      construct_base_model(vectors, l1, l2, round_size, bottom_radius_play, edge_sphere_push_out, edge_sphere_pull_in);

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
      construct_screw_hole(normal_vectors[i], l1, l2, l3[i], connector_end_extra_height, hole_size);
        if (gap_types[i] == "a") {
          construct_a_gap(normal_vectors[i], l1, l2, gap_epsilon, gap_extra_round_size, round_size, normal_middle_vector, gap_cut_out_play);
        }
        if (gap_types[i] == "b") {
          construct_b_gap(normal_vectors[i], l1, l2, gap_epsilon, gap_extra_round_size, round_size, normal_middle_vector, gap_cut_out_play);
        }
      }
    }
  }
}

// for dev only

draw_subhub(
//  edge_sphere_push_out=[10, 10, 10],
//  edge_sphere_pull_in=[-200, -15, -15],
  normal_vectors = [
[-0.46176692401208635, -0.16536591594381367, -0.8714501831616537],
[-0.6551289426291086, -0.749701407957592, -0.09356210470094439],
[0.16757988774483643, -0.7477098404652285, -0.6425316923661359]],
  gap_types = [
"none",
"none",
"b"],
  connector_types = [
"bottle",
"bottle",
"none"],
  l1 = 35.0,
  l3 = [
13.871094099104516,
14.788289754398557,
7.8091161942186185],
  connector_end_extra_height=7.0,
  connector_end_extra_round=9.95,
  connector_end_heigth=3.7,
  connector_end_round=15.0,
  gap_epsilon=0.8,
  gap_extra_round_size=3.0,
  hole_size=3.2,
  l2=40.0,
  round_size=12.0
);

