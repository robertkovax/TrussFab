using Revise
using MetaGraphs
using LightGraphs
using Plots
import TrussFab
using FFTW
using LinearAlgebra


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

function fft_on_vertex(sol, vertex_id, fps)
    F1 = fft(sol[vertex_id*6 + 0, :]) |> fftshift
    F2 = fft(sol[vertex_id*6 + 1, :]) |> fftshift
    F3 = fft(sol[vertex_id*6 + 2, :]) |> fftshift
    freqs = fftfreq(length(sol.t), fps) |> fftshift

    mag = log10.(abs.(F1) .+ abs.(F2) .+ abs.(F3))
    return freqs, mag
end

function get_frequency(sol, fps, vertex_id)
    (freqs, mag) = fft_on_vertex(sol, vertex_id, fps)
    # plots 
    time_domain = plot(transpose(sol[vertex_id*6:vertex_id*6+2, :]), title = "Signal")
    freq_domain = plot(freqs, mag, title = "Spectrum", xlim=(0, +1), ylims=(-1, 5))
    p = plot(time_domain, freq_domain, layout = 2) 
    display(p)
    return [freqs mag]
end

function get_amplitude(sol)
    # go through timeseries -> set start point 
    # -> advance as long as next vector is further away from start than previous one
    # -> when this is not the case anymore the path is considered one amplitude
    # -> check  whether this amplitued exceeds the currently longest amplitude
    # ↺ for entire time series
    vertex_id = 18 +1
    largest_aplitude = 0
    timeseries = sol[vertex_id*6:vertex_id*6+2, :]

    start_node = nothing
    prev_node = nothing
    current_amplitude_length = 0

    for vector in eachcol(timeseries)
        if start_node === nothing
            start_node = vector
        elseif prev_node === nothing
            current_amplitude_length = norm(start_node - vector)
            prev_node = vector
        elseif norm(start_node - vector) < norm(start_node - prev_node)
            # terminal condition
            if largest_aplitude < current_amplitude_length
                largest_aplitude = current_amplitude_length
            end
            start_node = nothing
            prev_node = nothing
        else
            current_amplitude_length += norm(prev_node - vector)
            prev_node = vector
        end
    end
    return largest_aplitude
end

function get_dominant_frequency(sol)
    spectrum = get_frequency(sol, 30, 18+1)
    get_frequency(sol, 30, 20)
    trimmed_spectrum = spectrum[0.2 .< spectrum[:, 1] .< 1.0, :]
    max_mag, index = findmax(trimmed_spectrum[:,2])
    return trimmed_spectrum[index]
end

# If we add weight and stiffness (in a way the frequency remains the same)
steps = 1:1:30

sol = TrussFab.run_simulation(g, tspan=(0., 30.), fps=30, actuation_power=50.0)

solution_cache = []

for step in steps
    # set_stiffness(step*10 + 10000)
    set_weight(step*3 + 40)
    sol = TrussFab.run_simulation(g, tspan=(0., 30.), fps=30, actuation_power=10.0)
    get_dominant_frequency(sol)
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
 

