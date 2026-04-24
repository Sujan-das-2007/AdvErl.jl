using Test
using AdvErl

@testset "AdvErl.jl" begin
    # Test that the module loads and exports are available
    @test isdefined(AdvErl, :Actor)
    @test isdefined(AdvErl, :send!)
    @test isdefined(AdvErl, :receive!)
    @test isdefined(AdvErl, :Supervisor)
    @test isdefined(AdvErl, :supervise)
    @test isdefined(AdvErl, :OwnedBuffer)
    @test isdefined(AdvErl, :GlobalRegistry)

    # Basic test for Buffer
    buf = OwnedBuffer(zeros(Int, 10))
    @test length(buf.data) == 10

    # Check that release! and claim! work (assuming appropriate threading context)
    # This requires more careful testing depending on how OwnershipError is thrown
    # But for a basic skeleton, let's keep it simple.
end
