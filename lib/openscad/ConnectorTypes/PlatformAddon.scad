part="STAND"; 

module drawSTAND(parameterArray=[0,"",6,30,8,60]) //It's just cylinders.
{
	poleHeight = parameterArray[2];
	poleWidth = parameterArray[3]/2;
	platformHeight = parameterArray[4];
	platformWidth = parameterArray[5]/2;
	cylinder(r=poleWidth, h=poleHeight);
	translate([0,0,poleHeight])
	cylinder(r1=poleWidth,r2=platformWidth, h=platformHeight-2);
	translate([0,0,poleHeight+platformHeight-2])
	cylinder(r=platformWidth,h=2);
}

module substractSTAND(parameterArray=[0,24.5,30,8,60]) 
{
	/*
	poleHeight = parameterArray[1];
	poleWidth = parameterArray[2]/2;
	platformHeight = parameterArray[3];
	platformWidth = parameterArray[4]/2;
	translate([0,0,poleHeight+platformHeight])
	color("Blue")
	cylinder(r=platformWidth,h=50);
	*/
}
	
//if (part=="STAND") drawSTAND();
//if (part=="STAND") substractSTAND();