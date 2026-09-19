# Tuibaozi probability and betting analysis

This repository studies a four-hand card game played with four copies of ranks 1 through 8. It provides exact state enumeration for four consecutive deals, conditional return distributions, equal-stake Kelly sizing, and Monte Carlo bankroll simulations.

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

Generated CSV and image files are intentionally excluded from version control. They can be regenerated from the MATLAB sources.

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

## Validation expectations

For every generated result file:

- deck-state probabilities should sum to 1 within floating-point tolerance;
- the 27 joint outcome probabilities should sum to 1 for every deck state;
- deck-state keys should be unique after padding to eight digits;
- the four result files should contain 1, 5,475, 38,165, and 5,475 states respectively.

## Reproducibility notes

`simulate_player` records its simulation count, number of four-deal cycles, random seed, starting bankroll, bankruptcy threshold, maximum bet, and elapsed time in `final_wealth_stats.csv`. Passing the same seed reproduces the same random sequence on a compatible MATLAB release.

The unfinished Word manuscript and older generated result copies are excluded because they contain stale calculations and template identity information.

## License

The MATLAB source code is released under the MIT License. See [LICENSE](LICENSE).

## Citation

Citation metadata is provided in [CITATION.cff](CITATION.cff).
