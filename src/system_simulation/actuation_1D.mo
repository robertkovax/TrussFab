model actuation_1D
  Modelica.Mechanics.MultiBody.Joints.Prismatic prismatic(a(fixed = false, start = 0),s(fixed = true, start = 1), useAxisFlange = true, v(fixed = false, start = 0))  annotation(
    Placement(visible = true, transformation(origin = {-40, -8}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Modelica.Mechanics.MultiBody.Joints.Prismatic prismatic1(useAxisFlange = true)  annotation(
    Placement(visible = true, transformation(origin = {36, -8}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Modelica.Mechanics.MultiBody.Parts.PointMass pointMass1(m = 30, r_0(fixed = false, start = {0, 0, 2}))  annotation(
    Placement(visible = true, transformation(origin = {72, -8}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Modelica.Mechanics.Translational.Components.SpringDamper springDamper(c = 10000, d = 10, s_rel0 = 1, v_rel(fixed = false))  annotation(
    Placement(visible = true, transformation(origin = {-44, 34}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  inner Modelica.Mechanics.MultiBody.World world annotation(
    Placement(visible = true, transformation(origin = {-88, -6}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Modelica.Mechanics.MultiBody.Parts.PointMass pointMass(a_0(fixed = true),m = 1, r_0(fixed = false, start = {0, 0, 2}), v_0(fixed = true)) annotation(
    Placement(visible = true, transformation(origin = {-2, -8}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Modelica.Blocks.Sources.Sine sine(amplitude = 0.3, freqHz = 0.7, offset = 0.3, startTime = 3) annotation(
    Placement(visible = true, transformation(origin = {2, 44}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Modelica.Mechanics.Translational.Sources.Position position(exact = true) annotation(
    Placement(visible = true, transformation(origin = {34, 44}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
equation
  connect(prismatic1.frame_b, pointMass1.frame_a) annotation(
    Line(points = {{46, -8}, {74, -8}, {74, -8}, {72, -8}}, color = {95, 95, 95}));
  connect(prismatic.support, springDamper.flange_a) annotation(
    Line(points = {{-44, -2}, {-54, -2}, {-54, 34}}, color = {0, 127, 0}));
  connect(springDamper.flange_b, prismatic.axis) annotation(
    Line(points = {{-34, 34}, {-34, 13}, {-32, 13}, {-32, -2}}, color = {0, 127, 0}));
  connect(world.frame_b, prismatic.frame_a) annotation(
    Line(points = {{-78, -6}, {-64, -6}, {-64, -8}, {-50, -8}}));
  connect(prismatic.frame_b, pointMass.frame_a) annotation(
    Line(points = {{-30, -8}, {-2, -8}, {-2, -8}, {-2, -8}}, color = {95, 95, 95}));
  connect(pointMass.frame_a, prismatic1.frame_a) annotation(
    Line(points = {{-2, -8}, {30, -8}, {30, -8}, {26, -8}, {26, -8}}, color = {95, 95, 95}));
  connect(position.flange, prismatic1.axis) annotation(
    Line(points = {{44, 44}, {44, -2}}, color = {0, 127, 0}));
  connect(position.support, prismatic1.support) annotation(
    Line(points = {{34, 34}, {34, 16}, {32, 16}, {32, -2}}, color = {0, 127, 0}));
  connect(sine.y, position.s_ref) annotation(
    Line(points = {{13, 44}, {22, 44}}, color = {0, 0, 127}));
  annotation(
    uses(Modelica(version = "3.2.2")));
end actuation_1D;