#!/usr/bin/env Rscript
source(file.path("R", "cpt_core.R"))
source(file.path("R", "models.R"))
source(file.path("R", "cli.R"))

assert_true <- function(value, message) if (!isTRUE(value)) stop(message, call. = FALSE)
assert_equal <- function(a, b, message, tolerance = 1e-10) {
  if (!isTRUE(all.equal(a, b, tolerance = tolerance, check.attributes = FALSE))) stop(message, call. = FALSE)
}

public_scripts <- c(
  "ann_full.R", "ann_full_log.R", "svm_full.R", "svm_full_log.R",
  "svm_kernel_test.R", "generate_data.R", "restore_historical_data.R", file.path("R", "runner.R")
)
for (file in public_scripts) parse(file = file)

archive <- file.path("legacy", "2018", "ANN_SVM_recovered_source.tar.xz")
assert_true(file.exists(archive), "Recovered ANN/SVM source archive is missing")
source_dir <- tempfile("ann-svm-source-")
dir.create(source_dir)
utils::untar(archive, exdir = source_dir)
legacy_scripts <- c(
  file.path("ANN", "For submission", "ANN_full.R"),
  file.path("ANN", "For submission", "ANN_full_log.R"),
  file.path("SVM", "For submission", "SVM_full.R"),
  file.path("SVM", "For submission", "SVM_full_log.R"),
  file.path("SVM", "For submission", "SVM_test.R"),
  file.path("SVM", "For submission", "SVM_test_log.R")
)
for (file in legacy_scripts) parse(file = file.path(source_dir, file))

assert_true(length(paper_experiments()) == 10L, "Historical experiment grid must contain 10 configurations")
assert_equal(signed_log_transform(c(0, 1)), c(0, 1), "Signed-log transform regression failed")
assert_equal(
  macro_recall(c(1, 1, 2, 2), c(1, 2, 2, 2)),
  (1 + 2 / 3) / 2,
  "Macro-recall regression failed"
)

validation <- make_validation_fold_map(10L, 2019L)
assert_true(length(unique(validation)) == 10L, "Validation folds must be unique")
assert_true(all(validation != seq_len(10L)), "Validation fold cannot equal its test fold")

sample_data <- data.frame(
  x = c(1, 2, 3, 10, 11, 12),
  y = c(2, 3, 4, 20, 21, 22),
  class = c(1, 1, 1, 2, 2, 2)
)
balanced <- balance_training_data(sample_data, "class", c("x", "y"), seed = 7L, minimum_per_class = 3L)
assert_true(length(unique(table(balanced$class))) == 1L, "Balancing regression failed")

assert_true(file.exists("restore_historical_data.R"), "Data restoration helper is missing")

# Current-package smoke checks: verify the refactored model wrappers still match
# the installed RSNNS and kernlab APIs without running the expensive paper grid.
toy <- data.frame(
  x1 = c(0.00, 0.05, 0.10, 0.15, 0.20, 0.25, 0.75, 0.80, 0.85, 0.90, 0.95, 1.00),
  x2 = c(0.05, 0.00, 0.15, 0.10, 0.25, 0.20, 0.80, 0.75, 0.90, 0.85, 1.00, 0.95),
  class = factor(rep(c("A", "B"), each = 6L))
)
ann_fit <- fit_ann(toy, "class", c("x1", "x2"), hidden = 2L, iterations = 20L, seed = 11L)
ann_pred <- predict_ann(ann_fit, toy, c("x1", "x2"))
assert_true(length(ann_pred) == nrow(toy), "ANN current-package smoke test failed")

svm_fit <- fit_polynomial_svm(
  toy, "class", c("x1", "x2"),
  degree = 1L, scale = 1, offset = 1,
  seed = 12L
)
svm_pred <- predict(svm_fit, toy[, c("x1", "x2"), drop = FALSE])
assert_true(length(svm_pred) == nrow(toy), "SVM current-package smoke test failed")

cat("All ANN/SVM core, provenance, and model smoke tests passed.\n")
