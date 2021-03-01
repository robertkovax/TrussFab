using Pkg

cd(@__DIR__)
Pkg.activate("./")
Pkg.instantiate()

include("./src/Server.jl")
println("Starting Server...")
serve()
