using Pkg

cd(@__DIR__)
Pkg.activate("./")
Pkg.instantiate()

println("Precompiling Server...")
include("./src/Server.jl")
serve()
