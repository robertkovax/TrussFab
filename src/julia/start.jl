using Pkg

Pkg.activate("./")
Pkg.instantiate()

include("./src/Server.jl")
println("Starting Server...")
serve()
