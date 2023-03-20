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

function truncatestring(s::AbstractString, truncstring::Int)
    truncstring <= 0 && return s
    totalwidth = 0
    for (i, c) in enumerate(s)
        totalwidth += textwidth(c)
        if totalwidth > truncstring
            return first(s, i-1) * '…'
        end
    end
    return s
end

our_sprint(col::AbstractVector, io) = sprint.(show, col; context = io)
our_sprint(col::AbstractVector{<:AbstractString}, io) =
    [@sprintf("%s", truncatestring(c, 10)) for c in col]

our_sprintf(c) = @sprintf("%.5g", c)
our_sprint(col::AbstractVector{<:Real}, io) =
    our_sprintf.(col)

function rpad_cols(col, colname, io)
    cols_str = our_sprint(col, io)
    maxwidthcol = max(textwidth(colname), maximum(textwidth.(cols_str)))
    rpad.(cols_str, maxwidthcol)
    if col isa AbstractVector{<:AbstractString}
        padded_cols = rpad.(cols_str, maxwidthcol)
    else
        padded_cols = lpad.(cols_str, maxwidthcol)
    end
    out = vcat([rpad(colname, maxwidthcol), repeat("─", maxwidthcol)], padded_cols)
    return out, maxwidthcol
end

function Base.show(io_out::IO, ::MIME"text/plain", t::AbstractColumnFrame{V}) where {V}
    check_cols(t)

    cols = vals(t)
    numcols = length(t)
    numrows = length(first(cols))
    colnames = string.(names(t))

    io_buf = IOBuffer()

    io = IOContext(io_buf,
        :compact=>get(io_out, :compact, true),
        :displaysize => get(io_out, :displaysize, displaysize(io_out)),
        :limit=>get(io_out, :typeinfo, true),
        :colo=>get(io_out, :color, true))


    m = _ismutable(t) ? "MutableColumnFrame" : "ColumnFrame"
    size_str = @sprintf("%d×%d %s", numrows, numcols, nameof(typeof(t)))
    println(io, size_str)


    allowed_height = min(20, io[:displaysize][1])
    allowed_width = min(100, io[:displaysize][2])

    two_part = numrows > 20
    if two_part
        total_show = min(numrows, allowed_height - 2) # For line above and middle ...
        inds_side = div(total_show, 2)
        inds = vcat(1:inds_side, (numrows - (total_show - inds_side) + 1):numrows)
        split_val = inds_side
    else
        inds = 1:min(numrows, allowed_height-1)
        split_val = -1
    end

    less_height = (numrows+2) < allowed_height # Header row and header line

    width = 0
    j = 1
    row_cols, row_width = rpad_cols(inds, "row", io)
    padded_cols = [row_cols]
    width = width + row_width + 2 # two spaces
    while j <= numcols
        colname = colnames[j]
        col = cols[j][inds]
        padded_col, colwidth = rpad_cols(col, colname, io)
        width = width + colwidth + 2 # 2 spaces in between
        if width > (allowed_width - 3) # Two spaces and the dots
            break
        else
            push!(padded_cols, padded_col)
        end
        j = j + 1
    end
    if j < numcols
        end_dots = vcat(["⋯", "─"], ["⋯" for i in 1:length(inds)])
        push!(padded_cols, end_dots)
    end

    for i in 1:(length(inds) + 2) # Column line and header line
        for j in eachindex(padded_cols)
            print(io, padded_cols[j][i], "  ")
        end
        println(io)
        if (i-2) == split_val
            println(io, "⋯")
        end
    end

    print(io_out, String(take!(io_buf)))
end

#=
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
            println(io, "⋮")
        end
    end
    print(io_out, String(take!(io_buf)))
=#

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


