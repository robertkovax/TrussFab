include <../Util/text_on.scad>
use <../Misc/Prism.scad>

module add_text(text) {
    v = [0, 0, 0];
    text_on_cube(t=text, cube_size=0, locn_vec=v, size=5, face="top", center=false, spacing=0.8);
}

module cut_out_b_cap(l1, gap_angle, gap_width, gap_height, gap_epsilon, gap_height_e) {
    mirror([1, 0, 0])
    union() {
        for (ii = [0:1]) {
            y_height_gap_cut = l1 + gap_height + ii * (2 * gap_height + gap_epsilon);
            for (i = [0:1]) {
                // 270: 180 deg because it's the other site and then (90 - deg)
                gap_angle_i = i == 0 ? - gap_angle : gap_angle - 270; 
                rotate([0, gap_angle_i, 0]) 
                translate([0, y_height_gap_cut, 0])
                cube([gap_width, gap_height_e, 100]);
            }
            translate([-gap_width, y_height_gap_cut, -50])
            cube([gap_width, gap_height_e, 100]);
        }
    }   
}


module cut_out_a_cap(l1, gap_angle, gap_width, gap_height, gap_epsilon, gap_height_e) {
        union() {
        for (ii = [0:1]) {
            extra_offset =  ii == 0 ? 100 : 0;            
            y_height_gap_cut = l1 + ii * (gap_height + gap_height_e);
            for (i = [0:1]) {
                gap_angle_i = i == 0 ? -gap_angle : gap_angle - 270;
                rotate([0, gap_angle_i, 0]) 
                translate([0, y_height_gap_cut - extra_offset, 0])
                cube([gap_width, gap_height_e + extra_offset, 100]);
            }
            translate([-gap_width, y_height_gap_cut - extra_offset, -50])
            cube([gap_width, gap_height_e + extra_offset, 100]);
        }
    }   
}


module hingepart(l1, l2, l3, gap, with_connector, label,
    depth, width, round_size, hole_size,
    gap_angle, gap_width, gap_height, gap_epsilon, gap_height_e,
    connector_end_round, connector_end_heigth,
    connector_end_extra_round, connector_end_extra_height,
    the_A_one=false) {
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
                
                translate([width - round_size, l2 + l3 - connector_end_heigth, depth / 2])
                rotate([-90, 0, 0])
                cylinder(connector_end_heigth, connector_end_round, connector_end_round);
            }
        }
        
        union() {
            // TODO: remove the magic numbers with calculated values            
            text_offset_x = width - round_size - 21;
            
            text_offset_y =
                the_A_one ?
                gap_height * 3 + gap_epsilon * 1.5 + 2 :
                gap_height * 2 + gap_epsilon * 1.5 + 2;
            
            text_offset_z = depth - 1;
            
            if (the_A_one) {
                translate([text_offset_x + 22, text_offset_y + 1, text_offset_z])
                mirror([1, 0, 0])
                add_text(label);                
            } else {
                translate([text_offset_x, text_offset_y, text_offset_z])
                add_text(label);                
            }
            
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
    alpha, // the angle between the hinge parts
    a_l1, a_l2, a_l3,
    a_gap, a_with_connector, a_label,
    b_l1, b_l2, b_l3,
    b_gap, b_with_connector, b_label,
    depth, // depth of a hinge part
    width, // not really important because parts that are too much gets cut away anyway
    round_size, // the round part of a hinge part
    hole_size_a, // where the screw goes through
    hole_size_b, // where the screw goes through
    gap_angle, // the angle for the triangle in the gap
    extra_width_for_hinging, // there needs to be an extra offset so the hinge part can swing fully
    gap_height, // gap of a hinge part
    gap_epsilon, // margin of the gap (due to printing issues)
    connector_end_round,
    connector_end_heigth,
    connector_end_extra_round,
    connector_end_extra_height
    ) {
    
    gap_width = 2 * round_size + depth / 2 + extra_width_for_hinging;
    gap_height_e = gap_height + gap_epsilon;
    
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
                        hingepart(b_l1, b_l2, b_l3, b_gap, b_with_connector, b_label,
                            depth, width, round_size, hole_size_b,
                            gap_angle, gap_width, gap_height, gap_epsilon, gap_height_e,
                            connector_end_round, connector_end_heigth,
                            connector_end_extra_round, connector_end_extra_height);
                        
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
                        hingepart(a_l1, a_l2, a_l3, a_gap, a_with_connector, a_label,
                            depth, width, round_size, hole_size_a,
                            gap_angle, gap_width, gap_height, gap_epsilon, gap_height_e,
                            connector_end_round, connector_end_heigth,
                            connector_end_extra_round, connector_end_extra_height, the_A_one=true);

                        // cut away parts that are on the on the other site
                        translate([0, 0, -500])
                        cube([1000, 1000, 1000]);        
                    }
                }
                
                // cuts out parts at the top
                // the height of the cube is responsible for the cutting out of the the top part
                // it can cause some problems if it cuts too much or to little
                // Edit: Hotfix, we choose a small cube height for smaller angles
                // (where there is less to cut)
                cut_out_cube = alpha < 50 ? (alpha < 40 ? 10 : 20) : 50;
                a_l12 = a_l1 + a_l2;
                b_l12 = b_l1 + b_l2;
                longest = max(a_l12, b_l12);
                translate([0, longest + 50 + 3, 0]) // you can tune the last summand
                cube([cut_out_cube, 100, 100], center=true);

            }
            
            if (a_gap) {
                cut_out_a_cap(a_l1, gap_angle, gap_width, gap_height, gap_epsilon, gap_height_e);
            }
          
        }
        
        if (b_gap) {
            cut_out_b_cap(b_l1, gap_angle, gap_width, gap_height, gap_epsilon, gap_height_e);
        }
    }
}


// just for dev

connection_angle = 40;

l1 = 50;
l2 = 10 * 4 + 0.8 * 1.5; // beaause there is no need to have it for the free haning part
l3 = 40;
//
//draw_hinge(alpha=connection_angle,
//    a_l1=l1, a_l2=l2, a_l3=l3, a_gap=true, a_label="123.456", b_label="133.789",
//    b_l1=l1, b_l2=l2, b_l3=l3, b_gap=true);

draw_hinge(alpha=59.93035835020898, a_l1=30.069641649791023, a_l2=41.199999999999996, a_l3=14.771333346882312, a_gap=false, b_l1=30.069641649791023, b_l2=41.199999999999996, b_l3=15.258982187190027, b_gap=true, a_with_connector=true, b_with_connector=false, a_label="76.149", b_label="76.75", depth=24.0, width=100.0, round_size=12.0, hole_size=3.1, gap_angle=45.0, extra_width_for_hinging=6.0, gap_height=10.0, gap_epsilon=0.8000000000000002, connector_end_round=15.0, connector_end_heigth=3.7, connector_end_extra_round=9.95, connector_end_extra_height=1.9999999999999998, cut_out_hex_height=5.0, cut_out_hex_d=11.5);
