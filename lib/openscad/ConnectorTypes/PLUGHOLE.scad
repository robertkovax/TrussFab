include <../Models/BottlePrecomputed.scad>
include <../Util/maths.scad>

part="PLUGHOLE";

function getQuadMatForAngle(angle) = quat_to_mat4(quat([0,0,1],angle));

$fn=200;

tubeODPLUGHOLE = 2*(12);
discODPLUGHOLE = 2*(15);
discHeightPLUGHOLE = 4;
holeRadiusPLUGHOLE = 8.3;
holeRadiusPLUGHOLE = 9.8;

negativeHeightPLUGHOLE = discHeightPLUGHOLE;

// Connector data in an array to pass-through to other scripts as a single parameter
connectorDataArrayPLUGHOLE = [tubeODPLUGHOLE, negativeHeightPLUGHOLE];

module drawPLUGHOLE() {
    difference() {
    translate([0,0,-negativeHeightPLUGHOLE+0.5]) //0.2 length correction + 0.3 indent (?)
    cylinder(r=discODPLUGHOLE/2, h=discHeightPLUGHOLE);
    translate([0,0,-negativeHeightPLUG+4.2])
    cylinder(r=discODPLUG/2-2, h=1);
    }
    //bottle holder
        difference() {
        translate([0,0,-negativeHeightPLUGHOLE+0.5])
        cylinder(r=holeRadiusPLUGHOLE, h=discHeightPLUGHOLE+2.5);
        cylinder(r=holeRadiusPLUGHOLE-1.5, h=discHeightPLUGHOLE+2.5);
        }
}

module holePLUGHOLE(holeLength, distanceToMiddle) { // Just a hole to save material
  translate([0,0,-50+distanceToMiddle])
    //cylinder(r=tubeODPLUGHOLE/2, h=50);
  translate([0,0,0.1-7])
  rotate(180,[1,0,0])
  //cylinder(r=holeRadiusPLUGHOLE,h=55+connectorDataDistance+discHeightPLUGHOLE);
    cylinder(r=holeRadiusPLUGHOLE+1.7,h=holeLength-7);
    translate([0,0,-50+distanceToMiddle])
    //cylinder(r=tubeODPLUGHOLE/2, h=50);
    translate([0,0,0.1])
    rotate(180,[1,0,0])
    cylinder(r=holeRadiusPLUGHOLE,h=holeLength-7);
}

//if (part=="PLUGHOLE") drawPLUGHOLE();
