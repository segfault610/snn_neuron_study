# Neuron ASIC Flow Scripts

## Supported designs
- lif
- izhikevich
- hodgkin_huxley

## Supported design kinds
- neuron
- layer

## Synthesis
The generalized Genus script is `run_genus.tcl`.

Required environment variables:
- `PROJECT_DIR`
- `MODEL`
- `DESIGN_KIND`
- `CORNER`

The output netlists are placed under:
`asic/genus/<model>/<design_kind>/<corner>/`

Area, timing and power reports are placed under:
`asic/reports/<model>/<design_kind>/<corner>/`

## Formal equivalence
`run_lec.tcl` compares the RTL against the mapped Genus netlist for the same model,
design kind and library corner. The mapped netlist must exist before LEC is run.

LEC results must be inspected. A script completing does not guarantee equivalence.

## Driver
Run `bash asic/scripts/run_all_asic.sh` from an environment where Genus and Conformal
are available. This attempts neuron and layer synthesis at slow, typical and fast
corners, followed by LEC. To run synthesis only, use:
`RUN_LEC=0 bash asic/scripts/run_all_asic.sh`

## Caveats
- Verify the installed Conformal command-line options and dofile syntax against the
  local installation before relying on unattended runs.
- Ensure the appropriate timing constraints are loaded before interpreting timing
  reports as final STA results.
- Vectorless power reports are estimates, not activity-based power measurements.
- The Izhikevich and Hodgkin-Huxley RTL are reduced-order integer approximations;
  they are not precision biological reference models.
