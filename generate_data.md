# Workspace generation

The historical workspace-generation instructions have been replaced by a portable command-line script:

```bash
Rscript generate_data.R --complete complete.csv --geology geology.csv --output data.RData --seed 2019
```

For the exact historical fold assignment, first run `Rscript restore_historical_data.R` to restore the archived data/workspace from the pinned Trees commit. Regeneration creates a new deterministic partition and therefore represents a new run.
