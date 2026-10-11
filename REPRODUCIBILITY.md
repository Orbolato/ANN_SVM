# Reproducibility scope

The cleaned ANN/SVM runners reproduce the cross-validation, preprocessing, hyperparameter-selection, and held-out evaluation workflow with explicit deterministic seeding.

The recovered 2018 ANN/SVM scripts additionally aggregate fold hyperparameters and construct a final model using all available data after cross-validation. Clean mode intentionally does not reinterpret or modernize that all-data final-model step because its aggregation and stochastic preprocessing are implementation-specific.

Use `--legacy` with `ann_full.R`, `ann_full_log.R`, `svm_full.R`, or `svm_full_log.R` when the exact recovered final-model procedure is required. Legacy mode intentionally preserves the historical time-derived random seeding and other implementation quirks.

The recovered `ANN_full_log.R` also uses two different logarithmic transforms: natural log in its main/geological blocks and the signed base-10 transform in its reduced-input blocks. Clean log mode consistently uses the signed base-10 transform used by the recovered SVM, DT, RF, and later MMP implementations. Therefore cleaned log-mode results are reproducible paper-oriented reruns, not a claim of bit-for-bit reproduction of every archived ANN result.
