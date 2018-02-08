use <../Util/maths.scad>

// https://en.wikibooks.org/wiki/OpenSCAD_User_Manual/List_Comprehensions
function cat(L1, L2) = [for (i=[0:len(L1)+len(L2)-1])
                        i < len(L1)? L1[i] : L2[i-len(L1)]] ;

module construct_intersection_poly(vectors) {
  points = cat([[0, 0, 0]], vectors);

  // NB: The order of the faces must be clock-wise (looking from the outside towards the face)

  // the top face depends on the number of input vector (points)
  top = [[for(i=[1:len(vectors)]) i ]];
  // always triangles, first get the easy sides
  side_all_but_not_last = [for(i=[1:len(vectors) - 1]) [i + 1, i, 0]];
  // the last to connect to the first one
  side_last = [[0, 1, len(vectors)]];

  // concat all together
  faces = cat(top, cat(side_all_but_not_last, side_last));

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

module construct_cylinders_at_position(vector, distance, h, r) {
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

module construct_multiple_cylinders_at_positin(normal_vectors, distance, h, r) {
  for(n_v = normal_vectors) {
    construct_cylinders_at_position(n_v, distance, h, r);
  }
}

// construct to later substract
module construct_a_gap(vector, gap_size, gap_play, round_size) {
  union() {
    gap_distance_from_origin_1 = l1 + gap_size + gap_play;
    construct_cylinders_at_position(vector, gap_distance_from_origin_1, gap_size, round_size + 3);
    
    gap_distance_from_origin_2 = l1 + gap_size * 3 + gap_play * 3;
    construct_cylinders_at_position(vector, gap_distance_from_origin_2, gap_size, round_size + 3);
  }
}

// construct to later substract
module construct_screw_holes(normal_vectors, l1, l2, hole_size) {
  construct_multiple_cylinders_at_positin(normal_vectors, l1 / 2, l2 * 2, hole_size);
}

module construct_hubless(
  normal_vectors, // array of vectors
  types, // array of types
  l1,
  l2,
  l3, // array of l3
  round_size,
  hole_size,
  gap_size,
  gap_play
  ) {
  vectors = 1.5 * (l1 + l2) * normal_vectors;

  difference() {
    union() {
      construct_base_model(vectors, l1, l2);
      
      for (i=[0:len(normal_vectors)]) {
        if (types[i] == "a_gap" || types[i] == "b_gap") {
          construct_cylinders_at_position(normal_vectors[i], l1, l2, round_size);
        } else  if (types[i] == "bottle_connector") {
          // TODO: REAL_CONNECTOR
          construct_cylinders_at_position(normal_vectors[i], l1, l2, round_size);
        }
      }
    }
    union() {
      construct_screw_holes(normal_vectors, l1, l2, hole_size);
      for (i=[0:len(normal_vectors)]) {
        if (types[i] == "a_gap") {
          construct_a_gap(normal_vectors[i], gap_size, gap_play, round_size);
        } else if (types[i] == "b_gap") {
          // TODO
          construct_a_gap(normal_vectors[i], gap_size, gap_play, round_size);      
        }
      }
    }
  }
}

// for dev only

l1 = 30;
l2 = 10 * 4 + 2 * 0.1;
//l3 = 10;

normal_vectors = [[-0.9948266171932849, -0.00015485714145741815, 0.1015872912476312],
[-0.3984857593670732, -0.28854789426039135, 0.8706027867515364],
[-0.4641256842132446, -0.883604515803502, 0.06189029734333352],
[-0.026760578914151064, -0.01836892195863407, -0.9994730882431289]];

types = ["a_gap", "b_gap", "bottle_connector", "bottle_connector"];
l3 = [0, 0, 0, 0];

construct_hubless(normal_vectors, types, l1, l2, l3, 12, 3, 10, 0.1);
