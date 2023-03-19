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

function Base.delete!(t::MutableColumnFrame, name::Symbol)
    d = lookup(t)
    ind = d[name]
    delete!(d, name)
    delete!(vals(t), ind)
end
