#!/usr/bin/env Rscript

# Public entry point for the recovered ANN analysis with signed-log inputs.
# The shared runner selects the exact preserved log script and applies the same
# reproducibility controls used by the non-log ANN/SVM entry points.
source(file.path("R", "legacy_runner.R"))
run_ann_svm_cli("ann", log_transform = TRUE)
