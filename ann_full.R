#!/usr/bin/env Rscript
source(file.path("R", "legacy_runner.R"))
run_ann_svm_cli("ann", log_transform = FALSE)
