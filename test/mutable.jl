module MutabilityTests

using ColumnFrames
using Test

@testset "mutability" begin
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

end
