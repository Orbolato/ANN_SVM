# Recovered 2018 ANN/SVM development source

`ANN_SVM_recovered_source.tar.xz` is a source-only preservation archive created from the author's recovered `SVM.zip` in October 2026. Despite the archive name, the recovered ZIP contains both the ANN and SVM development trees.

Archive SHA-256:

```text
8f7b77397c9cb4f15a9b6681a8ebfefc888a82904e58bd95ac6356e17918dedb  ANN_SVM_recovered_source.tar.xz
```

The archive contains 30 source files (`.R` and one `.m`) and an internal SHA-256 manifest. It excludes `.Rhistory`, PDFs, figures, and duplicate data/workspace files. The recovered ZIP also contains `complete.csv`, `geology.csv`, and `data.RData`. Those are byte-identical to the public historical artifacts already retained in the sibling Trees/KNN repositories, so they are restored on demand with `restore_historical_data.R` rather than duplicated in Git.

Key recovered submission scripts:

| File | SHA-256 |
| --- | --- |
| `ANN/For submission/ANN_full.R` | `56cf6e557f3fcf8272b317f691a187ed5ba556e9b722be98045d9cbaa5699bdb` |
| `ANN/For submission/ANN_full_log.R` | `b6e38e6daedcf8a5bb4d2d4a49900c146f3f76a9aca5835d5558bbb35f1132db` |
| `SVM/For submission/SVM_full.R` | `cb816548a70891f6f1cb141802d8cf43032cbafcaffbb959eb6c2e048d92b350` |
| `SVM/For submission/SVM_full_log.R` | `96a15c142e09954f77bafcd4920e403875a15215f3d14b01d1989abf8b17a41b` |
| `SVM/For submission/SVM_test.R` | `cf59c22bc0dbe45c1011b8b92df0018ea0e4fa6ab35845afc0e0f9cde9b294c3` |
| `SVM/For submission/SVM_test_log.R` | `0630d469356d910290245def14e0105c75ef450fa22949c12820aafdab77bc90` |

The recovered scripts use time-derived random seeds during class balancing, so exact numerical reruns are not deterministic. `ANN_full_log.R` also contains two different logarithmic transforms: its main/geological blocks use a natural-log expression, while its reduced-input blocks use the base-10 transform used by the recovered SVM, DT, RF, and later MMP code. These historical details are preserved unchanged in this archive.
