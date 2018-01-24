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
    faces = cat(cat(side_all_but_not_last, side_last), top);

    polyhedron( points, faces );
}

module construct_spheres(outer_radius, inner_radius) {
    difference() {
        mirror([0, 0, 1])
        sphere(r=outer_radius, center=true);

        union() {
            sphere(r=inner_radius, center=true);
//            translate([0, 0, -50])
//            cube([100, 100, 100], center=true);
        }
    }    
}


module create_intersection() {
    intersection() {
        construct_intersection_poly(real_vectors2);
        construct_spheres(outer_radius=l1 + l2, inner_radius=l1);
    }
}


l1 = 20;
l2 = 30;
l3 = 10;

real_vectors = [[-0.9948266171932849, -0.00015485714145741815, 0.1015872912476312],
[-0.3984857593670732, -0.28854789426039135, 0.8706027867515364],
[-0.4641256842132446, -0.883604515803502, 0.06189029734333352],
[-0.026760578914151064, -0.01836892195863407, -0.9994730882431289]];

real_vectors2 = 100 * real_vectors;

create_intersection();

module construct_plug(vector) {
    translating_vector = vector * l1  + vector * l2 / 2;

    start_position_vector = [0, 0, 1]; // starting position of the vector

    q = getQuatWithCrossproductCheck(start_position_vector,vector);
    qmat = quat_to_mat4(q);

    translate(translating_vector)
    multmatrix(qmat) // rotation for connection vector
    cylinder(h=l2, r=6, center=true);
}

construct_plug(real_vectors[0]);

construct_plug(real_vectors[1]);

construct_plug(real_vectors[2]);

construct_plug(real_vectors[3]);

//rotate([0, 90, 0])
//cylinder(h=12, r=6);

//construct_plug([1, 0, 0]);
//construct_plug([0, 1, 0]);
//construct_plug([0, 0, 1]);
//
//construct_plug([-1, 0, 0]);
//construct_plug([0, -1, 0]);
//construct_plug([0, 0, -1]);

