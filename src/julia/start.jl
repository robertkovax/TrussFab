using Pkg


cd(@__DIR__)
Pkg.activate("./")
println("checking dependecies... (this takes some time on the first run of the app)")
Pkg.instantiate()

println("precompiling server...")
include("./src/Server.jl")
serve()
