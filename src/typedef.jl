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


function print_col(io, padded_name, col, allowed_width)
    width = 0
    j = 1
    print(io, padded_name)
    print(io, " [")
    len_col = length(col)
    while j <= len_col
        item = sprint(show, col[j]; context = io)
        width = width + textwidth(item) + 2 # The comma and space below
        if width > (allowed_width - 4)
            print(io, "...]")
            break
        elseif j == len_col
            print(io, item, "]")
        else
            print(io, item, ", ")
        end
        j = j + 1
    end
end

function Base.show(io_out::IO, ::MIME"text/plain", t::AbstractColumnFrame{V}) where {V}
    check_cols(t)

    cols = vals(t)
    numcols = length(t)

    io_buf = IOBuffer()

    io = IOContext(io_buf,
        :compact=>get(io_out, :compact, true),
        :displaysize => get(io_out, :displaysize, (24, 80)),
        :limit=>true)


    m = _ismutable(t) ? "MutableColumnFrame" : "ColumnFrame"
    println(io, "$(length(first(cols))) by $(numcols) $m")


    allowed_height = io[:displaysize][1]
    allowed_width = io[:displaysize][2]

    two_part = numcols > 20
    if two_part
        total_show = min(numcols, allowed_height - 2) # For line above and middle ...
        inds_side = div(total_show, 2)
        inds = vcat(1:inds_side, (numcols-inds_side):length(t))
        split_val = inds_side
    else
        inds = 1:min(numcols, allowed_height-1)
        split_val = -1
    end

    less_height = numcols < allowed_height

    subnames = string.(names(t)[inds])
    textwidths = textwidth.(subnames)
    maxwidth = maximum(textwidths)
    padded_names = rpad.(subnames, maxwidth)

    i = 1
    max_ind = last(eachindex(inds))
    for i in eachindex(inds)
        print_col(io, padded_names[i], cols[inds[i]], allowed_width)
        i < max_ind && println(io)
        if i == split_val
            println(io, "...")
        end
    end
    print(io_out, String(take!(io_buf)))
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

# deepcopy the lookup when we construct directly
function MutableColumnFrame(t::ColumnFrame{V}) where {V}
    d = deepcopy(lookup(t))
    n = copy(names(t))
    v = convert(Vector{AbstractVector}, vals(t))
    MutableColumnFrame{typeof(v)}(Index(d, n), v)
end

function nocopy_mutablecolumnframe(t::ColumnFrame{V}) where {V}
    v = convert(Vector{AbstractVector}, vals(t))
    MutableColumnFrame{typeof(v)}(getfield(t, :index), v)
end

function MutableColumnFrame(args...; kwargs...)
    nocopy_mutablecolumnframe(ColumnFrame(args...; kwargs...))
end

function ColumnFrame(t::MutableColumnFrame)
    ColumnFrame(names(t), vals(t))
end


