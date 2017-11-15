use <../Misc/Prism.scad>

// dimension of one hinge part
depth = 24;
width = 60;

// diameters
round_size = 12;    
hole_size = 7/2;

// the part where ohter connectors go
gap_witdh = round_size * 2 + 5;

gap_epsilon = 0.6;
gap_height = 10;
gap_height_e = gap_height + gap_epsilon;

safety_margin = 10;

cap_end_round = 30;
cap_end_heigth = 4;

prism_middle = 10;

module hingepart(l1, l2, l3, gap, with_cap, solid_top, the_lower_one=false) {
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
            
            if (solid_top) {
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
            cut_gap_height = gap_height + gap_epsilon / 2;
            translate([width - gap_witdh, cut_gap_height, 0])
            cube([width, gap_height, depth]);
            
            // cut out the two holes
            translate([width - round_size, 0, depth / 2])
            rotate([-90, 0, 0])
            
            cylinder(l2 + l3 + safety_margin, hole_size, hole_size);
        }
    }
         x = sqrt((depth / 2) * (depth / 2) + (depth / 4) * (depth / 4)) + 3; // pythagoras
        translate([width - gap_witdh, gap_height_e + gap_height, 0])
        rotate([45, 0, -90])
        prism(gap_height_e, x, x);
}


module draw_hinge(
    alpha,
    a_l1, a_l2, a_l3, a_gap, a_solid_top, a_with_cap,
    b_l1, b_l2, b_l3, b_gap, b_solid_top, b_with_cap) {
    
    a_angle = - alpha / 2;
    a_translate_x = a_l1 * cos(90 + a_angle);
    a_translate_y = a_l1 * sin(90 + a_angle);
    
        
    difference() {
        translate([a_translate_x, a_translate_y, 0])
        rotate([0, 0, a_angle])
        translate([-(width - round_size), 0, 0])
        translate([0, 0, -depth / 2]) // center on the z axis
        hingepart(a_l1, a_l2, a_l3, a_gap, a_with_cap, a_solid_top);
        
        // cut away parts that are on the on the other site
        translate([-100, 0, -50])
        cube([100, 100, 100]);
    }

    b_angle = alpha / 2;
    b_translate_x = b_l1 * cos(90 + b_angle);
    b_translate_y = b_l1 * sin(90 + b_angle);
    
    difference() {
        translate([b_translate_x, b_translate_y, 0])
        rotate([0, 0, b_angle])
        mirror([1, 0, 0])
        translate([-(width - round_size), 0, 0])
        translate([0, 0, -depth / 2])
        hingepart(b_l1, b_l2, b_l3, b_gap, b_with_cap, b_solid_top, the_lower_one=true);

        // cut away parts that are on the on the other site
        translate([0, 0, -50])
        cube([100, 100, 100]);        
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
connection_angle = 60;

distance_origin = optimal_distance_origin(connection_angle);
//distance_origin = 5s0;

elongation_length = 100;

a_l1 = distance_origin;
a_l2 = 3 * gap_height + gap_epsilon;
a_l3 = elongation_length - a_l1 - a_l2;

b_l1 = distance_origin - gap_height; // add epsilon?
b_l2 = a_l2;
b_l3 = elongation_length - b_l1 - b_l2;

//
//draw_hinge(alpha=connection_angle,
//    a_l1=l1, a_l2=l2, a_l3=l3, a_solid_top=true,
//    b_l1=l1, b_l2=l2, b_l3=l3, b_gap=true, b_with_cap=true);

//
//draw_hinge(alpha=connection_angle,
//    a_l1=a_l1, a_l2=a_l2, a_l3=a_l3, a_solid_top=true,
//    b_l1=b_l1, b_l2=b_l2, b_l3=b_l3, b_gap=true, b_with_cap=true);
    
//draw_hinge(alpha=connection_angle,
//    a_l1=a_l1, a_l2=a_l2, a_l3=a_l3, a_gap=true,
//    b_l1=b_l1, b_l2=b_l2, b_l3=b_l3, b_solid_top=true);
    
draw_hinge(alpha=connection_angle,
    a_l1=a_l1, a_l2=a_l2, a_l3=a_l3, a_gap=true,
    b_l1=b_l1, b_l2=b_l2, b_l3=b_l3, b_gap=true);  
    
    
