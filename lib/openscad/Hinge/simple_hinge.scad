include <settings.scad>
use <../Misc/Prism.scad>


module cut_out_a_cap(a_l1) {
    mirror([1, 0, 0])
    union() {
        for (ii = [0:1]) {
            y_height_gap_cut = a_l1 + gap_height + ii * (2 * gap_height + gap_epsilon);
            echo(y_height_gap_cut);
            for (i = [0:1]) {
                rotate([0, -45 - i * 180, 0]) 
                translate([0, y_height_gap_cut, 0])
                cube([gap_witdh, gap_height_e, 100]);
            }
            translate([-gap_witdh, y_height_gap_cut, -50])
            cube([gap_witdh, gap_height_e, 100]);
        }
    }   
}


module cut_out_b_cap(a_l1) {
        union() {
        for (ii = [0:1]) {
            extra_offset =  ii == 0 ? 100 : 0;            
            y_height_gap_cut = a_l1 + ii * (gap_height + gap_height_e);
            for (i = [0:1]) {
                rotate([0, -45 - i * 180, 0]) 
                translate([0, y_height_gap_cut - extra_offset, 0])
                cube([gap_witdh, gap_height_e + extra_offset, 100]);
            }
            translate([-gap_witdh, y_height_gap_cut - extra_offset, -50])
            cube([gap_witdh, gap_height_e + extra_offset, 100]);
        }
    }   
}


module hingepart(l1, l2, l3, gap, with_cap, with_connector, the_lower_one=false) {
    // the base model
    difference() {
        union() {
            cube([width - round_size, l2, depth]);
            
            translate([width - round_size, 0, depth / 2])
            rotate([-90, 0, 0])
            cylinder(l2, round_size, round_size);
            
            if (with_connector) {
                translate([width - round_size, l2, depth / 2])
                rotate([-90, 0, 0])
                cylinder(l3, round_size, round_size);
                
                translate([width - round_size, l2 + l3 - cap_end_heigth, depth / 2])
                rotate([-90, 0, 0])
                cylinder(cap_end_heigth, cap_end_round, cap_end_round);
            }
        }
        
        if (gap || with_connector) {
            // cut out the two holes
            translate([width - round_size, 0, depth / 2])
            rotate([-90, 0, 0])
            cylinder(l2 + l3, hole_size, hole_size);
        }
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
         translate([extra_width_for_hinging + round_size, 0, 0])
         rotate([0, 0, alpha / 2])    
         rotate([0, 0, alpha / +2]) 
        translate([round_size + extra_width_for_hinging, 0, 0])
        difference() {
            translate([- round_size - extra_width_for_hinging, 0, 0])
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
                }
            }
            
            if (b_gap) {
                cut_out_b_cap(a_l1);
            }
          
        }
        
        if (a_gap) {
          cut_out_a_cap(a_l1);
        }
    }
}


// just for developing are some calls here

connection_angle = 40;

l1 = 50;
l2 = gap_height * 4 + gap_epsilon * 1.5; // beaause there is no need to have it for the free haning part
l3 = 40;

draw_hinge(alpha=connection_angle,
    a_l1=l1, a_l2=l2, a_l3=l3, a_gap=true,
    b_l1=l1, b_l2=l2, b_l3=l3, b_gap=true);

//draw_hinge(alpha=connection_angle,
//    a_l1=l1, a_l2=l2, a_l3=l3, a_gap=true,
//    b_l1=l1, b_l2=l2, b_l3=l3, b_with_connector=true);


//draw_hinge(alpha=connection_angle,
//    a_l1=l1, a_l2=l2, a_l3=l3, b_gap=true,
//    b_l1=l1, b_l2=l2, b_l3=l3, a_with_connector=true);