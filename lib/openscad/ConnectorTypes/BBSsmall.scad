$fn=50;
part="BBSsmall"; // "threads" for the part to print, "neck" for the part to subtract from your part

ScrewDiameterBBSsmall=6.2;
ScrewHoldingDiameterBBSsmall=4.9;
ScrewHeightBBSsmall=45;


// holder params

holderHeightBBSsmall=5;
holderODBBSsmall=50;
holderORBBSsmall=holderODBBSsmall/2;

connectionORBBSsmall=holderORBBSsmall-13;

bottleBottomSphereRadiusBBSsmall = 25; // How big the bottom part is
bottleBottomSphereThicknessBBSsmall = 1; // Not in millimeter! Actual size depends on Sphere radius
bottleBottomCutOffCubeSizeBBSsmall = bottleBottomSphereRadiusBBSsmall*2;
bottleBottomCutOffCubeOffsetBBSsmall = bottleBottomSphereRadiusBBSsmall/3;

negativeHeightBBSsmall = holderHeightBBSsmall-bottleBottomSphereThicknessBBSsmall; // Height until the bottle actually starts, to make sure connectorDataDistance is always the exact length from hub center to connection piece.

connectorDataArrayBBSsmall = [(connectionORBBSsmall)*2,negativeHeightBBSsmall];

module drawBBSsmall() {
	translate([0,0,-negativeHeightBBSsmall])
	difference(){
		union() {
			cylinder(r1=connectionORBBSsmall,r2=holderORBBSsmall, h=2);
			translate([0,0,2])
			
			cylinder(r=holderORBBSsmall,h=2);
			translate([0,0,4])
			cylinder(r=holderORBBSsmall-5, h=1);
		}
		
		
		cylinder(r=ScrewDiameterBBSsmall/2, h=5);
	}
	
	/*difference() {
		translate([0,0,-(bottleBottomSphereRadiusBBSsmall)]) //TODO make this adjust to washer diameter automatically
		sphere(r = bottleBottomSphereRadiusBBSsmall);
		translate([-bottleBottomCutOffCubeSizeBBSsmall/2,-bottleBottomCutOffCubeSizeBBSsmall/2,-bottleBottomCutOffCubeSizeBBSsmall-bottleBottomCutOffCubeOffsetBBSsmall])
		cube(size = [bottleBottomCutOffCubeSizeBBSsmall,bottleBottomCutOffCubeSizeBBSsmall,bottleBottomCutOffCubeSizeBBSsmall], center = false);
	}
*/

}
	
module substractBBSsmall() {
	xyz=0;
}

module holeBBSsmall() {
	translate([0,0,-negativeHeightBBSsmall])
	translate([0,0,holderHeightBBSsmall-ScrewHeightBBSsmall])
	cylinder(r=ScrewHoldingDiameterBBSsmall/2, h=50); // The smaller hole, where the screw can attach itself into the hub (easily.)
	
	translate([0,0,-negativeHeightBBSsmall])
	translate([0,0,holderHeightBBSsmall-ScrewHeightBBSsmall+18])
	cylinder(r=ScrewDiameterBBSsmall/2, h=50); // The bigger part of the "pre-drilled" hole, where the screw can just slide through
}


//if (part=="BBSsmall") drawBBSsmall();
//if (part=="BBSsmall") substractBBSsmall();