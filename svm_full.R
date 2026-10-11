#!/usr/bin/env Rscript

# Public entry point for the recovered SVM analysis without signed-log inputs.
# Model selection remains in the preserved historical script; this wrapper only
# delegates reproducibility, archive, workspace, and output handling.
source(file.path("R", "legacy_runner.R"))
run_ann_svm_cli("svm", log_transform = FALSE)
