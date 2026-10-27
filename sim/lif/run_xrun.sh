#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PROJECT_ROOT"

if ! command -v xrun >/dev/null 2>&1; then
    echo "ERROR: xrun is not in PATH."
    echo "Load your university's Cadence environment and retry."
    exit 1
fi

mkdir -p sim/logs sim/waves

xrun \
    -64bit \
    -sv \
    -timescale 1ns/1ps \
    -access +rwc \
    -top tb_lif_neuron \
    -l sim/logs/lif_neuron_xrun.log \
    -xmlibdirname sim/lif/xcelium.d \
    rtl/lif/lif_neuron.sv \
    tb/lif/tb_lif_neuron.sv

