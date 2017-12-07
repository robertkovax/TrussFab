module draw_hinge_cap(
    cap_height,
    round_size=12,
    hole_size=
    connector_end_round=30/2,
    connector_end_heigth=4,
    connector_end_extra_round=19.5/2,
    connector_end_extra_height=2) {
    difference() {
        union() {
            rotate([-90, 0, 0])
            cylinder(cap_height, round_size, round_size);

            translate([0, 0 + cap_height - connector_end_heigth, 0])
            rotate([-90, 0, 0])
            cylinder(connector_end_heigth, cap_end_round, cap_end_round);
         }
         
        // cut out the two holes
        rotate([-90, 0, 0])
        cylinder(cap_height, hole_size, hole_size);
    }
}

draw_hinge_cap(30);