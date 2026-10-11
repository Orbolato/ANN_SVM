#!/usr/bin/env Rscript
source(file.path("R", "cpt_core.R"))
source(file.path("R", "models.R"))
source(file.path("R", "cli.R"))

options <- parse_cli()
if (options$help) {
  cat("Compare Gaussian, Laplacian, and polynomial SVM kernels on the recovered experiment grid.\n\n")
  cat("Usage: Rscript svm_kernel_test.R [options]\n\n")
  print_common_help()
  quit(status = 0L)
}
if (options$legacy) stop("Use the recovered SVM_test*.R files in legacy/2018 for the exact historical preliminary kernel test.", call. = FALSE)

workspace <- load_archived_workspace(options$workspace)
experiments <- select_experiments(options$max_configurations)
max_folds <- min(10L, max(1L, options$max_folds))
rows <- list()
index <- 0L
for (config_index in seq_along(experiments)) {
  experiment <- experiments[[config_index]]
  data <- workspace[[experiment$data]]
  folds <- if (experiment$data == "complete") workspace$folds_complete else workspace$folds_geology
  for (fold_index in seq_len(max_folds)) {
    prepared <- prepare_fold(
      data, folds, workspace$validation_folds, fold_index,
      experiment$output, experiment$features,
      log_transform = FALSE,
      remove_fsb_zero = options$remove_fsb_zero,
      minimum_per_class = options$minimum_per_class,
      seed = options$seed + 1000L * config_index
    )
    split <- as_classification_frames(prepared$balanced, experiment$output)
    for (kernel in c("rbfdot", "laplacedot", "polydot")) {
      seed <- options$seed + 100000L * config_index + 100L * fold_index + match(kernel, c("rbfdot", "laplacedot", "polydot"))
      if (kernel == "polydot") {
        tuning <- tune_polynomial_svm(
          split$train, split$validation, experiment$output, experiment$features,
          seed, options$max_svm_degree, options$max_svm_scale, options$max_svm_offset
        )
        model <- fit_polynomial_svm(
          split$train, experiment$output, experiment$features,
          tuning$degree, tuning$scale, tuning$offset, seed + 50000L
        )
        validation_score <- tuning$validation_score
      } else {
        model <- fit_svm_kernel(split$train, experiment$output, experiment$features, kernel, seed)
        validation_score <- macro_recall(
          predict(model, split$validation[, experiment$features, drop = FALSE]),
          split$validation[[experiment$output]]
        )
      }
      test_score <- macro_recall(
        predict(model, split$test[, experiment$features, drop = FALSE]),
        split$test[[experiment$output]]
      )
      index <- index + 1L
      rows[[index]] <- data.frame(
        experiment = experiment$id,
        fold = fold_index,
        kernel = kernel,
        validation_macro_recall = validation_score,
        test_macro_recall = test_score,
        stringsAsFactors = FALSE
      )
    }
  }
}
results <- do.call(rbind, rows)
dir.create(options$output_dir, recursive = TRUE, showWarnings = FALSE)
utils::write.csv(results, file.path(options$output_dir, "svm_kernel_test.csv"), row.names = FALSE)
saveRDS(results, file.path(options$output_dir, "svm_kernel_test.rds"))
