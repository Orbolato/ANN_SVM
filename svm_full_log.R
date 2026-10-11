#!/usr/bin/env Rscript

# Public entry point for the recovered SVM analysis with signed-log inputs.
# The shared runner selects the exact preserved log script and applies the same
# reproducibility controls used by the other ANN/SVM variants.
source(file.path("R", "legacy_runner.R"))
run_ann_svm_cli("svm", log_transform = TRUE)
