# Running the ANN/SVM analyses

Main commands:

```bash
Rscript ann_full.R
Rscript ann_full_log.R
Rscript svm_full.R
Rscript svm_full_log.R
Rscript svm_kernel_test.R
```

For a short smoke run, restrict both configurations and folds, for example:

```bash
Rscript svm_full_log.R --max-configurations 1 --max-folds 1 --minimum-per-class 50
```

Use `--legacy` with one of the four main entry points to execute the exact recovered 2018 submission script instead of the cleaned implementation.
