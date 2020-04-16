model linear_seesaw3
  parameter Integer n = 4 "number of states";
  parameter Integer p = 3 "number of inputs";
  parameter Integer q = 7 "number of outputs";

  parameter Real x0[n] = {-0.2610412143339109, 0, 0, 0};
  parameter Real u0[p] = {100000, 1, 0};

  parameter Real A[n, n] = [0, 1, 0, 0; -197.9836611136692, -0.04255794794939439, 0.005110375098844779, 0.0256639241909885; 0, 0, 0, 1; 0.005142233427270894, 0.02582391435017741, -135.8040031168733, -0.04416407235672753];
  parameter Real B[n, p] = [0, 0, 0; -0.001217355707479184, -358.0457963174072, 4.135583055404806e-14; 0, 0, 0; -0, -0, 393.6734613022644];
  parameter Real C[q, n] = [-0.7067069470534866, 0, 0, 0; 0.5590845586368978, 0, 0, 0; -0.8495493353098212, 0, 0, 0; -0, -0, -0.3103076646659975, -0; 0, 0, 0.4014072399342231, 0; 0, 0, 1.12684125492518, 0; 0, -0.4466966507043133, 0, 0];
  parameter Real D[q, p] = [0, 0, 0; 0, 0, 0; 0, 0, 0; 0, 0, 0; 0, 0, 0; 0, 0, 0; 0, 0, 0];

  Real x[n](start=x0);
  input Real u[p](start=u0);
  output Real y[q];

  Real 'x_revLeft.phi' = x[1];
  Real 'x_revLeft.w' = x[2];
  Real 'x_revRight.phi' = x[3];
  Real 'x_revRight.w' = x[4];
  Real 'u_springLeftC' = u[1];
  Real 'u_springLeftS' = u[2];
  Real 'u_springRightS' = u[3];
  Real 'y_childLeftPos[1]' = y[1];
  Real 'y_childLeftPos[2]' = y[2];
  Real 'y_childLeftPos[3]' = y[3];
  Real 'y_childRightPos[1]' = y[4];
  Real 'y_childRightPos[2]' = y[5];
  Real 'y_childRightPos[3]' = y[6];
  Real 'y_springAcc' = y[7];
equation
  der(x) = A * x + B * u;
  y = C * x + D * u;
end linear_seesaw3;
