include <../Util/maths.scad>

part="SNAPSCREW"; 

//$fn=300;
$fn=80;

washerODSNAPSCREW = 2*(17); // Outer diameter of the bottom plate/washer
washerHeightSNAPSCREW = 10; // bottom plate/washer height
holderODSNAPSCREW = washerODSNAPSCREW;

plugHoleTopRadiusSNAPSCREW = 3.5; //Hole in the middle of the plug
plugHoleBotRadiusSNAPSCREW = 4.5;

snapRidgeWidthSNAPSCREW = 1.4; // How big the snap ridge is
snapRidgeHeightSNAPSCREW = 1; 
snapGuidingLengthSNAPSCREW = 4; // How long the guiding slop at the top should be

innerRadiusSNAPSCREW = 10.25; // Radius of middle part (e.g. the part in the bottleneck)
innerHeightSNAPSCREW = washerHeightSNAPSCREW+snapGuidingLengthSNAPSCREW+snapRidgeHeightSNAPSCREW + (27); // How long the middle part is

snapGuidingTopFlatnessSNAPSCREW = (innerRadiusSNAPSCREW+snapRidgeWidthSNAPSCREW)/ (1.2); // >= 1  // How big the flat part on the top is


// Connector data in an array to pass-through to other scripts as a single parameter

widthAtZero = washerODSNAPSCREW/2;
inwardsLength = washerHeightSNAPSCREW-0.1;

connectorDataArraySNAPSCREW = [widthAtZero,inwardsLength];


module drawSNAPSCREW() {
	translate([0,-washerHeightSNAPSCREW,0])
	polygon( points=[
		[-plugHoleTopRadiusSNAPSCREW,0],
		[-plugHoleTopRadiusSNAPSCREW,innerHeightSNAPSCREW],
		[-snapGuidingTopFlatnessSNAPSCREW,innerHeightSNAPSCREW],
		[-(innerRadiusSNAPSCREW+snapRidgeWidthSNAPSCREW),innerHeightSNAPSCREW-snapGuidingLengthSNAPSCREW],
		[-(innerRadiusSNAPSCREW+snapRidgeWidthSNAPSCREW),innerHeightSNAPSCREW-snapGuidingLengthSNAPSCREW-snapRidgeHeightSNAPSCREW],
		[-innerRadiusSNAPSCREW,innerHeightSNAPSCREW-snapGuidingLengthSNAPSCREW-snapRidgeHeightSNAPSCREW],
		[-innerRadiusSNAPSCREW,washerHeightSNAPSCREW],
		[4-washerODSNAPSCREW/2,washerHeightSNAPSCREW],
		[4-washerODSNAPSCREW/2,washerHeightSNAPSCREW+1],
		[5-washerODSNAPSCREW/2,washerHeightSNAPSCREW+1],
		[5-washerODSNAPSCREW/2,washerHeightSNAPSCREW+3],
		[4-washerODSNAPSCREW/2,washerHeightSNAPSCREW+3],
		[4-washerODSNAPSCREW/2,washerHeightSNAPSCREW+6],
		[5-washerODSNAPSCREW/2,washerHeightSNAPSCREW+6],
		[5-washerODSNAPSCREW/2,washerHeightSNAPSCREW+8],
		[4-washerODSNAPSCREW/2,washerHeightSNAPSCREW+8],
		[4-washerODSNAPSCREW/2,washerHeightSNAPSCREW+10],
		[-washerODSNAPSCREW/2,washerHeightSNAPSCREW+10],
		[-washerODSNAPSCREW/2,0],
		[-plugHoleBotRadiusSNAPSCREW,0],
	
		[plugHoleBotRadiusSNAPSCREW,0],
		[washerODSNAPSCREW/2,0],
		[washerODSNAPSCREW/2,washerHeightSNAPSCREW+10],
		[-5+washerODSNAPSCREW/2,washerHeightSNAPSCREW+10],
		[-5+washerODSNAPSCREW/2,washerHeightSNAPSCREW+8],
		[-4+washerODSNAPSCREW/2,washerHeightSNAPSCREW+8],
		[-4+washerODSNAPSCREW/2,washerHeightSNAPSCREW+5],
		[-5+washerODSNAPSCREW/2,washerHeightSNAPSCREW+5],
		[-5+washerODSNAPSCREW/2,washerHeightSNAPSCREW+3],
		[-4+washerODSNAPSCREW/2,washerHeightSNAPSCREW+3],
		[-4+washerODSNAPSCREW/2,washerHeightSNAPSCREW],
		[innerRadiusSNAPSCREW,washerHeightSNAPSCREW],
		[innerRadiusSNAPSCREW,innerHeightSNAPSCREW-snapGuidingLengthSNAPSCREW-snapRidgeHeightSNAPSCREW],
		[innerRadiusSNAPSCREW+snapRidgeWidthSNAPSCREW,innerHeightSNAPSCREW-snapGuidingLengthSNAPSCREW-snapRidgeHeightSNAPSCREW],
		[innerRadiusSNAPSCREW+snapRidgeWidthSNAPSCREW,innerHeightSNAPSCREW-snapGuidingLengthSNAPSCREW],
		[snapGuidingTopFlatnessSNAPSCREW,innerHeightSNAPSCREW],
		[plugHoleTopRadiusSNAPSCREW,innerHeightSNAPSCREW],
		[plugHoleTopRadiusSNAPSCREW,0]]
		
	
	
	);
}



//if (part=="SNAPSCREW") drawSNAPSCREW();