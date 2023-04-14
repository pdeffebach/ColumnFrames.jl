module MutableColumnFrameTests

using ColumnFrames
using Test

@testset "constructors" begin
    s = MutableColumnFrame(; a = [1, 2], b = [3, 4])
    t = MutableColumnFrame([[1, 2], [3, 4]], [:a, :b])
    @test t == s
    t = MutableColumnFrame((; a = [1, 2], b = [3, 4]))
    @test t == s
    t = MutableColumnFrame((;)) # Empty named tuple
    @test t == MutableColumnFrame(AbstractVector[], Symbol[])

    d = Dict([:a => [1, 2], :b => [3, 4]])
    t = MutableColumnFrame(pairs(d))
    @test t == s
    t = MutableColumnFrame(d)
    @test t == s

    t = MutableColumnFrame(s)
    @test t == s

    t = MutableColumnFrame(ColumnFrame(; a = [1, 2], b = [3, 4]))
    @test t == s
    t = MutableColumnFrame(MutableColumnFrame(; a = [1, 2], b = [3, 4]))
    @test t == s
end

@testset "constructor errors" begin
    @test_throws MethodError MutableColumnFrame([1, 2], [:a, :b])
    @test_throws DimensionMismatch MutableColumnFrame([[1, 2], [1]], [:a, :b])

    @test_throws MethodError MutableColumnFrame(a = 1, b = 2)
    @test_throws DimensionMismatch MutableColumnFrame(a = [1, 2], b = [1])

    # Show error
    s = MutableColumnFrame(a = [1, 2], b = [3, 4]);
    values(s)[1] = [1]
    io = IOBuffer()
    # TODO: Figure out show method
    @test_throws DimensionMismatch show(io, "text/plain", s)
end

@testset "constructor with named tuple" begin
    s = MutableColumnFrame(a = [1, 2], b = [3, 4])
    nt = (a = [1, 2], b = [3, 4])
    @test NamedTuple(s) == nt
end

@testset "construction and copying" begin
    x = [1, 2, 3]
    s = MutableColumnFrame(a = x)
    @test s.a === x

    t = MutableColumnFrame(s)
    @test t.a === s.a
end

@testset "length and iteration" begin
    s = MutableColumnFrame(; a = [1, 2, 3], b = [3, 4, 5])

    @test length(s) == 2
    @test first(s) == [1, 2, 3]
    @test last(s) == [3, 4, 5]
    @test firstindex(s) == 1
    @test lastindex(s) == 2
    @test [s...] == [[1, 2, 3], [3, 4, 5]]

    @test Base.rest(s) == s
    @test Base.rest(s, 2) == MutableColumnFrame(b = [3, 4, 5])

    @test Base.prevind(s, 2) == 1
    Base.nextind(s, 2) == 3
    Base.indexed_iterate(s, 1) == ([1, 2, 3], 2)
end

@testset "indexing" begin
    x = [1, 2, 3]; y = [3, 4, 5]
    s = MutableColumnFrame(; a = x, b = y)
    @test s[1] === x
    @test s[:a] === x
    @test s["a"] === x

    @test s[(:a, :b)] == s
    @test s[(1, 2)] == s
    @test s[(true, false)] == MutableColumnFrame(a = [1, 2, 3])
    @test s[("a", "b")] == s

    @test s[[:a, :b]] == s
    @test s[[1, 2]] == s
    @test s[[true, false]] == MutableColumnFrame(a = [1, 2, 3])
    @test s[["a", "b"]] == s

    t = s[:]
    @test t == s
    @test t.a === s.a
    @test getfield(t, :vals) !== getfield(s, :vals)
    t = copy(s)
    @test t == s
    @test t.a === s.a
    @test getfield(t, :vals) !== getfield(s, :vals)
end

@testset "indexing errors" begin
    s = MutableColumnFrame(a = [1, 2], b = ["x", "y"])
    @test_throws KeyError s[:z]
    @test_throws KeyError s.z
    @test_throws BoundsError s[3]
    @test_throws KeyError s[[:a, :z]]
end

@testset "empty" begin
    s = MutableColumnFrame()
    @test isempty(s)
    @test empty(MutableColumnFrame(a = [1, 2])) == s
end

@testset "merging" begin
    ref = MutableColumnFrame(a = [1, 2], b = [3, 4])
    s1 = MutableColumnFrame(a = [1, 2])
    s2 = MutableColumnFrame(b = [3, 4])
    nt = (; a = [1, 2])
    @test merge(s1, s2) == ref
    @test merge(s1, pairs(s2)) == ref
    @test merge(nt, s2) == (a = [1, 2], b = [3, 4])
end

@testset "type info" begin
    s_narrow = MutableColumnFrame(a = [1, 2], b = [3, 4])
    s_abstract = MutableColumnFrame(AbstractVector[[1, 2], [3, 4]], [:a, :b])
    s_hetero = MutableColumnFrame(a = [1, 2], b = 3:4)
    s_string = MutableColumnFrame(a = [1, 2], b = ["x", "y"])

    @test eltype(s_narrow) == AbstractVector
    @test valtype(s_narrow) == AbstractVector

    @test eltype(s_abstract) == AbstractVector
    @test valtype(s_abstract) == AbstractVector

    @test eltype(s_hetero) == AbstractVector
    @test valtype(s_hetero) == AbstractVector

    @test eltype(s_string) == AbstractVector
    @test valtype(s_string) == AbstractVector

    @test keytype(s_narrow) == Symbol
end

@testset "equality" begin
    s1 = MutableColumnFrame(a = [1, 2], b = [3, 4])
    s2 = MutableColumnFrame(a = [1, 2], b = [3, 4])
    s3 = MutableColumnFrame(a = [1, 2], b = [3, 400])
    s5 = MutableColumnFrame(a = [1, 2], b = [3, missing])
    s6 = MutableColumnFrame(a = [1, 2], b = [3, missing])
    s7 = MutableColumnFrame(a = [1, 2], c = [3, 4])

    @test s1 == s2
    @test isequal(s1, s2)
    @test s1 != s3
    @test s1 != s7
    @test isequal(s5, s6)
    @test ismissing((s5 == s6))
end

# TODO: Hash tests

@testset "less than" begin
    s1 = MutableColumnFrame(a = [1, 2], b = [3, 4])
    s2 = MutableColumnFrame(a = [1, 2], b = [3, 400])
    s3 = MutableColumnFrame(a = [1, 2], b = [3, missing])
    s4 = MutableColumnFrame(a = [1, 2], b = [3, 4], c = [5, 6])
    s5 = MutableColumnFrame(a = [1, 2], c = [3, 4])
    s6 = MutableColumnFrame(a = [1.0, 2.0], b = [3.0, 400.0])

    @test s1 < s2
    @test s1 < s2 # Vectors fall back on isless
    @test_throws ArgumentError s1 < s4
    @test_throws ArgumentError s1 < s5
    @test s1 < s6

    @test isless(s1, s2)
    @test isless(s1, s3) # Vectors fall back on isless
    @test_throws ArgumentError s1 < s4
    @test_throws ArgumentError s1 < s5
    @test isless(s1, s6)
end

@testset "map" begin
    s1 = MutableColumnFrame(a = [1, 2], b = [3, 4])
    s2 = MutableColumnFrame(a = [100, 200], b = [300, 400])
    s3 = MutableColumnFrame(a = [1000, 2000], b = [3000, 4000])

    t = map(s1) do col
        col .+ 1
    end
    @test t == MutableColumnFrame(a = [2, 3], b = [4, 5])

    t = map(s1) do col
        1
    end
    @test t == MutableColumnFrame(a = [1], b = [1])

    t = map(t -> "x", s1)
    @test t == MutableColumnFrame(a = ["x"], b = ["x"])
    t = map(+, s1, s2)
    @test t == MutableColumnFrame(a = [101, 202], b = [303, 404])

    t = map(+, s1, s2, s3)
    @test t == MutableColumnFrame(a = [1101, 2202], b = [3303, 4404])
end

@testset "dict interface" begin
    s = MutableColumnFrame(a = [1, 2], b = [3, 4])
    @test keys(s) == [:a, :b]
    @test values(s) == [[1, 2], [3, 4]]
    @test haskey(s, :a) == true
    @test haskey(s, :z) == false
    @test haskey(s, 1) == true
    @test haskey(s, 40) == false
end

@testset "misc namedtuple features" begin
    s = MutableColumnFrame(a = [1, 2], b = [3, 4], c = [5, 6])
    @test Base.tail(s) == MutableColumnFrame(b = [3, 4], c = [5, 6])
    @test Base.front(s) == MutableColumnFrame(a = [1, 2], b = [3, 4])

    t = MutableColumnFrame(b = [100, 100], z = [600, 700])
    @test Base.structdiff(s, t) == MutableColumnFrame(a = [1, 2], c = [5, 6])
    @test Base.setindex(s, [100, 200], :d) ==
        MutableColumnFrame(a = [1, 2], b = [3, 4], c = [5, 6], d = [100, 200])

    @test Base.setindex(s, [100, 200], :a) ==
        MutableColumnFrame(a = [100, 200], b = [3, 4], c = [5, 6])
end

end
