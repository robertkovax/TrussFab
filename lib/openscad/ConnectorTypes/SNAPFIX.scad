include <../Util/maths.scad>

part="SNAPFIX"; 

//$fn=300;

$fn=80;

bottomWidthSNAPFIX = 2*(29); // Outer diameter of the bottom plate/washer
topWidthSNAPFIX = 2*(29);
heightSNAPFIX = 34;

bottleHoleWidthSNAPFIX = 29.18;
heightBeforeBottlewasherSNAPFIX = 4.7;
bottlewasherHeightSNAPFIX = 4; //5.3 before
bottlewasherIndentationSNAPFIX = 4.65;
bottlewasherIndentationAngleWidthSNAPFIX = 0.2;
bottleThreadLengthSNAPFIX = 18.04+1.3; //due to Washer adjustment
bottleThreadRoundingSNAPFIX = 2;
bottleNeckFollowerHeightSNAPFIX = 7;
bottleNeckFollowerIncline = 10.5;

fixationPieceCutoutWidthSNAPFIX = 2.95;
fixationPieceCutoutHeightSNAPFIX = 17.3;
fixationPieceCutoutElevationSNAPFIX = -fixationPieceCutoutHeightSNAPFIX;

negativeHeightSNAPFIX = fixationPieceCutoutHeightSNAPFIX+1;
negativeTranslation = heightSNAPFIX+0; // how far the addon reaches into the center of the hub; the height below where it will be connected to its neighbor.
// It is assumed that the addons are connected at y=0, which means the area below y=0 in this file actually reaches into the center of the connector.

fixationPieceWidthSNAPFIX = 20.1;
fixationPieceHeightSNAPFIX = 20.5;
fixationPieceMiddleWidthSNAPFIX = 2.9;
fixationPieceMiddleHeightSNAPFIX = 8;
fixationPieceTopRoundingSNAPFIX = 0.7;
fixationPieceTopRounding2SNAPFIX = 1.9;
fixationPieceRoundingHeightSNAPFIX = 5;

fixationPieceCutoutPusherWidth = 1.2;
fixationPieceCutoutInsertTranslation = 2;
fixationPieceCutoutNotchWidth = 0.7;

fixationPieceEffectiveHeightSNAPFIX = fixationPieceHeightSNAPFIX - fixationPieceMiddleHeightSNAPFIX-fixationPieceRoundingHeightSNAPFIX;



widthAtZeroSNAPFIX = bottomWidthSNAPFIX/2;
inwardsLengthSNAPFIX = negativeHeightSNAPFIX+negativeTranslation-0.1;


connectorDataArraySNAPFIX = [widthAtZeroSNAPFIX,inwardsLengthSNAPFIX]; // Connector data in an array to pass-through to other scripts as a single parameter


module drawFixationHoleSNAPFIX() // The hole (with spring) where you put in the wedge
{
	polygon( points=[
		
		[fixationPieceCutoutWidthSNAPFIX/2+(fixationPieceCutoutPusherWidth*4),fixationPieceCutoutElevationSNAPFIX+fixationPieceCutoutHeightSNAPFIX],
		[-fixationPieceCutoutWidthSNAPFIX/2,fixationPieceCutoutElevationSNAPFIX+fixationPieceCutoutHeightSNAPFIX],
		//[-fixationPieceCutoutWidthSNAPFIX/2,fixationPieceCutoutElevationSNAPFIX],
		
		[-fixationPieceCutoutWidthSNAPFIX/2,fixationPieceCutoutElevationSNAPFIX+fixationPieceCutoutHeightSNAPFIX-fixationPieceEffectiveHeightSNAPFIX],
		[-fixationPieceCutoutWidthSNAPFIX/2+fixationPieceCutoutNotchWidth,fixationPieceCutoutElevationSNAPFIX+fixationPieceCutoutHeightSNAPFIX-fixationPieceEffectiveHeightSNAPFIX],
		[-fixationPieceCutoutWidthSNAPFIX/2+fixationPieceCutoutInsertTranslation,fixationPieceCutoutElevationSNAPFIX],
		[fixationPieceCutoutWidthSNAPFIX/2+fixationPieceCutoutInsertTranslation,fixationPieceCutoutElevationSNAPFIX],
		[-fixationPieceCutoutWidthSNAPFIX/2+fixationPieceCutoutNotchWidth+fixationPieceCutoutWidthSNAPFIX,fixationPieceCutoutElevationSNAPFIX+fixationPieceCutoutHeightSNAPFIX-fixationPieceEffectiveHeightSNAPFIX],
		//[-fixationPieceCutoutWidthSNAPFIX/2+fixationPieceCutoutPusherWidth+fixationPieceCutoutWidthSNAPFIX+(fixationPieceCutoutPusherWidth*1),fixationPieceCutoutElevationSNAPFIX+fixationPieceCutoutHeightSNAPFIX-fixationPieceEffectiveHeightSNAPFIX],
		//[-fixationPieceCutoutWidthSNAPFIX/2+fixationPieceCutoutWidthSNAPFIX+(fixationPieceCutoutPusherWidth*2),fixationPieceCutoutElevationSNAPFIX+fixationPieceCutoutHeightSNAPFIX-(fixationPieceEffectiveHeightSNAPFIX/4)],
		//[-fixationPieceCutoutWidthSNAPFIX/2+fixationPieceCutoutWidthSNAPFIX+(fixationPieceCutoutPusherWidth*1),fixationPieceCutoutElevationSNAPFIX+fixationPieceCutoutHeightSNAPFIX-(fixationPieceEffectiveHeightSNAPFIX/4)],
		//[-fixationPieceCutoutWidthSNAPFIX/2+fixationPieceCutoutWidthSNAPFIX+(fixationPieceCutoutPusherWidth*1),fixationPieceCutoutElevationSNAPFIX+fixationPieceCutoutHeightSNAPFIX-(fixationPieceEffectiveHeightSNAPFIX)+fixationPieceCutoutPusherWidth/2],
		[-fixationPieceCutoutWidthSNAPFIX/2+fixationPieceCutoutWidthSNAPFIX,fixationPieceCutoutElevationSNAPFIX+fixationPieceCutoutHeightSNAPFIX-(fixationPieceEffectiveHeightSNAPFIX)+fixationPieceCutoutPusherWidth/2+1],
		[fixationPieceCutoutWidthSNAPFIX/2,fixationPieceCutoutElevationSNAPFIX+fixationPieceCutoutHeightSNAPFIX-(fixationPieceCutoutPusherWidth*1)],
		[fixationPieceCutoutWidthSNAPFIX/2+(fixationPieceCutoutPusherWidth*3),fixationPieceCutoutElevationSNAPFIX+fixationPieceCutoutHeightSNAPFIX-(fixationPieceCutoutPusherWidth*1)],
		//[fixationPieceCutoutWidthSNAPFIX/2+(fixationPieceCutoutPusherWidth*3),fixationPieceCutoutElevationSNAPFIX],
		[fixationPieceCutoutWidthSNAPFIX/2+(fixationPieceCutoutPusherWidth*4),fixationPieceCutoutElevationSNAPFIX+2],
		],convexity=15);
}

module drawSNAPFIX() { 
	difference() {
		
		translate([0,-negativeTranslation,0])
		//translate([0,-negativeTranslation-2,0]) //DEBUG
		polygon( points=[ // Big polygon for the addon, then remove the wedge hole.
		
		[bottomWidthSNAPFIX/2,-negativeHeightSNAPFIX],
		[bottomWidthSNAPFIX/2,0],
		[topWidthSNAPFIX/2,heightSNAPFIX-15],
		[topWidthSNAPFIX/2,heightSNAPFIX],
		[topWidthSNAPFIX/2-bottleNeckFollowerIncline,heightSNAPFIX+bottleNeckFollowerHeightSNAPFIX],
		[bottleHoleWidthSNAPFIX/2,heightSNAPFIX],
		[bottleHoleWidthSNAPFIX/2,heightSNAPFIX-heightBeforeBottlewasherSNAPFIX],
		[bottleHoleWidthSNAPFIX/2+bottlewasherIndentationSNAPFIX,heightSNAPFIX-heightBeforeBottlewasherSNAPFIX],
		[bottleHoleWidthSNAPFIX/2+bottlewasherIndentationSNAPFIX+bottlewasherIndentationAngleWidthSNAPFIX,heightSNAPFIX-heightBeforeBottlewasherSNAPFIX-bottlewasherHeightSNAPFIX],
		[bottleHoleWidthSNAPFIX/2,heightSNAPFIX-heightBeforeBottlewasherSNAPFIX-bottlewasherHeightSNAPFIX],
		[bottleHoleWidthSNAPFIX/2,heightSNAPFIX-heightBeforeBottlewasherSNAPFIX-bottlewasherHeightSNAPFIX-bottleThreadLengthSNAPFIX+bottleThreadRoundingSNAPFIX],
		[bottleHoleWidthSNAPFIX/2-bottleThreadRoundingSNAPFIX,heightSNAPFIX-heightBeforeBottlewasherSNAPFIX-bottlewasherHeightSNAPFIX-bottleThreadLengthSNAPFIX],
		/*[-3+bottleHoleWidthSNAPFIX/2-bottleThreadRoundingSNAPFIX,heightSNAPFIX-heightBeforeBottlewasherSNAPFIX-bottlewasherHeightSNAPFIX-bottleThreadLengthSNAPFIX],
		[-3+bottleHoleWidthSNAPFIX/2-bottleThreadRoundingSNAPFIX,3+heightSNAPFIX-heightBeforeBottlewasherSNAPFIX-bottlewasherHeightSNAPFIX-bottleThreadLengthSNAPFIX],
		[3-bottleHoleWidthSNAPFIX/2+bottleThreadRoundingSNAPFIX,3+heightSNAPFIX-heightBeforeBottlewasherSNAPFIX-bottlewasherHeightSNAPFIX-bottleThreadLengthSNAPFIX],
		[3-bottleHoleWidthSNAPFIX/2+bottleThreadRoundingSNAPFIX,heightSNAPFIX-heightBeforeBottlewasherSNAPFIX-bottlewasherHeightSNAPFIX-bottleThreadLengthSNAPFIX],*/	
		[-bottleHoleWidthSNAPFIX/2+bottleThreadRoundingSNAPFIX,heightSNAPFIX-heightBeforeBottlewasherSNAPFIX-bottlewasherHeightSNAPFIX-bottleThreadLengthSNAPFIX],
		[-bottleHoleWidthSNAPFIX/2,heightSNAPFIX-heightBeforeBottlewasherSNAPFIX-bottlewasherHeightSNAPFIX-bottleThreadLengthSNAPFIX+bottleThreadRoundingSNAPFIX],
		[-bottleHoleWidthSNAPFIX/2,heightSNAPFIX-heightBeforeBottlewasherSNAPFIX-bottlewasherHeightSNAPFIX],
		[-bottleHoleWidthSNAPFIX/2-bottlewasherIndentationSNAPFIX-bottlewasherIndentationAngleWidthSNAPFIX,heightSNAPFIX-heightBeforeBottlewasherSNAPFIX-bottlewasherHeightSNAPFIX],
		[-bottleHoleWidthSNAPFIX/2-bottlewasherIndentationSNAPFIX,heightSNAPFIX-heightBeforeBottlewasherSNAPFIX],
		[-bottleHoleWidthSNAPFIX/2,heightSNAPFIX-heightBeforeBottlewasherSNAPFIX],
		[-bottleHoleWidthSNAPFIX/2,heightSNAPFIX],
		[-topWidthSNAPFIX/2+bottleNeckFollowerIncline,heightSNAPFIX+bottleNeckFollowerHeightSNAPFIX],    
		[-topWidthSNAPFIX/2,heightSNAPFIX],
		[-topWidthSNAPFIX/2,heightSNAPFIX-15],
		[-bottomWidthSNAPFIX/2,0],
		[-bottomWidthSNAPFIX/2,-negativeHeightSNAPFIX],
		],convexity=15);
		
		translate([-1,-negativeTranslation,0])
		drawFixationHoleSNAPFIX();
	}
	
	translate([0,-negativeTranslation,0]) // Another big polygon that draws the wedge
	polygon(points=[
	[fixationPieceMiddleWidthSNAPFIX/2,heightSNAPFIX-heightBeforeBottlewasherSNAPFIX-fixationPieceRoundingHeightSNAPFIX-fixationPieceMiddleHeightSNAPFIX],
	[fixationPieceMiddleWidthSNAPFIX/2,heightSNAPFIX-heightBeforeBottlewasherSNAPFIX-fixationPieceRoundingHeightSNAPFIX],
	[fixationPieceMiddleWidthSNAPFIX/2+fixationPieceTopRounding2SNAPFIX,heightSNAPFIX-heightBeforeBottlewasherSNAPFIX],
	[fixationPieceWidthSNAPFIX/2-fixationPieceTopRoundingSNAPFIX,heightSNAPFIX-heightBeforeBottlewasherSNAPFIX],
	[fixationPieceWidthSNAPFIX/2,heightSNAPFIX-heightBeforeBottlewasherSNAPFIX-fixationPieceRoundingHeightSNAPFIX],
	[fixationPieceWidthSNAPFIX/2,heightSNAPFIX-heightBeforeBottlewasherSNAPFIX-(fixationPieceHeightSNAPFIX-fixationPieceRoundingHeightSNAPFIX)],
	[fixationPieceWidthSNAPFIX/2-fixationPieceRoundingHeightSNAPFIX,heightSNAPFIX-heightBeforeBottlewasherSNAPFIX-(fixationPieceHeightSNAPFIX)],
	
	[-fixationPieceWidthSNAPFIX/2+fixationPieceRoundingHeightSNAPFIX,heightSNAPFIX-heightBeforeBottlewasherSNAPFIX-(fixationPieceHeightSNAPFIX)],
	[-fixationPieceWidthSNAPFIX/2,heightSNAPFIX-heightBeforeBottlewasherSNAPFIX-(fixationPieceHeightSNAPFIX-fixationPieceRoundingHeightSNAPFIX)],
	[-fixationPieceWidthSNAPFIX/2,heightSNAPFIX-heightBeforeBottlewasherSNAPFIX-fixationPieceRoundingHeightSNAPFIX],
	[-fixationPieceWidthSNAPFIX/2+fixationPieceTopRoundingSNAPFIX,heightSNAPFIX-heightBeforeBottlewasherSNAPFIX],
	[-fixationPieceMiddleWidthSNAPFIX/2-fixationPieceTopRounding2SNAPFIX,heightSNAPFIX-heightBeforeBottlewasherSNAPFIX],
	[-fixationPieceMiddleWidthSNAPFIX/2,heightSNAPFIX-heightBeforeBottlewasherSNAPFIX-fixationPieceRoundingHeightSNAPFIX],
	[-fixationPieceMiddleWidthSNAPFIX/2,heightSNAPFIX-heightBeforeBottlewasherSNAPFIX-fixationPieceRoundingHeightSNAPFIX-fixationPieceMiddleHeightSNAPFIX],
	
	]);
}



module substractSNAPFIX() { // Basically draws the middle part of the addon again, but using the inverse part. Then remove the wedge from that inverse area again. Also draw hole for wedge (which has to be removed from the final hub)
	color("Blue")
	translate([-1,-negativeTranslation,0])

	drawFixationHoleSNAPFIX();
	
	difference(){
		color("Green")
		translate([0,-negativeTranslation,0])
		polygon( points=[
		[topWidthSNAPFIX/2-bottleNeckFollowerIncline,heightSNAPFIX+bottleNeckFollowerHeightSNAPFIX],
		[bottleHoleWidthSNAPFIX/2,heightSNAPFIX],
		[bottleHoleWidthSNAPFIX/2,heightSNAPFIX-heightBeforeBottlewasherSNAPFIX],
		[bottleHoleWidthSNAPFIX/2+bottlewasherIndentationSNAPFIX,heightSNAPFIX-heightBeforeBottlewasherSNAPFIX],
		[bottleHoleWidthSNAPFIX/2+bottlewasherIndentationSNAPFIX+bottlewasherIndentationAngleWidthSNAPFIX,heightSNAPFIX-heightBeforeBottlewasherSNAPFIX-bottlewasherHeightSNAPFIX],
		[bottleHoleWidthSNAPFIX/2,heightSNAPFIX-heightBeforeBottlewasherSNAPFIX-bottlewasherHeightSNAPFIX],
		[bottleHoleWidthSNAPFIX/2,heightSNAPFIX-heightBeforeBottlewasherSNAPFIX-bottlewasherHeightSNAPFIX-bottleThreadLengthSNAPFIX+bottleThreadRoundingSNAPFIX],
		[bottleHoleWidthSNAPFIX/2-bottleThreadRoundingSNAPFIX,heightSNAPFIX-heightBeforeBottlewasherSNAPFIX-bottlewasherHeightSNAPFIX-bottleThreadLengthSNAPFIX],
		[-bottleHoleWidthSNAPFIX/2+bottleThreadRoundingSNAPFIX,heightSNAPFIX-heightBeforeBottlewasherSNAPFIX-bottlewasherHeightSNAPFIX-bottleThreadLengthSNAPFIX],
		[-bottleHoleWidthSNAPFIX/2,heightSNAPFIX-heightBeforeBottlewasherSNAPFIX-bottlewasherHeightSNAPFIX-bottleThreadLengthSNAPFIX+bottleThreadRoundingSNAPFIX],
		[-bottleHoleWidthSNAPFIX/2,heightSNAPFIX-heightBeforeBottlewasherSNAPFIX-bottlewasherHeightSNAPFIX],
		[-bottleHoleWidthSNAPFIX/2-bottlewasherIndentationSNAPFIX-bottlewasherIndentationAngleWidthSNAPFIX,heightSNAPFIX-heightBeforeBottlewasherSNAPFIX-bottlewasherHeightSNAPFIX],
		[-bottleHoleWidthSNAPFIX/2-bottlewasherIndentationSNAPFIX,heightSNAPFIX-heightBeforeBottlewasherSNAPFIX],
		[-bottleHoleWidthSNAPFIX/2,heightSNAPFIX-heightBeforeBottlewasherSNAPFIX],
		[-bottleHoleWidthSNAPFIX/2,heightSNAPFIX],
		[-topWidthSNAPFIX/2+bottleNeckFollowerIncline,heightSNAPFIX+bottleNeckFollowerHeightSNAPFIX]
		
		]);
	
		color("Red")
		translate([0,-negativeTranslation,0])
		polygon(points=[
		[fixationPieceMiddleWidthSNAPFIX/2,heightSNAPFIX-heightBeforeBottlewasherSNAPFIX-fixationPieceRoundingHeightSNAPFIX-fixationPieceMiddleHeightSNAPFIX],
		[fixationPieceMiddleWidthSNAPFIX/2,heightSNAPFIX-heightBeforeBottlewasherSNAPFIX-fixationPieceRoundingHeightSNAPFIX],
		[fixationPieceMiddleWidthSNAPFIX/2+fixationPieceTopRounding2SNAPFIX,heightSNAPFIX-heightBeforeBottlewasherSNAPFIX],
		[fixationPieceWidthSNAPFIX/2-fixationPieceTopRoundingSNAPFIX,heightSNAPFIX-heightBeforeBottlewasherSNAPFIX],
		[fixationPieceWidthSNAPFIX/2,heightSNAPFIX-heightBeforeBottlewasherSNAPFIX-fixationPieceRoundingHeightSNAPFIX],
		[fixationPieceWidthSNAPFIX/2,heightSNAPFIX-heightBeforeBottlewasherSNAPFIX-(fixationPieceHeightSNAPFIX-fixationPieceRoundingHeightSNAPFIX)],
		[fixationPieceWidthSNAPFIX/2-fixationPieceRoundingHeightSNAPFIX,heightSNAPFIX-heightBeforeBottlewasherSNAPFIX-(fixationPieceHeightSNAPFIX)],
		
		[-fixationPieceWidthSNAPFIX/2+fixationPieceRoundingHeightSNAPFIX,heightSNAPFIX-heightBeforeBottlewasherSNAPFIX-(fixationPieceHeightSNAPFIX)],
		[-fixationPieceWidthSNAPFIX/2,heightSNAPFIX-heightBeforeBottlewasherSNAPFIX-(fixationPieceHeightSNAPFIX-fixationPieceRoundingHeightSNAPFIX)],
		[-fixationPieceWidthSNAPFIX/2,heightSNAPFIX-heightBeforeBottlewasherSNAPFIX-fixationPieceRoundingHeightSNAPFIX],
		[-fixationPieceWidthSNAPFIX/2+fixationPieceTopRoundingSNAPFIX,heightSNAPFIX-heightBeforeBottlewasherSNAPFIX],
		[-fixationPieceMiddleWidthSNAPFIX/2-fixationPieceTopRounding2SNAPFIX,heightSNAPFIX-heightBeforeBottlewasherSNAPFIX],
		[-fixationPieceMiddleWidthSNAPFIX/2,heightSNAPFIX-heightBeforeBottlewasherSNAPFIX-fixationPieceRoundingHeightSNAPFIX],
		[-fixationPieceMiddleWidthSNAPFIX/2,heightSNAPFIX-heightBeforeBottlewasherSNAPFIX-fixationPieceRoundingHeightSNAPFIX-fixationPieceMiddleHeightSNAPFIX],
		
		]);
	}
}

//if (part=="SNAPFIX") drawSNAPFIX();
//if (part=="SNAPFIX") substractSNAPFIX();