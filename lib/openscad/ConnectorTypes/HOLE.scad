include <../Models/BottlePrecomputed.scad>
include <../Util/maths.scad>

part="HOLE";

function getQuadMatForAngle(angle) = quat_to_mat4(quat([0,0,1],angle));

$fn=200;

tubeODHOLE = 2*(12);
discODHOLE = 2*(15);
discHeightHOLE = 4;
holeRadiusHOLE = 2.8;

negativeHeightHOLE = discHeightHOLE;

// Connector data in an array to pass-through to other scripts as a single parameter
connectorDataArrayHOLE = [tubeODHOLE, negativeHeightHOLE];

module drawHole() {
}

module holeHOLE(holeLength, distanceToMiddle) { // Just a hole to save material
	translate([0,0,-50+distanceToMiddle])
    //cylinder(r=tubeODHOLE/2, h=50);
	translate([0,0,0.1])
	rotate(180,[1,0,0])
	//cylinder(r=holeRadiusHOLE,h=55+connectorDataDistance+discHeightHOLE);
    cylinder(r=holeRadiusHOLE,h=holeLength);
    echo(length=holeLength);
}

//if (part=="HOLE") drawHole();
