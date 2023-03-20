# ColumnFrames.jl

A lightweight Tables.jl compatible table designed to mimic the `NamedTuple` API. It is designed for authors of Statistical packages who want an easty-to-use table type without large dependency chains.


## Motivation

In the Julia data ecosystem, package authors have two main options when working with tabular data: `NamedTuple`s and `DataFrame`s from DataFrames.jl. 

`NamedTuple`s are useful because it has no dependencies and a streamlined API, however they have a few drawbacks. First, they is not mutable, making it difficult to work with as a persistent object. Second, `NamedTuple`s encode column names and types as part of the type information. This can create annoying compile times for interactive work and prohibitively long compile times for wide tables --- over 1000 columns. Finally, they are not designed for tables, and do not check for consistent column lenghts.

`DataFrame`s are fast for interactive work and are mutable, but the DataFrames.jl package is large has numerous dependencies, making it unsuitable for package authors looking to avoid long compile times and package incompatabilities. It also has a large API surface, which may feel like "overkill" for minimal table operations.

The ColumnFrames.jl seeks the best of both worlds. It provides the `AbstractColumnFrame` type which 

* Has no dependencies apart from Tables.jl
* Has a limited API surface. `AbstractColumnFrame` provides *only* the API of  `NamedTuple` from Base and Tables.jl, apart from a few usability exceptions such as indexing with strings and copying. 
* Is deliberately type-unstable, which allows for convenient interactive work and wide tables (type stability is easily regained with function barriers)
* Presents the `MutableColumnFrame` type for mutable columnframes, making it easy to add new columns like a `DataFrame`

# Usage

The `AbstractColumnFrame` type has two sub-types: `ColumnFrame` and `MutableColumnFrame`. They are both indexed collections of columns, similar to a `DataFrame`. `MutableColumnFrame` allows adding columns. 

## Constructor

```@setup all
using ColumnFrames
```

```@repl all
using ColumnFrames
s = ColumnFrame(a = [1, 2, 3], b = [4, 5, 6])
```


```@repl all
ColumnFrame(a = [5, 6])
```

