model actuation
  Modelica.Mechanics.MultiBody.Parts.PointMass pointMass(m = 5) annotation(
    Placement(visible = true, transformation(origin = {94, 26}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Modelica.Blocks.Sources.Sine sine(amplitude = 0.2, freqHz = 0.5, startTime = 5) annotation(
    Placement(visible = true, transformation(origin = {-22, 44}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Modelica.Mechanics.MultiBody.Joints.Prismatic prismatic(n = {0, 0, 1}) annotation(
    Placement(visible = true, transformation(origin = {72, 30}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Modelica.Mechanics.Translational.Sources.Position position(exact = true) annotation(
    Placement(visible = true, transformation(origin = {24, 44}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
equation
  connect(prismatic.frame_b, pointMass.frame_a) annotation(
    Line(points = {{82, 30}, {94, 30}, {94, 26}, {94, 26}}));
  connect(position.support, prismatic.support) annotation(
    Line(points = {{24, 34}, {68, 34}, {68, 36}, {68, 36}}, color = {0, 127, 0}));
  connect(sine.y, position.s_ref) annotation(
    Line(points = {{-10, 44}, {10, 44}, {10, 44}, {12, 44}}, color = {0, 0, 127}));
  connect(position.flange, prismatic.axis) annotation(
    Line(points = {{34, 44}, {80, 44}, {80, 36}, {80, 36}, {80, 36}}, color = {0, 127, 0}));
  annotation(
    uses(Modelica(version = "3.2.2")));
end actuation;