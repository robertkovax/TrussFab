using Plots

include("./simulator.jl")

g = TrussFab.import_trussfab_file("./test_models/seesaw_3.json")

sol = run_simulation(g)
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

plot()
plot_vertex(19)
