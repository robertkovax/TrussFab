// NB: Not all parameters for the angle and distance (to the origin) make sense. If the angle is low
// e.g. 40 deg, the distance should be high e.g. 80 mm.

// dimension of one hinge part
depth = 24;
width = 100; // not really important because it gets cut off anyway. But should be large enough to cover all.

// radius
round_size = 12;    
hole_size = 7/2; // Rob said it should a diameter of 6.5mm. Change it?

// the part where ohter connectors go
// 1. summand: the diameter of the hinging part
// 2. summand: the prism
// 3. summand: extra offset because we want to turn beyond 90 deg
//extra_width_for_hinging = round_size / 2;

gap_angle_a = 30;
gap_angle_b = gap_angle_a;

extra_width_for_hinging = 0;
gap_witdh = 2 * round_size + depth / 2 + extra_width_for_hinging; 

gap_epsilon = 0.8;
gap_height = 10;
gap_height_e = gap_height + gap_epsilon;

cap_end_round = 30 / 2;
cap_end_heigth = 4;