source(file.path("R", "cpt_core.R"))

ann_svm_variant <- function(model = c("ann", "svm"), log_transform = FALSE) {
  model <- match.arg(model)
  stem <- paste0(model, "_full", if (log_transform) "_log" else "")
  archive_path <- if (model == "ann") {
    paste0("ANN/For_submission/ANN_full", if (log_transform) "_log" else "", ".R")
  } else {
    paste0("SVM/For_submission/SVM_full", if (log_transform) "_log" else "", ".R")
  }
  list(model = model, log_transform = log_transform, stem = stem, archive_path = archive_path)
}

required_model_packages <- function(model) {
  if (identical(model, "ann")) c("kknn", "RSNNS") else c("kknn", "e1071", "kernlab")
}

check_model_dependencies <- function(model) {
  packages <- required_model_packages(model)
  missing <- packages[!vapply(packages, requireNamespace, logical(1), quietly = TRUE)]
  if (length(missing) > 0L) {
    stop(sprintf("Missing required package(s): %s", paste(missing, collapse = ", ")), call. = FALSE)
  }
  invisible(TRUE)
}

run_recovered_analysis <- function(model, log_transform = FALSE, workspace = "data.RData",
                                   output = NULL, seed = 2019L, legacy = FALSE,
                                   archive = file.path("legacy", "2018", "ANN_SVM_recovered_source.tar.xz")) {
  variant <- ann_svm_variant(model, log_transform)
  if (is.null(output)) output <- file.path("results", paste0("results_", variant$stem, ".RData"))
  if (!file.exists(archive)) stop(sprintf("Recovered source archive not found: %s", archive), call. = FALSE)
  check_model_dependencies(variant$model)

  env <- new.env(parent = globalenv())
  loaded <- load(workspace, envir = env)
  required <- c("dataNet", "dataGeo", "foldsNet", "foldsGeo", "validFolds")
  missing <- setdiff(required, loaded)
  if (length(missing) > 0L) stop(sprintf("Workspace is missing required object(s): %s", paste(missing, collapse = ", ")), call. = FALSE)

  source_dir <- tempfile("ann-svm-source-")
  dir.create(source_dir)
  utils::untar(archive, exdir = source_dir)
  script <- file.path(source_dir, variant$archive_path)
  if (!file.exists(script)) stop(sprintf("Recovered script not found: %s", variant$archive_path), call. = FALSE)

  if (!legacy) {
    base::set.seed(as.integer(seed))
    # Historical scripts repeatedly reseed from Sys.time(). Suppressing those
    # internal reseeds keeps the random stream deterministic while otherwise
    # executing the preserved source unchanged.
    env$set.seed <- function(...) invisible(NULL)
  }

  sys.source(script, envir = env)
  dir.create(dirname(output), recursive = TRUE, showWarnings = FALSE)
  exclude <- c(required, "set.seed")
  objects <- setdiff(ls(env, all.names = TRUE), exclude)
  save(list = objects, envir = env, file = output)
  message(sprintf("Saved %s analysis workspace to %s", if (legacy) "legacy" else "deterministic", output))
  invisible(output)
}

run_ann_svm_cli <- function(model, log_transform = FALSE) {
  args <- commandArgs(trailingOnly = TRUE)
  value_after <- function(flag, default = NULL) {
    position <- match(flag, args)
    if (is.na(position)) return(default)
    if (position == length(args)) stop(sprintf("%s requires a value.", flag), call. = FALSE)
    args[[position + 1L]]
  }
  if ("--help" %in% args) {
    cat(paste(
      sprintf("Run the recovered %s%s analysis.", toupper(model), if (log_transform) " log" else ""),
      "",
      "Options:",
      "  --workspace PATH   input workspace (default: data.RData)",
      "  --output PATH      output RData path",
      "  --seed INTEGER     deterministic random-stream seed (default: 2019)",
      "  --legacy           preserve historical time-dependent reseeding",
      sep = "\n"
    ))
    quit(status = 0L)
  }
  seed <- suppressWarnings(as.integer(value_after("--seed", "2019")))
  if (is.na(seed)) stop("--seed must be an integer.", call. = FALSE)
  run_recovered_analysis(
    model = model,
    log_transform = log_transform,
    workspace = value_after("--workspace", "data.RData"),
    output = value_after("--output", NULL),
    seed = seed,
    legacy = "--legacy" %in% args
  )
}
