model TetrahedronSpring_omedit
  "Body attached by one spring and spherical joint or constrained to environment"
  extends Modelica.Icons.Example;
  parameter Boolean animation=true "= true, if animation shall be enabled";

  parameter Real N1[3] = {0.0, 0.0, 0.014};
  parameter Real N2[3] = {0.6692815035095565, 0.0, 0.0140};
  parameter Real N3[3] = {0.3346407517547786, 0.5796147843223197, 0.0140};
  parameter Real N4[3] = {0.3346407517547786, 0.19320492810743977, 0.5604660592937206};
  inner Modelica.Mechanics.MultiBody.World world(n = {0, 0, -1})  annotation (Placement(
        visible = true, transformation(extent = {{-146, -110}, {-126, -90}}, rotation = 0)));
  Modelica.Mechanics.MultiBody.Parts.BodyCylinder bodyCylinder(a_0(fixed = true),r = N3 - N1, v_0(fixed = true), w_0_fixed = true, z_0_fixed = true)  annotation(
    Placement(visible = true, transformation(origin = {-56, -92}, extent = {{-14, -14}, {14, 14}}, rotation = 0)));
  Modelica.Mechanics.MultiBody.Joints.Spherical spherical2(angles_fixed = false, enforceStates = true, w_rel_a_fixed = true, z_rel_a_fixed = false) annotation(
    Placement(visible = true, transformation(origin = {22, -92}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Modelica.Mechanics.MultiBody.Parts.BodyCylinder bodyCylinder2(r = N2 -N3) annotation(
    Placement(visible = true, transformation(origin = {-56, -118}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Modelica.Mechanics.MultiBody.Joints.Spherical joint(angles_fixed = false, enforceStates = true, w_rel_a_fixed = true, z_rel_a_fixed = false) annotation(
    Placement(visible = true, transformation(origin = {0, -10}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Modelica.Mechanics.MultiBody.Forces.SpringDamperParallel springDamperParallel(c = 140, d = 10, fixedRotationAtFrame_a = false, fixedRotationAtFrame_b = false, s_unstretched = 0.6) annotation(
    Placement(visible = true, transformation(origin = {20, -54}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Modelica.Mechanics.MultiBody.Joints.Spherical spherical(angles_fixed = false, enforceStates = true, w_rel_a_fixed = true, z_rel_a_fixed = false) annotation(
    Placement(visible = true, transformation(origin = {96, -92}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Modelica.Mechanics.MultiBody.Parts.BodyCylinder bodyCylinder1(r = N4 - N3) annotation(
    Placement(visible = true, transformation(origin = {58, -92}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Modelica.Mechanics.MultiBody.Parts.PointMass pointMass(m = 1, v_0(start = {0, 0, 0})) annotation(
    Placement(visible = true, transformation(origin = {94, -54}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Modelica.Mechanics.MultiBody.Parts.BodyCylinder bodyCylinder4(r = N4 - N1)  annotation(
    Placement(visible = true, transformation(origin = {40, -10}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Modelica.Mechanics.MultiBody.Parts.BodyCylinder bodyCylinder3(r = N2 - N1, w_0_fixed = true, z_0_fixed = true) annotation(
    Placement(visible = true, transformation(origin = {-40, -54}, extent = {{-12, -12}, {12, 12}}, rotation = 0)));
equation
  connect(bodyCylinder.frame_b, spherical2.frame_a) annotation(
    Line(points = {{-42, -92}, {12, -92}}, color = {95, 95, 95}));
  connect(bodyCylinder2.frame_a, bodyCylinder.frame_b) annotation(
    Line(points = {{-66, -118}, {-7, -118}, {-7, -92}, {-42, -92}}));
  connect(spherical2.frame_b, bodyCylinder1.frame_a) annotation(
    Line(points = {{32, -92}, {48, -92}}, color = {95, 95, 95}));
  connect(springDamperParallel.frame_b, pointMass.frame_a) annotation(
    Line(points = {{30, -54}, {94, -54}}, color = {95, 95, 95}));
  connect(joint.frame_b, bodyCylinder4.frame_a) annotation(
    Line(points = {{10, -10}, {30, -10}, {30, -10}, {30, -10}}, color = {95, 95, 95}));
  connect(bodyCylinder1.frame_b, spherical.frame_a) annotation(
    Line(points = {{68, -92}, {86, -92}}, color = {95, 95, 95}));
  connect(spherical.frame_b, bodyCylinder4.frame_b) annotation(
    Line(points = {{106, -92}, {142, -92}, {142, -10}, {50, -10}}, color = {95, 95, 95}));
  connect(bodyCylinder4.frame_b, springDamperParallel.frame_b) annotation(
    Line(points = {{50, -10}, {66, -10}, {66, -54}, {30, -54}}));
  connect(bodyCylinder3.frame_b, springDamperParallel.frame_a) annotation(
    Line(points = {{-28, -54}, {10, -54}}, color = {95, 95, 95}));
  connect(world.frame_b, bodyCylinder.frame_a) annotation(
    Line(points = {{-126, -100}, {-84, -100}, {-84, -92}, {-70, -92}}));
  connect(world.frame_b, joint.frame_a) annotation(
    Line(points = {{-126, -100}, {-106, -100}, {-106, -10}, {-10, -10}, {-10, -10}}));
  connect(world.frame_b, bodyCylinder3.frame_a) annotation(
    Line(points = {{-126, -100}, {-94, -100}, {-94, -54}, {-52, -54}}, color = {95, 95, 95}));
  annotation(
    experiment(StopTime = 10),
    Documentation(info = "<html>
<p>This example demonstrates the functionality of <b>constraint</b> representing <b>spherical joint</b>. Each of two bodies is at one of its end connected by spring to the world. The other end is also connected to the world either by spherical joint or by appropriate constraint. Therefore, the body can only perform spherical movement depending on working forces.</p>
<p><b>Simulation results</b> </p>
<p>After simulating the model, see the animation of the multibody system and compare movement of body connected by joint (blue colored) with movement of that one connected by constraint (of green color). Additionally, the outputs from <code>sensorConstraintRelative</code> depict position deviations in the constraining element.</p>
</html>"),
    uses(Modelica(version = "3.2.2")));
end TetrahedronSpring_omedit;
