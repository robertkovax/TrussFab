include <../Models/BottlePrecomputed.scad>
include <../Util/maths.scad>

part="PLUG"; 

function getQuadMatForAngle(angle) = quat_to_mat4(quat([0,0,1],angle));

$fn=200;

tubeODPLUG = 2*(12);
discODPLUG = 2*(15);
discHeightPLUG = 4;
holeRadiusPLUG = 9;

negativeHeightPLUG = discHeightPLUG;

// Connector data in an array to pass-through to other scripts as a single parameter
connectorDataArrayPLUG = [tubeODPLUG, negativeHeightPLUG]; 

module drawPLUG() {
    difference()
     {
        translate([0,0,-negativeHeightPLUG+0.5])
        cylinder(r=discODPLUG/2, h=discHeightPLUG);
        translate([0,0,-negativeHeightPLUG+4.2])
        cylinder(r=discODPLUG/2-2, h=discHeightPLUG-3);
    }
}

module holePLUG(holeLength, distanceToMiddle) { // Just a hole to save material
	translate([0,0,-50+distanceToMiddle])
    //cylinder(r=tubeODPLUG/2, h=50);
	translate([0,0,0.1])
	rotate(180,[1,0,0])
	//cylinder(r=holeRadiusPLUG,h=55+connectorDataDistance+discHeightPLUG);
    cylinder(r=holeRadiusPLUG,h=holeLength);
    echo(length=holeLength);
}

//if (part=="PLUG") drawPLUG();
