using ColumnFrames
using Test

@testset "constructors" begin
    s = ColumnFrame(; a = [1, 2], b = [3, 4])
    t = ColumnFrame([:a, :b], [[1, 2], [3, 4]])
    @test t == s
    t = ColumnFrame((; a = [1, 2], b = [3, 4]))
    @test t == s
    t = ColumnFrame((;)) # Empty named tuple
    @test t == ColumnFrame(Symbol[], AbstractVector[])

    d = Dict([:a => [1, 2], :b => [3, 4]])
    t = ColumnFrame(pairs(d))
    @test t == s
    t = ColumnFrame(d)
    @test t == s

    t = ColumnFrame(s)
    @test t == s
end

@testset "constructor errors" begin
    @test_throws MethodError ColumnFrame([:a, :b], [1, 2])
    @test_throws DimensionMismatch ColumnFrame([:a, :b], [[1, 2], [1]])

    @test_throws MethodError ColumnFrame(a = 1, b = 2)
    @test_throws DimensionMismatch ColumnFrame(a = [1, 2], b = [1])
end

@testset "constructor with named tuple" begin
    s = ColumnFrame(a = [1, 2], b = [3, 4])
    nt = (a = [1, 2], b = p3, 4)
    @test NamedTuple(s) == nt
    @test convert(ColumnFrame, nt) == s
end

@testset "construction and copying" begin
    x = [1, 2, 3]
    s = ColumnFrame(a = x)
    @test s.a === x

    t = ColumnFrame(s)
    @test t.a === s.a
end

@testset "length and iteration" begin
    s = ColumnFrame(; a = [1, 2, 3], b = [3, 4, 5])

    @test length(s) == 2
    @test first(s) == [1, 2, 3]
    @test last(s) == [3, 4, 5]
    @test firstindex(s) == 1
    @test lastindex(s) == 2
    @test [s...] == [[1, 2, 3], [3, 4, 5]]

    @test Base.rest(s) == s
    @test Base.rest(s, 2) == ColumnFrame(b = [3, 4, 5])

    @test Base.prevind(s, 2) == 1
    Base.nextind(s, 2) == 3
    Base.indexed_iterate(s, 1) == ([1, 2, 3], 2)
end

@testset "indexing" begin
    x = [1, 2, 3]; y = [3, 4, 5]
    s = ColumnFrame(; a = x, b = y)
    @test s[1] === x
    @test s[:a] === x
    @test s[(:a, :b)] == s
    @test s[[:a, :b]] == s

    @test s[[(1, 2)]] == s
    @test s[[1, 2]] == s
    @test s[[1, 0]] == ColumnFrame(a = [1, 2, 3])
    @test s[(1, 0)] == ColumnFrame(a = [1, 2, 3])
    t = s[:]
    @test t == s
    @test t.a !== s.a
    @test getfield(t, :vals) !== getfield(s, :vals)
    t = copy(s)
    @test t == s
    @test t.a !== s.a
    @test getfield(t, :vals) !== getfield(s, :vals)
end

@testset "empty" begins
    s = ColumnFrame()
    @test isempty(s)
    @test empty(ColumnFrame(a = [1, 2])) == s
end

@testset "merging" begins
    ref = ColumnFrame(a = [1, 2], b = [3, 4])
    s1 = ColumnFrame(a = [1, 2])
    s2 = ColumnFrame(b = [3, 4])
    nt = (; a = [1, 2])
    @test merge(s1, s2) == ref
    @test merge(s1, pairs(s2)) == ref
    @test merge(nt, s2) == (a = [1, 2], b = [3, 4])
end

@test "type info" begin
    s_narrow = ColumnFrame(a = [1, 2], b = [3, 4])
    s_abstract = ColumnFrame([:a, :b], AbstractVector[[1, 2], [3, 4]])
    s_hetero = ColumnFrame(a = [1, 2], b = 3:4)
    s_string = ColumnFrame(a = [1, 2], b = ["x", "y"])

    @test eltype(s_narrow) == Vector{Int}
    @test valtype(s_narrow) == Vector{Int}

    @test eltype(s_abstract) == AbstractVector
    @test valtype(s_abstract) == AbstractVector

    @test eltype(s_hetero) == AbstractVector{Int}
    @test valtype(s_hetero) == AbstractVector{Int}

    @test eltype(s_string) == Vector
    @test valtype(s_string) == Vector

    @test keytype(s_narrow) == Symbol
end

@testset "equality" begin
    s1 = ColumnFrame(a = [1, 2], b = [3, 4])
    s2 = ColumnFrame(a = [1, 2], b = [3, 4])
    s3 = ColumnFrame(a = [1, 2], b = [3, 400])
    s5 = ColumnFrame(a = [1, 2], b = [3, missing])
    s6 = ColumnFrame(a = [1, 2], b = [3, missing])
    s7 = ColumnFrame(a = [1, 2], c = [3, 4])

    @test s1 == s2
    @test isequal(s1, s2)
    @test s1 != s3
    @test s1 != s7
    @test isequal(s5, s6)
    @test ismissing((s5 == s6))
end

# TODO: Hash tests

@testset "less than" begin
    s1 = ColumnFrame(a = [1, 2], b = [3, 4])
    s2 = ColumnFrame(a = [1, 2], b = [3, 400])
    s3 = ColumnFrame(a = [1, 2], b = [3, missing])
    s4 = ColumnFrame(a = [1, 2], b = [3, 4], c = [5, 6])
    s5 = ColumnFrame(a = [1, 2], c = [3, 4])
    s6 = ColumnFrame(a = [1.0, 2.0], b = [3.0, 400.0])

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
    s1 = ColumnFrame(a = [1, 2], b = [3, 4])
    s2 = ColumnFrame(a = [100, 200], b = [300, 400])
    s3 = ColumnFrame(a = [1000, 2000], b = [3000, 4000])

    t = map(s1) do col
        col .+ 1
    end
    @test t == ColumnFrame(a = [2, 3], b = [4, 5])

    t = map(+, s1, s2)
    @test t == ColumnFrame(a = [101, 202], b = [303, 404])

    t = map(+ s1, s2, s3)
end


