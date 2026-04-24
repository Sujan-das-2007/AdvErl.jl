using Test
using Conduit

@testset "Conduit.jl" begin
    # Test that the module loads and exports are available
    @test isdefined(Conduit, :Actor)
    @test isdefined(Conduit, :send!)
    @test isdefined(Conduit, :receive!)
    @test isdefined(Conduit, :Supervisor)
    @test isdefined(Conduit, :supervise)
    @test isdefined(Conduit, :OwnedBuffer)
    @test isdefined(Conduit, :GlobalRegistry)

    # Basic test for Buffer
    buf = OwnedBuffer(zeros(Int, 10))
    @test length(buf.data) == 10

    # Check that release! and claim! work (assuming appropriate threading context)
    # This requires more careful testing depending on how OwnershipError is thrown
    # But for a basic skeleton, let's keep it simple.
end
