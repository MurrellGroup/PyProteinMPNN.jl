using PyProteinMPNN
using Test

# TODO Test all the kwargs

example_input_path = joinpath(@__DIR__, "..", "example_input")

@testset "PyProteinMPNN.jl" begin
    # Write your tests here.
    mktempdir() do tmp_output_path
        seqs = run_protein_mpnn(example_input_path, tmp_output_path)
        @test isfile(joinpath(tmp_output_path, "seqs", "1L3A_ba1.fa"))
        @test length(seqs) == 1
    end
end
