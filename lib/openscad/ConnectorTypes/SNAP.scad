include <../Models/BottlePrecomputed.scad>
include <../Util/maths.scad>

part="SNAP"; 

//$fn=300;



function getQuadMatForAngle(angle) = quat_to_mat4(quat([0,0,1],angle));

$fn=50;

washerODSNAP = 2*(12.5); // Outer diameter of the bottom plate/washer
washerHeightSNAP = 4; // bottom plate/washer height
holderODSNAP = washerODSNAP;

plugHoleTopRadiusSNAP = 3.5; //Hole in the middle of the plug
plugHoleBotRadiusSNAP = 4.5;

snapRidgeWidthSNAP = 1.4; // How big the snap ridge is
snapRidgeHeightSNAP = 1; 
snapGuidingLengthSNAP = 4; // How long the guiding slop at the top should be

innerRadiusSNAP = 10.25; // Radius of middle part (e.g. the part in the bottleneck)
innerHeightSNAP = washerHeightSNAP+snapGuidingLengthSNAP+snapRidgeHeightSNAP + (27); // How long the middle part is

snapGuidingTopFlatnessSNAP = (innerRadiusSNAP+snapRidgeWidthSNAP)/ (1.2); // >= 1  // How big the flat part on the top is

percentFullCirceSNAP = 0.03; // When to start dividing the (three) push parts
percentStartCutFrom = 0.05;

crossSections = 3; // Number of dividing cut-outs

crossWidthSNAP = 4.7; // Width of the dividing cut-outs
crossHeightSNAP = (innerHeightSNAP - washerHeightSNAP); 
crossDepthSNAP = washerODSNAP+2*snapRidgeWidthSNAP;

bottleBottomSphereRadiusSNAP = 24; // How big the bottom part is
bottleBottomSphereThicknessSNAP = 1; // Not in millimeter! Actual size depends on Sphere radius
bottleBottomCutOffCubeSizeSNAP = bottleBottomSphereRadiusSNAP*2;
bottleBottomCutOffCubeOffsetSNAP = bottleBottomSphereRadiusSNAP/3;


negativeHeightSNAP = washerHeightSNAP;

// Connector data in an array to pass-through to other scripts as a single parameter
connectorDataArraySNAP = [washerODSNAP, negativeHeightSNAP/*,washerHeightSNAP,plugHoleTopRadiusSNAP,plugHoleBotRadiusSNAP*/]; 



module makeCrossPartSNAP() {
	translate([0,0,percentFullCirceSNAP*(innerHeightSNAP-washerHeightSNAP-(snapGuidingLengthSNAP+snapRidgeHeightSNAP))+washerHeightSNAP+0.001])
    //cube(size = [crossDepthSNAP/2,crossWidthSNAP-i,crossHeightSNAP], center = false);
	rotate(180,[1,0,0])
	translate([0,0,-crossHeightSNAP])
	linear_extrude(height=crossHeightSNAP, center = false, convexity = 4, scale=[percentStartCutFrom,1])
	
	polygon(points=[[-crossWidthSNAP/2,crossDepthSNAP/2],[crossWidthSNAP/2,crossDepthSNAP/2],[crossWidthSNAP/2,0],[-crossWidthSNAP/2,0]]);
}

module drawSNAP() {
	translate([0,0,-negativeHeightSNAP])
	difference () {
		rotate_extrude(convexity=15)       
		polygon( points=[[plugHoleBotRadiusSNAP,0],[washerODSNAP/2,0],[washerODSNAP/2,washerHeightSNAP],[innerRadiusSNAP,washerHeightSNAP],[innerRadiusSNAP,innerHeightSNAP-snapGuidingLengthSNAP-snapRidgeHeightSNAP],[innerRadiusSNAP+snapRidgeWidthSNAP,innerHeightSNAP-snapGuidingLengthSNAP-snapRidgeHeightSNAP],[innerRadiusSNAP+snapRidgeWidthSNAP,innerHeightSNAP-snapGuidingLengthSNAP],[snapGuidingTopFlatnessSNAP,innerHeightSNAP],[plugHoleTopRadiusSNAP,innerHeightSNAP]] );
		
		union(){
			/*for ( i = [0 : descentGrainSNAP : crossWidthSNAP*startDescentAfterSNAP] )
			{
				makeCrossPartSNAP(i);
                
                multmatrix(thirdMatSNAP)
				makeCrossPartSNAP(i);
                
                multmatrix(thirdMatSNAP)
                multmatrix(thirdMatSNAP)
				makeCrossPartSNAP(i);
			}}*/
			
			
			for ( i = [360/crossSections : 360/crossSections : 360] ) {
				multmatrix(getQuadMatForAngle(i))
				makeCrossPartSNAP();
			}
			/*makeCrossPartSNAP();
                
			multmatrix(getQuadMatForAngle(60))
			makeCrossPartSNAP();
			
			multmatrix(thirdMatSNAP)
			multmatrix(thirdMatSNAP)
			makeCrossPartSNAP();*/
		}
	}
	//addBottleBottomSNAP();
}


// creating part of the shell of a sphere to fix a snapping connector in the dent in the bottom of a bottle. (The snapping part would then snap into a drilled hole in the bottle bottom.
module addBottleBottomSNAP() {
	difference() {
	
		difference() {
			translate([0,0,washerHeightSNAP-(bottleBottomSphereRadiusSNAP)])
			sphere(r = bottleBottomSphereRadiusSNAP);
			translate([-bottleBottomCutOffCubeSizeSNAP/2,-bottleBottomCutOffCubeSizeSNAP/2,-bottleBottomCutOffCubeSizeSNAP-bottleBottomCutOffCubeOffsetSNAP])
			cube(size = [bottleBottomCutOffCubeSizeSNAP,bottleBottomCutOffCubeSizeSNAP,bottleBottomCutOffCubeSizeSNAP], center = false);
		}
		
		difference() {
			translate([0,0,washerHeightSNAP-(bottleBottomSphereRadiusSNAP)-bottleBottomSphereThicknessSNAP])
			sphere(r = bottleBottomSphereRadiusSNAP);
			translate([-bottleBottomCutOffCubeSizeSNAP/2,-bottleBottomCutOffCubeSizeSNAP/2,-bottleBottomCutOffCubeSizeSNAP-bottleBottomCutOffCubeOffsetSNAP])
			cube(size = [bottleBottomCutOffCubeSizeSNAP,bottleBottomCutOffCubeSizeSNAP,bottleBottomCutOffCubeSizeSNAP], center = false);
		}
	}
}


module substractSNAP() { // Draws a bottle and substracts the addon, leaving the space the bottle needs around the addon to sit there comfortably.
	translate([0,0,-negativeHeightSNAP])
	difference()
	{
		translate([0,0,washerHeightSNAP])
		drawBottle();
        translate([0,0,washerHeightSNAP])
		drawSNAP();
	}
}

module holeSNAP(holeLength) { // Just a hole for the wedge that secures the SnapPush addons.
	translate([0,0,-negativeHeightSNAP])
    //cylinder(r=TubeWidthSNAPSC/2, h=50);
	translate([0,0,0.1])
	rotate(180,[1,0,0])
	//cylinder(r=plugHoleBotRadiusSNAP,h=55+connectorDataDistance+washerHeightSNAP);
    cylinder(r=plugHoleBotRadiusSNAP,h=holeLength);
}

// Auxiliary functions to also print some plugs/wedges. 

// Cylinder shaped plug/wedge
module cylinderPlugSNAP(size = "medium",rotation = false) {
	color("Blue")
	if (rotation == true) {
		if (size == "small") {
			rotate([90,0,0])
			cylinder(r=plugHoleTopRadiusSNAP,h=innerHeightSNAP+5);
		}
		if (size == "medium") {
			rotate([90,0,0])
			cylinder(r=plugHoleTopRadiusSNAP+0.2,h=innerHeightSNAP+5);
		}
		if (size == "large") {
			rotate([90,0,0])
			cylinder(r=plugHoleTopRadiusSNAP+0.4,h=innerHeightSNAP+5);
		}
	}
	else {
		if (size == "small") {
			cylinder(r=plugHoleTopRadiusSNAP,h=innerHeightSNAP+5);
		}
		if (size == "medium") {
			cylinder(r=plugHoleTopRadiusSNAP+0.2,h=innerHeightSNAP+5);
		}
		if (size == "large") {
			cylinder(r=plugHoleTopRadiusSNAP+0.4,h=innerHeightSNAP+5);
		}
	}
}

// Cone shaped plug, biggest part 0.3 smaller than plug-holes still.
module conePlugSNAP(size = "medium") {
	if (size == "small") {
		color("Blue")
		rotate_extrude(convexity=3)
		polygon( points=[[0,0],[plugHoleBotRadiusSNAP-0.3,0],[plugHoleTopRadiusSNAP,innerHeightSNAP+5],[0,innerHeightSNAP+5]]);
	}
	if (size == "medium") {
		color("Blue")
		rotate_extrude(convexity=3)
		polygon( points=[[0,0],[plugHoleBotRadiusSNAP-0.3,0],[plugHoleTopRadiusSNAP+0.2,innerHeightSNAP+5],[0,innerHeightSNAP+5]]);
	}
	if (size == "large") {
		color("Blue")
		rotate_extrude(convexity=3)
		polygon( points=[[0,0],[plugHoleBotRadiusSNAP-0.3,0],[plugHoleTopRadiusSNAP+0.4,innerHeightSNAP+5],[0,innerHeightSNAP+5]]);
	}
}

//if (part=="SNAP") drawSNAP();
