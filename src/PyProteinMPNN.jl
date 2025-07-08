module PyProteinMPNN

# Write your package code here.
using PythonCall
using CondaPkg

include("helper_script_wrappers.jl")

import .HelperScriptWrappers

export run_protein_mpnn

ProteinMPNN_path = joinpath(dirname(@__FILE__), "ProteinMPNN")

function run_py_script(script_path; join_proteinmpnn_path=true, kwargs...)
    CondaPkg.withenv() do
        if join_proteinmpnn_path
            script_path = joinpath(ProteinMPNN_path, script_path)
        end
        cmd_args = String[]
        for (key, value) in kwargs
            if value === true
                push!(cmd_args, "--$key")
            elseif value !== false && value !== nothing
                push!(cmd_args, "--$key=$(value)")
            end
        end
        cmd = `python $script_path`
        for arg in cmd_args
            cmd = `$cmd $arg`
        end
        @show cmd
        run(cmd)
    end
end

function readfasta(file)
    seqs = Dict{String, String}()
    header = nothing
    for line in readlines(file)
        if startswith(line, ">")
            header = line[2:end]
        else
            @assert header !== nothing "Fasta file is malformed"
            seqs[header] = line
            header = nothing
        end
    end
    return seqs
end

function read_protein_mpnn_output(output_path)
    for file in readdir(joinpath(output_path, "seqs"))
        if endswith(file, ".fa")
            seqs = readfasta(joinpath(output_path, "seqs", file))
            return seqs
        end
    end
    error("No FASTA files found in $output_path/seqs")
end

"""
input_path must be a folder with PDB files.
"""
function run_protein_mpnn(tmp_dir, input_path, output_path; ca_only=false, kwargs...)
    mkpath(tmp_dir)
    parsed_pdbs_path = joinpath(tmp_dir, "parsed_pdbs.jsonl")
    HelperScriptWrappers.parse_multiple_chains(input_path, parsed_pdbs_path; ca_only)
    HelperScriptWrappers.protein_mpnn_run(parsed_pdbs_path, output_path; ca_only, kwargs...)
    seqs_dict = read_protein_mpnn_output(output_path)
    generated_seqs = collect(values(seqs_dict))[2:end]
    return generated_seqs
end
run_protein_mpnn(input_path, output_path; ca_only=false, kwargs...) = mktempdir() do tmp_dir
    run_protein_mpnn(tmp_dir, input_path, output_path; ca_only, kwargs...)
end

end
