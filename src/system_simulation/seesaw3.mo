model seesaw3
  inner Modelica.Mechanics.MultiBody.World world(n = {0, 0, -1}) annotation(
    Placement(visible = true, transformation(origin = {-154, -78}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  parameter Real N[20, 3] = {{2.9484185869449298, 1.7654563241484457, 0.018510048737482713}, {3.6177000904544852, 1.7654563241484457, 0.018510048737482713}, {3.2830593386997075, 2.3450711084707655, 0.018510048737482713}, {3.947326819617504, 2.0494087557778857, 0.5275012112885823}, {3.0622690093304436, 2.0837322389508527, 0.5955485971784531}, {3.485710676539986, 1.5664053112367365, 0.5724392644528126}, {3.519223542961237, 2.5623179549800493, 0.5303810344633691}, {4.028367031433341, 2.2685366987658986, 0.014}, {4.019266031487974, 1.4683140122435184, 0.1945079692471176}, {2.9285589789057076, 2.65837243288072, 0.2751577034301897}, {4.416529319302888, 1.610700847354188, 0.7172272298919407}, {3.875676806063144, 1.7079901332042007, 1.0992626794526568}, {3.951247074805726, 1.1321524760297739, 0.7666399832906941}, {3.1054704808874803, 3.006768559705716, 0.8077490751144259}, {2.641855459724598, 2.528172808076141, 0.8705579090016595}, {3.25240909732649, 2.438710912734777, 1.129707587436808}, {4.491261822855546, 1.0339449567598042, 0.3843384226720328}, {4.550800214583013, 1.0462281583073118, 1.0510411261501547}, {2.499395462921701, 3.0949276486309927, 0.540907459787559}, {2.5764553985251846, 3.104521581005094, 1.2055149456721892}};
  output Real [3] childLeftPos = childLeft.r_0;
  output Real [3] childRightPos = childRight.r_0;
  output Real springAcc(start=0) = der(springLeft.s);
  // output Real springForce = der(springLeft.f);
  input Real springLeftC(start = 2.89883548);
  Real springLeftS(start = 1);
  Real springRightC(start = 80846133);
  Real springRightS(start = 1);
  Real[3] qf = force.force;
  Modelica.Mechanics.MultiBody.Parts.Fixed fixed(animation = false, r = N[3]) annotation(
    Placement(visible = true, transformation(origin = {-108, -108}, extent = {{-10, -10}, {10, 10}}, rotation = 90)));
  Modelica.Mechanics.MultiBody.Parts.Fixed fixed2(animation = false, r = N[2]) annotation(
    Placement(visible = true, transformation(origin = {74, -108}, extent = {{-10, -10}, {10, 10}}, rotation = 90)));
  Modelica.Mechanics.MultiBody.Joints.Revolute revLeft(n = N[5] - N[7], stateSelect = StateSelect.prefer) annotation(
    Placement(visible = true, transformation(origin = {-72, -52}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Modelica.Mechanics.MultiBody.Joints.Revolute revRight(n = N[6] - N[4], stateSelect = StateSelect.prefer) annotation(
    Placement(visible = true, transformation(origin = {98, -36}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Modelica.Mechanics.MultiBody.Parts.PointMass childLeft(m = 70, r_0(fixed = false, start = N[20]), v_0(fixed = false, start = {0, 0, -1})) annotation(
    Placement(visible = true, transformation(origin = {-6, -40}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Modelica.Mechanics.MultiBody.Parts.FixedTranslation fixedTranslation(animation = false, r = N[5] - N[3]) annotation(
    Placement(visible = true, transformation(origin = {-108, -74}, extent = {{10, -10}, {-10, 10}}, rotation = -90)));
  Modelica.Mechanics.MultiBody.Parts.BodyCylinder bodyCylinder(r = (-N[5]) + N[16]) annotation(
    Placement(visible = true, transformation(origin = {-32, -60}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Modelica.Mechanics.MultiBody.Parts.BodyCylinder bodyCylinder1(r = N[20] - N[5], r_0(fixed = false)) annotation(
    Placement(visible = true, transformation(origin = {-32, -40}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Modelica.Mechanics.MultiBody.Parts.PointMass childRight(m = 70, r_0(fixed = true, start = N[18])) annotation(
    Placement(visible = true, transformation(origin = {172, -26}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Modelica.Mechanics.MultiBody.Parts.BodyCylinder bodyCylinder2(r = (-N[6]) + N[18]) annotation(
    Placement(visible = true, transformation(origin = {138, -26}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Modelica.Mechanics.MultiBody.Parts.BodyCylinder bodyCylinder3(r = (-N[6]) + N[12], r_0(fixed = true, start = N[6])) annotation(
    Placement(visible = true, transformation(origin = {142, -46}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Modelica.Mechanics.MultiBody.Parts.BodyCylinder bodyCylinder4(r = (-N[5]) + N[10]) annotation(
    Placement(visible = true, transformation(origin = {-32, -80}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Modelica.Mechanics.MultiBody.Parts.BodyCylinder bodyCylinder5(r = (-N[6]) + N[9]) annotation(
    Placement(visible = true, transformation(origin = {136, -64}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Modelica.Mechanics.MultiBody.Parts.FixedTranslation fixedTranslation1(animation = false, r = N[6] - N[2]) annotation(
    Placement(visible = true, transformation(origin = {74, -56}, extent = {{10, -10}, {-10, 10}}, rotation = -90)));
  Modelica.Mechanics.MultiBody.Forces.SpringDamperParallel springDamperParallel(c = 2, d = 10, s_unstretched = 1) annotation(
    Placement(visible = true, transformation(origin = {48, -76}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Modelica.Mechanics.MultiBody.Forces.WorldForce force annotation(
    Placement(visible = true, transformation(origin = {-60, -12}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  AdaptiveSpringDamper springLeft( d = 10, s(fixed=true, start=0.66), c=springLeftC) annotation(
    Placement(visible = true, transformation(origin = {-56, -104}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  AdaptiveSpringDamper springRight( d = 10 )  annotation(
    Placement(visible = true, transformation(origin = {148, -98}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));

// initial equation
  // springLeft.s = 0
equation
  qf = {0,0,0};
  springLeftS = springLeft.s_unstretched;
  //connect(springLeftC, springLeft.c);
  //connect(springLeftS, springLeft.s_unstretched);
  connect(springRightC, springRight.c);
  connect(springRightS, springRight.s_unstretched);

  connect(fixed.frame_b, fixedTranslation.frame_a) annotation(
    Line(points = {{-108, -98}, {-108, -84}}, color = {95, 95, 95}));
  connect(fixedTranslation.frame_b, revLeft.frame_a) annotation(
    Line(points = {{-108, -64}, {-108, -52}, {-82, -52}}));
  connect(revLeft.frame_b, bodyCylinder.frame_a) annotation(
    Line(points = {{-62, -52}, {-58, -52}, {-58, -60}, {-42, -60}}));
  connect(revLeft.frame_b, bodyCylinder1.frame_a) annotation(
    Line(points = {{-62, -52}, {-56, -52}, {-56, -40}, {-42, -40}}, color = {95, 95, 95}));
  connect(bodyCylinder1.frame_b, childLeft.frame_a) annotation(
    Line(points = {{-22, -40}, {-6, -40}}));
  connect(bodyCylinder2.frame_b, childRight.frame_a) annotation(
    Line(points = {{148, -26}, {172, -26}}));
  connect(revRight.frame_b, bodyCylinder2.frame_a) annotation(
    Line(points = {{108, -36}, {116, -36}, {116, -26}, {128, -26}}, color = {95, 95, 95}));
  connect(revRight.frame_b, bodyCylinder3.frame_a) annotation(
    Line(points = {{108, -36}, {116, -36}, {116, -46}, {132, -46}}));
  connect(revLeft.frame_b, bodyCylinder4.frame_a) annotation(
    Line(points = {{-62, -52}, {-62, -62}, {-58, -62}, {-58, -80}, {-42, -80}}, color = {95, 95, 95}));
  connect(revRight.frame_b, bodyCylinder5.frame_a) annotation(
    Line(points = {{108, -36}, {114, -36}, {114, -64}, {126, -64}, {126, -64}}, color = {95, 95, 95}));
  connect(fixedTranslation1.frame_a, fixed2.frame_b) annotation(
    Line(points = {{74, -66}, {74, -66}, {74, -98}, {74, -98}}));
  connect(fixedTranslation1.frame_b, revRight.frame_a) annotation(
    Line(points = {{74, -46}, {74, -46}, {74, -36}, {88, -36}, {88, -36}}));
  connect(bodyCylinder3.frame_b, springDamperParallel.frame_b) annotation(
    Line(points = {{152, -46}, {156, -46}, {156, -76}, {58, -76}}, color = {95, 95, 95}));
  connect(bodyCylinder.frame_b, springDamperParallel.frame_a) annotation(
    Line(points = {{-22, -60}, {24, -60}, {24, -78}, {38, -78}, {38, -76}}, color = {95, 95, 95}));
  connect(force.frame_b, bodyCylinder1.frame_b) annotation(
    Line(points = {{-50, -12}, {-22, -12}, {-22, -40}}, color = {95, 95, 95}));
  connect(springLeft.frame_b, bodyCylinder4.frame_b) annotation(
    Line(points = {{-46, -104}, {-6, -104}, {-6, -80}, {-22, -80}}, color = {95, 95, 95}));
  connect(springLeft.frame_a, fixed.frame_b) annotation(
    Line(points = {{-66, -104}, {-83, -104}, {-83, -98}, {-108, -98}}, color = {95, 95, 95}));
  connect(fixed2.frame_b, springRight.frame_a) annotation(
    Line(points = {{74, -98}, {138, -98}, {138, -98}, {138, -98}}));
  connect(bodyCylinder5.frame_b, springRight.frame_b) annotation(
    Line(points = {{146, -64}, {172, -64}, {172, -98}, {158, -98}, {158, -98}}, color = {95, 95, 95}));
  annotation(
    uses(Modelica(version = "3.2.2")));
end seesaw3;