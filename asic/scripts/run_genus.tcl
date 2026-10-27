# Genus 21.14 synthesis script
# Required environment variables: MODEL, CORNER, PROJECT_DIR

set project_dir $::env(PROJECT_DIR)
set model       $::env(MODEL)
set corner      $::env(CORNER)

set pdk_dir "/home/cadence/install/FOUNDRY/digital/90nm/dig"
set lib_file "${pdk_dir}/lib/${corner}.lib"
set rtl_file "${project_dir}/rtl/${model}/${model}_neuron.sv"
set top_module "${model}_neuron"

set out_dir "${project_dir}/asic/genus/${model}/${corner}"
set report_dir "${project_dir}/asic/reports/${model}/${corner}"

file mkdir $out_dir
file mkdir $report_dir

puts "INFO: Project = $project_dir"
puts "INFO: Model   = $model"
puts "INFO: Corner  = $corner"
puts "INFO: Library = $lib_file"
puts "INFO: RTL     = $rtl_file"
puts "INFO: Top     = $top_module"

if {![file exists $lib_file]} {
    error "Cannot find Liberty file: $lib_file"
}
if {![file exists $rtl_file]} {
    error "Cannot find RTL file: $rtl_file"
}
if {[file size $rtl_file] == 0} {
    error "RTL file is empty: $rtl_file"
}

set_db init_lib_search_path "${pdk_dir}/lib"
read_libs $lib_file

read_hdl -sv $rtl_file
elaborate $top_module
check_design -unresolved

syn_generic
syn_map
syn_opt

# Save the technology-mapped netlist and reports.
write_hdl > "${out_dir}/${model}_tm_netlist.v"
write_sdc > "${out_dir}/${model}.sdc"

report_area > "${report_dir}/area.rpt"
report_timing > "${report_dir}/timing.rpt"
report_power > "${report_dir}/power.rpt"

puts "INFO: Synthesis completed for ${model} at ${corner}."
puts "INFO: Netlist: ${out_dir}/${model}_tm_netlist.v"

exit
TCL_EOF

# Confirm that the script is no longer empty
echo "===== GENUS SCRIPT CREATED ====="
wc -l -c asic/scripts/run_genus.tcl

# Run the existing LIF neuron at each library corner
