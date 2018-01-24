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


module create_intersection(vectors, l1, l2) {
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

module construct_hubless(normal_vectors, l1, l2, l3, round_size, hole_size) {
    vectors = 1.5 * (l1 + l2 + l3) * normal_vectors;  
  
    difference() {
        union() {
            create_intersection(vectors, l1, l2);
            construct_multiple_cylinders_at_positin(normal_vectors, l1, l2, round_size);
        }
        union() {
            construct_multiple_cylinders_at_positin(normal_vectors, l1 / 2, l2 * 2, hole_size);
          }
    }
}


l1 = 20;
l2 = 30;
l3 = 10;


normal_vectors = [[-0.9948266171932849, -0.00015485714145741815, 0.1015872912476312],
[-0.3984857593670732, -0.28854789426039135, 0.8706027867515364],
[-0.4641256842132446, -0.883604515803502, 0.06189029734333352],
[-0.026760578914151064, -0.01836892195863407, -0.9994730882431289]];

construct_hubless(normal_vectors, l1, l2, l3, 12, 3);


