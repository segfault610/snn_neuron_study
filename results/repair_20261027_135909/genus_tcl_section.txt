set project_dir $::env(PROJECT_DIR)
set model       $::env(MODEL)
set corner      $::env(CORNER)
set design_kind $::env(DESIGN_KIND)

set pdk_dir "/home/cadence/install/FOUNDRY/digital/90nm/dig"
set lib_file "${pdk_dir}/lib/${corner}.lib"

if {$model eq "lif"} {
    set neuron_file "${project_dir}/rtl/lif/lif_neuron.sv"
    set layer_file  "${project_dir}/rtl/lif/lif_layer.sv"
    set neuron_top  "lif_neuron"
    set layer_top   "lif_layer"
} elseif {$model eq "izhikevich"} {
    set neuron_file "${project_dir}/rtl/izhikevich/izhikevich_neuron.sv"
    set layer_file  "${project_dir}/rtl/izhikevich/izhikevich_layer.sv"
    set neuron_top  "izhikevich_neuron"
    set layer_top   "izhikevich_layer"
} elseif {$model eq "hodgkin_huxley"} {
    set neuron_file "${project_dir}/rtl/hodgkin_huxley/hodgkin_huxley_neuron.sv"
    set layer_file  "${project_dir}/rtl/hodgkin_huxley/hodgkin_huxley_layer.sv"
    set neuron_top  "hodgkin_huxley_neuron"
    set layer_top   "hodgkin_huxley_layer"
} else {
    error "Unknown MODEL=$model"
}

if {$design_kind eq "neuron"} {
    set top_module $neuron_top
    set rtl_files [list $neuron_file]
} elseif {$design_kind eq "layer"} {
    set top_module $layer_top
    set rtl_files [list $neuron_file $layer_file]
} else {
    error "DESIGN_KIND must be neuron or layer"
}

set out_dir "${project_dir}/asic/genus/${model}/${design_kind}/${corner}"
set report_dir "${project_dir}/asic/reports/${model}/${design_kind}/${corner}"

file mkdir $out_dir
file mkdir $report_dir

foreach f $rtl_files {
    if {![file exists $f] || [file size $f] == 0} {
        error "RTL missing or empty: $f"
    }
}
if {![file exists $lib_file]} {
    error "Liberty file missing: $lib_file"
}

puts "INFO: MODEL=$model DESIGN_KIND=$design_kind CORNER=$corner"
puts "INFO: TOP=$top_module"

set_db init_lib_search_path "${pdk_dir}/lib"
read_libs $lib_file
read_hdl -sv $rtl_files
elaborate $top_module
check_design -unresolved

syn_generic
syn_map
syn_opt

write_hdl > "${out_dir}/${top_module}_tm_netlist.v"
write_sdc > "${out_dir}/${top_module}.sdc"

report_area   > "${report_dir}/area.rpt"
report_timing > "${report_dir}/timing.rpt"
report_power  > "${report_dir}/power.rpt"

puts "INFO: Synthesis completed: $model / $design_kind / $corner"
puts "INFO: Netlist: ${out_dir}/${top_module}_tm_netlist.v"
exit
