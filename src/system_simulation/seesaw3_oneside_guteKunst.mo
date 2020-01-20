model seesaw3_oneside_guteKunst
  inner Modelica.Mechanics.MultiBody.World world(n = {0, 0, -1}) annotation(
    Placement(visible = true, transformation(origin = {-154, -78}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  parameter Real N [28,3] = {
   { 0.00, 0.00, 0.015087487120996462},
{ 0.6000000000000015, 0.00, 0.015087487120996462},
{ 0.00, -0.6000000000000001, 0.015087487120996462},
{ 0.6000000000000015, -0.6000000000000001, 0.015087487120996462},
{ 0.6000000000000015, -0.6000000000000001, 0.6150874871209963},
{ 0.00, -0.6000000000000001, 0.6150874871209963},
{ 0.6000000000000015, 0.00, 0.6150874871209963},
{ 0.00, 0.00, 0.6150874871209963},
{ -0.5319002625860849, -0.3000, 0.0140},
{ -0.671269078742836, -0.3000, 0.5238715126640635},
{ 0.01883433054531685, -0.29740486607957536, 1.0288692703057336},
{ -0.45000000000000017, 0.00, 0.9980000000000001},
{ -0.4444322193349468, -0.6017940446596862, 1.0075602633768511},
{ -0.6483295450476023, -0.31709622223539543, 1.2266460744249457},
{ -0.9000, 0.00, 0.9980000000000001},
{ -0.9000, -0.5999999999999997, 0.9980000000000001},
{ -1.00, -0.11999999999999979, 0.33799999999999994},
{ -1.00, -0.47999999999999966, 0.3272454890941405},
{ 1.1319002625860905, -0.30000000000000125, 0.013999999999999995},
{ 1.2712690787428417, -0.30000000000000125, 0.5238715126640635},
{ 1.050000000000006, -0.6000000000000015, 0.9980000000000001},
{ 0.5811656694546889, -0.3025951339204259, 1.0288692703057336},
{ 1.2483295450476073, -0.2829037777646058, 1.2266460744249457},
{ 1.5000000000000061, -0.6000000000000013, 0.9980000000000001},
{ 1.5000000000000061, -0.01263344984181458e-12, 0.9980000000000001},
{ 1.6000000000000057, -0.12000000000000159, 0.3272454890941405},
{ 1.6000000000000057, -0.48000000000000136, 0.33799999999999994},
{ 1.0444322193349528, 0.0017940446596846868, 1.0075602633768511}
   };
  Modelica.Mechanics.MultiBody.Parts.Fixed fixed(animation = false, r = N[9])  annotation(
    Placement(visible = true, transformation(origin = {-42, -76}, extent = {{-10, -10}, {10, 10}}, rotation = 90)));
  Modelica.Mechanics.MultiBody.Joints.Revolute revLeft(a(fixed = false), n = N[8] - N[6], w(fixed = false))  annotation(
    Placement(visible = true, transformation(origin = {-6, -20}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Modelica.Mechanics.MultiBody.Parts.PointMass childLeft(a_0(fixed = false),m = 25, r_0(fixed = true, start = N[14]), v_0(fixed = false, start = {0, 0, 0}))  annotation(
    Placement(visible = true, transformation(origin = {60, -8}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Modelica.Mechanics.MultiBody.Parts.FixedTranslation fixedTranslation(animation = false, r = N[6] - N[9])  annotation(
    Placement(visible = true, transformation(origin = {-42, -42}, extent = {{10, -10}, {-10, 10}}, rotation = -90)));
  Modelica.Mechanics.MultiBody.Parts.BodyCylinder bodyCylinder1(r =  N[14] - N[6], r_0(fixed = false)) annotation(
    Placement(visible = true, transformation(origin = {34, -8}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Modelica.Mechanics.MultiBody.Parts.BodyCylinder bodyCylinder4(r = N[10] - N[6]) annotation(
    Placement(visible = true, transformation(origin = {34, -48}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Modelica.Mechanics.MultiBody.Forces.SpringDamperParallel springDamperParallel1(c = 15000, d = 500, s_unstretched = Modelica.Math.Vectors.length(N[9] - N[10])) annotation(
    Placement(visible = true, transformation(origin = {4, -74}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Modelica.Mechanics.MultiBody.Parts.PointMass pointMass(m = 60) annotation(
    Placement(visible = true, transformation(origin = {94, 26}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Modelica.Mechanics.MultiBody.Joints.Prismatic prismatic(n = {0, 0, 1}, useAxisFlange = true) annotation(
    Placement(visible = true, transformation(origin = {72, 30}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Modelica.Mechanics.Translational.Sources.Position position(exact = true) annotation(
    Placement(visible = true, transformation(origin = {68, 62}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Modelica.Blocks.Sources.Sine sine(amplitude = 0.25, freqHz = 1.5, startTime = 3) annotation(
    Placement(visible = true, transformation(origin = {-22, 44}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
equation
  connect(fixed.frame_b, fixedTranslation.frame_a) annotation(
    Line(points = {{-42, -66}, {-42, -52}}, color = {95, 95, 95}));
  connect(fixedTranslation.frame_b, revLeft.frame_a) annotation(
    Line(points = {{-42, -32}, {-42, -20}, {-16, -20}}));
  connect(revLeft.frame_b, bodyCylinder1.frame_a) annotation(
    Line(points = {{4, -20}, {10, -20}, {10, -8}, {24, -8}}, color = {95, 95, 95}));
  connect(bodyCylinder1.frame_b, childLeft.frame_a) annotation(
    Line(points = {{44, -8}, {60, -8}}));
  connect(revLeft.frame_b, bodyCylinder4.frame_a) annotation(
    Line(points = {{4, -20}, {4, -30}, {8, -30}, {8, -48}, {24, -48}}, color = {95, 95, 95}));
  connect(bodyCylinder4.frame_b, springDamperParallel1.frame_b) annotation(
    Line(points = {{44, -48}, {50, -48}, {50, -74}, {14, -74}}, color = {95, 95, 95}));
  connect(fixed.frame_b, springDamperParallel1.frame_a) annotation(
    Line(points = {{-42, -66}, {-24, -66}, {-24, -74}, {-6, -74}, {-6, -74}}));
  connect(prismatic.frame_b, pointMass.frame_a) annotation(
    Line(points = {{82, 30}, {94, 30}, {94, 26}, {94, 26}}));
  connect(bodyCylinder1.frame_b, prismatic.frame_a) annotation(
    Line(points = {{44, -8}, {46, -8}, {46, 30}, {62, 30}, {62, 30}}));
  connect(position.flange, prismatic.axis) annotation(
    Line(points = {{78, 62}, {80, 62}, {80, 36}}, color = {0, 127, 0}));
  connect(position.support, prismatic.support) annotation(
    Line(points = {{68, 52}, {68, 36}}, color = {0, 127, 0}));
  connect(sine.y, position.s_ref) annotation(
    Line(points = {{-10, 44}, {4, 44}, {4, 62}, {56, 62}}, color = {0, 0, 127}));
  annotation(
    uses(Modelica(version = "3.2.2")));
end seesaw3_oneside_guteKunst;