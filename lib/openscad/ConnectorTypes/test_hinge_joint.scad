use <../Misc/Prism.scad>

// dimension of one hinge part
depth = 24;
width = 60;

// diameters
round_size = 12;    
hole_size = 7/2;

// the part where ohter connectors go
gap_witdh = round_size * 2 + 10;

gap_epsilon = 0.8;
gap_height = 10;
gap_height_e = gap_height + gap_epsilon;

safety_margin = 10;

cap_end_round = 30 / 2;
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
            cut_gap_height = gap_height;
            translate([width - gap_witdh, cut_gap_height, 0])
            cube([width, gap_height_e, depth]);
            
            // cut out the two holes
            translate([width - round_size, 0, depth / 2])
            rotate([-90, 0, 0])
            
            cylinder(l2 + l3 + safety_margin, hole_size, hole_size);
        }
    }
    
    if (gap) {
        prism_height = 1 * gap_height_e + 3 * gap_height;
        prism_translate_x = width - gap_witdh;
        prism_translate_y = the_lower_one ? prism_height : prism_height - gap_height;
        
         x = sqrt((depth / 2) * (depth / 2) + (depth / 2) * (depth / 2)); // pythagoras
        translate([prism_translate_x, prism_translate_y, 0])
        rotate([45, 0, -90])
        prism(prism_height, x, x);
        
        translate_help_cube_y = !the_lower_one ? -gap_height_e : 0;
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
    a_l1, a_l2, a_l3, a_gap, a_solid_top, a_with_cap,
    b_l1, b_l2, b_l3, b_gap, b_solid_top, b_with_cap) {
    
    a_angle = alpha / -2;
    a_translate_x = a_l1 * cos(90 + a_angle);
    a_translate_y = a_l1 * sin(90 + a_angle);

    b_angle = alpha / 2;
    b_translate_x = b_l1 * cos(90 + b_angle);
    b_translate_y = b_l1 * sin(90 + b_angle);
        
    difference() {   
        union() {
            difference() {
                translate([a_translate_x, a_translate_y, 0])
                rotate([0, 0, a_angle])
                translate([-(width - round_size), 0, 0])
                translate([0, 0, depth / -2]) // center on the z axis
                hingepart(a_l1, a_l2, a_l3, a_gap, a_with_cap, a_solid_top);
                
                // cut away parts that are on the on the other site
                translate([-100, 0, -50])
                cube([100, 100, 100]);
            }
            
            difference() {
                translate([b_translate_x, b_translate_y, 0])
                rotate([0, 0, b_angle])
                mirror([1, 0, 0])
                translate([-(width - round_size), 0, 0])
                translate([0, 0, depth / -2])
                hingepart(b_l1, b_l2, b_l3, b_gap, b_with_cap, b_solid_top, the_lower_one=true);

                // cut away parts that are on the on the other site
                translate([0, 0, -50])
                cube([100, 100, 100]);        
            }
        }
        
        union() {
            // cuts out parts at the top
            a_l12 = a_l1 + a_l2;
            b_l12 = b_l1 + b_l2;
            longest = max(a_l12, b_l12);
            translate([0, longest + 50, 0])
            cube([100, 100, 100], center=true);    
            
 
            /*
                The following code cuts out the last ramp of the hinge part that is clostest to
                the origin. It's kind of difficult to achieve because before, every hinge part was
                responsible for his quadrant. Now, the one that is furter away from the origin,
                has to cut out parts of the other part (in the other quadrant). So we bascially
                have to replicate all the combined roations and translations. It helps, that we
                know the exacat distance from the origin. But it still unclear (to me) what the
                excact modifications were just tried out some values.
            */
            prune_angle = 90 - (alpha / 2);
            prune_length = a_l1 * 2 - 0.001;
            prune_width = gap_height * 1.4; // magic constant through experiments
            prune_depth = 100;
            for (i = [0:1]) {
                rotate([45 + 90 * i, 0, prune_angle])
                cube([prune_length, prune_width, prune_depth], center=true);
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
connection_angle = 80;

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
        