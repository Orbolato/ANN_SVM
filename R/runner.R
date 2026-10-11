source(file.path("R", "cpt_core.R"))
source(file.path("R", "models.R"))
source(file.path("R", "cli.R"))

ann_svm_help <- function(model, log_transform) {
  cat(sprintf("Run the cleaned %s%s CPT soil-classification experiments.\n\n", toupper(model), if (log_transform) " log-scaled" else ""))
  cat(sprintf("Usage: Rscript %s_full%s.R [options]\n\n", model, if (log_transform) "_log" else ""))
  print_common_help()
  if (model == "ann") {
    cat("\nANN options:\n  --max-iterations N           cap iteration tuning (default: 2000)\n  --max-hidden-multiplier N    hidden-layer search up to N x classes (default: 2)\n")
  } else {
    cat("\nSVM options:\n  --max-svm-degree N           polynomial degree bound (default: 6)\n  --max-svm-scale N            polynomial scale bound (default: 6)\n  --max-svm-offset N           polynomial offset bound (default: 6)\n")
  }
}

legacy_script_path <- function(model, log_transform) {
  directory <- if (model == "ann") "ANN" else "SVM"
  filename <- sprintf("%s_full%s.R", toupper(model), if (log_transform) "_log" else "")
  file.path(directory, "For submission", filename)
}

run_legacy_ann_svm <- function(model, log_transform, options) {
  archive <- file.path("legacy", "2018", "ANN_SVM_recovered_source.tar.xz")
  if (!file.exists(archive)) stop("Recovered source archive is missing.", call. = FALSE)
  if (!file.exists(options$workspace)) stop(sprintf("Workspace not found: %s", options$workspace), call. = FALSE)
  source_dir <- tempfile("ann-svm-legacy-")
  dir.create(source_dir)
  utils::untar(archive, exdir = source_dir)
  script <- file.path(source_dir, legacy_script_path(model, log_transform))
  if (!file.exists(script)) stop(sprintf("Recovered script missing: %s", script), call. = FALSE)
  env <- new.env(parent = globalenv())
  load(options$workspace, envir = env)
  sys.source(script, envir = env)
  dir.create(options$output_dir, recursive = TRUE, showWarnings = FALSE)
  output <- file.path(options$output_dir, sprintf("legacy_%s_full%s.RData", model, if (log_transform) "_log" else ""))
  save(list = ls(env, all.names = TRUE), envir = env, file = output)
  message(sprintf("Saved legacy analysis environment to %s", output))
  invisible(output)
}

run_ann_svm_experiments <- function(model = c("ann", "svm"), log_transform = FALSE, options = parse_cli()) {
  model <- match.arg(model)
  if (options$help) {
    ann_svm_help(model, log_transform)
    return(invisible(NULL))
  }
  if (options$legacy) return(run_legacy_ann_svm(model, log_transform, options))

  workspace <- load_archived_workspace(options$workspace)
  experiments <- select_experiments(options$max_configurations)
  max_folds <- min(10L, max(1L, options$max_folds))
  rows <- list()
  row_index <- 0L

  for (config_index in seq_along(experiments)) {
    experiment <- experiments[[config_index]]
    data <- workspace[[experiment$data]]
    folds <- if (experiment$data == "complete") workspace$folds_complete else workspace$folds_geology
    if (!options$quiet) message(sprintf("%s: %s", toupper(model), experiment$id))

    for (fold_index in seq_len(max_folds)) {
      prepared <- prepare_fold(
        data = data,
        folds = folds,
        validation_folds = workspace$validation_folds,
        fold_index = fold_index,
        output = experiment$output,
        features = experiment$features,
        log_transform = log_transform,
        remove_fsb_zero = options$remove_fsb_zero,
        minimum_per_class = options$minimum_per_class,
        seed = options$seed + 1000L * config_index
      )

      # ANN and SVM historical submission scripts ultimately use the balanced
      # training variant; the balanced/unbalanced pre-test blocks are commented.
      split <- as_classification_frames(prepared$balanced, experiment$output)
      fold_seed <- options$seed + 100000L * config_index + fold_index

      if (model == "ann") {
        tuning <- tune_ann(
          split$train, split$validation,
          experiment$output, experiment$features,
          seed = fold_seed,
          max_iterations = options$max_iterations,
          max_hidden_multiplier = options$max_hidden_multiplier
        )
        fit <- fit_ann(
          split$train, experiment$output, experiment$features,
          hidden = tuning$hidden, iterations = tuning$iterations,
          seed = fold_seed + 50000L
        )
        predictions <- predict_ann(fit, split$test, experiment$features)
        parameters <- sprintf(
          "hidden=%s;iterations=%d",
          paste(tuning$hidden, collapse = "x"), tuning$iterations
        )
      } else {
        tuning <- tune_polynomial_svm(
          split$train, split$validation,
          experiment$output, experiment$features,
          seed = fold_seed,
          max_degree = options$max_svm_degree,
          max_scale = options$max_svm_scale,
          max_offset = options$max_svm_offset
        )
        fit <- fit_polynomial_svm(
          split$train, experiment$output, experiment$features,
          tuning$degree, tuning$scale, tuning$offset,
          seed = fold_seed + 50000L
        )
        predictions <- predict_svm(fit, split$test[, experiment$features, drop = FALSE])
        parameters <- sprintf(
          "degree=%d;scale=%d;offset=%d",
          tuning$degree, tuning$scale, tuning$offset
        )
      }

      test_score <- macro_recall(predictions, split$test[[experiment$output]])
      row_index <- row_index + 1L
      rows[[row_index]] <- data.frame(
        model = toupper(model),
        log_transform = log_transform,
        experiment = experiment$id,
        output = experiment$output,
        features = paste(experiment$features, collapse = "+"),
        fold = fold_index,
        validation_macro_recall = tuning$validation_score,
        test_macro_recall = test_score,
        parameters = parameters,
        stringsAsFactors = FALSE
      )
      if (!options$quiet) message(sprintf("  fold %d: test macro recall %.4f", fold_index, test_score))
    }
  }

  results <- do.call(rbind, rows)
  summary_rows <- do.call(rbind, lapply(base::split(results, results$experiment), function(group) {
    data.frame(
      experiment = group$experiment[[1L]],
      output = group$output[[1L]],
      features = group$features[[1L]],
      mean_macro_recall = mean(group$test_macro_recall),
      sd_macro_recall = if (nrow(group) > 1L) stats::sd(group$test_macro_recall) else NA_real_,
      folds = nrow(group),
      stringsAsFactors = FALSE
    )
  }))
  rownames(summary_rows) <- NULL

  dir.create(options$output_dir, recursive = TRUE, showWarnings = FALSE)
  stem <- sprintf("%s_full%s", model, if (log_transform) "_log" else "")
  utils::write.csv(results, file.path(options$output_dir, paste0(stem, "_folds.csv")), row.names = FALSE)
  utils::write.csv(summary_rows, file.path(options$output_dir, paste0(stem, "_summary.csv")), row.names = FALSE)
  saveRDS(
    list(
      model = model,
      log_transform = log_transform,
      options = options,
      fold_results = results,
      summary = summary_rows
    ),
    file.path(options$output_dir, paste0(stem, ".rds"))
  )
  invisible(list(fold_results = results, summary = summary_rows))
}
