#!/usr/bin/env Rscript
# Restore the exact public historical CPT data artifacts from the Trees repository.
# The commit is pinned so future changes to that repository cannot silently alter
# the files used here.

base <- "https://raw.githubusercontent.com/Orbolato/Trees/dc29ad93fd9423a2c6322797e595a9a8082ec2cf"
files <- c("complete.csv", "geology.csv", "data.RData")
for (file in files) {
  url <- paste(base, file, sep = "/")
  message(sprintf("Downloading %s", file))
  utils::download.file(url, destfile = file, mode = "wb", quiet = FALSE)
}
message("Historical ANN/SVM data artifacts restored.")
