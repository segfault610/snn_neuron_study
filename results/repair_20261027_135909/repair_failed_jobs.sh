#!/bin/bash
set -u

PROJECT_DIR=/home/userdata/24bvd0198/snn_neuron_study
REPAIR_DIR="$PROJECT_DIR/results/repair_20261027_135909"
REPAIR_LOG="$REPAIR_DIR/repair_run.log"
STATUS_FILE="$REPAIR_DIR/repair_status.tsv"
PDK_DIR=/home/cadence/install/FOUNDRY/digital/90nm/dig

mkdir -p "$REPAIR_DIR"
cd "$PROJECT_DIR" || exit 1

exec > >(tee -a "$REPAIR_LOG") 2>&1

printf '\n===== REPAIR STARTED: %s =====\n' "$(date)"
printf 'JOB\tSTATUS\tEXIT_CODE\tDETAIL\n' > "$STATUS_FILE"

XRUN=""
for candidate in \
  /home/cadence/install_RB_8.7/XCELLIUM2409/tools/bin/xrun \
  /home/cadence/install_RB_8.7/XCELLIUM2409/tools/bin/xrun
do
  if [ -x "$candidate" ]; then XRUN="$candidate"; break; fi
done
if [ -z "$XRUN" ]; then XRUN="$(command -v xrun || true)"; fi

GENUS=/home/cadence/install_RB_8.7/GENUS211/tools.lnx86/synth/bin/64bit/genus

if [ -z "$XRUN" ] || [ ! -x "$XRUN" ]; then
  echo "ERROR: xrun executable not found."
  printf 'SIMULATIONS\tFAILED\t127\txrun not found\n' >> "$STATUS_FILE"
  exit 1
fi

if [ ! -x "$GENUS" ]; then
  echo "ERROR: Genus executable not found: $GENUS"
  printf 'SYNTHESIS\tFAILED\t127\tGenus not found\n' >> "$STATUS_FILE"
  exit 1
fi

printf 'Using XRUN=%s\n' "$XRUN"
printf 'Using GENUS=%s\n' "$GENUS"
printf 'PROJECT_DIR=%s\n' "$PROJECT_DIR"

SIM_FAILED=0

run_layer_simulation() {
  local model="$1"
  local neuron_rtl="$2"
  local layer_rtl="$3"
  local tb="$4"
  local top="$5"
  local job="SIM_${model}_${top}"
  local log="$REPAIR_DIR/${job}.log"
  local xmlib="$REPAIR_DIR/xcelium_${model}_${top}"

  printf '\n===== %s =====\n' "$job"
  printf 'Compiling neuron RTL and layer RTL together.\n'

  "$XRUN" -64bit -sv \
    "$neuron_rtl" "$layer_rtl" "$tb" \
    -top "$top" \
    -access +rwc \
    -xmlibdirname "$xmlib" \
    -l "$REPAIR_DIR/xrun_${model}_${top}.log" \
    -run > "$log" 2>&1
  local rc=$?

  cat "$log"

  if [ "$rc" -eq 0 ]; then
    printf '%s\tPASS\t0\tLayer simulation completed\n' "$job" >> "$STATUS_FILE"
    echo "PASS: $job"
  else
    printf '%s\tFAIL\t%s\tSee %s\n' "$job" "$rc" "$log" >> "$STATUS_FILE"
    echo "FAIL: $job (exit $rc)"
    SIM_FAILED=1
  fi
}

run_layer_simulation lif \
  rtl/lif/lif_neuron.sv \
  rtl/lif/lif_layer.sv \
  tb/lif/tb_lif_layer.sv \
  tb_lif_layer

run_layer_simulation izhikevich \
  rtl/izhikevich/izhikevich_neuron.sv \
  rtl/izhikevich/izhikevich_layer.sv \
  tb/izhikevich/tb_izhikevich_layer.sv \
  tb_izhikevich_layer

run_layer_simulation hodgkin_huxley \
  rtl/hodgkin_huxley/hodgkin_huxley_neuron.sv \
  rtl/hodgkin_huxley/hodgkin_huxley_layer.sv \
  tb/hodgkin_huxley/tb_hodgkin_huxley_layer.sv \
  tb_hodgkin_huxley_layer

SYNTH_FAILED=0

run_layer_synthesis_if_incomplete() {
  local model="$1"
  local corner="$2"
  local top="${model}_layer"
  local out_dir="$PROJECT_DIR/asic/genus/$model/layer/$corner"
  local report_dir="$PROJECT_DIR/asic/reports/$model/layer/$corner"
  local netlist="$out_dir/${top}_tm_netlist.v"
  local log="$PROJECT_DIR/asic/logs/GENUS_${model}_layer_${corner}.log"
  local job="GENUS_${model}_layer_${corner}"
  local complete=1

  if [ ! -s "$netlist" ]; then complete=0; fi
  if [ ! -s "$report_dir/area.rpt" ]; then complete=0; fi
  if [ ! -s "$report_dir/timing.rpt" ]; then complete=0; fi
  if [ ! -s "$report_dir/power.rpt" ]; then complete=0; fi

  if [ "$complete" -eq 1 ] && [ -s "$log" ] &&
     grep -q "Synthesis completed: $model / layer / $corner" "$log"; then
    printf '%s\tSKIPPED\t0\tNetlist and reports already exist; synthesis completion confirmed\n' "$job" >> "$STATUS_FILE"
    echo "SKIP: $job â existing outputs and completion message verified."
    return
  fi

  printf '\n===== RUNNING %s =====\n' "$job"
  mkdir -p "$PROJECT_DIR/asic/logs"
  export PROJECT_DIR MODEL="$model" DESIGN_KIND=layer CORNER="$corner"

  unset DISPLAY

  "$GENUS" \
    -files "$PROJECT_DIR/asic/scripts/run_genus.tcl" \
    -log "$log" > "$REPAIR_DIR/${job}.console.log" 2>&1
  local rc=$?

  cat "$REPAIR_DIR/${job}.console.log"

  if [ "$rc" -eq 0 ] &&
     [ -s "$netlist" ] &&
     [ -s "$report_dir/area.rpt" ] &&
     [ -s "$report_dir/timing.rpt" ] &&
     [ -s "$report_dir/power.rpt" ] &&
     grep -q "Synthesis completed: $model / layer / $corner" "$log"; then
    printf '%s\tPASS\t0\tSynthesis and output checks passed\n' "$job" >> "$STATUS_FILE"
    echo "PASS: $job"
  else
    printf '%s\tFAIL\t%s\tCheck %s and %s\n' "$job" "$rc" "$log" "$REPAIR_DIR/${job}.console.log" >> "$STATUS_FILE"
    echo "FAIL: $job â inspect its logs and output files."
    SYNTH_FAILED=1
  fi
}

for model in lif izhikevich hodgkin_huxley; do
  for corner in slow typical fast; do
    run_layer_synthesis_if_incomplete "$model" "$corner"
  done
done

printf '\n===== REPAIR SUMMARY =====\n'
cat "$STATUS_FILE"
printf '\nFull repair log: %s\n' "$REPAIR_LOG"
printf 'Status table: %s\n' "$STATUS_FILE"
printf '===== REPAIR FINISHED: %s =====\n' "$(date)"

if [ "$SIM_FAILED" -ne 0 ] || [ "$SYNTH_FAILED" -ne 0 ]; then
  exit 1
fi
exit 0
BASH
chmod +x results/repair_20261027_135909/repair_failed_jobs.sh
/bin/bash results/repair_20261027_135909/repair_failed_jobs.sh
