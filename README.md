# ANN and SVM Models for CPT Soil Classification

Public R implementation and recovered historical source for the artificial-neural-network (ANN) and support-vector-machine (SVM) experiments associated with:

**Lucas O. Carvalho, Dimas B. Ribeiro, and Francisco A. C. Monteiro, “Comparing Artificial Neural Networks with Support Vector Machines for Soil Classification,” CILAMCE 2019, Natal/RN, Brazil, November 11–14, 2019.**

The original repository was created in 2018 for the pre-publication implementation and contained only instructions after the source files disappeared. In October 2026, the author recovered the original ANN/SVM development archive. This repository now preserves that source and provides a cleaned, deterministic implementation for new reruns.

## Scope

The recovered code compares multilayer-perceptron ANN models and SVM classifiers for CPT-based soil classification. The common experiment design contains **10 configurations**:

- three four-variable feature families on the complete dataset, each tested for `SBTn` and `MSBTn` (6 configurations);
- two five-variable configurations including geological age `CG`, both predicting `MSBTn` (2 configurations);
- `Qtn + Fr_p` for `SBTn` and `Qtn + Fr_p + U2` for `MSBTn` (2 configurations).

The SVM submission implementation uses a polynomial kernel for the full comparison after preliminary Gaussian, Laplacian, and polynomial kernel tests. The ANN implementation uses multilayer perceptrons from `RSNNS`.

## Historical preprocessing recovered from the source

The 2018 submission scripts perform the following sequence within each test fold:

1. use one fold for testing and a separate fold for validation;
2. remove `SBTn` class 0 (and optionally `MSBTn` class 0);
3. min-max scale inputs using training-set extrema;
4. optionally apply logarithmic input scaling;
5. identify class-wise IQR outlier candidates (excluding depth) and apply a 1-NN edited-neighbor check;
6. balance classes by undersampling majority classes and synthesizing minority rows from the feature-wise mean of `d + 1` randomly selected same-class observations;
7. rescale the resulting training/validation/test variants;
8. tune model hyperparameters on the validation fold and report mean class recall on the test fold.

The recovered ANN/SVM scripts ultimately use the **balanced** training variant; their balanced-versus-unbalanced comparison blocks are commented out.

## Cleanup decisions

The cleaned default keeps the study design but makes the run deterministic and auditable:

- randomness is controlled by a single explicit `--seed` instead of repeated system-time seeds;
- the archived `data.RData` is used by default, preserving the historical folds;
- preprocessing and scoring are shared through `R/cpt_core.R` rather than duplicated thousands of lines across scripts;
- ANN and polynomial-SVM tuning are isolated in `R/models.R` and bounded by explicit command-line limits;
- outputs are written as compact CSV/RDS files under `results/` instead of relying on an interactive R session;
- the historical source remains available byte-for-byte through `--legacy` and `legacy/2018/ANN_SVM_recovered_source.tar.xz`.

### Log-transform discrepancy

The recovered `ANN_full_log.R` is internally inconsistent. Its main and geological experiment blocks use a natural-log transform,
while its reduced-input blocks use the signed base-10 transform also used consistently by the recovered SVM, DT, RF, and later MMP scripts.

The cleaned log entry points use one consistent transform:

```text
sign(x) * log10(1 + 99 * abs(x)) / 2
```

The exact mixed ANN behavior is preserved only in legacy mode. Consequently, cleaned log reruns should be treated as **paper-oriented reproducible reruns**, not assumed to reproduce every archived 2018 number exactly.

## Repository structure

```text
.
├── R/
│   ├── cpt_core.R              # data loading, folds, scaling, cleaning, balancing, metrics
│   ├── models.R                # ANN and SVM fitting/tuning
│   ├── cli.R                   # command-line options
│   └── runner.R                # common experiment runner + legacy execution
├── ann_full.R
├── ann_full_log.R
├── svm_full.R
├── svm_full_log.R
├── svm_kernel_test.R
├── generate_data.R
├── restore_historical_data.R   # restores the pinned public historical data/workspace
├── legacy/2018/                # exact recovered source archive + provenance
├── tests/test_core.R
└── .github/workflows/tests.yml
```

## Requirements

For ANN analyses:

```r
install.packages(c("kknn", "RSNNS"))
```

For SVM analyses:

```r
install.packages(c("kknn", "kernlab"))
```

The exact historical SVM scripts also load `e1071`. Workspace regeneration requires `caret`.

## Restore the historical data/workspace

The recovered ANN/SVM ZIP contains the same `complete.csv`, `geology.csv`, and `data.RData` files already published in the sibling Trees/KNN repositories. To avoid storing a second binary/data copy here, restore the exact pinned artifacts once:

```bash
Rscript restore_historical_data.R
```

The helper is pinned to the pre-refactor Trees commit containing byte-identical recovered artifacts. The restored files are ignored by Git.

## Run the cleaned analyses

```bash
Rscript ann_full.R
Rscript ann_full_log.R
Rscript svm_full.R
Rscript svm_full_log.R
```

A full 10-configuration × 10-fold run, especially ANN tuning, is computationally intensive. For a short check:

```bash
Rscript ann_full.R --max-configurations 1 --max-folds 1 --minimum-per-class 50 --max-iterations 400
Rscript svm_full.R --max-configurations 1 --max-folds 1 --minimum-per-class 50 --max-svm-degree 2 --max-svm-scale 2 --max-svm-offset 2
```

Useful common options include `--seed`, `--minimum-per-class`, `--max-configurations`, `--max-folds`, `--remove-fsb-zero`, `--output-dir`, and `--quiet`. Run any entry point with `--help` for details.

## Preliminary SVM kernel comparison

The recovered source contains `SVM_test.R` and `SVM_test_log.R`, which compare candidate kernels before the polynomial-kernel full runs. A cleaned equivalent is available as:

```bash
Rscript svm_kernel_test.R
```

## Exact recovered source

To execute the historical submission script directly:

```bash
Rscript ann_full.R --legacy
Rscript ann_full_log.R --legacy
Rscript svm_full.R --legacy
Rscript svm_full_log.R --legacy
```

Legacy mode intentionally preserves time-dependent random seeding and all historical implementation quirks. It is provided for audit/recovery, not recommended as the default for new analyses.

## Data provenance

`complete.csv`, `geology.csv`, and `data.RData` in the recovered ANN/SVM submission folders are byte-identical to the historical artifacts distributed with the related KNN and Trees repositories. `restore_historical_data.R` retrieves the exact pinned public copies on demand, avoiding redundant large binary/data files in this repository.

The old README referred to `results_ann_full.RData`, `results_ann_full_log.RData`, `results_svm_full.RData`, and `results_svm_full_log.RData`; those saved result workspaces were **not present in the recovered archive**, so they have not been invented or reconstructed.

## Tests

```bash
Rscript tests/test_core.R
```

The test suite checks the 10-configuration experiment grid, transforms, macro recall, balancing, archived workspace structure, parsing of the cleaned entry points, and parsing of the key recovered submission scripts. GitHub Actions runs the same checks automatically.

## Citation

If this code supports your work, please cite the CILAMCE 2019 paper listed at the top of this README. GitHub also exposes citation metadata from `CITATION.cff`.

## License

No separate software license has been assigned to this repository. The presence of source code on GitHub should not be interpreted as granting rights beyond those provided by applicable law or an explicit license.
