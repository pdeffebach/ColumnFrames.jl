abstract type AbstractColumnFrame{V<:AbstractVector{<:AbstractVector}} end


# Shared
struct Index
    lookup::Dict{Symbol, Int}      # name => names array position
    nms::Vector{Symbol}
end

function Index(names::Vector{Symbol})
    lookup = Dict{Symbol, Int}(zip(names, 1:length(names)))
    return Index(lookup, names)
end

## Im_ismutable, tabular
struct ColumnFrame{V <: AbstractVector} <: AbstractColumnFrame{V}
    index::Index
    vals::V
end

function check_cols(nms, cols)
    if length(nms) != length(cols)
        throw(DimensionMismatch("lengths do not match"))
    end
    # Stolen from DataFrames.jl
    len = -1
    firstvec = -1
    for (i, col) in enumerate(cols)
        if len == -1
            len = length(col)
        elseif len != length(col)
            n1 = nms[1]
            n2 = nms[i]
            throw(DimensionMismatch("column :$n1 has length $len and column " *
                                    ":$n2 has length $(length(col))"))
        end
    end
end
check_cols(t::AbstractColumnFrame) = check_cols(names(t), vals(t))

function ColumnFrame(nms::Vector{Symbol}, cols::V) where {V<:Union{AbstractVector{<:AbstractVector}, AbstractVector{AbstractVector}}}
    check_cols(nms, cols)
    ColumnFrame{V}(Index(nms), cols)
end

function ColumnFrame(; kwargs...)
    ColumnFrame((; kwargs...,))
end

function ColumnFrame(nt::NamedTuple)
    nms = collect(propertynames(nt))
    vals = collect(values(nt))
    ColumnFrame(nms, vals)
end

# Special case for empty named tuple
function ColumnFrame(nt::NamedTuple{(), Tuple{}})
    ColumnFrame(Symbol[], AbstractVector[])
end

names(t::ColumnFrame) = getfield(getfield(t, :index), :nms)
lookup(t::ColumnFrame) = getfield(getfield(t, :index), :lookup)
vals(t::ColumnFrame) = getfield(t, :vals)
constructor_name(t::ColumnFrame) = ColumnFrame
constructor_name(t::Type{ColumnFrame{V}}) where {V} = ColumnFrame

function Base.show(io::IO, ::MIME"text/plain", t::AbstractColumnFrame{V}) where {V}
    check_cols(t)
    io = IOContext(io, :compact=>get(io, :compact, true), :displaysize => (10, 10))
    num_elements = length(t)
    m = _ismutable(t) ? "Mutable" : "Immutable"
    println(io, "$m ColumnFrame with $num_elements columns and column type $(eltype(V)):")
    if length(t) <= 20
        for i in eachindex(names(t))
            println(io, names(t)[i], ":  ", vals(t)[i])
        end
    else
        @show inds = vcat(1:10, (length(t)-10):length(t))
        for i in inds
            println(io, names(t)[i], ":  ", vals(t)[i])
            i == 10 && println(io, "...")
        end
    end
end

struct MutableColumnFrame{V <: AbstractVector} <: AbstractColumnFrame{V}
    index::Index
    vals::V
end

names(t::MutableColumnFrame) = getfield(getfield(t, :index), :nms)
lookup(t::MutableColumnFrame) = getfield(getfield(t, :index), :lookup)
vals(t::MutableColumnFrame) = getfield(t, :vals)
constructor_name(t::MutableColumnFrame) = MutableColumnFrame
constructor_name(t::Type{MutableColumnFrame{V}}) where {V} = MutableColumnFrame


_ismutable(t::AbstractColumnFrame) = false
_ismutable(t::MutableColumnFrame) = true

function MutableColumnFrame(t::ColumnFrame{V}) where {V}
    d = copy(lookup(t))
    n = copy(names(t))
    v = convert(Vector{AbstractVector}, vals(t))
    MutableColumnFrame{typeof(v)}(Index(d, n), v)
end

function MutableColumnFrame(args...; kwargs...)
    MutableColumnFrame(ColumnFrame(args...; kwargs...))
end


