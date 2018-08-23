include <../Models/BottlePrecomputed.scad>
include <../Util/maths.scad>

part="PLUG";

function getQuadMatForAngle(angle) = quat_to_mat4(quat([0,0,1],angle));

$fn=200;

tubeODPLUG = 2*(12);
discODPLUG = 2*(15);
discHeightPLUG = 4;
holeRadiusPLUG = 9.8;

negativeHeightPLUG = discHeightPLUG;

// Connector data in an array to pass-through to other scripts as a single parameter
connectorDataArrayPLUG = [tubeODPLUG, negativeHeightPLUG];

module drawPLUG() {
        difference() {
        translate([0,0,-negativeHeightPLUGHOLE+0.5]) //0.2 correction + 0.3 indent (?)
        cylinder(r=discODPLUGHOLE/2, h=discHeightPLUGHOLE);
        translate([0,0,-negativeHeightPLUG+4.2])
        cylinder(r=discODPLUG/2-2, h=1);
        }
    //bottle holder
    translate([0,0,-negativeHeightPLUGHOLE+0.5])
    cylinder(r=holeRadiusPLUG, h=discHeightPLUGHOLE+6.5);
}

// There are differences but I don't know which version is better.
// module drawPLUG() {
//     difference()
//      {
//         translate([0,0,-negativeHeightPLUG+0.5])
//         cylinder(r=discODPLUG/2, h=discHeightPLUG);
//         translate([0,0,-negativeHeightPLUG+4.2])
//         cylinder(r=discODPLUG/2-2, h=discHeightPLUG-3);
//     }
// }

module holePLUG(holeLength, distanceToMiddle) { // Just a hole to save material
  translate([0,0,-50+distanceToMiddle])
  translate([0,0,0.1])
  rotate(180,[1,0,0])
  cylinder(r=holeRadiusPLUG,h=holeLength);
  echo(length=holeLength);
}


//if (part=="PLUG") drawPLUG();
