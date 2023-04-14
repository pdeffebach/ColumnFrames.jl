# ColumnFrames.jl

A lightweight Tables.jl compatible table designed to mimic the `NamedTuple` API. It is designed for authors of Statistical packages who want an easty-to-use table type without large dependency chains.

## Motivation

In the Julia data ecosystem, package authors have two main options when working with tabular data: `NamedTuple`s and `DataFrame`s from DataFrames.jl. 

`NamedTuple`s are useful because it has no dependencies and a streamlined API, however they have a few drawbacks. First, they are not mutable, making it difficult to work with as a persistent object. Second, `NamedTuple`s encode column names and types as part of the type information. This can create annoying compile times for interactive work and prohibitively long compile times for wide tables --- over 1000 columns. Finally, they are not designed for tables, and do not check for consistent column lenghts.

`DataFrame`s are fast for interactive work and are mutable, but the DataFrames.jl package is large has numerous dependencies, making it unsuitable for package authors looking to avoid long compile times and package incompatabilities. It also has a large API surface, which may feel like "overkill" for minimal table operations.

The ColumnFrames.jl seeks the best of both worlds. It provides the `AbstractColumnFrame` type which 

* Has no dependencies apart from Tables.jl
* Has a limited API surface. `AbstractColumnFrame` provides *only* the API of  `NamedTuple` from Base and Tables.jl, apart from a few usability exceptions such as indexing with strings and copying. 
* Is deliberately type-unstable, which allows for convenient interactive work and wide tables (type stability is easily regained with function barriers)
* Presents the `MutableColumnFrame` type for mutable columnframes, making it easy to add new columns like a `DataFrame`

## Usage

The `AbstractColumnFrame` type has two sub-types: `ColumnFrame` and `MutableColumnFrame`. They are both indexed collections of columns, similar to a `DataFrame`. `MutableColumnFrame` allows adding columns. 

```@setup all
using ColumnFrames
using ColumnFrames: Tables
```

### Construction

You can construct a `ColumnFrame` or `MutableColumnFrame` in the following ways

* Keyword arguments
* A vector of data and a vector of names
* Any type of Tables.jl source, including a `NamedTuple` of vectors and a vector of `NamedTuple`s. `ColumnFrame`s and `MutableColumnFrame`s can both be constructed seamlessly from CSV.jl's `CSV.File` objects as well as `DataFrame`s, `StructArray`s and any other Tables.jl source. 

See examples below. 

```@example all
person_names = ["Juan", "Ziyi", "Annette", "Muhammad"];
ages = [34, 45, 27, 52];
nt = (; person_name = person_names, age = ages);
rowtable = [
	(person_name = "Juan", age = 34),
	(person_name = "Ziyi", age = 45),
	(person_name = "Annette", age = 27),
	(person_name = "Muhammad", age = 52)]

s = begin 
	ColumnFrame(; person_name = person_names, age = ages);
	ColumnFrame([person_names, ages], [:person_name, :ages])
	ColumnFrame(nt)
	ColumnFrame(rowtable)
end
```

```@example all
m = begin 
	MutableColumnFrame(; person_name = person_names, age = ages);
	MutableColumnFrame([person_names, ages], [:person_name, :ages])
	MutableColumnFrame(nt)
	MutableColumnFrame(rowtable)
end
```

### Learning about the `ColumnFrame`

The API of ColumnFrames.jl is as close as possible to a `NamedTuple`. 

#### Number of columns

Length and iteration mirror `NamedTuple`s

```@example all
length(s)
```

```@example all
for col in s
	println(col)
end
```

#### Names of columns

Get the names of the columns with `keys` or `propertynames`. Also the `columnnaes` function from Tables.jl

```@example all
column_names = begin
	keys(s)
	propertynames(s)
	Tables.columnnames(s)
end
```

Check that a column exists with `haskey`

```@example all
haskey(s, :person_name)
```

#### Length of columns

ColumnFrames.jl performed internal checks to ensure the length of columns are the same. Get the length by calling

```@example all
length(first(s))
```

### Accessing columns

Columns can be accessed via `getproperty` (`x.a`), or `getindex` (`x[:a]`), for both `Symbol`s and `Strings`. Columns can also be accessed by column position. 

```@example all
person_names = begin
	s.person_name
	s."person_name"
	s[:person_name]
	s["person_name"]
	s[1]
end
```

### Subsetting columns

Create a new `AbstractColumnFrame` object by indexing an `AbstractVector` or `Tuple` of names. Row indexing is not supported. 

```@example all
s = ColumnFrame(
	[i * (1:3) for i in 1:5], 
	[Symbol("x$i") for i in 1:5])

s_sub = begin
	s[[:x1, :x2, :x3]]
	s[["x1", "x2", "x3"]]
	s[1:3]
	s[(:x1, :x2, :x3)]
	s[("x1", "x2", "x3")]
	s[(1, 2, 3)]
end
```

### Adding columns to `MutableDataFrame`s

Only `MutablColumnFrame`s support adding columns. You can add a column via `setindex!` (`s[:a] = ...`), or `setproperty!` (`s.a = ...`). 

```@example all
m = MutableColumnFrame(;
	person_name = ["Juan", "Ziyi", "Annette", "Muhammad"],
	age = [34, 45, 27, 52])

m[:city] = ["San Diego", "Columbus", "Santa Fe", "Concord"]
m["Commute length"] = [34, 12, 45, 43]
m.commute_type = ["Car", "Train", "Walk", "Bike"]
m
```

You can also modify existing columns in the same way

```@example all
m[:age] = m.age .+ 1
m[2] = m.age .- 1 # Second column is age
m
```

### Deleting columns from `MutableDataFrame`s

You can delete columns from a `MutableDataFrame` with `delete!`

```@example all
m2 = delete!(m, :commute_type)
```



