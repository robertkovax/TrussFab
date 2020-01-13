model threeTetrasTwoSprings
  parameter Real N1[3] = {0.0, 0.0, 0.0};
  parameter Real N2[3] = {0.6692815035095565, 0.0, 0.0140};
  parameter Real N3[3] = {0.3346407517547786, 0.5796147843223197, 0.0140};
  parameter Real N4[3] = {0.3346407517547786, 0.19320492810743977, 0.5604660592937206};
  parameter Real N5[3] = {0.89237, 0.51521, 0.37831};
  parameter Real N6[3] = {0.92955, -0.10733, 0.62118};
  inner Modelica.Mechanics.MultiBody.World world(n = {0, 0, -1})  annotation(
    Placement(visible = true, transformation(origin = {-78, 18}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Modelica.Mechanics.MultiBody.Forces.SpringDamperParallel springDamperParallel(c = 500, d = 1, s_unstretched = 0.5)  annotation(
    Placement(visible = true, transformation(origin = {-26, 18}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Modelica.Mechanics.MultiBody.Parts.Fixed fixed(r = N2 + (N3 - N2) / 2)  annotation(
    Placement(visible = true, transformation(origin = {14, -86}, extent = {{-10, -10}, {10, 10}}, rotation = 90)));
  Modelica.Mechanics.MultiBody.Parts.BodyCylinder bodyCylinder(r = N4 - (N2 + (N3 - N2) / 2), r_0(fixed = false))  annotation(
    Placement(visible = true, transformation(origin = {76, -48}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Modelica.Mechanics.MultiBody.Joints.Revolute revolute(a(fixed = false), n = N3 - N2, phi(fixed = false), w(fixed = false))  annotation(
    Placement(visible = true, transformation(origin = {34, -48}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Modelica.Mechanics.MultiBody.Joints.Revolute revolute1(a(fixed = false), n = N5 - N2, phi(fixed = false, start = 0.523599), w(fixed = false)) annotation(
    Placement(visible = true, transformation(origin = {76, -88}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Modelica.Mechanics.MultiBody.Parts.BodyCylinder bodyCylinder1(r = N6 - (N2 + (N5 - N2) / 2), r_0(fixed = false)) annotation(
    Placement(visible = true, transformation(origin = {118, -88}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Modelica.Mechanics.MultiBody.Parts.FixedTranslation fixedTranslation(r = N2 - N4 + (N5 - N2) / 2)  annotation(
    Placement(visible = true, transformation(origin = {132, -48}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Modelica.Mechanics.MultiBody.Forces.SpringDamperParallel springDamperParallel1(c = 300, d = 1, s_unstretched = 0.5) annotation(
    Placement(visible = true, transformation(origin = {152, 18}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Modelica.Mechanics.MultiBody.Parts.PointMass n6mass(m = 15)  annotation(
    Placement(visible = true, transformation(origin = {150, -110}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Modelica.Mechanics.MultiBody.Parts.PointMass n4mass(m = 0.1) annotation(
    Placement(visible = true, transformation(origin = {152, -70}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
equation
  connect(world.frame_b, springDamperParallel.frame_a) annotation(
    Line(points = {{-68, 18}, {-36, 18}}, color = {95, 95, 95}));
  connect(revolute.frame_a, fixed.frame_b) annotation(
    Line(points = {{24, -48}, {24, -54.5}, {16, -54.5}, {16, -49}, {14, -49}, {14, -76}}, color = {95, 95, 95}));
  connect(revolute.frame_b, bodyCylinder.frame_a) annotation(
    Line(points = {{44, -48}, {66, -48}}));
  connect(bodyCylinder.frame_b, springDamperParallel.frame_b) annotation(
    Line(points = {{86, -48}, {110, -48}, {110, 18}, {-16, 18}}));
  connect(revolute1.frame_b, bodyCylinder1.frame_a) annotation(
    Line(points = {{86, -88}, {108, -88}}));
  connect(bodyCylinder.frame_b, fixedTranslation.frame_a) annotation(
    Line(points = {{86, -48}, {122, -48}}));
  connect(fixedTranslation.frame_b, revolute1.frame_a) annotation(
    Line(points = {{142, -48}, {142, -60}, {66, -60}, {66, -88}}, color = {95, 95, 95}));
  connect(springDamperParallel1.frame_a, springDamperParallel.frame_b) annotation(
    Line(points = {{142, 18}, {-16, 18}, {-16, 18}, {-16, 18}}));
  connect(springDamperParallel1.frame_b, bodyCylinder1.frame_b) annotation(
    Line(points = {{162, 18}, {176, 18}, {176, -88}, {128, -88}, {128, -88}, {128, -88}}));
  connect(bodyCylinder1.frame_b, n6mass.frame_a) annotation(
    Line(points = {{128, -88}, {150, -88}, {150, -110}, {150, -110}}));
  connect(fixedTranslation.frame_b, n4mass.frame_a) annotation(
    Line(points = {{142, -48}, {150, -48}, {150, -70}, {152, -70}, {152, -70}}));
  annotation(
    uses(Modelica(version = "3.2.2")));
end threeTetrasTwoSprings;
