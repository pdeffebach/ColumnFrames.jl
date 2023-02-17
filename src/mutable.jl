function Base.setproperty!(t::MutableColumnFrame, name::Symbol, x::AbstractVector)
    d = lookup(t)
    v = vals(t)
    n = names(t)
    if length(first(v)) != length(x)
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
Base.setindex!(t::MutableColumnFrame, x, name::Symbol, ) = setproperty!(t, name, x)
Base.setindex!(t::MutableColumnFrame, x::AbstractVector, name::Symbol) = setproperty!(t, name, x)

Base.setindex!(t::MutableColumnFrame, x,  i::Integer,) = setfield!(vals(t), x, i)

function Base.setindex!(t::MutableColumnFrame, x::AbstractVector, i::Integer)
    d = lookup(t)
    v = vals(t)
    n = names(t)
    if length(first(v)) != length(x)
        throw(DimensionMismatch("new column must have the same length as old columns"))
    end
    setindex!(vals(t), x, i)
end