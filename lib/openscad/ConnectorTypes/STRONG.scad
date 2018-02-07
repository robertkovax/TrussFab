include <../Util/maths.scad>
include <../Models/Bottle.scad>


part="STRONG";

//$fn=300;

height=30;
radius=10.2;
clampUpperOffset=0;
holeRadius=4;
clampRadius = 22;
clampRadiusInner = 14.5;
connectorDiskRadius = radius + 3.75;
cutoutHeight=9.25;

holderODSTRONG = connectorDiskRadius*2; //radius*2-1;
washerHeightStrong =6; // bottom plate/washer height
connectorDataArrayStrong = [holderODSTRONG, washerHeightStrong];

distance = 10; //distance to baseTube

module drawStrong() {
  //upper disk, bottle neck rests here
  rotate([0,180,0])
  cylinder(r=connectorDiskRadius,h=3.10,center=false);

  translate([0,0,height/2-25]){
    //middle cylinder, goes into bottle neck
    cylinder(r=radius,h=height/2+15,center=false);
  }
}

module drawClampHalf(){
  difference(){
    //outer mantle
    union(){
      cylinder(r1=clampRadius-1,r2=clampRadius,h=(height+clampUpperOffset)/2+1.5,center=false);
      //outer mantle
      rotate([180,0,0])
      cylinder(r1=clampRadius-3,r2=connectorDiskRadius+2,h=height+clampUpperOffset-15+.5,center=false);
    }
    //inner room for bottle neck
    color("green")
    translate([0,0,2])
    cylinder(r=clampRadiusInner,h=height,center=true);

    color("green")
    translate([0,0,-15])
    cylinder(r=holderODSTRONG/2+1,h=5,center=true);

    //space for bottle neck disk
    color("red")
    translate([0,0,12])
    cylinder(r=bottleNeckDiscRadius+.5,h=3.5,center=true);

    //space for connector disk
    color("red")
    translate([0,0,-12])
    cylinder(r=connectorDiskRadius+.5,h=3.5,center=true);

    //cutouts for tightener
    cutoutHeight=9.25;
    translate([0,0,cutoutHeight/2-1])
    drawCutout();

    //cut in two pieces
    //*
    color("red")
    translate([-clampRadius,-.5,-(height + 5)/2])
    cube(size =[clampRadius*2,clampRadius+.5,height+5], center= false);
    //*/
  }
}

module drawClamp(){
  drawClampHalf();
  rotate([0,0,180])
  drawClampHalf();
}

module drawCutout(){
  color("blue")
  render(){
    difference(){
      cylinder(r=clampRadius, h=cutoutHeight,center=true);
      cylinder(r=clampRadius-5, h=cutoutHeight,center=true);
    }
  }
}
/*
translate([0,0,-height/2 +5])
{
drawStrong();

%drawBottle();
    }
render()
drawClampHalf();
*/
