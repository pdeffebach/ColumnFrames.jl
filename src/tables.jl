function ColumnFrame(table)
    if Tables.istable(table) == false
        throw(ArgumentError("Not a Tables.jl source"))
    end

    nms = collect(Tables.columnnames(table))
    cols = [Tables.getcolumn(table, nm) for nm in nms]
    ColumnFrame(nms, cols)
end

Tables.istable(::Type{<:AbstractColumnFrame{V}}) where {V} = true
Tables.columnaccess(::Type{<:AbstractColumnFrame{V}})  where {V} = true
Tables.columns(x::AbstractColumnFrame) = x

function Tables.schema(t::AbstractColumnFrame)
    types = eltype.(vals(t))
    Tables.Schema(names(t), types)
end

# to do
Tables.materializer(t::Type{<:AbstractColumnFrame{V}}) where {V} = constructor_name(t)
#Tables.subset(x::MyTable, inds; viewhint)

Tables.getcolumn(table::AbstractColumnFrame, i::Int) = table[i]
Tables.getcolumn(table::AbstractColumnFrame, nm::Symbol) = table[nm]
Tables.columnnames(table::AbstractColumnFrame) = names(table)
