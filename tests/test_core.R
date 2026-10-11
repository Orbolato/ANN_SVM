#!/usr/bin/env Rscript
source(file.path("R", "cpt_core.R"))
source(file.path("R", "legacy_runner.R"))
assert_true <- function(x, message) if (!isTRUE(x)) stop(message, call. = FALSE)
assert_equal <- function(a, b, message) if (!isTRUE(all.equal(a, b, check.attributes = FALSE))) stop(message, call. = FALSE)

for (file in c("ann_full.R", "ann_full_log.R", "svm_full.R", "svm_full_log.R", "generate_data.R", file.path("R", "cpt_core.R"), file.path("R", "legacy_runner.R"))) parse(file = file)

archive <- file.path("legacy", "2018", "ANN_SVM_recovered_source.tar.xz")
assert_true(file.exists(archive), "Recovered source archive is missing")
source_dir <- tempfile("ann-svm-test-")
dir.create(source_dir)
utils::untar(archive, exdir = source_dir)
submission <- c(
  "ANN/For_submission/ANN_full.R",
  "ANN/For_submission/ANN_full_log.R",
  "SVM/For_submission/SVM_full.R",
  "SVM/For_submission/SVM_full_log.R",
  "shared/generate_data.R"
)
for (file in submission) parse(file = file.path(source_dir, file))

assert_true(length(paper_experiments()) == 10L, "Experiment grid should contain 10 configurations")
assert_equal(signed_log_transform(c(0, 1)), c(0, 1), "Signed-log transform regression failed")
assert_equal(macro_recall(c(1, 1, 2, 2), c(1, 2, 2, 2)), (1 + 2/3)/2, "Macro-recall regression failed")
validation <- make_validation_fold_map(10L, 2019L)
assert_true(length(unique(validation)) == 10L, "Validation folds must be unique")
assert_true(all(validation != seq_len(10L)), "Validation fold cannot equal test fold")

# Validate the workspace contract without duplicating the shared historical data.
workspace_file <- tempfile(fileext = ".RData")
dataNet <- data.frame(SBTn = c(1, 2), x = c(0, 1))
dataGeo <- data.frame(MSBTn = c(1, 2), x = c(0, 1))
foldsNet <- replicate(10L, 1L, simplify = FALSE)
foldsGeo <- replicate(10L, 1L, simplify = FALSE)
validFolds <- make_validation_fold_map(10L, 2020L)
save(dataNet, dataGeo, foldsNet, foldsGeo, validFolds, file = workspace_file)
workspace <- load_archived_workspace(workspace_file)
assert_true(nrow(workspace$complete) == 2L && nrow(workspace$geology) == 2L, "Workspace contract failed")
assert_true(length(workspace$folds_complete) == 10L && length(workspace$folds_geology) == 10L, "Workspace folds contract failed")

assert_true(ann_svm_variant("ann", FALSE)$archive_path == "ANN/For_submission/ANN_full.R", "ANN mapping failed")
assert_true(ann_svm_variant("svm", TRUE)$archive_path == "SVM/For_submission/SVM_full_log.R", "SVM mapping failed")
cat("All ANN/SVM static and core tests passed.\n")
