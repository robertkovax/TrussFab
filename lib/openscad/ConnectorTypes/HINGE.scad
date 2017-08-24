include <../Models/BottlePrecomputed.scad>
include <../Util/maths.scad>

part="HINGE"; 

//$fn=300;


height=40;
radius=10;
holeradius=4.25;

holderODHinge = 20;

washerODHinge = 0; // Outer diameter of the bottom plate/washer
washerHeightHinge = 0; // bottom plate/washer height
connectorDataArrayHinge = [washerODHinge, washerHeightHinge]; 

washerODHingeF = 0; // Outer diameter of the bottom plate/washer
washerHeightHingeF = 0; // bottom plate/washer height
connectorDataArrayHingeF = [washerODHingeF, washerHeightHingeF]; 

hingeDistance = 16; //distance to baseTube

module drawHingeM(angle=0,elongation=0) {
    rotate([0,90,180-angle]){
        drawHingeBase(angle, elongation);
    }
}
module drawHingeF(angle=0, elongation=0) {
    rotate([0,90,angle]){
        drawHingeBase(angle, elongation);
    }
}
module drawHingeBase(angle, elongation){
translate([-hingeDistance,0,height/6])
    difference(){
        union(){
            cylinder(h=height,r=radius,center=true);
            translate([0,-radius,-height/2])
            cube (size=[elongation+hingeDistance+connectorDataDistance,radius*2,height], center=false);
        }
        cylinder(h=height,r=holeradius,center=true);
        translate([radius,-radius,+height/5.5])
        rotate([0,180,0])
        cube(size=[30,radius*2,height/2.75],center=false);
    }
}
//drawHingeM();