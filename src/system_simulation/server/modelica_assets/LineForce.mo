model LineForce
  "General line force component with an optional point mass on the connection line"

  import Modelica.Mechanics.MultiBody.Types;
  extends Modelica.Mechanics.MultiBody.Interfaces.LineForceBase;
  Modelica.Mechanics.Translational.Interfaces.Flange_a flange_b
    "1-dim. translational flange (connect force of Translational library between flange_a and flange_b)"
    annotation (Placement(transformation(
        origin={60,100},
        extent={{-10,-10},{10,10}},
        rotation=90)));
  Modelica.Mechanics.Translational.Interfaces.Flange_b flange_a
    "1-dim. translational flange (connect force of Translational library between flange_a and flange_b)"
    annotation (Placement(transformation(
        origin={-60,100},
        extent={{-10,-10},{10,10}},
        rotation=90)));

  parameter Boolean animateLine=true
    "= true, if a line shape between frame_a and frame_b shall be visualized";
  parameter Boolean animateMass=true
    "= true, if point mass shall be visualized as sphere provided m > 0";
  parameter Modelica.SIunits.Mass m(min=0)=0
    "Mass of point mass on the connection line between the origin of frame_a and the origin of frame_b";
  parameter Real lengthFraction(
    unit="1",
    min=0,
    max=1) = 0.5
    "Location of point mass with respect to frame_a as a fraction of the distance from frame_a to frame_b";
  input Types.SpecularCoefficient specularCoefficient = world.defaultSpecularCoefficient
    "Reflection of ambient light (= 0: light is completely absorbed)"
    annotation (Dialog(tab="Animation", enable=animateLine or animateMass));
  parameter Types.ShapeType lineShapeType="cylinder"
    "Type of shape visualizing the line from frame_a to frame_b"
    annotation (Dialog(tab="Animation", group="if animateLine = true", enable=animateLine));
  input Modelica.SIunits.Length lineShapeWidth=world.defaultArrowDiameter "Width of shape"
    annotation (Dialog(tab="Animation", group="if animateLine = true", enable=animateLine));
  input Modelica.SIunits.Length lineShapeHeight=lineShapeWidth "Height of shape"
    annotation (Dialog(tab="Animation", group="if animateLine = true", enable=animateLine));
  parameter Types.ShapeExtra lineShapeExtra=0.0 "Extra parameter for shape"
    annotation (Dialog(tab="Animation", group="if animateLine = true", enable=animateLine));
  input Types.Color lineShapeColor=Modelica.Mechanics.MultiBody.Types.Defaults.SensorColor
    "Color of line shape"
    annotation (Dialog(colorSelector=true, tab="Animation", group="if animateLine = true", enable=animateLine));
  input Real massDiameter=world.defaultBodyDiameter
    "Diameter of point mass sphere"
    annotation (Dialog(tab="Animation", group="if animateMass = true", enable=animateMass));
  input Types.Color massColor=Modelica.Mechanics.MultiBody.Types.Defaults.BodyColor
    "Color of point mass"
    annotation (Dialog(colorSelector=true, tab="Animation", group="if animateMass = true", enable=animateMass));

  Real energy;
  Real pot_energy;
  Real kin_energy;

protected
  Modelica.SIunits.Force fa "Force from flange_a";
  Modelica.SIunits.Force fb "Force from flange_b";
  Modelica.SIunits.Position r_CM_0[3](each stateSelect=StateSelect.avoid)
    "Position vector from world frame to point mass, resolved in world frame";
  Modelica.SIunits.Velocity v_CM_0[3](each stateSelect=StateSelect.avoid)
    "First derivative of r_CM_0";
  Modelica.SIunits.Acceleration ag_CM_0[3] "der(v_CM_0) - gravityAcceleration";

  Modelica.Mechanics.MultiBody.Visualizers.Advanced.Shape lineShape(
    shapeType=lineShapeType,
    color=lineShapeColor,
    specularCoefficient=specularCoefficient,
    length=length,
    width=lineShapeWidth,
    height=lineShapeHeight,
    lengthDirection=e_rel_0,
    widthDirection=Modelica.Mechanics.MultiBody.Frames.resolve1(frame_a.R, {0,1,0}),
    extra=lineShapeExtra,
    r=frame_a.r_0) if world.enableAnimation and animateLine;

  Modelica.Mechanics.MultiBody.Visualizers.Advanced.Shape massShape(
    shapeType="sphere",
    color=massColor,
    specularCoefficient=specularCoefficient,
    length=massDiameter,
    width=massDiameter,
    height=massDiameter,
    lengthDirection=e_rel_0,
    widthDirection={0,1,0},
    r_shape=e_rel_0*(length*lengthFraction - massDiameter/2),
    r=frame_a.r_0) if world.enableAnimation and animateMass and m > 0;

equation
  flange_a.s = 0;
  flange_b.s = length;

  // Determine translational flange forces
  if cardinality(flange_a) > 0 and cardinality(flange_b) > 0 then
    fa = flange_a.f;
    fb = flange_b.f;
  elseif cardinality(flange_a) > 0 and cardinality(flange_b) == 0 then
    fa = flange_a.f;
    fb = -fa;
  elseif cardinality(flange_a) == 0 and cardinality(flange_b) > 0 then
    fa = -fb;
    fb = flange_b.f;
  else
    fa = 0;
    fb = 0;
  end if;

  /* Force and torque balance of point mass
   - Kinematics for center of mass CM of point mass including gravity
     r_CM_0 = frame_a.r0 + r_rel_CM_0;
     v_CM_0 = der(r_CM_0);
     ag_CM_0 = der(v_CM_0) - world.gravityAcceleration(r_CM_0);
   - Power balance for the connection line
     (f1=force on frame_a side, f2=force on frame_b side, h=lengthFraction)
     0 = f1*va - m*ag_CM*(va+(vb-va)*h) + f2*vb
       = (f1 - m*ag_CM*(1-h))*va + (f2 - m*ag_CM*h)*vb
     since va and vb are completely independent from other
     the parenthesis must vanish:
       f1 := m*ag_CM*(1-h)
       f2 := m*ag_CM*h
   - Force balance on frame_a and frame_b finally results in
       0 = frame_a.f + e_rel_a*fa - f1_a
       0 = frame_b.f + e_rel_b*fb - f2_b
     and therefore
       frame_a.f = -e_rel_a*fa + m*ag_CM_a*(1-h)
       frame_b.f = -e_rel_b*fb + m*ag_CM_b*h
*/
    r_CM_0 = frame_a.r_0 + r_rel_0*lengthFraction;
    v_CM_0 = der(r_CM_0);
    ag_CM_0 = der(v_CM_0) - world.gravityAcceleration(r_CM_0);
    frame_a.f = Modelica.Mechanics.MultiBody.Frames.resolve2(frame_a.R, (m*(1 - lengthFraction))*ag_CM_0 - e_rel_0*fa);
    frame_b.f = Modelica.Mechanics.MultiBody.Frames.resolve2(frame_b.R, (m*lengthFraction)*ag_CM_0 - e_rel_0*fb);

    pot_energy = r_CM_0[3] * m * 9.81;
    kin_energy = 0.5 * m * Modelica.Math.Vectors.length(v_CM_0)^2;
    energy = kin_energy + pot_energy;

end LineForce;
