using Revise
using MetaGraphs
using LightGraphs
using Plots
import TrussFab
using LinearAlgebra
include("analysis.jl")

g = TrussFab.import_trussfab_file("./test_models/seesaw_3.json")

function set_stiffness(k)
    for e in edges(g)
        if get_prop(g, e, :type) == "spring"
            set_prop!(g, e, :spring_stiffness, k)
        end
    end
end

function set_weight(m)
    for v in vertices(g)
        if get_prop(g, v, :active_user)
            set_prop!(g, v, :m, m)
        end
    end
end

function plot_spectrum(sol, vertex_id)
    (freqs, mag) = get_frequency_spectrum(sol, vertex_id)
    # plots 
    time_domain = plot(transpose(sol[((vertex_id -1)*6 +1):((vertex_id -1)*6+3), :]), title = "Signal")
    freq_domain = plot(freqs, mag, title = "Spectrum", xlim=(0, +1), ylims=(-1, 5))
    p = plot(time_domain, freq_domain, layout = 2) 
    display(p)
    return [freqs mag]
end

function get_dominant_frequency(sol)
    node_of_interest = 18
    spectrum = get_frequency_spectrum(sol, node_of_interest)
    plot_spectrum(sol, node_of_interest)
    trimmed_spectrum = spectrum[0.2 .< spectrum[:, 1] .< 1.0, :]
    max_mag, index = findmax(trimmed_spectrum[:,2])
    return trimmed_spectrum[index]
end

# If we add weight and stiffness (in a way the frequency remains the same)
steps = 1:1:30

solution_cache = []

for step in steps
    # set_stiffness(step*10 + 10000)
    set_weight(step*3 + 40)
    sol = TrussFab.run_simulation(g, tspan=(0., 30.), fps=30, actuation_power=10.0)
    plot_spectrum(sol, 18)
    push!(solution_cache, sol)
end

using Serialization
serialize("sim_sweep.tfs", solution_cache)
solution_cache2 = deserialize("sim_sweep.tfs")

function plot_solutions(solutions)
    frequencies = solutions .|> get_dominant_frequency
    amplitudes = solutions .|> get_amplitude
    display(plot(steps.*3 .+ 40, [frequencies amplitudes]))
end
plot_solutions(solution_cache2)

set_weight(40)
get_dominant_frequency(sol)


results2 = []
for step in steps
    set_stiffness(step*100 + 3000)
    # set_weight(step*3 + 40)
    sol = TrussFab.run_simulation(g, tspan=(0., 30.), fps=30, actuation_power=10.0)
    freq = get_dominat_frequency(sol)
    println(freq)
    push!(results2, freq)
end
plot(steps.*100 .+ 3000, results2)

# what is the effect on frequency and amplitude for a given user power?

# How frequency (adjusting stiffness) changes acceleration and amplitude? 

# Simulate Energy Stealing on the Dinosaur
 