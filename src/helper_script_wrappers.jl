module HelperScriptWrappers

import ..PyProteinMPNN

"""
    parse_multiple_chains(input_path, output_path; ca_only=false)

Parse a PDB file with multiple chains into a JSONL file.

# Arguments
- `input_path::String`: Path to the PDB file.
- `output_path::String`: Path to the output JSONL file.
- `ca_only::Bool`: Whether to only include CA atoms.
"""
function parse_multiple_chains(input_path, output_path; ca_only=false)
    PyProteinMPNN.run_py_script("helper_scripts/parse_multiple_chains.py"; input_path, output_path, ca_only)
end

"""
    protein_mpnn_run(jsonl_path, out_folder; kwargs...)

Run ProteinMPNN on a JSONL file.

# Arguments
- `jsonl_path::String`: Path to the JSONL file.
- `out_folder::String`: Path to the output folder.
- `kwargs...`: Additional keyword arguments to pass to the ProteinMPNN script.
"""
function protein_mpnn_run(jsonl_path, out_folder; kwargs...)
    PyProteinMPNN.run_py_script("protein_mpnn_run.py"; jsonl_path, out_folder, kwargs...)
end

end