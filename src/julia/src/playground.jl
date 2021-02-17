using LightGraphs
using Plots
using Revise
using GraphPlot
import TrussFab
using MetaGraphs

# Test whether all test modesl are parsed without raising an error
all_test_models = filter(f -> endswith(f, ".json"), readdir("./test_models", join=true))
TrussFab.import_trussfab_file.(all_test_models)

g = TrussFab.import_trussfab_file("./test_models/seesaw_3.json")

nodelabel = 1:nv(g)
gplot(g, nodelabel=nodelabel)

sol = TrussFab.run_simulation(g)

plot(sol[1, :], sol[2, :], sol[3, :])
plot(sol[19, :], sol[20, :], sol[21, :])
plot(sol[19, :], sol[20, :], sol[21, :])

plot(transpose(sol[45:48, :]))

function plot_vertex(index)
    start_index = (index - 1) * 6
    plot!(sol[start_index+1, :], sol[start_index + 2, :], sol[start_index + 3, :])
end

for v in vertices(g)
    plot_vertex(v)
end

plot_vertex(19)
