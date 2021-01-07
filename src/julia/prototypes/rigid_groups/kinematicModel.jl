using JuMP
using GLPK

model = Model();

pos1 = [0,0,0]
pos2 = [1,0,0]

@variable(model, r2[i=1:3])
r2
@constraint(model, con2, ((x-pos1[1])^2 + (y-pos1[2])^2 + (z-pos1[3])^2) == 0)



set_optimizer(model, GLPK.Optimizer)
optimize!(model)