# Running ANN/SVM analyses

Use one of the maintained entry points:

```bash
Rscript ann_full.R
Rscript ann_full_log.R
Rscript svm_full.R
Rscript svm_full_log.R
```

Add `--legacy` to preserve the historical time-dependent reseeding behavior, or `--seed INTEGER` for a deterministic rerun.
