include <../Models/BottlePrecomputed.scad>
include <../Util/maths.scad>

part="PLUGPLANE";

function getQuadMatForAngle(angle) = quat_to_mat4(quat([0,0,1],angle));

$fn=200;

tubeODPLUGPLANE = 2*(12);
discODPLUGPLANE = 2*(15);
discHeightPLUGPLANE = 4;
holeRadiusPLUGPLANE = 0;

negativeHeightPLUGPLANE = discHeightPLUGPLANE;

// Connector data in an array to pass-through to other scripts as a single parameter
connectorDataArrayPLUGPLANE = [tubeODPLUG, negativeHeightPLUGPLANE];

module drawPLUGPLANE() {
  difference() {
    translate([0,0,-negativeHeightPLUGPLANE+0.5]) //0.2 correction + 0.3 indent (?)
    cylinder(r=discODPLUGPLANE/2, h=discHeightPLUGPLANE);
    translate([0,0,-negativeHeightPLUGPLANE+4.2])
    cylinder(r=discODPLUGPLANE/2-2, h=1);
  }
  //bottle holder
  translate([0,0,-negativeHeightPLUGPLANE+0.5])
  cylinder(r=holeRadiusPLUGPLANE, h=discHeightPLUGPLANE+2.5);
}

module holePLUGPLANE(holeLength, distanceToMiddle) { // Just a hole to save material

}

//if (part=="PLUGPLANE") drawPLUGPLANE();
