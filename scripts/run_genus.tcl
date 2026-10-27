# ============================================================
# Genus synthesis: single-neuron RTL
# Environment variables:
#   PROJECT_DIR, MODEL, CORNER
# ============================================================

if {![info exists ::env(PROJECT_DIR)]} {
    error "PROJECT_DIR environment variable is not set"
}
if {![info exists ::env(MODEL)]} {
    error "MODEL must be lif, izhikevich, or hodgkin_huxley"
}
if {![info exists ::env(CORNER)]} {
    error "CORNER must be slow, typical, or fast"
}

set PROJECT $::env(PROJECT_DIR)
set MODEL   $::env(MODEL)
set CORNER  $::env(CORNER)

set PDK "/home/cadence/install/FOUNDRY/digital/90nm/dig"
set LIB "$PDK/lib/${CORNER}.lib"
set RTL "$PROJECT/rtl/$MODEL/${MODEL}_neuron.sv"
set OUT "$PROJECT/asic/genus/$MODEL/$CORNER"
set RPT "$PROJECT/asic/reports/$MODEL/$CORNER"
set LOG "$PROJECT/asic/logs/$MODEL/$CORNER"

file mkdir $OUT
file mkdir $RPT
file mkdir $LOG

if {![file exists $LIB]} {
    error "Library not found: $LIB"
}
if {![file exists $RTL]} {
    error "RTL not found: $RTL"
}

# Select the top module.
switch -- $MODEL {
    lif {
        set TOP lif_neuron
    }
    izhikevich {
        set TOP izhikevich_neuron
    }
    hodgkin_huxley {
        set TOP hodgkin_huxley_neuron
    }
    default {
        error "Unsupported MODEL: $MODEL"
    }
}

puts "============================================================"
puts "TOP    = $TOP"
puts "MODEL  = $MODEL"
puts "CORNER = $CORNER"
puts "LIB    = $LIB"
puts "RTL    = $RTL"
puts "============================================================"

# Technology library.
set_db init_lib_search_path [list "$PDK/lib"]
read_libs $LIB

# RTL elaboration.
read_hdl -sv $RTL
elaborate $TOP
check_design -unresolved

# Timing constraints: design.sdc must define the actual clock port.
set SDC "$PROJECT/asic/constraints/design.sdc"
if {![file exists $SDC]} {
    error "SDC not found: $SDC"
}
read_sdc $SDC

# Synthesis.
syn_generic
syn_map
syn_opt

# Technology-mapped netlist for this corner.
write_hdl > "$OUT/${TOP}_${CORNER}_tm_netlist.v"
write_sdc > "$OUT/${TOP}_${CORNER}.sdc"

# Reports.
report_area   > "$RPT/${TOP}_${CORNER}_area.rpt"
report_timing > "$RPT/${TOP}_${CORNER}_timing.rpt"
report_power  > "$RPT/${TOP}_${CORNER}_power.rpt"

puts "Genus completed for $TOP at $CORNER corner."
puts "Netlist: $OUT/${TOP}_${CORNER}_tm_netlist.v"

