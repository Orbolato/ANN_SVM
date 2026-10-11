# Shared CPT data and evaluation helpers for the recovered 2018 ANN/SVM study.

.require_namespace <- function(package) {
  if (!requireNamespace(package, quietly = TRUE)) {
    stop(sprintf("Package '%s' is required for this operation.", package), call. = FALSE)
  }
}

validate_columns <- function(data, columns, data_name = "data") {
  missing <- setdiff(columns, names(data))
  if (length(missing) > 0L) {
    stop(sprintf("%s is missing required column(s): %s", data_name, paste(missing, collapse = ", ")), call. = FALSE)
  }
  invisible(TRUE)
}

load_archived_workspace <- function(path = "data.RData") {
  if (!file.exists(path)) stop(sprintf("Workspace not found: %s", path), call. = FALSE)
  env <- new.env(parent = baseenv())
  loaded <- load(path, envir = env)
  required <- c("dataNet", "dataGeo", "foldsNet", "foldsGeo", "validFolds")
  missing <- setdiff(required, loaded)
  if (length(missing) > 0L) {
    stop(sprintf("Workspace is missing required object(s): %s", paste(missing, collapse = ", ")), call. = FALSE)
  }
  list(
    complete = env$dataNet,
    geology = env$dataGeo,
    folds_complete = env$foldsNet,
    folds_geology = env$foldsGeo,
    validation_folds = as.integer(env$validFolds)
  )
}

load_cpt_csvs <- function(complete_path = "complete.csv", geology_path = "geology.csv") {
  if (!file.exists(complete_path)) stop(sprintf("Complete CSV not found: %s", complete_path), call. = FALSE)
  if (!file.exists(geology_path)) stop(sprintf("Geology CSV not found: %s", geology_path), call. = FALSE)
  list(
    complete = utils::read.csv(complete_path, check.names = FALSE),
    geology = utils::read.csv(geology_path, check.names = FALSE)
  )
}

make_validation_fold_map <- function(k = 10L, seed = 2019L) {
  if (k < 2L) stop("k must be at least 2.", call. = FALSE)
  set.seed(seed)
  test_folds <- seq_len(k)
  repeat {
    validation <- sample(test_folds, k, replace = FALSE)
    if (all(validation != test_folds)) return(validation)
  }
}

paper_experiments <- function() {
  list(
    list(id = "raw_isg", data = "complete", output = "SBTn", features = c("Depth_m", "qt_MPa", "fs_kPa", "u_kPa")),
    list(id = "raw_fsb", data = "complete", output = "MSBTn", features = c("Depth_m", "qt_MPa", "fs_kPa", "u_kPa")),
    list(id = "qt1_isg", data = "complete", output = "SBTn", features = c("Depth_m", "Qt1", "Fr_p", "Bq")),
    list(id = "qt1_fsb", data = "complete", output = "MSBTn", features = c("Depth_m", "Qt1", "Fr_p", "Bq")),
    list(id = "qtn_isg", data = "complete", output = "SBTn", features = c("Depth_m", "Qtn", "Fr_p", "U2")),
    list(id = "qtn_fsb", data = "complete", output = "MSBTn", features = c("Depth_m", "Qtn", "Fr_p", "U2")),
    list(id = "geology_raw_fsb", data = "geology", output = "MSBTn", features = c("CG", "Depth_m", "qt_MPa", "fs_kPa", "u_kPa")),
    list(id = "geology_qtn_fsb", data = "geology", output = "MSBTn", features = c("CG", "Depth_m", "Qtn", "Fr_p", "U2")),
    list(id = "reduced_isg", data = "complete", output = "SBTn", features = c("Qtn", "Fr_p")),
    list(id = "reduced_fsb", data = "complete", output = "MSBTn", features = c("Qtn", "Fr_p", "U2"))
  )
}

signed_log_transform <- function(x) sign(x) * log10(1 + 99 * abs(x)) / 2

macro_recall <- function(predicted, observed) {
  predicted <- as.character(predicted)
  observed <- as.character(observed)
  classes <- sort(unique(observed[!is.na(observed)]))
  all_classes <- sort(unique(c(predicted, observed)))
  all_classes <- all_classes[!is.na(all_classes)]
  confusion <- table(factor(predicted, levels = all_classes), factor(observed, levels = all_classes))
  recalls <- vapply(classes, function(class_value) {
    denominator <- sum(confusion[, class_value])
    if (denominator == 0L) return(NA_real_)
    confusion[class_value, class_value] / denominator
  }, numeric(1))
  mean(recalls, na.rm = TRUE)
}
