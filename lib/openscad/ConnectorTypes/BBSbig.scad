$fn=50;
part="BBSbig"; // "threads" for the part to print, "neck" for the part to subtract from your part

ScrewDiameterBBSbig=6.2;
ScrewHoldingDiameterBBSbig=4.9;
ScrewHeightBBSbig=45;


// holder params

holderHeightBBSbig=5;
holderODBBSbig=63.5;
holderORBBSbig=holderODBBSbig/2;

connectionORBBSbig=holderORBBSbig-15;

bottleBottomSphereRadiusBBSbig = 25; // How big the bottom part is
bottleBottomSphereThicknessBBSbig = 1; // Not in millimeter! Actual size depends on Sphere radius
bottleBottomCutOffCubeSizeBBSbig = bottleBottomSphereRadiusBBSbig*2;
bottleBottomCutOffCubeOffsetBBSbig = bottleBottomSphereRadiusBBSbig/3;

negativeHeightBBSbig = holderHeightBBSbig-bottleBottomSphereThicknessBBSbig; // Height until the bottle actually starts, to make sure connectorDataDistance is always the exact length from hub center to connection piece.

connectorDataArrayBBSbig = [(connectionORBBSbig)*2,negativeHeightBBSbig];

module drawBBSbig() {
  translate([0,0,-negativeHeightBBSbig])
  difference(){
    union() {
      cylinder(r1=connectionORBBSbig,r2=holderORBBSbig, h=2);
      translate([0,0,2])

      cylinder(r=holderORBBSbig,h=2);
      translate([0,0,4])
      cylinder(r=holderORBBSbig-7, h=1);
    }


    cylinder(r=ScrewDiameterBBSbig/2, h=5);
  }

  /*difference() {
    translate([0,0,-(bottleBottomSphereRadiusBBSbig)]) //TODO make this adjust to washer diameter automatically
    sphere(r = bottleBottomSphereRadiusBBSbig);
    translate([-bottleBottomCutOffCubeSizeBBSbig/2,-bottleBottomCutOffCubeSizeBBSbig/2,-bottleBottomCutOffCubeSizeBBSbig-bottleBottomCutOffCubeOffsetBBSbig])
    cube(size = [bottleBottomCutOffCubeSizeBBSbig,bottleBottomCutOffCubeSizeBBSbig,bottleBottomCutOffCubeSizeBBSbig], center = false);
  }
*/

}

module substractBBSbig() {
  xyz=0; // Do nothing.
}

module holeBBSbig() {
  translate([0,0,-negativeHeightBBSbig])
  translate([0,0,holderHeightBBSbig-ScrewHeightBBSbig])
  cylinder(r=ScrewHoldingDiameterBBSbig/2, h=50); // The smaller hole, where the screw can attach itself into the hub (easily.)

  translate([0,0,-negativeHeightBBSbig])
  translate([0,0,holderHeightBBSbig-ScrewHeightBBSbig+18])
  cylinder(r=ScrewDiameterBBSbig/2, h=50); // The bigger part of the "pre-drilled" hole, where the screw can just slide through
}


//if (part=="BBSbig") drawBBSbig();
//if (part=="BBSbig") substractBBSbig();
