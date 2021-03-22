using Random
using Revise
# TODO refactor out dependecies to low level graph libs and instead use TrussGraph type
using MetaGraphs
using LightGraphs
using Plots
using LinearAlgebra

using MultivariateStats

using Distributed
import TrussFab

# workers = addprocs([("root@157.90.240.68", 32)], exename="/root/julia-1.5.3/bin/julia", dir="/root/TrussFab/src/julia/src", tunnel=true)
addprocs(10, dir="./")
# @everywhere include("../warm_up.jl")

@everywhere begin
    using Pkg
    Pkg.activate("./")
    Pkg.instantiate()
    println("checking dependecies... (this takes some time on the first run of the app)")
    import TrussFab
    TrussFab.warm_up()
    # include("src/analysis.jl")
end

seed = MersenneTwister(1234)
g = TrussFab.import_trussfab_file("./test_models/seesaw_3.json")


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


function simulate(g::TrussFab.TrussGraph, spring_constants, age, type)
    if type !== :ramp_up
       throw(ErrorException("Not yet implemeted. Only ramp up simulations are supported rn."))
    end

    # println((spring_constants, age, type))
    TrussFab.set_stiffness!(g, spring_constants)
    TrussFab.set_age!(g, age)

    return @spawnat :any begin
        sol = TrussFab.run_simulation(g, tspan=(0., 10.), fps=3)
        # the calculation of the metrics should be also done on the worker to minimize serialization effort
        [[TrussFab.get_dominant_frequency(sol, v), TrussFab.get_amplitude(sol, v)[1]] for v in TrussFab.users(g)]
    end
end

plot_matrix = m -> heatmap(m, color=:greys)

# parameter space
spring_stiffnesses = range(5e3, 15e3, length=5)
additional_weights = [5, 10]

# single sample
age_groups = [5.0, 7.0, 12.0]
types = [:ramp_up]
samples = (Iterators.product([spring_stiffnesses for _ in TrussFab.springs(g)]...) .|> tuple -> [tuple...]) |> collect |> v -> hcat(v...) |> transpose

shuffled_samples = shuffle(seed, samples)

function run_sample(sample)
    return map(age -> [sample...; age; fetch(simulate(g, sample, age, :ramp_up))...], age_groups)
end

using ProgressBars
@time results = asyncmap(run_sample, ProgressBar(eachrow(shuffled_samples)), ntasks=1)

results2 = cat(vcat(results...)..., dims=2)
reshape(results2, )


using CSV
using Tables
table = Tables.table(transpose(results2), header=["spring_1", "spring_2", "spring_3", "age", "user_1_freq", "user_1_amplitude_length", "user_2_freq", "user_2_amplitude_length"])
CSV.write("seesaw_sampling.csv", table)


results2 = hcat(results...) |> transpose
display(plot_matrix(results2))

function distance(sample1, sample2)
    # TODO come up with sane weighing
    (sample1 .- sample2 .|> x -> x^2) |> sum
end

function find_closes_sample_index(vector)
    return findmin([distance(vector, sample) for sample in results])[2]
end

using Serialization
serialize("./seesaw_sampling3", (samples, results))
shuffled_samples, results = deserialize("./seesaw_sampling3")
index = find_closes_sample_index(fill(100, 9))
results[index]
shuffled_samples[index]
plot(results2)
results[1]
