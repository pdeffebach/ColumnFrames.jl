Base.length(t::AbstractColumnFrame) = length(vals(t))
Base.iterate(t::AbstractColumnFrame, iter = 1) = iter > length(t) ? nothing : (getindex(t, iter), iter + 1)
Base.rest(t::AbstractColumnFrame) = t
function Base.rest(t::AbstractColumnFrame, i::Int)
    rest_syms = Base.rest(names(t))
    rest_vals = Base.rest(vals(t))
    constructor_name(t)(rest_syms, rest_vals)
end

firstindex(t::AbstractColumnFrame) = 1
lastindex(t::AbstractColumnFrame) = length(t)
Base.getindex(t::AbstractColumnFrame, i::Int) = getindex(vals(t), i)
Base.getindex(t::AbstractColumnFrame, i::Symbol) = getindex(vals(t), lookup(t)[i])
Base.getindex(t::AbstractColumnFrame, ::Colon) = deepcopy(t)

Base.getproperty(t::AbstractColumnFrame, s::Symbol) = getindex(t, s)

function Base.getindex(t::AbstractColumnFrame, syms::Tuple{Vararg{Symbol}})
    syms_v = collect(syms)
    new_inds = [lookup(t)[sym] for sym in syms_v]
    new_vals = vals(t)[new_inds]
    constructor_name(t)(syms_v, new_vals)
end

function Base.getindex(t::AbstractColumnFrame, syms::AbstractVector{Symbol})
    new_inds = [lookup(t)[sym] for sym in syms]
    new_vals = vals(t)[new_inds]
    constructor_name(t)(syms, new_vals)
end

Base.indexed_iterate(t::AbstractColumnFrame, i::Int, state=1) = (getindex(t, i), i+1)

Base.isempty(t::AbstractColumnFrame) = isempty(vals(t))

Base.empty(t::AbstractColumnFrame) = constructor_name(t)(Symbol[], Any[])

Base.prevind(t::AbstractColumnFrame, i::Integer) = Int(i)-1

Base.nextind(t::AbstractColumnFrame, i::Integer) = Int(i)+1
Base.convert(::Type{NamedTuple}, t::AbstractColumnFrame) =  NamedTuple{(names(t)...,)}((vals(t)...,))

function merge_names(an::AbstractVector{Symbol}, bn::AbstractVector{Symbol})
    out = copy(an)
    for n in bn
        if !in(n, an)
            push!(out, n)
        end
    end
    out
end

function Base.merge(a::AbstractColumnFrame, b::AbstractColumnFrame)
    an = a.index.nms
    bn = b.index.nms
    nms = merge_names(an, bn)
    ka = Base.keys(lookup(a))
    kb = Base.keys(lookup(b))
    vals = Base.map(nms) do n
        if n in kb
            b[n]
        else
            a[n]
        end
    end
    typeof(t)(nms, vals)
end

function Base.merge(a::AbstractColumnFrame, itr)
    names = Symbol[]
    vals = Any[]
    inds = IdDict{Symbol,Int}()
    for (k, v) in itr
        k = k::Symbol
        oldind = Base.get(inds, k, 0)
        if oldind > 0
            vals[oldind] = v
        else
            push!(names, k)
            push!(vals, v)
            inds[k] = length(names)
        end
    end
    Base.merge(a, typeof(t)(names, vals))
end

Base.merge(a::AbstractColumnFrame, b::NamedTuple) = merge(a, pairs(b))

Base.eltype(::Type{AbstractColumnFrame{T}}) where {T} = T
Base.eltype(t::AbstractColumnFrame{T}) where {T} = T

Base.keytype(nt::AbstractColumnFrame) = keytype(typeof(nt))
Base.keytype(T::Type{AbstractColumnFrame}) = Symbol

valtype(nt::AbstractColumnFrame) = valtype(typeof(nt))
valtype(T::Type{AbstractColumnFrame{V}}) where{V} = V

function Base.:(==)(a::AbstractColumnFrame, b::AbstractColumnFrame)
    a.index.nms == b.index.nms || return false
    vals(a) == vals(b)
end

function Base.isequal(a::AbstractColumnFrame, b::AbstractColumnFrame)
    isequal(a.index.nms, b.index.nms) || return false
    isequal(vals(a), vals(b))
end

hash(x::AbstractColumnFrame, h::UInt) = xor(hash(x.index.nms), hash(x.vals, h))

function Base.:(<)(a::AbstractColumnFrame, b::AbstractColumnFrame)
    if length(a.index.nms) != length(b.index.nms)
        throw(ArgumentError("Arguments do not have the same lengths"))
    end
    if a.index.nms != b.index.nms
        throw(ArgumentError("Arguments do not have the same names"))
    end
    vals(a) < vals(b)
end

function Base.isless(a::AbstractColumnFrame, b::AbstractColumnFrame)
    if length(a.index.nms) != length(b.index.nms)
        throw(ArgumentError("Arguments do not have the same lengths"))
    end
    if a.index.nms != b.index.nms
        throw(ArgumentError("Arguments do not have the same names"))
    end
    isless(vals(a), vals(b))
end

same_names(ts::AbstractColumnFrame...) = allequal(names(t) for t in ts)

# NOTE: this method signature makes sure we don't define map(f)
function Base.map(f, nt::AbstractColumnFrame, nts::AbstractColumnFrame...)
   if !same_names(nt, nts...)
       throw(ArgumentError("Names do not match."))
   end
   nms = copy(nnames(t))
   vals = Base.map(f, nvals(t), (vals(t) for t in nts)...)
   typeof(nt)(nms, vals)
end

# TODO: More merge methods
Base.keys(nt::AbstractColumnFrame) = lookup(nt)
Base.values(nt::AbstractColumnFrame) = nvals(t)
Base.haskey(nt::AbstractColumnFrame, key::Integer) = key in 1:length(nt)
Base.haskey(nt::AbstractColumnFrame, key::Symbol) = key in Base.keys(lookup(nt))

Base.get(nt::AbstractColumnFrame, key::Union{Integer, Symbol}, default) = isdefined(nt, key) ? getfield(nt, key) : default
Base.get(f::Base.Callable, nt::AbstractColumnFrame, key::Union{Integer, Symbol}) = isdefined(nt, key) ? getfield(nt, key) : f()
Base.tail(t::AbstractColumnFrame) = typeof(t)(tail(nnames(t)), tail(nvals(t)))
Base.front(t::AbstractColumnFrame) = typeof(t)(front(nnames(t)), front(nvals(t)))
Base.reverse(nt::AbstractColumnFrame) = typeof(t)(reverse(nnames(t)), reverse(nvals(t)))

function Base.structdiff(a::AbstractColumnFrame, b::AbstractColumnFrame)
    names = diff(a.index.nms, b.index.nms)
    a[names]
end

function Base.setindex(nt::AbstractColumnFrame, v, idx::Symbol)
    merge(nt, (; idx => v))
end
