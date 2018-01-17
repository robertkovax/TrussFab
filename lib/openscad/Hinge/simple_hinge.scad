include <../Util/text_on.scad>
use <../Util/line_calculations.scad>
use <../Misc/Prism.scad>
use <../Misc/Hexagon.scad>

text_size = 7;
text_spacing = 0.9;
text_printin = 1; // how much mm goes into 

module add_text(text) {
    v = [0, 0, 0];
    text_on_cube(t=text, cube_size=0, locn_vec=v, size=text_size, face="top", center=false, spacing=text_spacing);
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


// cuts out parts at the top of both hinge parts
module cut_out_top_part(alpha, a_l1, a_l2, b_l1, b_l2, depth) {
    SKIM = 1;
    CUT_OFF_TOP = 100;
    
    a_l12 = a_l1 + a_l2;
    b_l12 = b_l1 + b_l2;
    longest = max(a_l12, b_l12);
    
    // line parallel to the x axis to cut off later
    t1 = longest;
    m1 = 0;

    the_angle = 90 + (90 - alpha / 2); // used later to get the slopes   
    m2 = tan(the_angle);
    t2 = t1 / (cos(alpha / 2)); // ankathete
    
    // We need to find the intersecion of l1 and l2 to determin how much we have to cut away.
    // This is important because if we have a connector, you might cut away parts of it otherwise.
    intersection_x = get_line_intersection_x(m1, t1, m2, t2);
                    
    translate([0, longest + CUT_OFF_TOP, 0])
    cube([intersection_x * 2 + SKIM, CUT_OFF_TOP * 2, depth + SKIM], center=true);
}

module add_bottom_for_higher_degrees(alpha, a_l1, a_l2, b_l1, b_l2, depth) {
    cube_height = max(a_l1, b_l1);
    
    a_l12 = a_l1 + a_l2;
    b_l12 = b_l1 + b_l2;
    longest = max(a_l12, b_l12);
    
    t1 = longest;
    m1 = 0;

    the_angle = 90 + (90 - alpha / 2); // used later to get the slope
    m2 = tan(the_angle);
    t2 = t1 / (cos(alpha / 2)); // ankathete
    
    // We need to find the intersecion of l1 and l2 to determin how much we have to cut away.
    // This is important because if we have a connector, you might cut away parts of it otherwise.
    intersection_x = get_line_intersection_x(m1, t1, m2, t2);
    
    // they are not needed (because there is already solid structure) but can mess up with the text. So cut some mms off.
    remove_some_mm = 20; 
    
    // the parameter to determine how much to add was determined experimentally
    translate([0, longest - cube_height / 4, 0]) 
    cube([intersection_x * 2 - remove_some_mm, cube_height, depth], center=true);
}


module hingepart(l1, l2, l3, gap, with_connector, label,
    depth, width, round_size, hole_size,
    gap_angle, gap_width, gap_height, gap_epsilon, gap_height_e,
    connector_end_round, connector_end_heigth,
    connector_end_extra_round, connector_end_extra_height, cut_out_hex_height, cut_out_hex_d,
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

                translate([width - round_size, l2 + l3, depth / 2])
                rotate([-90, 0, 0])
                cylinder(connector_end_extra_height, connector_end_extra_round,            connector_end_extra_round);
            }
        }
        
        union() {
            // TODO: remove the magic numbers with calculated values for the label/text placing           
            if (the_A_one) {
                text_offset_x = width - round_size;
                text_offset_y = gap_height * 3 + gap_epsilon * 1.5 + 2;
                text_offset_z = depth - text_printin;
                
                translate([text_offset_x, text_offset_y, text_offset_z])
                mirror([1, 0, 0])
                add_text(label);                
            } else {
                text_offset_x = width - round_size - 35;
                text_offset_y = gap_height * 2 + gap_epsilon * 1.5 + 1.5;
                text_offset_z = depth - text_printin;
                
                translate([text_offset_x, text_offset_y, text_offset_z])
                add_text(label);                
            }
            
            // cut out the two holes
            translate([width - round_size, 0, depth / 2])
            rotate([-90, 0, 0])
            cylinder(l2 + l3 + connector_end_extra_height, hole_size, hole_size);
            
            translate([width - round_size, l2 + l3 + connector_end_extra_height - cut_out_hex_height / 2 + 0.01, depth / 2])
            rotate([-90, 0, 0])       
            Hexagon(cut_out_hex_d, cut_out_hex_height);
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
    gap_angle_a, // the angle for the triangle in the gap
    gap_angle_b, // the angle for the triangle in the gap
    extra_width_for_hinging, // there needs to be an extra offset so the hinge part can swing fully
    gap_height, // gap of a hinge part
    gap_epsilon, // margin of the gap (due to printing issues)
    connector_end_round,
    connector_end_heigth,
    connector_end_extra_round,
    connector_end_extra_height,
    cut_out_hex_height_a,
    cut_out_hex_height_b,
    cut_out_hex_d_a,
    cut_out_hex_d_b,
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
                            gap_angle_b, gap_width, gap_height, gap_epsilon, gap_height_e,
                            connector_end_round, connector_end_heigth,
                            connector_end_extra_round, connector_end_extra_height,
                            cut_out_hex_height_b, cut_out_hex_d_b);
                        
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
                            gap_angle_a, gap_width, gap_height, gap_epsilon, gap_height_e,
                            connector_end_round, connector_end_heigth,
                            connector_end_extra_round, connector_end_extra_height,
                            cut_out_hex_height_a, cut_out_hex_d_a ,the_A_one=true);

                        // cut away parts that are on the on the other site
                        translate([0, 0, -500])
                        cube([1000, 1000, 1000]);        
                    }
                    
                    if (alpha > 90) {
                        add_bottom_for_higher_degrees(alpha, a_l1, a_l2, b_l1, b_l2, depth);
                    }
                }                
                cut_out_top_part(alpha, a_l1, a_l2, b_l1, b_l2, depth);
            }
            
            if (a_gap) {
                cut_out_a_cap(a_l1, gap_angle_a, gap_width, gap_height, gap_epsilon, gap_height_e);
            }
          
        }
        
        if (b_gap) {
            cut_out_b_cap(b_l1, gap_angle_a, gap_width, gap_height, gap_epsilon, gap_height_e);
        }
    }
}


// just for dev

draw_hinge(
alpha=120,
a_l1=65.0,
a_l2=41.199999999999996,
a_l3=50.0,
a_gap=true,
b_l1=65.0,
b_l2=41.199999999999996,
b_l3=50.0,
b_gap=true,
a_with_connector=true,
b_with_connector=true,
a_label="130.i76",
b_label="130.i20",
depth=24.0,
width=100.0,
round_size=12.0,
gap_angle_a=45.0,
gap_angle_b=45.0,
hole_size_a=3.1,
hole_size_b=3.1,
extra_width_for_hinging=0.9999999999999999,
gap_height=10.0,
gap_epsilon=0.8000000000000002,
connector_end_round=15.0,
connector_end_heigth=3.7,
connector_end_extra_round=9.95,
connector_end_extra_height=1.9999999999999998,
cut_out_hex_height_a=0,
cut_out_hex_d_a=0,
cut_out_hex_height_b=0,
cut_out_hex_d_b=0
);
