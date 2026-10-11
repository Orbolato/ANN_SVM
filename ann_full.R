#!/usr/bin/env Rscript

# Public entry point for the recovered ANN analysis without signed-log inputs.
# All archive handling, reproducibility controls, and CLI options live in the
# shared runner so this file cannot drift from the other ANN/SVM variants.
source(file.path("R", "legacy_runner.R"))
run_ann_svm_cli("ann", log_transform = FALSE)
