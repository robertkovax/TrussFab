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

l1 = 20;
l2 = 10;
l3 = 10;

real_vectors = [[-0.9948266171932849, -0.00015485714145741815, 0.1015872912476312],
[-0.3984857593670732, -0.28854789426039135, 0.8706027867515364],
[-0.4641256842132446, -0.883604515803502, 0.06189029734333352],
[-0.026760578914151064, -0.01836892195863407, -0.9994730882431289]];

real_vectors2 = 100 * real_vectors;



intersection() {
    construct_intersection_poly(real_vectors2);
    construct_spheres(outer_radius=l1 + l2, inner_radius=l1);
}

//    construct_intersection_poly(real_vectors2);


function len_v(v) = sqrt(v[0] * v[0] + v[1] * v[1] + v[2] * v[2]);


function get_direction(v) = [acos(v[0] / len_v(v)), acos(v[1] / len_v(v)), acos(v[2] / len_v(v))];


function get_init_rotate(a) = a[0] > a[1] && a[0] > a[2] ? [0, 0, 0] : ( a[1] > a[0] && a[1] > a[2] ? [90, 0, 0] : ( a[2] > a[1] && a[2] > a[0] ? [9, 90, 0] : [0, 0, 0] ) );


module construct_plug(vector) {
//t_v_temp = [0, 0, 0];
t_v_temp = vector * l1;

translating_vector = [t_v_temp[0] , t_v_temp[1], t_v_temp[2]];

angles = get_direction(vector);

angles_turn = [angles[2], angles[0], angles[1]];
    
echo(angles);
    
rotate_vector = get_init_rotate(angles);
    
echo(angles[0] > angles[1]);
    


echo(rotate_vector);

translate(translating_vector)
rotate(angles_turn)
rotate(rotate_vector)
cylinder(h=l2, r=6, center=true);
}

construct_plug(real_vectors[0]);

construct_plug(real_vectors[1]);

construct_plug(real_vectors[2]);

construct_plug(real_vectors[3]);

//rotate([0, 90, 0])
//cylinder(h=12, r=6);
