use <simple_hinge.scad>
// just for d

// linear function to get the optiomal distance to the origin
p1_x = 30;
p1_y = 60;

p2_x = 90;
p2_y = 20;

m = (p2_y - p1_y) / (p2_x - p1_x);
b = p1_y - m * p1_x;

function optimal_distance_origin(angle) = (
  m * angle + b
);

//connection_angle = 60;
connection_angle = 90;

//distance_origin = optimal_distance_origin(connection_angle);
distance_origin = 50;

elongation_length = 120;

gap_height = 10;
gap_epsilon = 0.8;

a_l1 = distance_origin;
a_l2 = 4 * gap_height + gap_epsilon;
a_l3 = elongation_length - a_l1 - a_l2;

b_l1 = distance_origin; // add epsilon?
b_l2 = a_l2;
b_l3 = elongation_length - b_l1 - b_l2;

draw_hinge(alpha=connection_angle,
  a_l1=a_l1, a_l2=a_l2, a_l3=a_l3, a_gap=true,
  b_l1=b_l1, b_l2=b_l2, b_l3=b_l3, b_gap=true);

translate([150, 0, 0])
draw_hinge(alpha=connection_angle,
  a_l1=a_l1, a_l2=a_l2, a_l3=a_l3, a_gap=true,
  b_l1=b_l1, b_l2=b_l2, b_l3=b_l3, b_with_connector=true);

translate([-150, 0, 0])
draw_hinge(alpha=connection_angle,
  a_l1=a_l1, a_l2=a_l2, a_l3=a_l3, a_gap=false,
  b_l1=b_l1, b_l2=b_l2, b_l3=b_l3, b_gap=true, a_with_connector=true);

