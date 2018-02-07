// 2 Liter Bottle Holder
//
// (c) 2013 Laird Popkin, based on http://www.threadspecs.com/assets/Threadspecs/ISBT-PCO-1881-Finish-3784253-18.pdf.
// Credit to eagleapex for creating and then deleting http://www.thingiverse.com/thing:10489
// which inspired me to create this.

$fn=50;

partTHREAD="cap"; // "threads" for the part to print, "neck" for the part to subtract from your part, cap for the complete holder
clearanceTHREAD=0.6; // tune to get the right 'fit' for your printer

// Bottle params

bottleIDTHREAD=25.2;   //25.07; // OD = Outer diameter
bottleODTHREAD=28.4;   //27.4;
bottlePitchTHREAD=2.7;
bottleHeightTHREAD=12;
bottleAngleTHREAD=2;
threadLenTHREAD=22;

// holder params

holderHeightTHREAD=bottleHeightTHREAD+1;
holderODTHREAD=bottleODTHREAD+7;
holderORTHREAD=holderODTHREAD/2;

squeezeRingLengthTHREAD = 4;
squeezeRingWidthTHREAD = 0.5;

// funnel params

funnelODTHREAD=100;
funnelWallTHREAD=2;

// Bottle Computations

threadHeightTHREAD = bottlePitchTHREAD/3;

negativeHeightTHREAD = 1; // The actual pen starts after 1mm. This parameter makes sure that the connectorDataDistance is always the exact distance to the connection piece.

connectorDataArrayTHREAD = [holderODTHREAD,negativeHeightTHREAD]; // Addon data in an array to pass-through to other scripts as a single parameter

module bottleNeckTHREAD() {
  difference() {
    union() {
      translate([0,0,-0.5]) cylinder(r=bottleODTHREAD/2+clearanceTHREAD,h=bottleHeightTHREAD+1);
      }
    union() {
      for (i=[-((bottleHeightTHREAD/bottlePitchTHREAD)/2)+0.5 : ((bottleHeightTHREAD/bottlePitchTHREAD)/2)-2])
      {
      translate([0,0,i*bottlePitchTHREAD]) {
        rotate([0,bottleAngleTHREAD,0]) translate([-threadLenTHREAD/2,0,bottleHeightTHREAD/2]) cube([threadLenTHREAD,bottleODTHREAD,threadHeightTHREAD]);
        rotate([0,bottleAngleTHREAD,90]) translate([-threadLenTHREAD/2,0,bottleHeightTHREAD/2+bottlePitchTHREAD/4]) cube([threadLenTHREAD,bottleODTHREAD,threadHeightTHREAD]);
        rotate([0,bottleAngleTHREAD,-90]) translate([-threadLenTHREAD/2,0,bottleHeightTHREAD/2+bottlePitchTHREAD*3/4]) cube([threadLenTHREAD,bottleODTHREAD,threadHeightTHREAD]);
        rotate([0,bottleAngleTHREAD,180]) translate([-threadLenTHREAD/2,0,bottleHeightTHREAD/2+bottlePitchTHREAD/2]) cube([threadLenTHREAD,bottleODTHREAD,threadHeightTHREAD]);
        }
      }
      //translate([0,0,bottleHeight/2+bottlePitch/2]) rotate([0,0,90]) cube([10,bottleOD,threadHeight], center=true);
      }
    }
  translate([0,0,-1]) cylinder(r=bottleIDTHREAD/2+clearanceTHREAD,h=bottleHeightTHREAD+2);
  }

module bottleHolderTHREAD() {
  difference() {
    cylinder(r=holderORTHREAD,h=bottleHeightTHREAD);
    bottleNeckTHREAD();
    }
  }

module drawTHREAD() {
  translate([0,0,-negativeHeightTHREAD])
  {
    translate([0,0,1])
    bottleHolderTHREAD();
    cylinder(r=holderORTHREAD, h=1);

    difference() {
      translate([0,0,bottleHeightTHREAD+1-squeezeRingLengthTHREAD])
      cylinder(r=holderORTHREAD, h=squeezeRingLengthTHREAD);
      translate([0,0,bottleHeightTHREAD+1-squeezeRingLengthTHREAD-0.02])
      cylinder(r=(bottleODTHREAD)/2+clearanceTHREAD-squeezeRingWidthTHREAD, h=squeezeRingLengthTHREAD+0.12);
      }
  }
}

module substractTHREAD() {
  difference() {
        translate([0,0,-negativeHeightTHREAD])
    union() {
      translate([0,0,1])
      cylinder(r=clearanceTHREAD+(bottleODTHREAD)/2, h=20);
      translate([0,0,bottleHeightTHREAD+1])
      cylinder(r=clearanceTHREAD+3+(bottleODTHREAD)/2, h=3);
    }
    drawTHREAD();
  }
}

// This module creates a simple thread connection piece (instead of using bottles) for example to connect two hubs that lie close to each other (closer than a bottle length)
module drawBasicUnifyerTHREAD(unificationLength=30,sparsemode=true) {
  fatTHREAD = threadHeightTHREAD+0.5;
  difference() {
    union(){
      drawHalfBasicUnifyerTHREAD();
      rotate(180,[1,0,0])
      translate([0,0,-unificationLength])
      drawHalfBasicUnifyerTHREAD();
    }
    if (sparsemode == true)
    {
      translate([0,0,-0.1])
      cylinder(r = ((bottleODTHREAD-2.5)/2)*0.8, h=unificationLength+0.2);
    }

  }

  module drawHalfBasicUnifyerTHREAD() {
    cylinder(r=(bottleODTHREAD-2.5)/2, h=unificationLength/2);
    difference() {
      union() {
        for (i=[-((bottleHeightTHREAD/bottlePitchTHREAD)/2)+0.5 : ((bottleHeightTHREAD/bottlePitchTHREAD)/2)-3])
        {
        translate([0,0,i*bottlePitchTHREAD]) {
          rotate([0,bottleAngleTHREAD,0]) translate([-threadLenTHREAD/2,0,bottleHeightTHREAD/2]) cube([threadLenTHREAD,bottleODTHREAD,fatTHREAD]);
          rotate([0,bottleAngleTHREAD,90]) translate([-threadLenTHREAD/2,0,bottleHeightTHREAD/2+bottlePitchTHREAD/4]) cube([threadLenTHREAD,bottleODTHREAD,fatTHREAD]);
          rotate([0,bottleAngleTHREAD,-90]) translate([-threadLenTHREAD/2,0,bottleHeightTHREAD/2+bottlePitchTHREAD*3/4]) cube([threadLenTHREAD,bottleODTHREAD,fatTHREAD]);
          rotate([0,bottleAngleTHREAD,180]) translate([-threadLenTHREAD/2,0,bottleHeightTHREAD/2+bottlePitchTHREAD/2]) cube([threadLenTHREAD,bottleODTHREAD,fatTHREAD]);
          }
        }
      }
      difference() {
        cylinder(r=50, h=30);
        cylinder(r=clearanceTHREAD+(bottleODTHREAD-0.2)/2,h=30);
      }
    }
  }
}

//drawBasicUnifyerTHREAD(80);

/*
module funnel() {
  translate([0,0,bottleHeight]) difference() {
    difference() {
      cylinder(r=holderOR, h=funnelWall);
      translate([0,0,-.1]) cylinder(r=bottleID/2, h=funnelWall+.2);
      }
    }
  translate([0,0,bottleHeight+funnelWall]) difference() {
    cylinder(r1=holderOR,r2=funnelOD, h=funnelOD-bottleOD);
    translate([0,0,-.1]) cylinder(r1=bottleID/2,r2=funnelOD-funnelWall, h=funnelOD-bottleOD+.2);
    }
  bottleHolder();
  }*/


/*if (partTHREAD=="threads") bottleHolderTHREAD();;
if (partTHREAD=="neck") bottleNeckTHREAD();
if (partTHREAD=="holder") bottleHolderTHREAD();
if (partTHREAD=="cap") drawTHREAD();*/

//difference() {
//drawTHREAD();
//substractTHREAD();
//}
