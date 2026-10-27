#!/usr/bin/env bash

# ============================================================
# SNN NEURON STUDY: PDK AND CADENCE TOOL DISCOVERY
# ============================================================

set -u

PROJECT_DIR="${HOME}/snn_neuron_study"
PDK_ROOT="/home/cadence/install/FOUNDRY/digital/90nm/dig"
LIB_DIR="${PDK_ROOT}/lib"
LEF_DIR="${PDK_ROOT}/lef"

printf '\n===== 1. PROJECT DIRECTORY =====\n'

if [ -d "$PROJECT_DIR" ]; then
    printf '[OK] %s\n' "$PROJECT_DIR"
    cd "$PROJECT_DIR" || {
        printf '[ERROR] Cannot enter project directory.\n'
        exit 1
    }
else
    printf '[ERROR] Project directory does not exist: %s\n' "$PROJECT_DIR"
    exit 1
fi

printf '\n===== 2. PDK DIRECTORY =====\n'

if [ -d "$PDK_ROOT" ]; then
    printf '[OK] %s\n' "$PDK_ROOT"
else
    printf '[ERROR] PDK directory not found: %s\n' "$PDK_ROOT"
fi

printf '\n===== 3. LIBERTY TIMING LIBRARIES =====\n'

if [ -d "$LIB_DIR" ]; then
    printf '[OK] Library directory: %s\n' "$LIB_DIR"

    find "$LIB_DIR" -maxdepth 3 -type f \
        \( -name '*.lib' -o -name '*.lib.gz' \) \
        -print 2>/dev/null | sort

    if [ -f "$LIB_DIR/slow.lib" ]; then
        printf '[OK] Reference library slow.lib exists.\n'
    else
        printf '[WARN] Reference library slow.lib was not found.\n'
    fi
else
    printf '[ERROR] Library directory not found: %s\n' "$LIB_DIR"
fi

printf '\n===== 4. LEF FILES =====\n'

if [ -d "$LEF_DIR" ]; then
    find "$LEF_DIR" -maxdepth 2 -type f \
        \( -name '*.lef' -o -name '*.tlef' \) \
        -print 2>/dev/null | sort

    if [ -f "$LEF_DIR/gsclib090_translated.lef" ]; then
        printf '[OK] Reference standard-cell LEF exists.\n'
    else
        printf '[WARN] Reference standard-cell LEF was not found.\n'
    fi
else
    printf '[ERROR] LEF directory not found: %s\n' "$LEF_DIR"
fi

printf '\n===== 5. STANDARD-CELL VERILOG MODELS =====\n'

if [ -d "$PDK_ROOT" ]; then
    find "$PDK_ROOT" -maxdepth 5 -type f \
        \( -name '*.v' -o -name '*.sv' -o -name '*.v.gz' \) \
        -print 2>/dev/null | sort
else
    printf '[SKIP] PDK root is unavailable.\n'
fi

printf '\n===== 6. CADENCE TOOLS =====\n'

for tool in xrun genus lec tempus innovus; do
    if command -v "$tool" >/dev/null 2>&1; then
        printf '[OK] %-8s %s\n' "$tool" "$(command -v "$tool")"
    else
        printf '[WARN] %-8s not found in PATH\n' "$tool"
    fi
done

printf '\n===== 7. DISCOVERY COMPLETE =====\n'
printf 'Copy the terminal output back into the chat.\n'

