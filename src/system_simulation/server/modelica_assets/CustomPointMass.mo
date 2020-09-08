model CustomPointMass
  "Rigid body where body rotation and inertia tensor is neglected (6 potential states)"

  import Modelica.Mechanics.MultiBody.Types;
  Modelica.Mechanics.MultiBody.Interfaces.Frame_a frame_a
    "Coordinate system fixed at center of mass point" annotation (Placement(
        transformation(extent={{-16,-16},{16,16}})));
  parameter Boolean animation=true
    "= true, if animation shall be enabled (show sphere)";
  parameter Modelica.SIunits.Mass m(min=0) "Mass of mass point";
  input Modelica.SIunits.Diameter sphereDiameter=world.defaultBodyDiameter
    "Diameter of sphere" annotation (Dialog(
      tab="Animation",
      group="if animation = true",
      enable=animation));
  input Types.Color sphereColor=Modelica.Mechanics.MultiBody.Types.Defaults.BodyColor
    "Color of sphere" annotation (Dialog(
      colorSelector=true,
      tab="Animation",
      group="if animation = true",
      enable=animation));
  input Types.SpecularCoefficient specularCoefficient=world.defaultSpecularCoefficient
    "Reflection of ambient light (= 0: light is completely absorbed)"
    annotation (Dialog(
      tab="Animation",
      group="if animation = true",
      enable=animation));
  parameter StateSelect stateSelect=StateSelect.avoid
    "Priority to use frame_a.r_0, v_0 (= der(frame_a.r_0)) as states"
    annotation (Dialog(tab="Advanced"));

  Modelica.SIunits.Position r_0[3](start={0,0,0}, each stateSelect=stateSelect)
    "Position vector from origin of world frame to origin of frame_a, resolved in world frame"
    annotation (Dialog(group="Initialization",showStartAttribute=true));
  Modelica.SIunits.Velocity v_0[3](start={0,0,0}, each stateSelect=stateSelect)
    "Absolute velocity of frame_a, resolved in world frame (= der(r_0))"
    annotation (Dialog(group="Initialization",showStartAttribute=true));
  Modelica.SIunits.Acceleration a_0[3](start={0,0,0})
    "Absolute acceleration of frame_a resolved in world frame (= der(v_0))"
    annotation (Dialog(group="Initialization",showStartAttribute=true));

  Real energy;
  Real pot_energy;
  Real kin_energy;
protected
  outer Modelica.Mechanics.MultiBody.World world;

  // Declarations for animation
  Modelica.Mechanics.MultiBody.Visualizers.Advanced.Shape sphere(
    shapeType="sphere",
    color=sphereColor,
    specularCoefficient=specularCoefficient,
    length=sphereDiameter,
    width=sphereDiameter,
    height=sphereDiameter,
    lengthDirection={1,0,0},
    widthDirection={0,1,0},
    r_shape=-{1,0,0}*sphereDiameter/2,
    r=frame_a.r_0,
    R=frame_a.R) if world.enableAnimation and animation;
equation
  // If any possible, do not use the connector as root
  Connections.potentialRoot(frame_a.R, 10000);
  frame_a.R = Modelica.Mechanics.MultiBody.Frames.nullRotation();

  // Newton equation: f = m*(a-g)
  r_0 = frame_a.r_0;
  v_0 = der(r_0);
  a_0 = der(v_0);
  frame_a.f = m*Modelica.Mechanics.MultiBody.Frames.resolve2(frame_a.R, a_0 - world.gravityAcceleration(
    r_0));
  pot_energy = r_0[3] * m * 9.81;
  kin_energy = 0.5 * m * Modelica.Math.Vectors.length(v_0)^2;
  energy = kin_energy + pot_energy;
end CustomPointMass;
