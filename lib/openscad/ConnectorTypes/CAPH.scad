$fn=90;
part="CAPH"; // A holder for a bottle cap (tight fit, but should still be glued in) which then can hold a bottle.
clearanceCAPH=0.2; // tune to get the right 'fit' for your printer

// bottle params

bottleODCAPH=30.4; // OD = Outer diameter
bottleHeightCAPH=14.5;


// holder params

holderHeightCAPH=bottleHeightCAPH+1;
holderODCAPH=bottleODCAPH+6;
holderORCAPH=holderODCAPH/2;

negativeHeightCAPH = 1; // The actual pen starts after 1mm. This parameter makes sure that the connectorDataDistance is always the exact distance to the connection piece.

connectorDataArrayCAPH = [holderODCAPH,negativeHeightCAPH]; // Addon data in an array to pass-through to other scripts as a single parameter

module drawBottleNeckCAPH() {
	color("Blue")
	 translate([0,0,-0.5]) cylinder(r1=bottleODCAPH/2+clearanceCAPH,r2=bottleODCAPH/2+clearanceCAPH-0.2,h=bottleHeightCAPH+1);
}

module drawBottleHolderCAPH() {
	difference() {
		cylinder(r=holderORCAPH,h=bottleHeightCAPH);
		drawBottleNeckCAPH();
		}
	}

module drawCAPH() {
	translate([0,0,-negativeHeightCAPH])
	{
	translate([0,0,1]) 
	drawBottleHolderCAPH();
	cylinder(r=holderORCAPH, h=1);
	}
}
	
module substractCAPH() {
	translate([0,0,-negativeHeightCAPH])
	translate([0,0,1.5])
	drawBottleNeckCAPH();
	//drawCAPH();
}

//difference(){
//if (part=="CAPH") drawCAPH();
//substractCAPH();
//}
//drawBottleNeckCAPH() ;