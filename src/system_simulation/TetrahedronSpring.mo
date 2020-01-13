model TetrahedronSpring
  extends Modelica.Icons.Example;
  parameter Boolean animation=true "= true, if animation shall be enabled";

  parameter Real N1[3] = {0.0, 0.0, 0.0};
  parameter Real N2[3] = {0.6692815035095565, 0.0, 0.0};
  parameter Real N3[3] = {0.3346407517547786, 0.5796147843223197, 0.0};
  parameter Real N4[3] = {0.3346407517547786, 0.19320492810743978, 0.5464660592937206};

  inner Modelica.Mechanics.MultiBody.World world(n = {0, 0, -1})  ;
  Modelica.Mechanics.MultiBody.Parts.BodyCylinder bodyCylinder(a_0(fixed = true),r = N3 - N1, v_0(fixed = true), w_0_fixed = true, z_0_fixed = true)  ;
  Modelica.Mechanics.MultiBody.Joints.Spherical spherical2(angles_fixed = false, enforceStates = true, w_rel_a_fixed = true, z_rel_a_fixed = false) ;
  Modelica.Mechanics.MultiBody.Parts.BodyCylinder bodyCylinder2(r = N2 -N3) ;
  Modelica.Mechanics.MultiBody.Joints.Spherical joint(angles_fixed = false, enforceStates = true, w_rel_a_fixed = true, z_rel_a_fixed = false) ;
  Modelica.Mechanics.MultiBody.Forces.SpringDamperParallel springDamperParallel(c = 140, d = 10, fixedRotationAtFrame_a = false, fixedRotationAtFrame_b = false, s_unstretched = 0.6) ;
  Modelica.Mechanics.MultiBody.Joints.Spherical spherical(angles_fixed = false, enforceStates = true, w_rel_a_fixed = true, z_rel_a_fixed = false) ;
  Modelica.Mechanics.MultiBody.Parts.BodyCylinder bodyCylinder1(r = N4 - N3) ;
  Modelica.Mechanics.MultiBody.Parts.PointMass pointMass(m = 1, v_0(start = {0, 0, 0})) ;
  Modelica.Mechanics.MultiBody.Parts.BodyCylinder bodyCylinder4(r = N4 - N1)  ;
  Modelica.Mechanics.MultiBody.Parts.BodyCylinder bodyCylinder3(r = N2 - N1, w_0_fixed = true, z_0_fixed = true) ;
equation
  connect(bodyCylinder.frame_b, spherical2.frame_a) ;
  connect(bodyCylinder2.frame_a, bodyCylinder.frame_b) ;
  connect(spherical2.frame_b, bodyCylinder1.frame_a) ;
  connect(springDamperParallel.frame_b, pointMass.frame_a) ;
  connect(joint.frame_b, bodyCylinder4.frame_a) ;
  connect(bodyCylinder1.frame_b, spherical.frame_a) ;
  connect(spherical.frame_b, bodyCylinder4.frame_b) ;
  connect(bodyCylinder4.frame_b, springDamperParallel.frame_b) ;
  connect(bodyCylinder3.frame_b, springDamperParallel.frame_a) ;
  connect(world.frame_b, bodyCylinder.frame_a) ;
  connect(world.frame_b, joint.frame_a) ;
  connect(world.frame_b, bodyCylinder3.frame_a) ;
end TetrahedronSpring;
