# Published exact results

This directory contains the complete exact-enumeration outputs used by the reports. These are deterministic probability tables, not Monte Carlo estimates.

| File | Deck states | Purpose |
| --- | ---: | --- |
| `round1.csv` | 1 | Full-deck outcome distribution |
| `round2.csv` | 5,475 | Conditional distributions with 24 cards remaining |
| `round3.csv` | 38,165 | Conditional distributions with 16 cards remaining |
| `round4.csv` | 5,475 | Conditional distributions with 8 cards remaining |
| `strategy_lookup.csv` | 49,116 | Compact lookup of deck state, single-farmer expected return, and equal-stake Kelly fraction |

## Reading the tables

`deck` is an eight-character key. Its digits are the remaining counts of ranks 1 through 8. For example, `00444444` means that ranks 1 and 2 are absent and ranks 3 through 8 each have four cards remaining.

The main derived columns are:

- `ev_farmer_X`: expected net return per unit staked on one farmer position;
- `std_X` and `std_XYZ`: standard deviations for one farmer and for the average return across three equal farmer bets;
- `kelly_f`: optimal fraction of current wealth staked on each farmer position;
- `kelly_log_growth`: expected log growth at `kelly_f`, in percent;
- `kelly_growth`: equivalent geometric growth, in percent;
- `winrate_X`, `nonpair_win_X`, and `pair_win_X`: single-farmer outcome probabilities;
- `twoFarmers` and `threeFarmers`: probabilities that at least two, or all three, farmer positions win;
- `joint_*`: the complete 27-outcome joint distribution of the three farmer returns, whose possible values are `-1`, `1`, and `2`;
- `prob_from_first` or `prob_from_prior`: probability of observing the deck state;
- `*_Weight` and `totalDeals`: exact integer enumeration weights and denominator.

## Validation

The published files were regenerated with the current post-processing code and validated row by row.

| Deal | Maximum joint-probability sum error | Maximum two/three-farmer summary error | Weighted mean return | Negative-EV states | Weighted expected log growth |
| ---: | ---: | ---: | ---: | ---: | ---: |
| 1 | 0 | 8.60e-16 | 0.0088987764 | 0 | 0.0061167% |
| 2 | 1.78e-15 | 1.50e-15 | 0.0088987764 | 1 | 0.0078843% |
| 3 | 2.11e-15 | 5.00e-16 | 0.0088987764 | 559 | 0.0211917% |
| 4 | 1.67e-15 | 1.22e-15 | 0.0088987764 | 653 | 0.1284610% |

All deck keys are eight characters long and unique. The compact lookup contains 49,116 unique keys.

Before publication, the round-three `twoFarmers` and `threeFarmers` columns were reconstructed exactly from the retained 27-outcome joint probabilities so that the table matches the corrected `round3.m`. No probability was estimated or resimulated in this repair. Volatility and Kelly columns were then regenerated with `compute_stds.m` and `kelly_ratio.m`.

Use [`SHA256SUMS.txt`](SHA256SUMS.txt) to verify downloaded files.

Monte Carlo bankroll outputs are not included here because the older saved runs predate fixes to zero-bet deck advancement and bankruptcy handling. They should be regenerated with explicit simulation count, cycle count, and random seed before publication.
