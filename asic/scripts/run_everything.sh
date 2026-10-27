#!/usr/bin/env bash

# ============================================================
# SNN NEURON STUDY: MASTER EXECUTION SCRIPT
# Simulations -> Genus synthesis -> Conformal LEC -> Summary
# ============================================================

set -u

PROJECT_DIR="/home/userdata/24bvd0198/snn_neuron_study"
cd "$PROJECT_DIR" || exit 1

export PROJECT_DIR

STAMP="$(date +%Y%m%d_%H%M%S)"
RUN_DIR="$PROJECT_DIR/results/run_${STAMP}"

mkdir -p "$RUN_DIR" \
         "$PROJECT_DIR/sim/logs" \
         "$PROJECT_DIR/sim/waves" \
         "$PROJECT_DIR/asic/logs"

export RUN_DIR

SUMMARY="$RUN_DIR/summary.tsv"
CONSOLE="$RUN_DIR/console.log"

printf 'STEP\tSTATUS\tEXIT_CODE\tLOG\n' > "$SUMMARY"

# Record console output and retain it in a file.
exec > >(tee -a "$CONSOLE") 2>&1

echo "============================================================"
echo "SNN NEURON STUDY: FULL EXECUTION"
echo "============================================================"
echo "Project : $PROJECT_DIR"
echo "Run dir : $RUN_DIR"
echo "Started : $(date)"
echo

# ------------------------------------------------------------
# Generic command runner. Never abort the full workflow because
# one individual command fails.
# ------------------------------------------------------------
run_step() {
    local name="$1"
    local logfile="$2"
    shift 2

    echo
    echo "------------------------------------------------------------"
    echo "STEP: $name"
    echo "LOG : $logfile"
    echo "CMD : $*"
    echo "------------------------------------------------------------"

    "$@" > "$logfile" 2>&1
    local rc=$?

    if [ "$rc" -eq 0 ]; then
        echo "RESULT: PASS (exit 0)"
        printf '%s\tPASS\t0\t%s\n' "$name" "$logfile" >> "$SUMMARY"
    else
        echo "RESULT: FAIL (exit $rc)"
        printf '%s\tFAIL\t%s\t%s\n' "$name" "$rc" "$logfile" >> "$SUMMARY"
        echo "---- Last 30 lines of log ----"
        tail -n 30 "$logfile" 2>/dev/null || true
    fi

    return 0
}

# ------------------------------------------------------------
# Capture environment information.
# ------------------------------------------------------------
{
    echo "Date: $(date)"
    echo "Host: $(hostname)"
    echo "User: $(whoami)"
    echo "Project: $PROJECT_DIR"
    echo
    echo "===== GIT ====="
    git status --short --branch 2>&1 || true
    git log -1 --oneline 2>&1 || true
    echo
    echo "===== TOOL LOCATIONS ====="
    for tool in xrun genus lec conformal innovus tempus; do
        printf '%-12s' "$tool"
        command -v "$tool" 2>/dev/null || echo "NOT FOUND"
    done
    echo
    echo "===== RTL FILE SIZES ====="
    find rtl -type f -exec wc -l -c {} \; 2>&1
    echo
    echo "===== TOOL VERSIONS ====="
    xrun -version 2>&1 || true
    genus -version 2>&1 || true
} > "$RUN_DIR/environment.txt"

echo "Environment information saved."

# ============================================================
# PHASE 1: XCELIUM SIMULATION
# ============================================================

if ! command -v xrun >/dev/null 2>&1; then
    echo "ERROR: xrun not found; skipping simulation phase."
    printf 'SIMULATION_PHASE\tSKIPPED\t127\txrun not found\n' >> "$SUMMARY"
else
    while IFS='|' read -r model rtl tb top; do
        [ -n "$model" ] || continue

        name="SIM_${model}_${top}"
        logfile="$RUN_DIR/${name}.log"

        run_step "$name" "$logfile" \
            xrun -64bit -sv \
            "$rtl" "$tb" \
            -top "$top" \
            -access +rwc \
            -xmlibdirname "$RUN_DIR/xcelium_${model}_${top}" \
            -l "$RUN_DIR/xrun_${model}_${top}.log" \
            -run
    done <<'SIMS'
lif|rtl/lif/lif_neuron.sv|tb/lif/tb_lif_neuron.sv|tb_lif_neuron
izhikevich|rtl/izhikevich/izhikevich_neuron.sv|tb/izhikevich/tb_izhikevich_neuron.sv|tb_izhikevich_neuron
hodgkin_huxley|rtl/hodgkin_huxley/hodgkin_huxley_neuron.sv|tb/hodgkin_huxley/tb_hodgkin_huxley_neuron.sv|tb_hodgkin_huxley_neuron
lif|rtl/lif/lif_layer.sv|tb/lif/tb_lif_layer.sv|tb_lif_layer
izhikevich|rtl/izhikevich/izhikevich_layer.sv|tb/izhikevich/tb_izhikevich_layer.sv|tb_izhikevich_layer
hodgkin_huxley|rtl/hodgkin_huxley/hodgkin_huxley_layer.sv|tb/hodgkin_huxley/tb_hodgkin_huxley_layer.sv|tb_hodgkin_huxley_layer
SIMS
fi

# ============================================================
# PHASE 2: GENUS SYNTHESIS
# 3 models x 2 design types x 3 corners = 18 runs
# ============================================================

if ! command -v genus >/dev/null 2>&1; then
    echo "ERROR: genus not found; skipping synthesis phase."
    printf 'SYNTHESIS_PHASE\tSKIPPED\t127\tgenus not found\n' >> "$SUMMARY"
else
    for model in lif izhikevich hodgkin_huxley; do
        for kind in neuron layer; do
            for corner in slow typical fast; do

                export MODEL="$model"
                export DESIGN_KIND="$kind"
                export CORNER="$corner"

                name="GENUS_${model}_${kind}_${corner}"
                logfile="$RUN_DIR/${name}.log"

                run_step "$name" "$logfile" \
                    genus \
                    -files "$PROJECT_DIR/asic/scripts/run_genus.tcl" \
                    -log "$PROJECT_DIR/asic/logs/${name}.log"

            done
        done
    done
fi

# ============================================================
# PHASE 3: CONFORMAL LEC
# Uses the generalized LEC dofile and each matching netlist.
# ============================================================

LEC_BIN=""

if command -v lec >/dev/null 2>&1; then
    LEC_BIN="$(command -v lec)"
elif command -v conformal >/dev/null 2>&1; then
    LEC_BIN="$(command -v conformal)"
fi

if [ -z "$LEC_BIN" ]; then
    echo "WARNING: Neither 'lec' nor 'conformal' was found."
    echo "Skipping LEC. See environment.txt."
    printf 'LEC_PHASE\tSKIPPED\t127\tConformal executable not found\n' >> "$SUMMARY"
else
    echo "LEC executable: $LEC_BIN"

    for model in lif izhikevich hodgkin_huxley; do
        for kind in neuron layer; do
            for corner in slow typical fast; do

                export MODEL="$model"
                export DESIGN_KIND="$kind"
                export CORNER="$corner"

                case "$model" in
                    lif)
                        top="lif_neuron"
                        [ "$kind" = "layer" ] && top="lif_layer"
                        ;;
                    izhikevich)
                        top="izhikevich_neuron"
                        [ "$kind" = "layer" ] && top="izhikevich_layer"
                        ;;
                    hodgkin_huxley)
                        top="hodgkin_huxley_neuron"
                        [ "$kind" = "layer" ] && top="hodgkin_huxley_layer"
                        ;;
                esac

                netlist="$PROJECT_DIR/asic/genus/${model}/${kind}/${corner}/${top}_tm_netlist.v"

                name="LEC_${model}_${kind}_${corner}"
                logfile="$RUN_DIR/${name}.log"

                if [ ! -s "$netlist" ]; then
                    echo
                    echo "SKIPPING $name: mapped netlist missing:"
                    echo "$netlist"
                    printf '%s\tSKIPPED\t2\tmissing netlist: %s\n' \
                        "$name" "$netlist" >> "$SUMMARY"
                    continue
                fi

                if [ "$LEC_BIN" = "$(command -v lec 2>/dev/null || true)" ]; then
                    run_step "$name" "$logfile" \
                        "$LEC_BIN" -nogui \
                        -dofile "$PROJECT_DIR/asic/scripts/run_lec.tcl" \
                        -logfile "$PROJECT_DIR/asic/logs/${name}.log"
                else
                    run_step "$name" "$logfile" \
                        "$LEC_BIN" \
                        -dofile "$PROJECT_DIR/asic/scripts/run_lec.tcl" \
                        -logfile "$PROJECT_DIR/asic/logs/${name}.log"
                fi

            done
        done
    done
fi

# ============================================================
# PHASE 4: COLLECT REPORTS AND WAVEFORMS
# ============================================================

echo
echo "============================================================"
echo "COLLECTING OUTPUTS"
echo "============================================================"

find "$PROJECT_DIR/asic/reports" -type f -print \
    > "$RUN_DIR/report_file_list.txt" 2>/dev/null || true

find "$PROJECT_DIR/asic/genus" -type f -print \
    > "$RUN_DIR/netlist_file_list.txt" 2>/dev/null || true

find "$PROJECT_DIR/asic/lec" -type f -print \
    > "$RUN_DIR/lec_file_list.txt" 2>/dev/null || true

find "$PROJECT_DIR/sim/waves" -type f -name '*.vcd' -print \
    > "$RUN_DIR/waveform_file_list.txt" 2>/dev/null || true

# Include compact tool-log summaries for quick review.
{
    echo "===== SIMULATION RESULTS ====="
    grep -hE 'TB complete|Simulation complete|errors:|warnings:' \
        "$RUN_DIR"/SIM_*.log 2>/dev/null || true

    echo
    echo "===== SYNTHESIS RESULTS ====="
    grep -hE 'Synthesis completed|ERROR:|Error:|FATAL|Warning:' \
        "$RUN_DIR"/GENUS_*.log 2>/dev/null || true

    echo
    echo "===== LEC RESULTS ====="
    grep -hEi 'PASS|FAIL|compare|equivalent|non.?equivalent|error|fatal' \
        "$RUN_DIR"/LEC_*.log 2>/dev/null || true
} > "$RUN_DIR/key_messages.txt"

# Generate an archive of the run evidence.
# The archive includes logs, reports, netlists, scripts and VCDs.
ARCHIVE="$PROJECT_DIR/results/snn_run_${STAMP}.tar.gz"

tar -czf "$ARCHIVE" \
    "$RUN_DIR" \
    "$PROJECT_DIR/asic/reports" \
    "$PROJECT_DIR/asic/lec" \
    "$PROJECT_DIR/asic/scripts" \
    "$PROJECT_DIR/sim/waves" \
    "$PROJECT_DIR/asic/genus" \
    2>"$RUN_DIR/archive_warnings.log"

archive_rc=$?
if [ "$archive_rc" -eq 0 ]; then
    echo "Diagnostic archive: $ARCHIVE"
else
    echo "WARNING: Archive creation returned $archive_rc."
fi

# ============================================================
# FINAL SUMMARY
# ============================================================

echo
echo "============================================================"
echo "FINAL SUMMARY"
echo "============================================================"

column -t -s "$(printf '\t')" "$SUMMARY" 2>/dev/null || cat "$SUMMARY"

echo
echo "===== COUNTS ====="
awk -F '\t' '
    NR > 1 { count[$2]++ }
    END {
        printf "PASS: %d\n", count["PASS"]
        printf "FAIL: %d\n", count["FAIL"]
        printf "SKIPPED: %d\n", count["SKIPPED"]
    }
' "$SUMMARY"

echo
echo "===== OUTPUT LOCATIONS ====="
echo "Run directory : $RUN_DIR"
echo "Summary       : $SUMMARY"
echo "Console log   : $CONSOLE"
echo "Key messages  : $RUN_DIR/key_messages.txt"
echo "Environment   : $RUN_DIR/environment.txt"
echo "Archive       : $ARCHIVE"
echo
echo "Finished: $(date)"
echo "Workflow finished; review results before treating any stage as passing."

exit 0
