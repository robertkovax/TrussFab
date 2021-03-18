using Random
using Revise
using MetaGraphs
using LightGraphs
using Plots
import TrussFab
using LinearAlgebra

using MultivariateStats


include("analysis.jl")

seed = MersenneTwister(1234)
g = TrussFab.import_trussfab_file("./test_models/seesaw_3.json")

function set_stiffness(k::Float64)
    for e in edges(g)
        if get_prop(g, e, :type) == "spring"
            set_prop!(g, e, :spring_stiffness, k)
        end
    end
end

function set_stiffness(ks::AbstractArray{Float64, 1})
    ks = deepcopy(ks)
    for e in edges(g)
        if get_prop(g, e, :type) == "spring"
            set_prop!(g, e, :spring_stiffness, pop!(ks))
        end
    end
end


function set_first_stiffness(k)
    for e in edges(g)
        if get_prop(g, e, :type) == "spring"
            set_prop!(g, e, :spring_stiffness, k)
            return
        end
    end
end

function set_weight!(g, m)
    for v in TrussFab.users(g)
        set_prop!(g, v, :m, m)
    end
end

function set_actuation!(g, watts)
    for v in TrussFab.users(g)
        set_prop!(g, v, :actuation_power, watts)
    end
end

function weight(age)
    2.75 * (age-3) + 15
end

function power(age)
    7 * (age-3) + 30
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

function get_ramp_up_time(sol)
    # TODO implement
    return 1.0
end

function poincare_section_fit(sol)
    return fit(PCA, sol; maxoutdim=10)
    # reconstruct testing observations (approximately)
    # Xr = reconstruct(M, Yte)
    # plot(Xr')
end

function poincare_section(model, sol)
    # suppose Xtr and Xte are training and testing data matrix,
    # with each observation in a column

    # train a PCA model

    # apply PCA model to testing set
    Yte = transform(model, sol)
    p = plot(Yte[1, :], Yte[2, :])
    display(p)
end


function plot_solutions(solutions)
    frequencies = solutions .|> get_dominant_frequency
    amplitudes = solutions .|> get_amplitude
    display(plot(steps.*3 .+ 40, [frequencies amplitudes]))
end
plot_solutions(solution_cache2)

users = filter(v -> get_prop(g, v, :active_user), vertices(g))
springs = filter(e -> get_prop(g, e, :type) == "spring", collect(edges(g)))

# parameter space
spring_stiffnesses = 5e3:1e3:15e3
additional_weights = [5, 10]

# single sample
age_groups = [5, 7, 12]
types = [:ramp_up]


samples = Iterators.product([spring_stiffnesses for _ in springs]...) |> collect |> vec


function simulate(spring_constants, age, type)
    if type !== :ramp_up
       throw(ErrorException("Not yet implemeted. Only ramp up simulations are supported rn."))
    end

    println((spring_constants, age, type))
    set_stiffness([spring_constants...])
    sol = TrussFab.run_simulation(g, tspan=(0., 10.), fps=3)
    user_metrics = [[get_dominant_frequency(sol, v), get_amplitude(sol, v)[1]] for v in users]
    return [get_ramp_up_time(sol); user_metrics...]
end

    

results = []
shuffled_samples = shuffle(seed, samples)
for sample in shuffled_samples
    result_vector = []
    for age in age_groups
        for type in types
            result_vector = simulate(sample, age, type)
        end
    end
    push!(results, result_vector)
end

results
nothing