"""
`AbstractColumnFrame`


An abstract type for which all concrete types expose a
`NamedTuple`-like interface for working with tabular data.

An `AbstractColumnFrame` is a two-dimensional table with
`Symbol`s for column names. All columns must be the
same length.

There are two sub-types of `AbstractColumnFrame`, `ColumnFrame`,
whose structure cannot be altered, and `MutableColumnFrame`,
which behaves exactly the same as a `ColumnFrame` except columns
can be added and removed.

`AbstractColumnFrame` delibrately exposes a minimal interface.
They behave identical to a `NamedTuple` of vectors with few
deviations in order to

1. Avoid long compilation times by having type information
   of the columns and names stored as part of the type

2. Provide select convenience features for easier use of
   tabular data
"""
abstract type AbstractColumnFrame end


# Shared
struct Index
    lookup::Dict{Symbol, Int}      # name => names array position
    nms::Vector{Symbol}
end

function Index(names::Vector{Symbol})
    lookup = Dict{Symbol, Int}(zip(names, 1:length(names)))
    return Index(lookup, names)
end

"""
    ColumnFrame <: AbstractColumnFrame

A two-dimensional table with an API similar to that of a
`NamedTuple` of `Vector`s. Once created, columns cannot be
added or removed.
"""
struct ColumnFrame <: AbstractColumnFrame
    index::Index
    vals::Vector{AbstractVector}
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

"""
    ColumnFrame(cols::V, nms::Vector{Symbol}) where {V<:AbstractVector{<:AbstractVector}}}

Construct a `ColumnFrame` with names `nms` and column `cols`.
Allocates a new container for columns, but does not copy underlying
columns directly.

```
julia> ColumnFrame([[1, 2], [3, 4]], [:a, :b])
2×2 ColumnFrame
row  a  b
───  ─  ─
  1  1  3
  2  2  4
```
"""
function ColumnFrame(cols::V, nms::Vector{Symbol}) where {V<:AbstractVector{<:AbstractVector}}
    check_cols(nms, cols)
    v = AbstractVector[ci for ci in cols]
    ColumnFrame(Index(copy(nms)), cols)
end

"""
    ColumnFrame(; kwargs...)

Construct a `ColumnFrame` from `kwargs` in the form of `name => col` pairs
Does not copy columns directly.
```
julia> ColumnFrame(; a = [1, 2], b = [3, 4])
2×2 ColumnFrame
row  a  b
───  ─  ─
  1  1  3
  2  2  4
```
"""
function ColumnFrame(; kwargs...)
    ColumnFrame((; kwargs...,))
end

"""
    ColumnFrame(nt::NamedTuple)

Construct a `ColumnFrame` from a `NamedTuple` as input.
Does not copy columns directly.
```
julia> nt = (a = [1, 2], b = [3, 4]);

julia> ColumnFrame(nt)
2×2 ColumnFrame
row  a  b
───  ─  ─
  1  1  3
  2  2  4
```
"""
function ColumnFrame(nt::NamedTuple)
    nms = collect(propertynames(nt))
    vals = collect(values(nt))
    ColumnFrame(vals, nms)
end

# Special case for empty named tuple
function ColumnFrame(nt::NamedTuple{(), Tuple{}})
    ColumnFrame(AbstractVector[], Symbol[])
end

names(t::ColumnFrame) = getfield(getfield(t, :index), :nms)
lookup(t::ColumnFrame) = getfield(getfield(t, :index), :lookup)
vals(t::ColumnFrame) = getfield(t, :vals)
constructor_name(t::ColumnFrame) = ColumnFrame
constructor_name(t::Type{ColumnFrame}) = ColumnFrame

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

our_sprint(col::AbstractVector, io, w) = sprint.(show, col; context = io)
our_sprint(col::AbstractVector{<:AbstractString}, io, w) =
    [@sprintf("%s", truncatestring(c, w)) for c in col]

our_sprintf(c) = @sprintf("%.5g", c, w)
our_sprint(col::AbstractVector{<:Real}, io) =
    our_sprintf.(col)

function rpad_cols(col, colname, io)
    maxw_str = max(textwidth(colname), 10)
    cols_str = our_sprint(col, io, maxw_str)
    maxwidthcol = max(textwidth(colname), maximum(textwidth.(cols_str); init = 0))
    rpad.(cols_str, maxwidthcol)
    if col isa AbstractVector{<:AbstractString}
        padded_cols = rpad.(cols_str, maxwidthcol)
    else
        padded_cols = lpad.(cols_str, maxwidthcol)
    end
    out = vcat([rpad(colname, maxwidthcol), repeat("─", maxwidthcol)], padded_cols)
    return out, maxwidthcol
end

function Base.show(io_out::IO, ::MIME"text/plain", t::AbstractColumnFrame)
    check_cols(t)


    cols = vals(t)
    numcols = isempty(t) ? 0 : length(t)
    numrows = isempty(t) ? 0 : length(first(cols))
    colnames = string.(names(t))

    io_buf = IOBuffer()

    io = IOContext(io_buf,
        :compact=>get(io_out, :compact, true),
        :displaysize => get(io_out, :displaysize, displaysize(io_out)),
        :limit=>get(io_out, :typeinfo, true),
        :colo=>get(io_out, :color, true))

    m = _ismutable(t) ? "MutableColumnFrame" : "ColumnFrame"

    if isempty(t)
        size_str = @sprintf("0×0 %s", m)
        print(io, size_str)

        print(io_out, String(take!(io_buf)))
        return nothing
    end


    size_str = @sprintf("%d×%d %s", numrows, numcols, nameof(typeof(t)))
    println(io, size_str)

    allowed_height = min(22, io[:displaysize][1])
    allowed_width = min(100, io[:displaysize][2])

    two_part = numrows > 20
    if two_part
        total_show = min(numrows, allowed_height-2) # For line above and middle ...
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
        if width > (allowed_width - 3) # 2 spaces and the dots
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
        if two_part && (i-2) == split_val
            println(io, "⋯")
        end
    end

    print(io_out, String(take!(io_buf)))
end

"""
    ColumnFrame <: AbstractColumnFrame

A two-dimensional table with an API similar to that of a
`NamedTuple` of `Vector`s. Columns can be
added or removed.
"""
struct MutableColumnFrame <: AbstractColumnFrame
    index::Index
    vals::Vector{AbstractVector}
end

"""
    MutableColumnFrame(nt::NamedTuple)

Construct a `MutableColumnFrame` from a `NamedTuple` as input
Does not copy columns directly.

```
julia> nt = (a = [1, 2], b = [3, 4]);

julia> MutableColumnFrame(nt)
2×2 MutableColumnFrame
row  a  b
───  ─  ─
  1  1  3
  2  2  4
```
"""
function MutableColumnFrame(nt::NamedTuple)
    nms = collect(propertynames(nt))
    vals = collect(values(nt))
   MutableColumnFrame(vals, nms)
end

# Special case for empty named tuple
function MutableColumnFrame(nt::NamedTuple{(), Tuple{}})
    MutableColumnFrame(AbstractVector[], Symbol[])
end

names(t::MutableColumnFrame) = getfield(getfield(t, :index), :nms)
lookup(t::MutableColumnFrame) = getfield(getfield(t, :index), :lookup)
vals(t::MutableColumnFrame) = getfield(t, :vals)
constructor_name(t::MutableColumnFrame) = MutableColumnFrame
constructor_name(t::Type{MutableColumnFrame}) = MutableColumnFrame

_ismutable(t::AbstractColumnFrame) = false
_ismutable(t::MutableColumnFrame) = true

"""
    MutableColumnFrame(t::ColumnFrame)

Construct a `MutableColumnFrame` from an existing `ColumnFrame`
Allocates a fresh container for columns, but does not copy the
columns directly.
"""
function MutableColumnFrame(t::ColumnFrame)
    v = AbstractVector[vi for vi in vals(t)]
    MutableColumnFrame(v, copy(names(t)))
end

"""
    MutableColumnFrame(; kwargs...)

Construct a `MutableColumnFrame` from `kwargs` in the form of `name => col` pairs
Does not copy columns directly.
```
julia> MutableColumnFrame(; a = [1, 2], b = [3, 4])
2×2 MutableColumnFrame
row  a  b
───  ─  ─
  1  1  3
  2  2  4
```
"""
function MutableColumnFrame(; kwargs...)
    MutableColumnFrame((; kwargs...,))
end

"""
    MutableColumnFrame(cols::V, nms::Vector{Symbol}) where {V<:AbstractVector{<:AbstractVector}}}

Construct a `MutableColumnFrame` with names `nms` and column `cols`.
Allocates a new container for columns, but does not copy underlying
columns directly.

```
julia> MutableColumnFrame([[1, 2], [3, 4]], [:a, :b])
2×2 ColumnFrame
row  a  b
───  ─  ─
  1  1  3
  2  2  4
```
"""
function MutableColumnFrame(cols::V, nms::Vector{Symbol}) where {V<:AbstractVector{<:AbstractVector}}
    check_cols(nms, cols)
    v = AbstractVector[ci for ci in cols]
    MutableColumnFrame(Index(copy(nms)), cols)
end

"""
    ColumnFrame(t::MutableColumnFrame)

Construct a `ColumnFrame` from an existing `MutableColumnFrame`
Allocates a fresh container for columns, but does not copy the
columns directly.

```
julia> m = MutableColumnFrame(a = [1, 2], b = [3, 4]);

julia> ColumnFrame(m)
2×2 ColumnFrame
row  a  b
───  ─  ─
  1  1  3
  2  2  4
```
"""
function ColumnFrame(t::MutableColumnFrame)
    v = AbstractVector[vi for vi in vals(t)]
    ColumnFrame(v, copy(names(t)))
end


