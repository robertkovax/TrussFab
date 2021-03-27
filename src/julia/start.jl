using Distributed
using Pkg

println(ARGS)

cd(@__DIR__)
Pkg.activate(".")
println("checking dependecies... (this takes some time on the first run of the app)")
Pkg.instantiate()

println("starting up simulation workers...")
addprocs(3, dir="./", exeflags="--project")
# addprocs(3, dir="./", exeflags="-Jsysimage")

@everywhere using TrussFab
for worker in workers()
    @spawnat worker include("./warm_up.jl")
end

println("precompiling http server...")
include("./src/Server.jl")
