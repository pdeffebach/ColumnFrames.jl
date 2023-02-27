push!(LOAD_PATH, "..")

using Documenter
using ColumnFrames

makedocs(
	sitename = "ColumnFrames.jl",
	pages = Any[
		"Introduction" => "index.md",
		"API" => "api/api.md"],
	format = Documenter.HTML(
		canonical = "https://pdeffebach.github.io/ColumnFrames.jl/stable/"
	))

deploydocs(
    repo = "github.com/pdeffebach/ColumnFrames.jl.git",
    target = "build",
    deps = nothing,
    make = nothing)
