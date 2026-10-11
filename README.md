# Artificial Neural Networks and Support Vector Machines for CPT Soil Classification

This repository recovers and documents the 2018 R source developed for ANN/SVM soil classification from cone penetration test (CPT) data.

The original repository described a manuscript titled **“A new approach for soil classification from cone penetration test data comparing artificial neural networks with support vector machines.”** The work subsequently appeared as the 2019 CILAMCE conference paper **“Comparing artificial neural networks with support vector machines for soil classification”** by Lucas O. Carvalho, Dimas B. Ribeiro, and Francisco A. C. Monteiro. The ANN and SVM techniques were later incorporated into the broader five-model comparison and MMP ensemble published in *Soils and Rocks* in 2021.

## Recovery status

The public repository originally contained only three instruction files and named source files that were missing. In October 2026, the author's archived `SVM.zip` was recovered. It contains both the ANN and SVM development trees, including the submission versions:

- `ANN_full.R` and `ANN_full_log.R`;
- `SVM_full.R` and `SVM_full_log.R`;
- SVM test variants and earlier biased/geology/confusion-development scripts;
- the common `complete.csv`, `geology.csv`, and `data.RData` snapshot.

A matching historical `generate_data.R` was recovered from the companion DT/RF archive (`RF.zip`). The complete source snapshot is preserved byte-for-byte in `legacy/2018/ANN_SVM_recovered_source.tar.xz`; data files are stored separately at repository root so they remain directly usable.

## Historical source vs cleaned entry points

The historical full scripts are large monolithic programs (roughly 4,000–4,800 lines each) and repeatedly reseed from system time. Rewriting that tuning/preprocessing code would create a high risk of changing the scientific method. The refactor therefore takes a conservative approach:

- exact historical scripts remain unchanged in the legacy archive;
- top-level `ann_full*.R` and `svm_full*.R` are small command-line entry points;
- default execution uses one explicit random stream seed and suppresses the historical time-based reseeding calls;
- `--legacy` executes the recovered script with its original time-dependent reseeding;
- the recovered script itself still performs the historical model selection, preprocessing, balancing, fitting, and evaluation logic.

Deterministic reruns are therefore **method-preserving reruns**, not claims of bit-for-bit identity with historical result workspaces.

## Data snapshot

`complete.csv`, `geology.csv`, and `data.RData` are the exact 2018 submission copies found in both the ANN/SVM and DT/RF archives. Their SHA-256 hashes are:

```text
1c0e81dadf23ae9db4c815acb30a520eeb557ebc37cd14b98dd031990695a7ef  complete.csv
78f9e9a355fe8b3d9bf62ececab5694e261f6a75b87b6acca0566ad83593f9c5  geology.csv
7ec316cd397fd722911487eecf1422e111ce666f8d96be33bfc7b0948f142ec1  data.RData
```

The same files are used by the companion `Trees` repository, confirming a shared historical experiment snapshot across ANN, SVM, DT, and RF.

## Models

The recovered ANN code uses `RSNNS::mlp` and searches one- and two-hidden-layer architectures together with iteration counts. The recovered SVM code uses `kernlab::ksvm`; the submission source selects the polynomial kernel (`polydot`), while Gaussian (`rbfdot`) and Laplacian (`laplacedot`) alternatives remain visible in the historical source. Both families use the common CPT preprocessing/fold framework and k-NN-based editing steps.

## Requirements

```r
install.packages(c("kknn", "RSNNS", "e1071", "kernlab", "caret"))
```

The source was developed for an older R environment (the original README cites R 3.5.0 and RStudio 1.1.456), so modern package versions may produce numerical differences.

## Run

```bash
Rscript ann_full.R
Rscript ann_full_log.R
Rscript svm_full.R
Rscript svm_full_log.R
```

Useful options:

```text
--workspace PATH   input workspace (default: data.RData)
--output PATH      output RData path
--seed INTEGER     deterministic random-stream seed (default: 2019)
--legacy           preserve historical time-dependent reseeding
```

For example:

```bash
Rscript svm_full_log.R --seed 2026
Rscript ann_full.R --legacy
```

The wrappers save resulting analysis objects under `results/` unless `--output` is supplied.

## Regenerate a workspace

The archived `data.RData` preserves the historical folds. To generate a new reproducible workspace from the CSV files:

```bash
Rscript generate_data.R --complete complete.csv --geology geology.csv --output data.RData --seed 2019
```

A newly generated workspace is reproducible but should not be assumed to contain the same historical random fold assignment.

## Provenance

The recovered source archive SHA-256 is:

```text
057e7e51f3ab126b56f99d997d45a70b4fa055b9ebe9424ce3cd3d69dd8866c4  ANN_SVM_recovered_source.tar.xz
```

See `legacy/2018/README.md` for submission-file hashes and recovery notes.

## Tests

```bash
Rscript tests/test_core.R
```

The tests validate source parsing, experiment definitions, transforms, macro recall, fold mapping, historical workspace structure, and archive-to-wrapper mappings. GitHub Actions runs the same checks.

## Citation

For the ANN/SVM comparison, cite the 2019 CILAMCE paper:

```text
Carvalho, L. O., Ribeiro, D. B., & Monteiro, F. A. C. (2019).
Comparing artificial neural networks with support vector machines for soil classification.
Proceedings of the XL Ibero-Latin-American Congress on Computational Methods in Engineering.
```

For the later integrated framework, cite:

```text
Carvalho, L. O., & Ribeiro, D. B. (2021).
A multiple model machine learning approach for soil classification from cone penetration test data.
Soils and Rocks, 44(4), e2021072121.
https://doi.org/10.28927/SR.2021.072121
```

## License

No separate software license has been assigned to this repository.
