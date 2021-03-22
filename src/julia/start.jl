using Distributed
using Pkg


cd(@__DIR__)
Pkg.activate(".")
println("checking dependecies... (this takes some time on the first run of the app)")
Pkg.instantiate()

println("starting up simulation workers...")
workers = addprocs(3, dir="./", exeflags="--project")

@everywhere using TrussFab
for worker in workers
    @spawnat worker include("./warm_up.jl")
end

println("precompiling http server...")
include("./src/Server.jl")
