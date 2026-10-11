#!/usr/bin/env Rscript

# Deterministic workspace generator for ANN/SVM reruns. It recreates the object
# names expected by the recovered scripts while using explicit seeds instead of
# the historical time-dependent partitioning behavior.

source(file.path("R", "cpt_core.R"))
args <- commandArgs(trailingOnly = TRUE)

# Return the token following one named command-line option.
value_after <- function(flag, default) {
  position <- match(flag, args)
  if (is.na(position)) return(default)
  if (position == length(args)) stop(sprintf("%s requires a value.", flag), call. = FALSE)
  args[[position + 1L]]
}

if ("--help" %in% args) {
  cat("Usage: Rscript generate_data.R [--complete complete.csv] [--geology geology.csv] [--output data.RData] [--seed 2019]\n")
  quit(status = 0L)
}

.require_namespace("caret")
complete_path <- value_after("--complete", "complete.csv")
geology_path <- value_after("--geology", "geology.csv")
output_path <- value_after("--output", "data.RData")
seed <- suppressWarnings(as.integer(value_after("--seed", "2019")))
if (is.na(seed)) stop("--seed must be an integer.", call. = FALSE)

# The complete and geological subsets use the historical output variables for
# stratification. Separate seeds keep the two fold partitions reproducible.
data <- load_cpt_csvs(complete_path, geology_path)
dataNet <- data$complete
dataGeo <- data$geology
set.seed(seed)
foldsNet <- caret::createFolds(dataNet$SBTn, k = 10L, list = TRUE, returnTrain = FALSE)
set.seed(seed + 1L)
foldsGeo <- caret::createFolds(dataGeo$MSBTn, k = 10L, list = TRUE, returnTrain = FALSE)
validFolds <- make_validation_fold_map(10L, seed + 2L)

# A newly generated workspace is reproducible for the chosen seed, but it is not
# claimed to reproduce the exact historical random fold realization.
save(dataNet, dataGeo, foldsNet, foldsGeo, validFolds, file = output_path)
message(sprintf("Saved reproducible workspace to %s", output_path))
