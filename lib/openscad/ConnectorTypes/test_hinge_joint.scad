// dimension of one hinge part
height = 30;
depth = 24;
width = 40;

// diameters
round_size = 12;    
hole_size = 7/2;

// the part where ohter connectors go
gap_height = 15;
gap_remaining_width = 10;

connection_angle = 90;

top_bottom_part_height = (height - gap_height) / 2;

// model should be 40mm away from origin
distance_origin = 90;

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


echo(optimal_distance_origin(30));

module hingepart(gap = false) {
    difference() {
        // the base model
        union() {
            cube([width - round_size, height, depth]);
            
            translate([width - round_size, 0, depth / 2])
            rotate([-90, 0, 0])
            cylinder(height, round_size, round_size);
        }
        
        if (gap) {
            translate([gap_remaining_width, top_bottom_part_height, 0])
            cube([height * 2, gap_height, depth]);
            // why * 2? Just make sure you cut out enough. Does not hurt to cut out more.
        }
        
        // cut out the two holes
        translate([width - round_size, 0, depth / 2])
        rotate([-90, 0, 0])
        cylinder(height, hole_size, hole_size);
    }
}
angle1 = - connection_angle / 2;
len1 = optimal_distance_origin(connection_angle) + top_bottom_part_height;
x1 = len1 * cos(90 + angle1);
y1 = len1 * sin(90 + angle1);

translate([x1, y1, 0])
rotate([0, 0, angle1])
translate([-(width - round_size), 0, 0])
hingepart();

angle2 = connection_angle / 2;
len2 = optimal_distance_origin(connection_angle);
x2 = len2 * cos(90 + angle2);
y2 = len2 * sin(90 + angle2);

translate([x2, y2, 0])
rotate([0, 0, angle2])
mirror([1, 0, 0])
translate([-(width - round_size), 0, 0])
hingepart(gap = true);

//translate([-10, -10, 0])
//cube([6, height, depth]);
