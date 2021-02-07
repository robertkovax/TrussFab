using PackageCompiler
using Pkg

Pkg.activate(".")
PackageCompiler.create_sysimage(
    :TrussFab,
    sysimage_path="./sysimage",
    precompile_execution_file="./warm_up.jl",
    # cpu_target="generic;sandybridge,-xsaveopt,clone_all;haswell,-rdrnd,base(1)"
    cpu_target="haswell"
)
