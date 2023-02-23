Base.length(t::AbstractColumnFrame) = length(vals(t))
Base.iterate(t::AbstractColumnFrame, iter = 1) = iter > length(t) ? nothing : (getindex(t, iter), iter + 1)
Base.rest(t::AbstractColumnFrame) = t
function Base.rest(t::AbstractColumnFrame, i::Int)
    rest_syms = Base.rest(names(t), i)
    rest_vals = Base.rest(vals(t), i)
    constructor_name(t)(rest_syms, rest_vals)
end

# Not part of NamedTuple API, but necessary for
# mapping
struct EachColIterator{T <: AbstractColumnFrame}
    t::T
end

Base.eachcol(t::AbstractColumnFrame) = EachColIterator(t)
Base.length(t::EachColIterator) = length(t.t)
Base.iterate(t::EachColIterator, iter = 1) = iterate(t.t, iter)
Base.pairs(t::EachColIterator) = pairs(t.t)

Base.propertynames(t::AbstractColumnFrame) = names(t)

Base.firstindex(t::AbstractColumnFrame) = 1
Base.lastindex(t::AbstractColumnFrame) = length(t)
Base.getindex(t::AbstractColumnFrame, i::Int) = getindex(vals(t), i)
Base.getindex(t::AbstractColumnFrame, i::Symbol) = getindex(vals(t), lookup(t)[i])
# TODO: Document that this is a deviation from the base NamedTuple.jl interface
Base.copy(t::AbstractColumnFrame) = constructor_name(t)(copy(names(t)), copy(vals(t)))
Base.getindex(t::AbstractColumnFrame, ::Colon) = copy(t)

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

# TODO: Document that this is a deviation from the base NamedTuple.jl interface
function Base.getindex(t::AbstractColumnFrame, inds::AbstractVector{<:Integer})
    new_syms = names(t)[inds]
    new_vals = vals(t)[inds]
    constructor_name(t)(new_syms, new_vals)
end

# TODO: Document that this is a deviation from the base NamedTuple.jl interface
Base.getindex(t::AbstractColumnFrame, inds::Tuple{Vararg{<:Integer}}) =
    Base.getindex(t, collect(inds))

Base.indexed_iterate(t::AbstractColumnFrame, i::Int, state=1) = (getindex(t, i), i+1)
Base.isempty(t::AbstractColumnFrame) = isempty(vals(t))
Base.empty(t::AbstractColumnFrame) = constructor_name(t)(Symbol[], AbstractVector[])

Base.prevind(t::AbstractColumnFrame, i::Integer) = Int(i)-1

Base.nextind(t::AbstractColumnFrame, i::Integer) = Int(i)+1
# TODO: Understand why this doesn't work more intuitively
Base.NamedTuple(t::AbstractColumnFrame) = NamedTuple(pairs(t))

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
    an = names(a)
    bn = names(b)
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
    constructor_name(a)(nms, vals)
end

function Base.merge(a::AbstractColumnFrame, itr)
    names = Symbol[]
    vals = AbstractVector[]
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
    Base.merge(a, ColumnFrame(names, vals))
end

Base.merge(a::AbstractColumnFrame, b::NamedTuple) = merge(a, pairs(b))
Base.merge(a::NamedTuple, b::AbstractColumnFrame) = merge(a, pairs(b))

Base.eltype(::Type{<:AbstractColumnFrame{V}}) where {V} = eltype(V)
Base.keytype(::Type{<:AbstractColumnFrame{V}}) where {V} = Symbol
Base.keytype(t::AbstractColumnFrame) = Base.keytype(typeof(t))
Base.valtype(::Type{<:AbstractColumnFrame{V}}) where{V} = valtype(V)
Base.valtype(t::AbstractColumnFrame) = Base.valtype(typeof(t))

function Base.:(==)(a::AbstractColumnFrame, b::AbstractColumnFrame)
    names(a) == names(b) || return false
    vals(a) == vals(b)
end

function Base.isequal(a::AbstractColumnFrame, b::AbstractColumnFrame)
    isequal(names(a), names(b)) || return false
    isequal(vals(a), vals(b))
end

hash(x::AbstractColumnFrame, h::UInt) = xor(hash(x.index.nms), hash(x.vals, h))

function Base.:(<)(a::AbstractColumnFrame, b::AbstractColumnFrame)
    na = names(a); nb = names(b);

    if length(na) != length(nb)
        throw(ArgumentError("Arguments do not have the same lengths"))
    end
    if na != nb
        throw(ArgumentError("Arguments do not have the same names"))
    end
    vals(a) < vals(b)
end

function Base.isless(a::AbstractColumnFrame, b::AbstractColumnFrame)
    na = names(a); nb = names(b);

    if length(na) != length(nb)
        throw(ArgumentError("Arguments do not have the same lengths"))
    end
    if na != nb
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
   nms = copy(names(nt))

   v = Base.map(f, vals(nt), (vals(t) for t in nts)...)
   constructor_name(nt)(nms, v)
end

# TODO: More merge methods
Base.keys(nt::AbstractColumnFrame) = names(nt)
Base.values(nt::AbstractColumnFrame) = vals(nt)
Base.haskey(nt::AbstractColumnFrame, key::Integer) = key in 1:length(nt)
Base.haskey(nt::AbstractColumnFrame, key::Symbol) = key in Base.keys(lookup(nt))

Base.get(nt::AbstractColumnFrame, key::Union{Integer, Symbol}, default) = isdefined(nt, key) ? getfield(nt, key) : default
Base.get(f::Base.Callable, nt::AbstractColumnFrame, key::Union{Integer, Symbol}) = isdefined(nt, key) ? getfield(nt, key) : f()
Base.tail(t::AbstractColumnFrame) = typeof(t)(tail(nnames(t)), tail(vals(t)))
Base.front(t::AbstractColumnFrame) = typeof(t)(front(nnames(t)), front(vals(t)))
Base.reverse(nt::AbstractColumnFrame) = typeof(t)(reverse(nnames(t)), reverse(vals(t)))

function Base.structdiff(a::AbstractColumnFrame, b::AbstractColumnFrame)
    names = diff(a.index.nms, b.index.nms)
    a[names]
end

function Base.setindex(nt::AbstractColumnFrame, v, idx::Symbol)
    merge(nt, (; idx => v))
end
