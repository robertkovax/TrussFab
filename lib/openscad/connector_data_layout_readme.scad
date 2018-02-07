hubID = "12"; // The ID of the connector. Will e printed on the sides of the connections in the Tube mode if no separate ID for that connection is specified, or in the middle of the connector in Flat mode.

mode = "Tube"; // Set general mode. E.g. Tube mode, Ball mode, Flat mode (2D)...

safetyFlag = false; // Set whether overlapping of addon parts shall be fixed by the script. Computes the space where bottles, pens, etc. would be and substracts it from the model. Takes a lot of computation time and can break preview functionality due to number of objects and broken openSCAD difference() and preview functionality

connectorDataDistance = 45; // Main value how far the addons are from the center of the connector

tubeThinning = 0.95; // Shrink tubes (in TubeMode) in diameter in the middle to this percentage (range: 0-1)

useFixedCenterSize = false; // If true, use hubCenterSize, otherwise use "dynamic" value (e.g. outer diameter of widest used addon)
hubCenterSize = 0; // Diameter

groundConnector = false; // Deprecated, use [0,0,-1] vector with stand addon instead

printVectorInteger = 4; // Chose one vector that will be pointed down to give printing a flat surface, preferably a stand addon, or if not available a thread addon. Counting starts at 0.

dataFileVectorArray = [ // Storage for all vectors (different addons, standing platforms, etc.) The parameters are mapped to these vectors through ordering. E.g. dataFileVectorArray[i] is further parametrized through dataFileAddonParameterArray[i] and connectorTypeArray[i] with i >= 0
[-6.29921245489015, 3.630456486078687, -10.282048380120928],
[-6.2973654548901505, -10.909483513921312, 0.006051619879071879],
[-12.60027645489015, 0.001066486078687312, 0.006051619879071879],
[3.5451098492345068e-06, -7.280093513921313, -10.282048380120928],
[0,0,1]
];

dataFileAddonParameterArray = [ // Parameters for all addons; First parameter = extra distance of the addon from the center of the connector in mm,
  // Second (6. for stand addons) parameter = specific connection ID. Use "undef" (without parenthesis) to use the hubID for this connection instead. Use " " (whitespace-String) for no text.
  // Third (7. for stand addons) parameter = diameter for a hole for a string that can be stretched through or alongside the bottle connection to strengthen it against tensile forces
    // Fourth (Not necessary for stand addons yet) parameter = length of hole, e.g. for SnapPush wedge. If this is undef, a value long enough to penetrate the whole connector+connections is used instead.
[0,undef,0],
[15,"conn_2",5],
[0," ",10],
[0,"conn_4",0],
//[x,30,y,60] //Proper length for small bottles from centerpoint = (connectorDataDistance+x+y) = 32.5mm radius, small bottle diameter = 65mm
// big bottle diameter = 81mm --> 40.5mm radius total
[0,40.5-(connectorDataDistance+8),30,8,60,undef,0] // Four (4) additional parameters for stand: [Tube length in mm, Tube diameter, Flat top extension length (2mm straight, then it narrows to match the tube-width), Flat top diameter]
// These four parameters have to be defined BEFORE the connectionID and the hole diameter, but after the extra distance
// for Hinge joint connectors the fourth parameter is the angle of the axis
// connecting counterparts need to have the same value
[0, "HingeM",0 , 90],
[0, "HingeF",0 , 90],
// for "AXLE" the fourth parameter is the radius of the hole
[0, "AXLE",0 , 8.5],
];

connectorTypeArray = [ // Which addon type to use
// AXLE = creates a hole for an axle
// HINGEF = hinge joint connector, connects to HINGEM
// HINGEM = hinge joint connector, connects to HINGEM
// STRONG = strong connector (for Bottles, uses additional set of cuffs)
// CAPH = CapHolder (for Bottles)
// PH = PenHolder
// THREAD (for Bottles)
// SNAP = SnapPush (for Bottles)
// STAND = Holding platform to hold the model off the ground, or to hold a flat surface etc.
// BBSsmall = Bottle Bottom Screw Holder (Small bottles)
// BBSbig = Bottle Bottom Screw Holder
// SNAPFIX = 2D connctor (for Bottles)
// SNAPSCREW = 2D connctor (for Bottles) //not optimized
/
"HINGEF",
"HINGEM",
"STRONG",
"CAPH",
"PH",
"THREAD",
"SNAP",
"STAND",
"BBSsmall",
"BBSbig",
"SNAPFIX",
"SNAPSCREW"

];
