include <../Util/text_on.scad>
use <../Util/line_calculations.scad>
use <../Models/Prism.scad>
use <../Models/Hexagon.scad>
use <util.scad>

text_size = 7;
text_spacing = 0.9;
text_printin = 1; // how much mm goes into

// some large constant to cut away space for gaps
large_number_to_cut_off = 100;
// some small constant to remove leftovers
rounding_fix_epsilon = 0.001;

// all credits Robert Kovacs
function calc_extra_width_for_hinging(gap_angle, radius) = radius / cos(90 - gap_angle) - radius;

function label_offset(l2, i, gap_epsilon) = l2 * (i/4) + ((l2/4) - text_size) / 2 + gap_epsilon / 4;

module add_text(text) {
  v = [0, 0, 0];
  text_on_cube(t=text, cube_size=0, locn_vec=v, size=text_size, face="top", center=false, spacing=text_spacing);
}

module cut_out_b_gap(l1, l2, gap_angle, gap_width, gap_epsilon) {
  mirror([1, 0, 0])
  union() {
    for (ii = [0:1]) {
      fix_rounding_issue = ii == 1 ? rounding_fix_epsilon : 0;
      gap_height = hinge_b_y_gap_height(l2, gap_epsilon, ii == 0);
      gap_offset = hinge_b_y_gap_offset(l1, l2, gap_epsilon, ii == 0);
      for (i = [0:1]) {
        // 270: 180 deg because it's the other site and then (90 - deg)
        gap_angle_i = i == 0 ? - gap_angle : gap_angle - 270;
        rotate([0, gap_angle_i, 0])
        translate([0, gap_offset, 0])
        cube([gap_width, gap_height + fix_rounding_issue, large_number_to_cut_off]);
      }
      translate([-gap_width, gap_offset, large_number_to_cut_off / -2])
      cube([gap_width, gap_height + fix_rounding_issue, large_number_to_cut_off]);
    }
  }
}

 module cut_out_a_gap(l1, l2, gap_angle, gap_width, gap_epsilon) {
   union() {
     for (ii = [0:1]) {
       fix_rounding_issue = ii == 0 ? large_number_to_cut_off : 0;
       gap_height = hinge_a_y_gap_height(l2, gap_epsilon, ii == 0);
       gap_offset = hinge_a_y_gap_offset(l1, l2, gap_epsilon, ii == 0);
        for (i = [0:1]) {
         // 270: 180 deg because it's the other site and then (90 - deg)
         gap_angle_i = i == 0 ? -gap_angle : gap_angle - 270;
         rotate([0, gap_angle_i, 0])
         translate([0, gap_offset - fix_rounding_issue, 0])
         cube([gap_width, gap_height + fix_rounding_issue, large_number_to_cut_off]);
       }
       translate([-gap_width, gap_offset - fix_rounding_issue, large_number_to_cut_off / -2])
       cube([gap_width, gap_height + fix_rounding_issue, large_number_to_cut_off]);
     }
   }
 }

// cuts out parts at the top of both hinge parts
module cut_out_top_part(alpha, l1, l2, depth) {
  SKIM = 1;
  CUT_OFF_TOP = 100;

  l12 = l1 + l2;

  // line parallel to the x axis to cut off later
  t1 = l12;
  m1 = 0;

  real_angle_on_the_line = 90 + (90 - alpha / 2); // used later to get the slopes
  m2 = tan(real_angle_on_the_line);
  t2 = t1 / (cos(alpha / 2)); // ankathete

  // We need to find the intersecion of l1 and l2 to determin how much we have to cut away.
  // This is important because if we have a connector, you might cut away parts of it otherwise.
  intersection_x = get_line_intersection_x(m1, t1, m2, t2);

  translate([0, l12 + CUT_OFF_TOP, 0])
  cube([intersection_x * 2 + SKIM, CUT_OFF_TOP * 2, depth + SKIM], center=true);
}

// add support material when the degress for the alpha are very high
module add_bottom_for_higher_degrees(alpha, l1, l2, depth) {
  cube_height = l1;
  
  l12 = l1 + l2;

  t1 = l12;
  m1 = 0;

  real_angle_on_the_line = 90 + (90 - alpha / 2); // used later to get the slope
  m2 = tan(real_angle_on_the_line);
  t2 = t1 / (cos(alpha / 2)); // ankathete

  // We need to find the intersecion of l1 and l2 to determin how much we have to cut away.
  // This is important because if we have a connector, you might cut away parts of it otherwise.
  intersection_x = get_line_intersection_x(m1, t1, m2, t2);

  // they are not needed (because there is already solid structure) but can mess up with the text. So cut some mms off.
  remove_some_mm = 20;

  // the parameter to determine how much to add was determined experimentally
  translate([0, l12 - cube_height / 4, 0])
  cube([intersection_x * 2 - remove_some_mm, cube_height, depth], center=true);
}


module construct_hinge_part(l1, l2, l3, gap, with_connector, label, id_label,
    depth, width, round_size, hole_size, gap_epsilon, connector_end_round, connector_end_heigth,
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
                cylinder(connector_end_extra_height, connector_end_extra_round, connector_end_extra_round);
            }
        }

        union() {
            // TODO: remove the magic numbers with calculated values for the label/text placing
            if (the_A_one) {
                text_offset_x = width - round_size + 5;
                text_offset_y = label_offset(l2, 3, gap_epsilon);
                text_offset_z = depth - text_printin;

                translate([text_offset_x, text_offset_y, text_offset_z])
                mirror([1, 0, 0])
                add_text(label);

                text_offset_x_2 = width - round_size + 5;
                text_offset_y_2 = label_offset(l2, 1, gap_epsilon);
                text_offset_z_2 = depth - text_printin;

                translate([text_offset_x_2, text_offset_y_2, text_offset_z_2])
                mirror([1, 0, 0])
                add_text(id_label);

            } else {
                l_b = len(label);
                magic_x_number = l_b == 2 ? 10 : l_b == 3 ? 15 : 17;
                text_offset_x = width - round_size - magic_x_number;
                text_offset_y = label_offset(l2, 2, gap_epsilon);
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
  l1, l2, a_l3, b_l3,
  a_gap, a_with_connector, a_label,
  b_gap, b_with_connector, b_label,
  id_label,
  depth, // depth of a hinge part
  width, // not really important because parts that are too much gets cut away anyway
  round_size, // the round part of a hinge part
  hole_size_a, // where the screw goes through
  hole_size_b, // where the screw goes through
  gap_angle_a, // the angle for the triangle in the gap
  gap_angle_b, // the angle for the triangle in the gap
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
   // there needs to be an extra offset so the hinge part can swing fully
  extra_width_for_hinging_a = calc_extra_width_for_hinging(gap_angle_a, round_size);
  extra_width_for_hinging_b = calc_extra_width_for_hinging(gap_angle_b, round_size);

  gap_width_a = 2 * round_size + depth / 2 + extra_width_for_hinging_a;
  gap_width_b = 2 * round_size + depth / 2 + extra_width_for_hinging_b;

  a_angle = alpha / -2;
  a_translate_x = l1 * cos(90 + a_angle);
  a_translate_y = l1 * sin(90 + a_angle);

  b_angle = alpha / 2;
  b_translate_x = l1 * cos(90 + b_angle);
  b_translate_y = l1 * sin(90 + b_angle);

  // the last cut out for the gap of the left side to fully hinge
  // the translations are only to cut off some other parts for the gaps more easily
  difference() {
    translate([extra_width_for_hinging_b + round_size, 0, 0])
    rotate([0, 0, alpha / 2])
    rotate([0, 0, alpha / +2])
      translate([round_size + extra_width_for_hinging_a, 0, 0])
      difference() {
        translate([- round_size - extra_width_for_hinging_a, 0, 0])
        rotate([0, 0, alpha / -2])
        difference() {
          union() {
            difference() {
              translate([a_translate_x, a_translate_y, 0])
              rotate([0, 0, a_angle])
              translate([-(width - round_size), 0, 0])
              translate([0, 0, depth / -2]) // center on the z axis
              construct_hinge_part(l1, l2, b_l3, b_gap, b_with_connector, b_label, id_label,
                  depth, width, round_size, hole_size_b, gap_epsilon,
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
              construct_hinge_part(l1, l2, a_l3, a_gap, a_with_connector, a_label, id_label,
                depth, width, round_size, hole_size_a, gap_epsilon,
                connector_end_round, connector_end_heigth,
                connector_end_extra_round, connector_end_extra_height,
                cut_out_hex_height_a, cut_out_hex_d_a ,the_A_one=true);

              // cut away parts that are on the on the other site
              translate([0, 0, -500])
              cube([1000, 1000, 1000]);
            }

            if (alpha > 90) {
              add_bottom_for_higher_degrees(alpha, l1, l2, depth);
            }
          }
          cut_out_top_part(alpha, l1, l2, depth);
        }

    if (a_gap) {
      cut_out_a_gap(l1, l2, gap_angle_a, gap_width_a, gap_epsilon);
    }
  }
    if (b_gap) {
      cut_out_b_gap(l1, l2, gap_angle_b, gap_width_b, gap_epsilon);
    }
  }
}


// for dev only

draw_hinge(
alpha=40,
l1=40.0,
l2=40,
a_l3=10.0,
a_gap=true,
b_l3=10.0,
b_gap=true,
a_with_connector=false,
b_with_connector=false,
a_label="I823",
b_label="I753",
id_label = "127N",
depth=24.0,
width=100.0,
round_size=12.0,
gap_angle_a=70.0,
gap_angle_b=70.0,
hole_size_a=3.2000000000000006,
hole_size_b=3.2000000000000006,
gap_epsilon=0.8,
connector_end_round=15.0,
connector_end_heigth=3.7,
connector_end_extra_round=9.95,
connector_end_extra_height=3.9999999999999996,
cut_out_hex_height_a=5.0,
cut_out_hex_height_b=5.0,
cut_out_hex_d_a=10.6,
cut_out_hex_d_b=10.6,
gap_angle=70.0);
