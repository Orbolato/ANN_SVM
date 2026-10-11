# Workspace generation

If you have local copies of `complete.csv` and `geology.csv`, use the maintained generator:

```bash
Rscript generate_data.R --complete complete.csv --geology geology.csv --output data.RData --seed 2019
```

The exact historical `data.RData` is not duplicated here because it is byte-for-byte identical to the copy preserved in the companion `Orbolato/Trees` repository. Regenerating a workspace creates a new deterministic fold assignment and is not expected to reproduce the archived historical folds exactly.
