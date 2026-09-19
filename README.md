# Tuibaozi: positive-edge betting under a landlord-favored tie rule

[中文研究报告](docs/report.zh-CN.md) | [English report](docs/report.en.md)

The central result is counterintuitive: ties go to the landlord and a single farmer wins only about 45.85% of deals, so the rules appear to favor the landlord. However, a winning pair pays two units of net profit, which more than offsets the lower win rate. The exact full-deck expected return of a one-unit bet on one farmer is therefore `+0.0088988`, or about `+0.8899%`.

This repository shows how a bettor can turn that payout edge into positive expected growth under the stated model: observe the remaining deck, skip negative-expectation states, and size equal bets across the three farmer positions from their joint return distribution. It provides exact state enumeration for four consecutive deals, conditional return distributions, equal-stake Kelly sizing, and Monte Carlo bankroll simulations.

The project name is a transliteration of 推豹子. The code is intended for probability and optimization research, not as gambling advice or a promise of profit.

## Game model

- The deck has 32 cards: four cards of each rank from 1 to 8.
- A landlord and three farmer positions each receive two cards per deal.
- A pair scores `10 + rank`; a non-pair scores `(rank1 + rank2) mod 10`.
- Ties go to the landlord.
- A winning non-pair returns one unit of net profit; a winning pair returns two units. A loss costs one unit.
- Four deals are made before the deck is reset.

The model assumes that the remaining count of every rank is known before each bet.

## Files

| File | Purpose |
| --- | --- |
| `round1.m` to `round4.m` | Enumerate deck states and exact outcome probabilities |
| `compute_stds.m` | Add volatility and Sharpe-ratio columns |
| `kelly_ratio.m` | Compute equal-stake Kelly fractions and log-growth metrics |
| `merge_kelly_results.m` | Build the lookup table used by simulation |
| `simulate_player.m` | Simulate bankroll paths with integer and table-limit constraints |
| [`results/`](results/) | Complete validated exact-enumeration tables and a compact strategy lookup |

The full exact results are published as CSV files because they allow every reported deck state and conditional distribution to be inspected without rerunning the expensive enumeration. Older duplicate tables, unfinished Monte Carlo outputs, and generated images remain excluded.

## Requirements

- MATLAB R2024a or a compatible recent release
- No optional MATLAB toolbox is required by the current implementation

## Reproduce the analysis

Run the following commands from the repository directory:

```matlab
round1
round2
round3
round4

files = {'round1_results.csv', 'round2_results.csv', ...
         'round3_results.csv', 'round4_results.csv'};
for i = 1:numel(files)
    compute_stds(files{i});
    kelly_ratio(files{i});
end

merge_kelly_results
simulate_player(1000000, 25, 1)
```

The exact enumeration can take a long time, especially for the third round.

Validated snapshots of the complete outputs, their column definitions, checksums, and numerical validation summary are available in [`results/`](results/).

## Validation expectations

For every generated result file:

- deck-state probabilities should sum to 1 within floating-point tolerance;
- the 27 joint outcome probabilities should sum to 1 for every deck state;
- deck-state keys should be unique after padding to eight digits;
- the four result files should contain 1, 5,475, 38,165, and 5,475 states respectively.

## Reproducibility notes

`simulate_player` records its simulation count, number of four-deal cycles, random seed, starting bankroll, bankruptcy threshold, maximum bet, and elapsed time in `final_wealth_stats.csv`. Passing the same seed reproduces the same random sequence on a compatible MATLAB release.

The unfinished Word manuscript and older generated result copies are excluded because they contain stale calculations and template identity information. Historical Monte Carlo outputs are also excluded because they predate fixes to zero-bet deck advancement and bankruptcy handling.

## Related interactive tool

[Tuibaozi Calculator](https://github.com/MegaKeqing/tuibaozi-calculator) ([live demo](https://megakeqing.github.io/tuibaozi-calculator/)) is an earlier browser-based companion that estimates one-deal win probabilities and expected returns by Monte Carlo simulation for a user-entered remaining deck. Its dealing and payout rules match this project, but its sampled estimates are not the source of the exact values reported here. This repository provides the exact enumeration, full joint distributions, and Kelly analysis; the calculator is useful for interactive exploration and approximate checks.

## License

The MATLAB source code is released under the MIT License. See [LICENSE](LICENSE).

## Citation

Citation metadata is provided in [CITATION.cff](CITATION.cff).
