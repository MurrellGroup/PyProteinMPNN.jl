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

function readfasta(filename; remove_first=false)
    seqs = Dict{String, String}()
    header = nothing
    lines = readlines(filename)
    if remove_first
        lines = lines[3:end]
    end
    for line in lines
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
    seqs = Dict()
    for filename in readdir(joinpath(output_path, "seqs"))
        if endswith(filename, ".fa")
            pdb_name = first(splitext(filename))
            seqs[pdb_name] = collect(values(readfasta(joinpath(output_path, "seqs", filename); remove_first=true)))
        end
    end
    return seqs
end

"""
input_path must be a folder with PDB files.
"""
function run_protein_mpnn(tmp_dir, input_path, output_path; ca_only=false, kwargs...)
    mkpath(tmp_dir)
    if isfile(input_path)
        new_input_path = joinpath(tmp_dir, basename(input_path))
        cp(input_path, new_input_path)
        input_path = new_input_path
    end
    parsed_pdbs_path = joinpath(tmp_dir, "parsed_pdbs.jsonl")
    HelperScriptWrappers.parse_multiple_chains(input_path, parsed_pdbs_path; ca_only)
    HelperScriptWrappers.protein_mpnn_run(parsed_pdbs_path, output_path; ca_only, kwargs...)
    seqs_dict = read_protein_mpnn_output(output_path)
    return seqs_dict
end
run_protein_mpnn(input_path, output_path; ca_only=false, kwargs...) = mktempdir() do tmp_dir
    run_protein_mpnn(tmp_dir, input_path, output_path; ca_only, kwargs...)
end
run_protein_mpnn(input_path; ca_only=false, kwargs...) = mktempdir() do tmp_dir
    run_protein_mpnn(tmp_dir, input_path, joinpath(tmp_dir, "output"); ca_only, kwargs...)
end

end
