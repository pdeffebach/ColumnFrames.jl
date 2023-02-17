# ColumnFrames

A lightweight package for working with small tables with low compilation cost. Provides the abstract type `AbstractColumnTable` and sub-types `ColumnTable` and `MutableColumnTable` For use as a drop-in replacement for `NamedTuple`s of `Vectors`. 

`ColumnTable` implements the API of `NamedTuple` and nothing more, except for Tables.jl definitions. 

Unlike `NamedTuple`s of `Vector`s, `AbstractColumnTable` do not store names or a tuple of element types in the type information. This allows 1000s of columns to be created with low compilation cost. 

`MutableColumnTable` implements the same methods as `ColumnTable`, but in addition is mutable, meaning it implements the methods `setfield!` and `setproperty!`. 

## Examples

```julia
julia> using ColumnFrames

julia> t = ColumnFrame([:a, :b], [[1, 2], [4, 5]])
Immutable ColumnFrame with 2 columns and column type Vector{Int64}:
a:  [1, 2]
b:  [4, 5]


julia> t.a
2-element Vector{Int64}:
 1
 2

julia> s = MutableColumnFrame([:a, :b], [[1, 2], [3, 4]])
Mutable ColumnFrame with 2 columns and column type AbstractVector:
a:  [1, 2]
b:  [3, 4]


julia> s.c = [5, 6]
2-element Vector{Int64}:
 5
 6

julia> s
Mutable ColumnFrame with 3 columns and column type AbstractVector:
a:  [1, 2]
b:  [3, 4]
c:  [5, 6]
```