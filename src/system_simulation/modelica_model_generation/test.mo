model LineForceGenerated
  inner Modelica.Mechanics.MultiBody.World world(n = {0, 0, -1});

  
     Modelica.Mechanics.MultiBody.Forces.LineForceWithMass edge_from_1_to_2(fixedRotationAtFrame_a = false, fixedRotationAtFrame_b = false, m = 1);
    
     Modelica.Mechanics.Translational.Components.Rod edge_from_1_to_2_rod(L = 1.0);
    
     Modelica.Mechanics.MultiBody.Forces.LineForceWithMass edge_from_2_to_3(fixedRotationAtFrame_a = false, fixedRotationAtFrame_b = true, m = 1);
    
     Modelica.Mechanics.Translational.Components.Rod edge_from_2_to_3_rod(L = 1.0);
    
     Modelica.Mechanics.MultiBody.Forces.LineForceWithMass edge_from_3_to_1(fixedRotationAtFrame_a = false, fixedRotationAtFrame_b = false, m = 1);
    
     Modelica.Mechanics.Translational.Components.Rod edge_from_3_to_1_rod(L = 1.0);
    
     Modelica.Mechanics.MultiBody.Forces.LineForceWithMass edge_from_1_to_4(fixedRotationAtFrame_a = false, fixedRotationAtFrame_b = true, m = 1);
    
     Modelica.Mechanics.Translational.Components.Rod edge_from_1_to_4_rod(L = 1.0);
    
     Modelica.Mechanics.MultiBody.Forces.LineForceWithMass edge_from_2_to_4(fixedRotationAtFrame_a = false, fixedRotationAtFrame_b = false, m = 1);
    
     Modelica.Mechanics.Translational.Components.Rod edge_from_2_to_4_rod(L = 1.0);
    
     Modelica.Mechanics.MultiBody.Forces.LineForceWithMass edge_from_3_to_4(fixedRotationAtFrame_a = false, fixedRotationAtFrame_b = false, m = 1);
    
     Modelica.Mechanics.Translational.Components.Rod edge_from_3_to_4_rod(L = 1.0);
    
     Modelica.Mechanics.MultiBody.Forces.LineForceWithMass edge_from_1_to_5(fixedRotationAtFrame_a = false, fixedRotationAtFrame_b = true, m = 1);
    
     Modelica.Mechanics.Translational.Components.Rod edge_from_1_to_5_rod(L = 1.0);
    
     Modelica.Mechanics.MultiBody.Forces.LineForceWithMass edge_from_2_to_5(fixedRotationAtFrame_a = false, fixedRotationAtFrame_b = false, m = 1);
    
     Modelica.Mechanics.Translational.Components.Rod edge_from_2_to_5_rod(L = 1.0);
    
     Modelica.Mechanics.MultiBody.Forces.LineForceWithMass edge_from_3_to_5(fixedRotationAtFrame_a = false, fixedRotationAtFrame_b = false, m = 1);
    
     Modelica.Mechanics.Translational.Components.SpringDamper edge_from_3_to_5_spring(c = 70, s_rel0 = 1, d = 100);
    
     Modelica.Mechanics.MultiBody.Parts.Fixed node_1_fixture(r = {1.0, 1.0, 1.0}); 
     Modelica.Mechanics.MultiBody.Parts.Fixed node_2_fixture(r = {1.0, 2.0, 1.0}); 

initial equation
  
  edge_from_1_to_2.v_CM_0 = {0,0,0}; 
  edge_from_2_to_3.v_CM_0 = {0,0,0}; 
  edge_from_3_to_1.v_CM_0 = {0,0,0}; 
  edge_from_1_to_4.v_CM_0 = {0,0,0}; 
  edge_from_2_to_4.v_CM_0 = {0,0,0}; 
  edge_from_3_to_4.v_CM_0 = {0,0,0}; 
  edge_from_1_to_5.v_CM_0 = {0,0,0}; 
  edge_from_2_to_5.v_CM_0 = {0,0,0}; 
  edge_from_3_to_5.v_CM_0 = {0,0,0}; 
equation
  
  connect(edge_from_1_to_2.flange_a, edge_from_1_to_2_rod.flange_a);
  connect(edge_from_1_to_2.flange_b, edge_from_1_to_2_rod.flange_b);
  connect(edge_from_2_to_3.flange_a, edge_from_2_to_3_rod.flange_a);
  connect(edge_from_2_to_3.flange_b, edge_from_2_to_3_rod.flange_b);
  connect(edge_from_3_to_1.flange_a, edge_from_3_to_1_rod.flange_a);
  connect(edge_from_3_to_1.flange_b, edge_from_3_to_1_rod.flange_b);
  connect(edge_from_1_to_4.flange_a, edge_from_1_to_4_rod.flange_a);
  connect(edge_from_1_to_4.flange_b, edge_from_1_to_4_rod.flange_b);
  connect(edge_from_2_to_4.flange_a, edge_from_2_to_4_rod.flange_a);
  connect(edge_from_2_to_4.flange_b, edge_from_2_to_4_rod.flange_b);
  connect(edge_from_3_to_4.flange_a, edge_from_3_to_4_rod.flange_a);
  connect(edge_from_3_to_4.flange_b, edge_from_3_to_4_rod.flange_b);
  connect(edge_from_1_to_5.flange_a, edge_from_1_to_5_rod.flange_a);
  connect(edge_from_1_to_5.flange_b, edge_from_1_to_5_rod.flange_b);
  connect(edge_from_2_to_5.flange_a, edge_from_2_to_5_rod.flange_a);
  connect(edge_from_2_to_5.flange_b, edge_from_2_to_5_rod.flange_b);
  connect(edge_from_3_to_5.flange_a, edge_from_3_to_5_spring.flange_a);
  connect(edge_from_3_to_5.flange_b, edge_from_3_to_5_spring.flange_b);
  connect(edge_from_1_to_2.frame_a, edge_from_3_to_1.frame_b);
  connect(edge_from_1_to_2.frame_a, edge_from_1_to_4.frame_a);
  connect(edge_from_1_to_2.frame_a, edge_from_1_to_5.frame_a);
  connect(edge_from_2_to_3.frame_a, edge_from_1_to_2.frame_b);
  connect(edge_from_2_to_3.frame_a, edge_from_2_to_4.frame_a);
  connect(edge_from_2_to_3.frame_a, edge_from_2_to_5.frame_a);
  connect(edge_from_3_to_1.frame_a, edge_from_2_to_3.frame_b);
  connect(edge_from_3_to_1.frame_a, edge_from_3_to_4.frame_a);
  connect(edge_from_3_to_1.frame_a, edge_from_3_to_5.frame_a);
  connect(edge_from_1_to_4.frame_b, edge_from_2_to_4.frame_b);
  connect(edge_from_1_to_4.frame_b, edge_from_3_to_4.frame_b);
  connect(edge_from_1_to_5.frame_b, edge_from_2_to_5.frame_b);
  connect(edge_from_1_to_5.frame_b, edge_from_3_to_5.frame_b);
  connect(node_1_fixture.frame_b, edge_from_1_to_2.frame_a);
  connect(node_2_fixture.frame_b, edge_from_2_to_3.frame_a);
end LineForceGenerated;
