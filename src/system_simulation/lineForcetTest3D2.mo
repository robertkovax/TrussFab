model lineForcetTest3D2
  Modelica.Mechanics.Translational.Components.Rod rod1(L = 1)  annotation(
    Placement(visible = true, transformation(origin = {-28, -44}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Modelica.Mechanics.MultiBody.Forces.LineForceWithMass lineForceWithMass1(fixedRotationAtFrame_a = false, fixedRotationAtFrame_b = false, m = 1) annotation(
    Placement(visible = true, transformation(origin = {-26, -66}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  inner Modelica.Mechanics.MultiBody.World world annotation(
    Placement(visible = true, transformation(origin = {-166, -8}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Modelica.Mechanics.Translational.Components.Rod rod(L = 1)  annotation(
    Placement(visible = true, transformation(origin = {-75, 25}, extent = {{-11, -11}, {11, 11}}, rotation = 0)));
  Modelica.Mechanics.MultiBody.Forces.LineForceWithMass lineForceWithMass(fixedRotationAtFrame_b = true, m = 1) annotation(
    Placement(visible = true, transformation(origin = {-75, -3}, extent = {{-19, -19}, {19, 19}}, rotation = 0)));
  Modelica.Mechanics.Translational.Components.Rod rod2(L = 1) annotation(
    Placement(visible = true, transformation(origin = {-88, -48}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Modelica.Mechanics.MultiBody.Forces.LineForceWithMass lineForceWithMass2(fixedRotationAtFrame_a = false, fixedRotationAtFrame_b = true, m = 1) annotation(
    Placement(visible = true, transformation(origin = {-86, -70}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Modelica.Mechanics.MultiBody.Forces.LineForceWithMass lineForceWithMass3(fixedRotationAtFrame_a = false, fixedRotationAtFrame_b = true, m = 1) annotation(
    Placement(visible = true, transformation(origin = {86, -12}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Modelica.Mechanics.Translational.Components.Rod rod3(L = 1) annotation(
    Placement(visible = true, transformation(origin = {84, 10}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Modelica.Mechanics.MultiBody.Forces.LineForceWithMass lineForceWithMass4(fixedRotationAtFrame_a = false, fixedRotationAtFrame_b = false, m = 1) annotation(
    Placement(visible = true, transformation(origin = {92, -66}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Modelica.Mechanics.Translational.Components.Rod rod4(L = 1) annotation(
    Placement(visible = true, transformation(origin = {90, -44}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
initial equation
// lineForceWithMass.r_rel_0 = {0.343241, 0.939204, -0.00903105};
lineForceWithMass.v_CM_0 = {0,0,0};
lineForceWithMass1.v_CM_0 = {0,0,0};
lineForceWithMass2.v_CM_0 = {0,0,0};
lineForceWithMass3.v_CM_0 = {0,0,0};
lineForceWithMass4.v_CM_0 = {0,0,0};
//lineForceWithMass5.v_CM_0 = {0,0,0};
equation
  connect(rod1.flange_b, lineForceWithMass1.flange_b) annotation(
    Line(points = {{-18, -44}, {-20, -44}, {-20, -56}}, color = {0, 127, 0}));
  connect(rod1.flange_a, lineForceWithMass1.flange_a) annotation(
    Line(points = {{-38, -44}, {-32, -44}, {-32, -56}}, color = {0, 127, 0}));
  connect(world.frame_b, lineForceWithMass.frame_a) annotation(
    Line(points = {{-156, -8}, {-116, -8}, {-116, -3}, {-94, -3}}));
  connect(rod.flange_b, lineForceWithMass.flange_b) annotation(
    Line(points = {{-64, 25}, {-64, 16}}, color = {0, 127, 0}));
  connect(rod.flange_a, lineForceWithMass.flange_a) annotation(
    Line(points = {{-86, 25}, {-86, 16}}, color = {0, 127, 0}));
  connect(rod2.flange_b, lineForceWithMass2.flange_b) annotation(
    Line(points = {{-78, -48}, {-78, -60}, {-80, -60}}, color = {0, 127, 0}));
  connect(rod2.flange_a, lineForceWithMass2.flange_a) annotation(
    Line(points = {{-98, -48}, {-98, -60}, {-92, -60}}, color = {0, 127, 0}));
  connect(world.frame_b, lineForceWithMass2.frame_a) annotation(
    Line(points = {{-156, -8}, {-134, -8}, {-134, -70}, {-96, -70}, {-96, -70}}));
  connect(lineForceWithMass.frame_b, lineForceWithMass1.frame_b) annotation(
    Line(points = {{-56, -3}, {38, -3}, {38, -66}, {-16, -66}}));
  connect(lineForceWithMass1.frame_a, lineForceWithMass2.frame_b) annotation(
    Line(points = {{-36, -66}, {-55, -66}, {-55, -70}, {-76, -70}}, color = {95, 95, 95}));
  connect(rod4.flange_a, lineForceWithMass4.flange_a) annotation(
    Line(points = {{80, -44}, {86, -44}, {86, -56}}, color = {0, 127, 0}));
  connect(rod4.flange_b, lineForceWithMass4.flange_b) annotation(
    Line(points = {{100, -44}, {100, -53}, {98, -53}, {98, -56}}, color = {0, 127, 0}));
  connect(rod3.flange_a, lineForceWithMass3.flange_a) annotation(
    Line(points = {{74, 10}, {80, 10}, {80, -2}}, color = {0, 127, 0}));
  connect(rod3.flange_b, lineForceWithMass3.flange_b) annotation(
    Line(points = {{94, 10}, {94, -11}, {90, -11}, {90, -2}, {92, -2}}, color = {0, 127, 0}));
  connect(lineForceWithMass.frame_b, lineForceWithMass3.frame_a) annotation(
    Line(points = {{-56, -2}, {58, -2}, {58, -12}, {76, -12}, {76, -12}}, color = {95, 95, 95}));
  connect(lineForceWithMass3.frame_b, lineForceWithMass4.frame_b) annotation(
    Line(points = {{96, -12}, {134, -12}, {134, -66}, {102, -66}, {102, -66}}, color = {95, 95, 95}));
  connect(lineForceWithMass4.frame_a, lineForceWithMass2.frame_b) annotation(
    Line(points = {{82, -66}, {48, -66}, {48, -86}, {-54, -86}, {-54, -68}, {-76, -68}, {-76, -70}}));
  connect(lineForceWithMass1.frame_b, lineForceWithMass1.frame_b) annotation(
    Line(points = {{-16, -66}, {-16, -66}, {-16, -66}, {-16, -66}}));
  annotation(
    uses(Modelica(version = "3.2.2")),
    __OpenModelica_commandLineOptions = "--matchingAlgorithm=PFPlusExt --indexReductionMethod=dynamicStateSelection -d=initialization,NLSanalyticJacobian");
end lineForcetTest3D2;