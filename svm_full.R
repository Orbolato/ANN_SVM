#!/usr/bin/env Rscript
source(file.path("R", "runner.R"))
run_ann_svm_experiments(model = "svm", log_transform = FALSE)
