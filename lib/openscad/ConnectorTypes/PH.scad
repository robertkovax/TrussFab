include <../Models/Pen.scad>

$fn=60;
part="PEN"; // Simple holder for pens. 
clearancePH=0.4; // tune to get the right 'fit' for your printer

// pen params

penODPH=6.65; // OD = Outer diameter
penHeightPH=11;


// holder params

holderHeightPH=penHeightPH+1;
holderODPH=penODPH+3.5;
holderORPH=holderODPH/2;

negativeHeightPH = 1; // The actual pen starts after 1mm. This parameter makes sure that the connectorDataDistance is always the exact distance to the connection piece.

connectorDataArrayPH = [holderODPH,negativeHeightPH]; // Addon data in an array to pass-through to other scripts as a single parameter

module penNeckPH() {
	 translate([0,0,-0.5]) cylinder(r=penODPH/2+clearancePH,h=penHeightPH+1);
}

module penHolderPH() {
	difference() {
		cylinder(r=holderORPH,h=penHeightPH);
		penNeckPH();
		}
	}

module drawPH() {
	
	translate([0,0,-negativeHeightPH])
	{
		translate([0,0,1]) 
		penHolderPH();
		cylinder(r=holderORPH, h=1);
	}
}
	
module substractPH() {
	translate([0,0,-negativeHeightPH])
	translate([0,0,1])
	drawPen();
	//drawPH();
}

//difference(){
//if (part=="PEN") drawPH();
//substractPH();
//}