module TablesTests

using Test

using ColumnFrames

using ColumnFrames.Tables

@testset "ColumnFrame Tables" begin
    s = ColumnFrame(a = [1], b = [2])
    @test Tables.istable(s) == true
    @test Tables.istable(typeof(s)) == true
    @test Tables.materializer(s) == ColumnFrame
    @test Tables.getcolumn(s, 1) == [1]
    @test Tables.getcolumn(s, :b) == [2]
    @test Tables.columnnames(s) == [:a, :b]

    @test Tables.columns(s) == s
    r = Tables.rows(s)
    @test first(r).a == 1
    @test Tables.columntable(s) == (a = [1], b = [2])
    @test Tables.rowtable(s) == [(a = 1, b = 2)]
end


@testset "MutableColumnFrames Tables" begin
    s = MutableColumnFrame(a = [1], b = [2])
    @test Tables.istable(s) == true
    @test Tables.istable(typeof(s)) == true
    @test Tables.materializer(s) == MutableColumnFrame
    @test Tables.getcolumn(s, 1) == [1]
    @test Tables.getcolumn(s, :b) == [2]
    @test Tables.columnnames(s) == [:a, :b]

    @test Tables.columns(s) == s
    r = Tables.rows(s)
    @test first(r).a == 1
    @test Tables.columntable(s) == (a = [1], b = [2])
    @test Tables.rowtable(s) == [(a = 1, b = 2)]
end


end