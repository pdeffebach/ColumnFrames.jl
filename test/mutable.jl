module MutabilityTests

using ColumnFrames
using Test

@testset "adding columns" begin
    s = MutableColumnFrame(a = [1, 2], b = [3, 4])
    t = copy(s)
    t.c = [5, 6]
    @test t == ColumnFrame(a = [1, 2], b = [3, 4], c = [5, 6])
    t = copy(s)
    t."c" = [5, 6]
    @test t == ColumnFrame(a = [1, 2], b = [3, 4], c = [5, 6])
    t = copy(s)
    t[:c] = [5, 6]
    @test t == ColumnFrame(a = [1, 2], b = [3, 4], c = [5, 6])
    t = copy(s)
    t["c"] = [5, 6]
    @test t == ColumnFrame(a = [1, 2], b = [3, 4], c = [5, 6])

    t = copy(s)
    t.a = ["x", "y"]
    @test t == ColumnFrame(a = ["x", "y"], b = [3, 4])
    t = copy(s)
    t."a" = ["x", "y"]
    @test t == ColumnFrame(a = ["x", "y"], b = [3, 4])
    t = copy(s)
    t[:a] = ["x", "y"]
    @test t == ColumnFrame(a = ["x", "y"], b = [3, 4])
    t = copy(s)
    t["a"] = ["x", "y"]
    @test t == ColumnFrame(a = ["x", "y"], b = [3, 4])
    t = copy(s)
    t[1] = ["x", "y"]
    @test t == ColumnFrame(a = ["x", "y"], b = [3, 4])
end

@testset "deleting columns" begin
    s = MutableColumnFrame(a = ["x", "y"], b = [3, 4])
    t = delete!(copy(s), :a)
    @test t == ColumnFrame(b = [3, 4])
    @test t.b === s.b
end

end
