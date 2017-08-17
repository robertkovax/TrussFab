module drawMiddleBetweenTwoConnection(vectorArray,i1,i2,distance1,distance2,connectionWidth1,connectionWidth2,inwardsLength1,inwardsLength2) {
	
	// Connects an addon to it's (left) neighbor, and fills in the middle (including the area to [0,0]) ...
	// ... by creating a polygon from [0,0] to the lower right point of the right addon, following the outline of the right addon to the top left point of that addon (assuming a rectangular shape in this area), then connecting that to the top right point of the left addon, following this outline to the bottom left point of that addon and completing the polygon back at [0,0].
	
	/* // Direct input of ° in vectorArray[0]
	v1 = [sin(-vectorArray[i1][0]),cos(-vectorArray[i1][0])];
	v2 = [sin(-vectorArray[i2][0]),cos(-vectorArray[i2][0])];*/
	v1 = [vectorArray[i1][0],vectorArray[i1][1],0]/magnitude([vectorArray[i1][0],vectorArray[i1][1],0]);
	v2 = [vectorArray[i2][0],vectorArray[i2][1],0]/magnitude([vectorArray[i2][0],vectorArray[i2][1],0]);
	
	p1 = v1*distance1;
	p2 = v2*distance2;
	
	ov1 = [-v1[1],v1[0]];
	ov2 = [-v2[1],v2[0]];
	opl1 = p1+(ov1*connectionWidth1);
	opr1 = p1-(ov1*connectionWidth1);
	opl2 = p2+(ov2*connectionWidth2);
	opr2 = p2-(ov2*connectionWidth2);
	opld1 = opl1 - (v1*inwardsLength1);
	oprd1 = opr1 - (v1*inwardsLength1);
	opld2 = opl2 - (v2*inwardsLength2);
	oprd2 = opr2 - (v2*inwardsLength2);
    
	polygon(points=[[0,0],opld2,oprd2,opr2,opl1,opld1,oprd1]);
	/*if (i1==1) { // Debug output
		translate([p1[0],p1[1],0])
		color("Green")
		sphere(r=2);
		echo("v1",v1);
		echo("p1",p1);
		translate([p2[0],p2[1],0])
		color("Green")
		sphere(r=2);
		
		translate(opl1)
		color("Lime")
		sphere(r=2);
		translate(opr1)
		color("Violet")
		sphere(r=2);
		translate(opl2)
		color("Lime")
		sphere(r=2);
		translate(opr2)
		color("Violet")
		sphere(r=2);
		translate(opld1)
		color("Grey")
		sphere(r=2);
		translate(oprd1)
		color("Black")
		sphere(r=2);
		translate(opld2)
		color("Grey")
		sphere(r=2);
		translate(oprd2)
		color("Black")
		sphere(r=2);
	}*/
}

module addBaseFlat(vectorArray,connectorTypeArray,connectorDataDistance) {  // Drawing the middle

	for (i=[0:len(vectorArray)-1]) { // For every connection...
		i2=i; // choose addon ...
		i1=(i==0)?(len(vectorArray)-1):(i-1); // and its left neighbor...
		
		// Modularity: ----Adjust for new connector type----
		connectionWidth1 = (connectorTypeArray[i1] == "SNAPSCREW") ? (connectorDataArraySNAPSCREW[0]) : ((connectorTypeArray[i1] == "SNAPFIX") ? (connectorDataArraySNAPFIX[0]) : (0));
		connectionInwardsLength1 = (connectorTypeArray[i1] == "SNAPSCREW") ? (connectorDataArraySNAPSCREW[1]) : ((connectorTypeArray[i1] == "SNAPFIX") ? (connectorDataArraySNAPFIX[1]) : (0));
		connectionWidth2 = (connectorTypeArray[i2] == "SNAPSCREW") ? (connectorDataArraySNAPSCREW[0]) : ((connectorTypeArray[i2] == "SNAPFIX") ? (connectorDataArraySNAPFIX[0]) : (0));
		connectionInwardsLength2 = (connectorTypeArray[i2] == "SNAPSCREW") ? (connectorDataArraySNAPSCREW[1]) : ((connectorTypeArray[i2] == "SNAPFIX") ? (connectorDataArraySNAPFIX[1]) : (0));		
	
		// Calculating prolonging the connection to make bending for high variances in the third dimension possible
		/*
		prolongedConnectionLength1 = dataFileAddonParameterArray[i1][0]+getProlongLengthFromAngleFromVector(vectorArray[i1]);
		prolongedConnectionLength2 = dataFileAddonParameterArray[i2][0]+getProlongLengthFromAngleFromVector(vectorArray[i2]);
		*/
		// Alternatively expecting this has already been taken care of in SketchUp (to make sure the connectors also fit the model perfectly)
		prolongedConnectionLength1 = dataFileAddonParameterArray[i1][0];
		prolongedConnectionLength2 = dataFileAddonParameterArray[i2][0];
		
		distance1 = connectorDataDistance+prolongedConnectionLength1+heightSNAPFIX;
		distance2 = connectorDataDistance+prolongedConnectionLength2+heightSNAPFIX;
		
		
		/*effectiveInwardsLength1 = (prolongedConnectionLength1 > connectionInwardsLength1) ? (-(prolongedConnectionLength1-connectionInwardsLength1)) : (+connectionInwardsLength1-prolongedConnectionLength1);
		effectiveInwardsLength2 = (prolongedConnectionLength2 > connectionInwardsLength2) ? (-(prolongedConnectionLength2-connectionInwardsLength2)) : (+connectionInwardsLength2-prolongedConnectionLength2*/
		
		effectiveInwardsLength1 = connectionInwardsLength1;
		effectiveInwardsLength2 = connectionInwardsLength2;

		
		drawMiddleBetweenTwoConnection(vectorArray,i1,i2,distance1,distance2,connectionWidth1,connectionWidth2,effectiveInwardsLength1,effectiveInwardsLength2); // and fill the area between these neighbors and [0,0]
		
	}
}

module addAddonFlat(part,connectionVector,distance,parametersArray,connectionText) { // Adding an addon
	
	/*rotationAngle = connectionVector[0];
		rotate(rotationAngle,[0,0,1])
		translate([0,distance,0])*/
	
	vObject = [0,1,0];
	q = getQuatWithCrossproductCheck(vObject,[connectionVector[0],connectionVector[1],0]);
	qmat = quat_to_mat4(q);
	multmatrix(qmat) 
	
	// Calculating prolonging the connection to make bending for high variances in the third dimension possible
		// translate([0,distance+getProlongLengthFromAngleFromVector(connectionVector),0])
		// Alternatively expecting this has already been taken care of in SketchUp (to make sure the connectors also fit the model perfectly)
	translate([0,distance,0])
	
	if (part == "SNAPSCREW") {		// Snapscrew would need an update before using it. No negative translation, to make sure connectorDataDistance describes the length until the bottle actually starts, defined yet. (translate the piece upwards (in 2D) so that it basically starts at y=0 again; see Snapfix)
		drawSNAPSCREW();
	} 
	else if (part == "SNAPFIX") {
		translate([0,heightSNAPFIX,0])
		drawSNAPFIX();
	}
	
}

module substractAddonFlat(part,connectionVector,distance,parametersArray) { // Draw the holes of the addon, used to remove overlap after all addons are drawn.
	
	/*rotationAngle = connectionVector[0];
		rotate(rotationAngle,[0,0,1])
		translate([0,distance,0])*/
	
	vObject = [0,1,0];
	q = getQuatWithCrossproductCheck(vObject,[connectionVector[0],connectionVector[1],0]);
	qmat = quat_to_mat4(q);
	multmatrix(qmat) 
	
	// Calculating prolonging the connection to make bending for high variances in the third dimension possible
		// translate([0,distance+getProlongLengthFromAngleFromVector(connectionVector),0])
		// Alternatively expecting this has already been taken care of in SketchUp (to make sure the connectors also fit the model perfectly)
	translate([0,distance,0])
	
	if (part == "SNAPSCREW") {		
		xyz=0; // // Snapscrew would need an update before using it. No substraction method implemented yet.
	} 
	else if (part == "SNAPFIX") {	
		translate([0,heightSNAPFIX,0])
		substractSNAPFIX();
	}
	
}