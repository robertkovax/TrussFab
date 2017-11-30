include <settings.scad>

module draw_hinge_cap(cap_height) {
    difference() {
        union() {
            rotate([-90, 0, 0])
            cylinder(cap_height, round_size, round_size);

            translate([0, 0 + cap_height - cap_end_heigth, 0])
            rotate([-90, 0, 0])
            cylinder(cap_end_heigth, cap_end_round, cap_end_round);
         }
         
        // cut out the two holes
        rotate([-90, 0, 0])
        cylinder(cap_height, hole_size, hole_size);
    }
}

draw_hinge_cap(30);