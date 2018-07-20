use <../Util/maths.scad>
use <../Util/text_on.scad>


module construct_cylinder_at_position(vector, distance, h, r) {
  translating_vector = vector * distance  + vector * h / 2;
  start_position_vector = [0, 0, 1]; // starting position of the vector

  q = getQuatWithCrossproductCheck(start_position_vector,vector);
  qmat = quat_to_mat4(q);

  translate(translating_vector)
  multmatrix(qmat) // rotation for connection vector
  cylinder(h=h, r=r, center=true);
}


module construct_text_on_sphere_at_position(vector, r, t, size, spacing) {
    // the starting position for the `text_on_sphere` looks like to be [0, -1, 0]
    // construct_cylinder_at_position([0, -1, 0], 0, 100, 1);

    start_position_vector = [0, -1, 0]; // starting position of the vector
    q = getQuatWithCrossproductCheck(start_position_vector,vector);
    qmat = quat_to_mat4(q);
  
    echo(size, spacing);
  
    multmatrix(qmat) // rotation for connection vector
    text_on_sphere(t=t, r=r, size=size, spacing=spacing);
}


// dev
sphere(10);
construct_text_on_sphere_at_position([1, 1, 111], 10);
