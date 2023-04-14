"""
    ColumnFrame(table)

Construct a `ColumnFrame` from any Tables.jl compatible source.
Does not copy the underlying columns.
"""
function ColumnFrame(table)
    if Tables.istable(table) == false
        throw(ArgumentError("Not a Tables.jl source"))
    end

    table = Tables.columns(table)

    nms = collect(Tables.columnnames(table))
    cols = AbstractVector[Tables.getcolumn(table, nm) for nm in nms]

    ColumnFrame(cols, nms)
end

"""
    MutableColumnFrame(table)

Construct a `MutableColumnFrame` from any Tables.jl compatible source.
Does not copy the underlying columns.

```

```
"""
function MutableColumnFrame(table)
    if Tables.istable(table) == false
        throw(ArgumentError("Not a Tables.jl source"))
    end

    table = Tables.columns(table)

    nms = collect(Tables.columnnames(table))
    cols = AbstractVector[Tables.getcolumn(table, nm) for nm in nms]

    MutableColumnFrame(cols, nms)
end

Tables.istable(::Type{<:AbstractColumnFrame}) = true
Tables.columnaccess(::Type{<:AbstractColumnFrame}) = true
Tables.columns(x::AbstractColumnFrame) = x

function Tables.schema(t::AbstractColumnFrame)
    types = eltype.(vals(t))
    Tables.Schema(names(t), types)
end

# to do
Tables.materializer(t::Type{<:AbstractColumnFrame}) = constructor_name(t)
#Tables.subset(x::MyTable, inds; viewhint)

Tables.getcolumn(table::AbstractColumnFrame, i::Int) = table[i]
Tables.getcolumn(table::AbstractColumnFrame, nm::Symbol) = table[nm]
Tables.columnnames(table::AbstractColumnFrame) = names(table)
