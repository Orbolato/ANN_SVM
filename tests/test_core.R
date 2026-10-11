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

cat("All ANN/SVM core and provenance tests passed.\n")
