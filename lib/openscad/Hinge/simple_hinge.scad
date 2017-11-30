// NB: Not all parameters for the angle and distance (to the origin) make sense. If the angle is low
// e.g. 40 deg, the distance should be high e.g. 80 mm.

use <../Misc/Prism.scad>

// dimension of one hinge part
depth = 24;
width = 100; // not really important because it gets cut off anyway. But should be large enough to cover all.

// radius
round_size = 12;    
hole_size = 7/2;

// the part where ohter connectors go
// 1. summand: the diameter of the hinging part
// 2. summand: the prism
// 3. summand: extra offset because we want to turn beyond 90 deg
extra_width_for_hinging = round_size / 2;
gap_witdh = 2 * round_size + depth / 2 + extra_width_for_hinging; 

gap_epsilon = 0.8;
gap_height = 10;
gap_height_e = gap_height + gap_epsilon;

safety_margin = 10;

cap_end_round = 30 / 2;
cap_end_heigth = 4;

module hingepart(l1, l2, l3, gap, with_cap, with_connector, the_lower_one=false) {
    // the base model
    difference() {
        union() {
            cube([width - round_size, l2, depth]);
            
            translate([width - round_size, 0, depth / 2])
            rotate([-90, 0, 0])
            cylinder(l2, round_size, round_size);
            
            if (with_cap) {
                translate([width - round_size, l2 + safety_margin, depth / 2])
                rotate([-90, 0, 0])
                cylinder(l3, round_size, round_size);
                
                translate([width - round_size, l2 + l3 - cap_end_heigth + safety_margin, depth / 2])
                rotate([-90, 0, 0])
                cylinder(cap_end_heigth, cap_end_round, cap_end_round);
            }
            
            if (with_connector) {
                translate([width - round_size, l2, depth / 2])
                rotate([-90, 0, 0])
                cylinder(l3, round_size, round_size);
                
                translate([width - round_size, l2 + l3 - cap_end_heigth, depth / 2])
                rotate([-90, 0, 0])
                cylinder(cap_end_heigth, cap_end_round, cap_end_round);

            }
        }      
        if (gap) {
            // move gap to the middle of the part
            cut_gap_height = gap_height;
            translate([width - gap_witdh, cut_gap_height, 0])
            cube([width, gap_height_e, depth]);
            
            // cut out the two holes
            translate([width - round_size, 0, depth / 2])
            rotate([-90, 0, 0])
            
            cylinder(l2 + l3 + safety_margin, hole_size, hole_size);
        }
    }
    
    // the triangle within the gap
    if (gap) {
        prism_height = 1 * gap_height_e + 3 * gap_height;
        prism_translate_x = width - gap_witdh;
        prism_translate_y = the_lower_one ? prism_height : prism_height - gap_height;
        
         x = sqrt((depth / 2) * (depth / 2) + (depth / 2) * (depth / 2)); // pythagoras
        translate([prism_translate_x, prism_translate_y, 0])
        rotate([45, 0, -90])
        prism(prism_height, x, x);
            
        // fill in space where the prism isn't enough
        translate_help_cube_y = the_lower_one ? 0 : -gap_height;
        translate([0, translate_help_cube_y, 0])
        cube([prism_translate_x, prism_height, depth]);
    }
}

/*
a: the right part
b: the left part, should be the one closer to the origin
*/

module draw_hinge(
    alpha,
    a_l1, a_l2, a_l3, a_gap, a_with_connector, a_with_cap,
    b_l1, b_l2, b_l3, b_gap, b_with_connector, b_with_cap) {
    
    a_angle = alpha / -2;
    a_translate_x = a_l1 * cos(90 + a_angle);
    a_translate_y = a_l1 * sin(90 + a_angle);

    b_angle = alpha / 2;
    b_translate_x = b_l1 * cos(90 + b_angle);
    b_translate_y = b_l1 * sin(90 + b_angle);
    
    // the last cut out for the gap of the left side to fully hinge
    // the translations are only to cut off some other parts for the gaps more easily
    difference() {
        translate([-round_size - extra_width_for_hinging, 0, 0])
        rotate([0, 0, alpha / -2])    
        difference() {   
            union() {
                difference() {
                    translate([a_translate_x, a_translate_y, 0])
                    rotate([0, 0, a_angle])
                    translate([-(width - round_size), 0, 0])
                    translate([0, 0, depth / -2]) // center on the z axis
                    hingepart(a_l1, a_l2, a_l3, a_gap, a_with_cap, a_with_connector);
                    
                    // cut away parts that are on the on the other site
                    translate([-1000, 0, -500])
                    cube([1000, 1000, 1000]);
                }
                
                difference() {
                    translate([b_translate_x, b_translate_y, 0])
                    rotate([0, 0, b_angle])
                    mirror([1, 0, 0])
                    translate([-(width - round_size), 0, 0])
                    translate([0, 0, depth / -2])
                    hingepart(b_l1, b_l2, b_l3, b_gap, b_with_cap, b_with_connector, the_lower_one=true);

                    // cut away parts that are on the on the other site
                    translate([0, 0, -500])
                    cube([1000, 1000, 1000]);        
                }
            }
            
            union() {
                if (!a_with_connector && !b_with_connector) {
                    // cuts out parts at the top
                    a_l12 = a_l1 + a_l2;
                    b_l12 = b_l1 + b_l2;
                    longest = max(a_l12, b_l12);
                    translate([0, longest + 50 + 3, 0]) // you can tune the last summand
                    cube([100, 100, 100], center=true);    
                }
                /*
                    The following code cuts out the last ramp of the hinge part that is clostest to
                    the origin. It's kind of difficult to achieve because before, every hinge part was
                    responsible for his quadrant. Now, the one that is furter away from the origin,
                    has to cut out parts of the other part (in the other quadrant). So we bascially
                    have to replicate all the combined roations and translations. It helps, that we
                    know the exacat distance from the origin. But it still unclear (to me) what the
                    excact modifications were just tried out some values.
                */
                if (a_gap) {
                    prune_angle = 90 - (alpha / 2);
                    prune_length = a_l1 * 2 - 0.001;
                    prune_width = gap_height * 2.55; // magic constant through experiments            
                    prune_depth = 100;
                    for (i = [0:1]) {
                        rotate([45 + 90 * i, 0, prune_angle])
                        cube([prune_length, prune_width, prune_depth], center=true);
                    }
                }
            }
        }
        if (b_gap) {
            for (i = [0:1]) {
                rotate([0, -45 - i * 180, 0]) 
                translate([0, a_l1, 0])
                cube([gap_witdh, gap_height_e, 100]);
            }
        }
    }
}



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
connection_angle = 40;

//distance_origin = optimal_distance_origin(connection_angle);
distance_origin = 65;

elongation_length = 120;

a_l1 = distance_origin;
a_l2 = 3 * gap_height + gap_epsilon;
a_l3 = elongation_length - a_l1 - a_l2;

b_l1 = distance_origin - gap_height; // add epsilon?
b_l2 = a_l2;
b_l3 = elongation_length - b_l1 - b_l2;

//
//draw_hinge(alpha=connection_angle,
//    a_l1=l1, a_l2=l2, a_l3=l3, a_with_connector=true,
//    b_l1=l1, b_l2=l2, b_l3=l3, b_gap=true, b_with_cap=true);

//
//draw_hinge(alpha=connection_angle,
//    a_l1=a_l1, a_l2=a_l2, a_l3=a_l3, a_with_connector=true,
//    b_l1=b_l1, b_l2=b_l2, b_l3=b_l3, b_gap=true, b_with_cap=true);
    
//draw_hinge(alpha=connection_angle,
//    a_l1=a_l1, a_l2=a_l2, a_l3=a_l3, a_gap=true,
//    b_l1=b_l1, b_l2=b_l2, b_l3=b_l3, b_with_connector=true);
    
draw_hinge(alpha=connection_angle,
    a_l1=a_l1, a_l2=a_l2, a_l3=a_l3, a_gap=false,
    b_l1=b_l1, b_l2=b_l2, b_l3=b_l3, b_gap=true, a_with_connector=true);  
        