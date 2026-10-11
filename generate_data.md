# Workspace generation

Use the maintained generator:

```bash
Rscript generate_data.R --complete complete.csv --geology geology.csv --output data.RData --seed 2019
```

The tracked `data.RData` preserves the recovered historical fold assignment. Regenerating it creates a new deterministic workspace and is not expected to reproduce the historical folds exactly.
