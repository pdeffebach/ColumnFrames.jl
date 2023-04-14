function Base.setproperty!(t::MutableColumnFrame, name::Symbol, x::AbstractVector)

    d = lookup(t)
    v = vals(t)
    n = names(t)

    if !isempty(t) && length(first(v)) != length(x)
        throw(DimensionMismatch("new column must have the same length as old columns"))
    end
    if haskey(t, name)
        ind = d[name]
        v[ind] = x
        n[ind] = name
    else
        ind = length(t) + 1
        d[name] = ind
        push!(v, x)
        push!(n, name)
    end
    return x
end
Base.setproperty!(t::MutableColumnFrame, name::AbstractString, x::AbstractVector) =
    setproperty!(t, Symbol(name), x)

Base.setindex!(t::MutableColumnFrame, x::AbstractVector, name::Symbol) = setproperty!(t, name, x)
Base.setindex!(t::MutableColumnFrame, x::AbstractVector, name::AbstractString) = setproperty!(t, name, x)
function Base.setindex!(t::MutableColumnFrame, x::AbstractVector, i::Integer)
    d = lookup(t)
    v = vals(t)
    n = names(t)
    if !isempty(t) == false && length(first(v)) != length(x)
        throw(DimensionMismatch("new column must have the same length as old columns"))
    end
    setindex!(vals(t), x, i)
end

function fix_dict!(d, ind)
    for k in keys(d)
        v = d[k]
        if v > ind
            d[k] = v - 1
        end
    end
end

function Base.delete!(t::MutableColumnFrame, name::Symbol)
    d = lookup(t)
    ind = d[name]
    delete!(d, name)
    deleteat!(names(t), ind)
    deleteat!(vals(t), ind)
    fix_dict!(d, ind)
    t
end

Base.delete!(t::MutableColumnFrame, name::AbstractString) = delete!(t, Symbol(name))

function Base.delete!(t::MutableColumnFrame, ind)
    nms = names(t)
    name = nms[ind]
    d = lookup(t)
    delete!(d, name)
    deleteat!(nms, ind)
    deleteat!(vals(t), ind)
    fix_dict!(d, ind)
    t
end

function Base.get!(t::MutableColumnFrame, key, default)
    if haskey(t, key)
        t[key]
    else
        t[k] = default
    end
end

Base.setproperty!(t::ColumnFrame, name::Symbol, x::AbstractVector) =
    throw(ArgumentError("Cannot add columns to ColumnFrames. Use a MutableColumnFrame instead"))

Base.setproperty!(t::ColumnFrame, name::AbstractString, x::AbstractVector) =
    throw(ArgumentError("Cannot add columns to ColumnFrames. Use a MutableColumnFrame instead"))

Base.setindex!(t::ColumnFrame, x::AbstractVector, name::Symbol) =
    throw(ArgumentError("Cannot add columns to ColumnFrames. Use a MutableColumnFrame instead"))

Base.setindex!(t::ColumnFrame, x::AbstractVector, name::AbstractString) =
    throw(ArgumentError("Cannot add columns to ColumnFrames. Use a MutableColumnFrame instead"))

Base.setindex!(t::ColumnFrame, x::AbstractVector, i::Integer) =
    throw(ArgumentError("Cannot add columns to ColumnFrames. Use a MutableColumnFrame instead"))

Base.delete!(t::ColumnFrame, name::Symbol) =
    throw(ArgumentError("Cannot remove columns from ColumnFrames. Use a MutableColumnFrame instead"))

Base.get!(t::ColumnFrame, key, default) =
    throw(ArgumentError("Cannot remove columns from ColumnFrames. Use a MutableColumnFrame instead"))