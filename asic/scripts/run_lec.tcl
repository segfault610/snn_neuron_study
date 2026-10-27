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

set netlist_file "${project_dir}/asic/genus/${model}/${design_kind}/${corner}/${top_module}_tm_netlist.v"
set report_dir "${project_dir}/asic/lec/${model}/${design_kind}/${corner}"
file mkdir $report_dir

if {![file exists $lib_file]} {
    error "Liberty file missing: $lib_file"
}
if {![file exists $netlist_file]} {
    error "Mapped netlist missing: $netlist_file"
}

# Read the technology library for mapped standard cells.
read library -both -liberty $lib_file

# Golden = RTL; Revised = technology-mapped netlist.
read design -golden -sv $rtl_files -top $top_module
read design -revised -verilog $netlist_file -top $top_module

set system mode lec
add compare points -all
compare

report verification
report compare data

puts "INFO: LEC run finished: $model / $design_kind / $corner"
exit
