# Execution wrapper for the exact recovered ANN/SVM source preserved in legacy/.
#
# The historical scripts remain unchanged. This module maps public entry points
# to those scripts, validates dependencies/workspace objects, optionally replaces
# repeated time-based reseeding with one deterministic random stream, and saves
# the resulting analysis environment.

source(file.path("R", "cpt_core.R"))

# Resolve a public model/log choice to a stable output stem and the exact path
# of the preserved submission script inside ANN_SVM_recovered_source.tar.xz.
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

# Dependencies differ by model family but both historical scripts also use kknn
# during preprocessing/editing.
required_model_packages <- function(model) {
  if (identical(model, "ann")) c("kknn", "RSNNS") else c("kknn", "e1071", "kernlab")
}

# Check all model-specific packages before starting a potentially long legacy run.
check_model_dependencies <- function(model) {
  packages <- required_model_packages(model)
  missing <- packages[!vapply(packages, requireNamespace, logical(1), quietly = TRUE)]
  if (length(missing) > 0L) {
    stop(sprintf("Missing required package(s): %s", paste(missing, collapse = ", ")), call. = FALSE)
  }
  invisible(TRUE)
}

# Execute one recovered submission script in an isolated environment.
#
# By default, the wrapper seeds R once and masks the script's internal set.seed()
# calls. The preserved source repeatedly reseeds from Sys.time(); suppressing
# only those calls keeps the historical preprocessing/tuning/model code intact
# while making the cleaned rerun reproducible. Setting legacy=TRUE exposes the
# exact historical reseeding behavior instead.
run_recovered_analysis <- function(model, log_transform = FALSE, workspace = "data.RData",
                                   output = NULL, seed = 2019L, legacy = FALSE,
                                   archive = file.path("legacy", "2018", "ANN_SVM_recovered_source.tar.xz")) {
  variant <- ann_svm_variant(model, log_transform)
  if (is.null(output)) output <- file.path("results", paste0("results_", variant$stem, ".RData"))
  if (!file.exists(archive)) stop(sprintf("Recovered source archive not found: %s", archive), call. = FALSE)
  check_model_dependencies(variant$model)

  # Load the exact object names expected by the preserved scripts into a private
  # environment so execution cannot overwrite objects in the caller's session.
  env <- new.env(parent = globalenv())
  loaded <- load(workspace, envir = env)
  required <- c("dataNet", "dataGeo", "foldsNet", "foldsGeo", "validFolds")
  missing <- setdiff(required, loaded)
  if (length(missing) > 0L) stop(sprintf("Workspace is missing required object(s): %s", paste(missing, collapse = ", ")), call. = FALSE)

  # Unpack to a temporary directory instead of copying/editing historical source
  # into the maintained tree.
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

  # Save analysis products but omit the large input/fold objects already stored
  # in the workspace. Also omit the temporary set.seed mask from deterministic
  # runs because it is an execution aid rather than a scientific result.
  dir.create(dirname(output), recursive = TRUE, showWarnings = FALSE)
  exclude <- c(required, "set.seed")
  objects <- setdiff(ls(env, all.names = TRUE), exclude)
  save(list = objects, envir = env, file = output)
  message(sprintf("Saved %s analysis workspace to %s", if (legacy) "legacy" else "deterministic", output))
  invisible(output)
}

# Shared CLI front end used by the four tiny top-level ANN/SVM entry points.
run_ann_svm_cli <- function(model, log_transform = FALSE) {
  args <- commandArgs(trailingOnly = TRUE)

  # Return the token following one option, or a default when the option is absent.
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
