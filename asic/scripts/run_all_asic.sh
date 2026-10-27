#!/usr/bin/env bash
set -u

PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
export PROJECT_DIR

RUN_LEC="${RUN_LEC:-1}"
MODELS=(lif izhikevich hodgkin_huxley)
KINDS=(neuron layer)
CORNERS=(slow typical fast)

mkdir -p "$PROJECT_DIR/asic/logs"

for model in "${MODELS[@]}"; do
    for kind in "${KINDS[@]}"; do
        for corner in "${CORNERS[@]}"; do
            export MODEL="$model"
            export DESIGN_KIND="$kind"
            export CORNER="$corner"

            echo
            echo "=================================================="
            echo "GENUS: MODEL=$MODEL DESIGN_KIND=$DESIGN_KIND CORNER=$CORNER"
            echo "=================================================="

            genus -files "$PROJECT_DIR/asic/scripts/run_genus.tcl" \
                -log "$PROJECT_DIR/asic/logs/genus_${model}_${kind}_${corner}.log"
            genus_rc=$?

            if [ "$genus_rc" -ne 0 ]; then
                echo "ERROR: Genus failed for $model/$kind/$corner (status $genus_rc)"
                continue
            fi

            if [ "$RUN_LEC" = "1" ]; then
                echo
                echo "CONFORMAL LEC: $model/$kind/$corner"

                lec -nogui \
                    -dofile "$PROJECT_DIR/asic/scripts/run_lec.tcl" \
                    -logfile "$PROJECT_DIR/asic/logs/lec_${model}_${kind}_${corner}.log"
                lec_rc=$?

                if [ "$lec_rc" -ne 0 ]; then
                    echo "ERROR: LEC command failed for $model/$kind/$corner (status $lec_rc)"
                fi
            fi
        done
    done
done

echo
echo "Driver finished. Inspect logs under asic/logs."
