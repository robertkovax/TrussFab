### A Pluto.jl notebook ###
# v0.11.12

using Markdown
using InteractiveUtils

# ╔═╡ 1b4dec78-f1a4-11ea-2fcb-e7fd66f77146
using JuMP, GLPK

# ╔═╡ 26f399d8-f1a4-11ea-111c-3914ee47e185
model = Model(with_optimizer(GLPK.Optimizer))

# ╔═╡ 3ecf2df6-f1a4-11ea-0cab-69fdf737b4f6
@variable(model, 0 <= x <= 2)

# ╔═╡ 4b8337e0-f1a4-11ea-2e57-572907f941cf
@variable(model, 0 <= y <= 30)

# ╔═╡ 546e856e-f1a4-11ea-225f-1f314ce64a5c
@objective(model, Max, 5x + 3 * y)

# ╔═╡ 6cbf5d80-f1a4-11ea-225b-29a79c2b2061
model

# ╔═╡ 5b9daff4-f1a4-11ea-3f12-2ffe4abd450a
@constraint(model, con, 1x + 5y <= 3)

# ╔═╡ 760005f2-f1a4-11ea-223f-4b43a9304fd6
optimize!(model)

# ╔═╡ 64052cce-f1a4-11ea-1584-5d729de45982
objective_value(model)

# ╔═╡ Cell order:
# ╠═1b4dec78-f1a4-11ea-2fcb-e7fd66f77146
# ╠═26f399d8-f1a4-11ea-111c-3914ee47e185
# ╠═3ecf2df6-f1a4-11ea-0cab-69fdf737b4f6
# ╠═4b8337e0-f1a4-11ea-2e57-572907f941cf
# ╠═546e856e-f1a4-11ea-225f-1f314ce64a5c
# ╠═6cbf5d80-f1a4-11ea-225b-29a79c2b2061
# ╠═5b9daff4-f1a4-11ea-3f12-2ffe4abd450a
# ╠═760005f2-f1a4-11ea-223f-4b43a9304fd6
# ╠═64052cce-f1a4-11ea-1584-5d729de45982
