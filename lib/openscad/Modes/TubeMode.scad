module addBaseTube() { 
	if (useFixedCenterSize)	{
		sphere(r=hubCenterSize/2);
	} else if (search(["HINGEF"],connectorTypeArray)!=[[]]) {
		sphere(r=holderODHinge);
	} else if (search(["HINGEM"],connectorTypeArray)!=[[]]) {
		sphere(r=holderODHinge);
	} else if (search(["THREAD"],connectorTypeArray)!=[[]]) { 
		sphere(r=holderODTHREAD/2);
	} else if (search(["STRONG"],connectorTypeArray)!=[[]]) {
		sphere(r=holderODSTRONG/2);
	} else if (search(["SNAP"],connectorTypeArray)!=[[]]) {
		sphere(r=holderODSNAP/2);
    } else if (search(["PLUG"],connectorTypeArray)!=[[]]) { //Check from big to small
		sphere(r=tubeODPLUG/2);
    } else if (search(["PLUGPLANE"],connectorTypeArray)!=[[]]) {
        sphere(r=tubeODPLUGPLANE/2);
    } else if (search(["PLUGHOLE"],connectorTypeArray)!=[[]]) {
        sphere(r=tubeODPLUGHOLE/2);
	} else if (search(["PH"],connectorTypeArray)!=[[]]) {
		sphere(r=holderODPH);
	} 
	// Modularity: ----Adjust for new connector type----
	
	// TODO: Wait for OpenSCAD update or find inofficial addon to make the fully automated search for the biggest diameter of connector types possible.	
}

module addAddonTube(vStart,part,distance,parametersArray) { // Adding the addons (e.g. bottle holders etc.)
    vEnd = [0,0,0];

    v = vStart-vEnd;

    vObject = [0,0,1];
    
    q = getQuatWithCrossproductCheck(vObject,v);
    qmat = quat_to_mat4(q);
    
	multmatrix(qmatDown) // Printing adjustment rotation 
	translate((vStart/magnitude(vStart))*distance) // how far away from the center to put the connection
	multmatrix(qmat) // rotation for connection vector
	if (part == "SNAP") {
        //cylinder(r=10.2,h=42,center=true);
		drawSNAP();
	}
	else if (part == "PH") {
		drawPH();
	}
	else if (part == "THREAD") {
		drawTHREAD();
	}
	else if (part == "BBSbig") {
		drawBBSbig();
	}
	else if (part == "BBSsmall") {
		drawBBSsmall();
	}
	else if (part == "PLUG") {
		drawPLUG();
	}
	else if (part == "PLUGPLANE") {
		drawPLUGPLANE();
	}
	else if (part == "PLUGHOLE") {
		drawPLUGHOLE();
	}
	else if (part == "STAND") {
		drawSTAND(parametersArray); //Stand has user defined size
	}
	else if (part == "HINGEF") {
		drawHingeF(parametersArray[3],parametersArray[0]);  //custom angle
	}
	else if (part == "HINGEM") {
		drawHingeM(parametersArray[3],parametersArray[0]); //custom angle
	}
	else if (part == "STRONG") {
		drawStrong();
	}
    else if (part == "HOLE") {
        drawHole();
    }
}

module addSubstractionTube(vStart,part,distance,parametersArray) { // Remove parts to counter overlapping. Optional, used when safetyFlag = true.
    
	vEnd = [0,0,0];

    v = vStart-vEnd;

    vObject = [0,0,1];
    
    q = getQuatWithCrossproductCheck(vObject,v);
    qmat = quat_to_mat4(q);
	
	multmatrix(qmatDown)
	translate((vStart/magnitude(vStart))*distance)
	multmatrix(qmat)
	if (part == "SNAP") {
		substractSNAP();
	}
	else if (part == "PH") {
		substractPH();
	}
	else if (part == "THREAD") {
		substractTHREAD();
	}
	else if (part == "BBSbig") {
		substractBBSbig();
	}
	else if (part == "BBSsmall") {
		substractBBSsmall();
	}
	else if (part == "PLUG") {
		substractPLUG();
	}
    else if (part == "PLUGPLANE") {
        substractPLUGPLANE();
    }
    else if (part == "PLUGHOLE") {
        substractPLUGHOLE();
    }
	else if (part == "STAND") {
		substractSTAND(parametersArray);
	}

    
	
    /*vEnd = [0,0,0];

    v = vStart-vEnd;

    vObject = [0,0,1];

    q = getQuatWithCrossproductCheck(vObject,v);
    qmat = quat_to_mat4(q);
    multmatrix(qmatDown)
    translate(((vStart/magnitude(vStart))*(distance+0.2)))
    multmatrix(qmat)
    cylinder(r=TubeWidth/2, h=50);*/

}

module addHolesTube(vStart,part,distance,holeLength,paramArray) { // Always used, creates holes to insert plug/wedges for snap push connectors, or "pre-drilled" holes for the screws of bottle bottoms.
    
	vEnd = [0,0,0];

    v = vStart-vEnd;

    vObject = [0,0,1];
    
    q = getQuatWithCrossproductCheck(vObject,v);
    qmat = quat_to_mat4(q);
	
	distanceWithPadding = distance+0.2;
	
    multmatrix(qmatDown)
    translate((vStart/magnitude(vStart))*distanceWithPadding)
    multmatrix(qmat)
    if (part == "SNAP") {
		holeSNAP(holeLength);
	}
    else if (part == "PLUGHOLE") {
        holePLUGHOLE(holeLength, 0);
    }
    else if (part == "PLUGPLANE") {
        holePLUGPLANE(holeLength, 0);
    }
	else if (part == "HOLE") {
        holeHOLE(holeLength, 0);
	}
	else if (part == "STAND") {
       // holePLUG(holeLength, 20);
	}
	else if (part == "BBSsmall") { 
		holeBBSsmall();
	}
	else if (part == "BBSbig") { 
		holeBBSbig();
	}
    if (part == "AXLE") {
		cylinder(r=paramArray[4],h=holeLength,center=true);
	}
}

module addExtrusionTube(vStart,distance,widthOfExtrusionTube,thinning,hubID, connectorType) { // Adds the tube connecting the addon and the center of the hub.
    v = vStart;

    vObject = [0,0,-1];
    
    qv = getQuatWithCrossproductCheck(vObject,v);
    qmatv = quat_to_mat4(qv);
	
    distanceWithPadding = distance+0.2;
    
	textSize = 5.5*(widthOfExtrusionTube/20);


	//difference(){	
    multmatrix(qmatDown)
    translate((vStart/magnitude(vStart))*(distanceWithPadding)) 
    multmatrix(qmatv)
	{
		color("Blue")
		
		rotate_extrude(convexity=10)
		// polygon instead of a simple cylinder to make tube thinning possible (saves material by making the tube thinner in the middle. (only suitable for connections that don't have to endure too much force)
		polygon( points=[[0,0],[widthOfExtrusionTube/2,0],[widthOfExtrusionTube/2,0.2],[(widthOfExtrusionTube/2)*thinning,((distanceWithPadding)/10*1.5)],[(widthOfExtrusionTube/2)*thinning,(distanceWithPadding)],[(widthOfExtrusionTube/2)*thinning,(distanceWithPadding)/10*5.5],[widthOfExtrusionTube/2,(distanceWithPadding)],[0,(distanceWithPadding)]]);
		
        echo(connectorType);
        if (connectorType == "PLUG"){
            translate([0,0,6])
            rotate(180,[1,0,0]) // The connection-ID's are added here on the sides of the tubes.
            {
                text_on_cylinder(t=hubID,locn_vec=[0,0,-5],r=(widthOfExtrusionTube/2),h=1,eastwest=90,direction="ltr",size=textSize);
                //text_on_cylinder(t=hubID,locn_vec=[0,0,-5],r=(widthOfExtrusionTube/2),h=1,eastwest=270,direction="ltr",size=textSize);
            }
        }
        else if (connectorType == "PLUGHOLE"){
            translate([0,0,6])
            rotate(180,[1,0,0]) // The connection-ID's are added here on the sides of the tubes.
            {
                text_on_cylinder(t=hubID,locn_vec=[0,0,-5],r=(widthOfExtrusionTube/2),h=1,eastwest=90,direction="ltr",size=textSize);
                //text_on_cylinder(t=hubID,locn_vec=[0,0,-5],r=(widthOfExtrusionTube/2),h=1,eastwest=270,direction="ltr",size=textSize);
            }
        }
        else if (connectorType == "PLUGPLANE"){
            translate([0,0,6])
            rotate(180,[1,0,0]) // The connection-ID's are added here on the sides of the tubes.
            {
                text_on_cylinder(t=hubID,locn_vec=[0,0,-5],r=(widthOfExtrusionTube/2),h=1,eastwest=90,direction="ltr",size=textSize);
                //text_on_cylinder(t=hubID,locn_vec=[0,0,-5],r=(widthOfExtrusionTube/2),h=1,eastwest=270,direction="ltr",size=textSize);
            }
        }
        else
        {
            rotate(180,[1,0,0]) // The connection-ID's are added here on the sides of the tubes.
            {
                text_on_cylinder(t=hubID,locn_vec=[0,0,-5],r=(widthOfExtrusionTube/2),h=1,eastwest=90,direction="ltr",size=textSize);
                //text_on_cylinder(t=hubID,locn_vec=[0,0,-5],r=(widthOfExtrusionTube/2),h=1,eastwest=270,direction="ltr",size=textSize);
            }
        }
    }
}

module addStringHolesTube(vStart,distance,widthOfExtrusionTube,thinning,holeDiameter) { // Simple holes in the tubes e.g. to attach a string in addition to the usual connection piece. (e.g. add a steel line alongside the bottles to help with tensile forces)
    v = vStart;

    vObject = [0,0,-1];
    
    qv = getQuatWithCrossproductCheck(vObject,v);
    qmatv = quat_to_mat4(qv);
	
    distanceWithPadding = distance+0.2;
		
    multmatrix(qmatDown)
    translate((vStart/magnitude(vStart))*((distanceWithPadding)*0.85-holeDiameter/2)) 
    multmatrix(qmatv)
	translate([0,((widthOfExtrusionTube)*thinning)/2,0])
	rotate(90,[1,0,0])
	{
		color("Red")
		
		cylinder(r=holeDiameter/2,h=(widthOfExtrusionTube)*thinning);
		//polygon( points=[[0,0],[widthOfExtrusionTube/2,0],[widthOfExtrusionTube/2,0.2],[(widthOfExtrusionTube/2)*thinning,((distanceWithPadding)/10*1.5)],[(widthOfExtrusionTube/2)*thinning,(distanceWithPadding)],[(widthOfExtrusionTube/2)*thinning,(distanceWithPadding)/10*5.5],[widthOfExtrusionTube/2,(distanceWithPadding)],[0,(distanceWithPadding)]]);
    }
}