model AdaptiveSpringDamper "Linear 1D translational spring and damper in parallel with changable length and stiffness"
  extends Modelica.Mechanics.Translational.Interfaces.PartialCompliantWithRelativeStates;
  // parameter Modelica.SIunits.TranslationalSpringConstant c(final min=0, start=1)
  //  "Spring constant";
  parameter Modelica.SIunits.TranslationalDampingConstant d(final min=0, start=1)
    "Damping constant";
  // parameter Modelica.SIunits.Position s_rel0 = 0 "Unstretched spring length";
  extends
    Modelica.Thermal.HeatTransfer.Interfaces.PartialElementaryConditionalHeatPortWithoutT;

  Modelica.Blocks.Interfaces.RealInput s_rel0;
  Modelica.Blocks.Interfaces.RealInput c;
protected
  Modelica.SIunits.Force f_c "Spring force";
  Modelica.SIunits.Force f_d "Damping force";
equation
  f_c = c*(s_rel - s_rel0);
  f_d = d*v_rel;
  f = f_c + f_d;
  lossPower = f_d*v_rel;
annotation(
    uses(Modelica(version = "3.2.2")));
end AdaptiveSpringDamper;
