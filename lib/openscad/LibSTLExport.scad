// ********* Load general + BottleProject math functions *********
include <Util/maths.scad>
include <Util/text_on.scad>
// ********* Load all connector types modules *********
include <Modes/TubeMode.scad>
include <Modes/FlatMode.scad>
// ********* Load all connection modules *********
include <ConnectorTypes/THREAD.scad>
include <ConnectorTypes/SNAP.scad>
include <ConnectorTypes/PH.scad>
include <ConnectorTypes/PlatformAddon.scad>
include <ConnectorTypes/SNAPSCREW.scad>
include <ConnectorTypes/SNAPFIX.scad>
include <ConnectorTypes/BBSsmall.scad>
include <ConnectorTypes/BBSbig.scad>
//include <ConnectorTypes/PLUG.scad>
include <ConnectorTypes/HINGE.scad>
include <ConnectorTypes/STRONG.scad>
include <ConnectorTypes/PLUG.scad>
include <ConnectorTypes/HOLE.scad>
include <ConnectorTypes/PLUGHOLE.scad>
include <ConnectorTypes/PLUGPLANE.scad>


// ********* Script Setup *********

truth="true"; // Avoids infinite recursion

$fn=60;

qmatDown = quat([1,1,1],0);

module drawHub(vectorArray, addonParameterArray, connectorTypeArray){
    if (mode == "Tube"){
        drawTubeConnectors(vectorArray, addonParameterArray, connectorTypeArray);
    } else if (mode =="Flat"){
        drawFlatConnectors(vectorArray, addonParameterArray, connectorTypeArray);
    }

}

// ********* Construction of workpiece *********
module drawTubeConnectors(vectorArray, addonParameterArray, connectorTypeArray){
    difference() {
        union() {
            addBaseTube(); //Creates the center sphere

            for (i=[0:len(vectorArray)-1]) { //For all connections ...
                prolongedConnectionLength = addonParameterArray[i][0];
                addAddonTube(vectorArray[i],connectorTypeArray[i],connectorDataDistance+prolongedConnectionLength,addonParameterArray[i]); // ... add the addon at the end of the tube
                    // Modularity: ----Adjust for new connector types----
                widthOfExtrusionTube = getExtrusionTubeWidth(connectorTypeArray[i], addonParameterArray,i);

                connectorDataDistanceLengthSubstractionFromConnector = getSubstractionLength(connectorTypeArray[i]);

                connectionID = (connectorTypeArray[i]=="STAND") ? (addonParameterArray[i][5]) : (addonParameterArray[i][1]);
                connectionText = (((connectionID == undef) || (connectionID == " ")) ? (hubID) : (str(hubID,".",connectionID))); // Final Connection-ID is compromised of hub-id and partner hub-id

                //connectionText= " ";
                addExtrusionTube(vectorArray[i],connectorDataDistance+prolongedConnectionLength-connectorDataDistanceLengthSubstractionFromConnector,widthOfExtrusionTube,tubeThinning,connectionText,connectorTypeArray[i]); //... and add the tube connecting the center and the addon
            }
        }
        if (safetyFlag == true) { // remove overlapping material that would make the connection unuseable (e.g. make room so that the bottle can fit)
                // Often necessary if there are small angles between connections, and/or a very small center size was chosen.
            for (i=[0:len(vectorArray)-1]) {
                prolongedConnectionLength = addonParameterArray[i][0];
                addSubstractionTube(vectorArray[i],connectorTypeArray[i],connectorDataDistance+prolongedConnectionLength,addonParameterArray[i]);
            }
        }
        for (i=[0:len(vectorArray)-1]) { // For all connections, create a hole within the tube (e.g. to insert the wedge into the SnapPush connections, or to have a screw hole for bottle bottom connections)

            prolongedConnectionLength = addonParameterArray[i][0];
             // 30 mm is long enough to go through all common connections, plus size of hub, or use user specified value (e.g. to avoid putting a hole through a thread or so)
            holeLengthForSNAP =
                (connectorTypeArray[i] == "PLUG") ? (addonParameterArray[i][0]) :
                ((connectorTypeArray[i] == "STAND") ? (addonParameterArray[i][0]+addonParameterArray[i][2]+addonParameterArray[i][4]+16) :
                ((connectorTypeArray[i] == "PLUGHOLE") ? (addonParameterArray[i][0]) :
                ((connectorTypeArray[i] == "PLUGPLANE") ? (addonParameterArray[i][0]) :
                ((connectorTypeArray[i] == "HOLE") ? (addonParameterArray[i][0]) :
                ((addonParameterArray[i][3] == undef) ? (40+30+2*connectorDataDistance) :
                (addonParameterArray[i][3]))))));

            echo(holeLength=holeLengthForSNAP);
            addHolesTube(vectorArray[i],connectorTypeArray[i],connectorDataDistance+prolongedConnectionLength+50,holeLengthForSNAP,addonParameterArray[i]);
        }
        for (i=[0:len(vectorArray)-1]) { // For all connections...
            prolongedConnectionLength = addonParameterArray[i][0];
            holeDiameter = (connectorTypeArray[i]=="STAND") ? (addonParameterArray[i][6]) :
                (addonParameterArray[i][2]);
            widthOfExtrusionTube = getExtrusionTubeWidth(connectorTypeArray[i], addonParameterArray,i);
            addStringHolesTube(vectorArray[i],connectorDataDistance+prolongedConnectionLength,widthOfExtrusionTube,  tubeThinning,holeDiameter); // ... add a hole in the tube to fix a string onto the connector later
        }
    }
}

//addSafetyTube(dataFileVectorArray[i], dataFileAddonParameterArray[i],connectorTypeArray[i]);
module addSafetyTube(vector,addonArray,connector){
    prolongedConnectionLength = addonArray[0];
    addSubstractionTube(vector,connector,connectorDataDistance+prolongedConnectionLength,addonArray);
}
function getExtrusionTubeWidth(connectorType, addonParameterArray,i)=
            (connectorType=="SNAP") ? (connectorDataArraySNAP[0]) :
            ((connectorType=="THREAD") ? (connectorDataArrayTHREAD[0]) :
            ((connectorType=="PH") ? (connectorDataArrayPH[0]) :
            ((connectorType=="BBSsmall") ? (connectorDataArrayBBSsmall[0]) :
            ((connectorType=="BBSbig") ? (connectorDataArrayBBSbig[0]) :
            ((connectorType=="PLUG") ? (connectorDataArrayPLUG[0]) :
            ((connectorType=="PLUGPLANE") ? (connectorDataArrayPLUG[0]) :
            ((connectorType=="STAND") ? (addonParameterArray[i][3]) : //Stand does not have a fixed width, always user defined
            ((connectorType=="HINGEF") ? (connectorDataArrayHingeF[0]) :
            ((connectorType=="HINGEM") ? (connectorDataArrayHinge[0]) :
            ((connectorType=="STRONG") ? (connectorDataArrayStrong[0]) :
            ((connectorType=="HOLE") ? (connectorDataArrayHOLE[0]) :
            ((connectorType=="PLUGHOLE") ? (connectorDataArrayPLUGHOLE[0]) :
            (0)))))))))))))
;

function getSubstractionLength(connectorType)=
                (connectorTypeArray[i]=="SNAP") ? (connectorDataArraySNAP[1]) :
                ((connectorTypeArray[i]=="THREAD") ? (connectorDataArrayTHREAD[1]) :
                ((connectorTypeArray[i]=="PH") ? (connectorDataArrayPH[1]) :
                ((connectorTypeArray[i]=="BBSsmall") ? (connectorDataArrayBBSsmall[1]) :
                ((connectorTypeArray[i]=="BBSbig") ? (connectorDataArrayBBSbig[1]) :
                ((connectorTypeArray[i]=="PLUG") ? (connectorDataArrayPLUG[1]) :
                ((connectorTypeArray[i]=="PLUGPLANE") ? (connectorDataArrayPLUG[1]) :
                ((connectorTypeArray[i]=="HOLE") ? (connectorDataArrayHOLE[1]) :
                ((connectorTypeArray[i]=="PLUGHOLE") ? (connectorDataArrayPLUGHOLE[1]) :
                ((connectorTypeArray[i]=="STAND") ? (0) :
              ((connectorType=="HINGEF") ? (connectorDataArrayHingeF[1]) :
              ((connectorType=="HINGEM") ? (connectorDataArrayHinge[1]) :
                ((connectorType=="STRONG") ? (connectorDataArrayStrong[1]) :

              (0)))))))))))))
;

module drawFlatConnectors(vectorArray, addonParameterArray, connectorTypeArray){
  scale([2.83468,2.83468,2.83468]) // Magic number necessary to export .SVG since OpenSCAD does not support SVG export in specific units (i.e. millimeters) yet.
  difference() {
    union(){
      //color("Green")
      //circle(r=connectorDataDistance);
      addBaseFlat(vectorArray,connectorTypeArray,connectorDataDistance); //Create middle area
      for (i=[0:len(vectorArray)-1]) { // Add all addons specified in data file
        prolongedConnectionLength = addonParameterArray[i][0];
        color("Red")
        addAddonFlat(connectorTypeArray[i],vectorArray[i],connectorDataDistance+prolongedConnectionLength,addonParameterArray[i]);
      }
    }
    for (i=[0:len(vectorArray)-1]) { // Add ID's for cutting (== removing something from the 2D polygons) and remove where the connection pieces (and utility holes like the hole for a wedge) will be in case of overlapping.
      prolongedConnectionLength = addonParameterArray[i][0];

      connectionID = (connectorTypeArray[i]=="STAND") ? ( addonParameterArray[i][5]) : // There actually should ne be stands in this mode. Could be removed, but might result in a script error with slightly faulty user input then.
        (addonParameterArray[i][1]);
      connectionText = (((connectionID == undef) || (connectionID == " ")) ? (hubID) : connectionID);
            //connectionText = (((connectionID == undef) || (connectionID == " ")) ? (hubID) : (str(hubID,".",connectionID)));

      substractAddonFlat(connectorTypeArray[i],vectorArray[i],connectorDataDistance+prolongedConnectionLength,addonParameterArray[i]); // Creates the space necessary for wedges etc. and the connection pieces.

      vObject = [0,1,0];
      q = getQuatWithCrossproductCheck(vObject,[vectorArray[i][0],vectorArray[i][1],0]); //Rotation in 2D, since we still want to have a flat hub.
      qmat = quat_to_mat4(q);
      multmatrix(qmat)

      translate([-5.5,connectorDataDistance+prolongedConnectionLength-(len(connectionText))*1.3-0.2,0]) // working magic value for placement of the ID's, adjusted also for use with the connectors that use a wedge.
      rotate(90,[0,0,1])
      color("Blue")
      text(connectionText,size = 3,halign="center",valign="center",font = "Liberation Sans",spacing=1.3); // ID's for connections
    }
    rotate(45,[0,0,1])
    color("Blue")
    text(hubID,size = 3,halign="center",valign="center",font = "Liberation Sans",spacing=1.3); // The hub-ID in the middle.
  }
}

