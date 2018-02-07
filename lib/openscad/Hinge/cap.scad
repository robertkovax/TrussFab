include <../Util/text_on.scad>
use <../Misc/Hexagon.scad>

module draw_hinge_cap(
  cap_height,
  label,
  round_size,
  hole_size,
  connector_end_round,
  connector_end_heigth,
  connector_end_extra_round,
  connector_end_extra_height,
  cut_out_hex_height,
  cut_out_hex_d) {
  difference() {
    union() {
      rotate([-90, 0, 0])
      cylinder(cap_height, round_size, round_size);

      translate([0, 0 + cap_height - connector_end_heigth, 0])
      rotate([-90, 0, 0])
      cylinder(connector_end_heigth, connector_end_round, connector_end_round);

      translate([0, cap_height, 0])
      rotate([-90, 0, 0])
      cylinder(connector_end_extra_height, connector_end_extra_round, connector_end_extra_round);
     }

    union() {
      // cut out the two holes
      rotate([-90, 0, 0])
      cylinder(cap_height + connector_end_extra_height, hole_size, hole_size);

      translate([0, cap_height + connector_end_extra_height - cut_out_hex_height / 2 + 0.01, 0])
      rotate([-90, 0, 0])
      Hexagon(cut_out_hex_d, cut_out_hex_height);

      translate([0, -4, 0]) // works for cap_height=10
      rotate([-90, 0, 0])
      text_on_cylinder(label, r1=round_size - 1, r2=round_size - 1, h=cap_height, size=5);
    }
  }
}

// for dev only
draw_hinge_cap(10, "133.789", 12, 3.1, 30/2, 3.7, 19.9/2, 5, 5, 11.5);
