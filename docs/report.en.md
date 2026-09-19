# Tuibaozi: positive-edge betting under a landlord-favored tie rule

[中文版](report.zh-CN.md)

## Main result

Ties go to the landlord, and a single farmer position wins only about 45.85% of deals, so the rules appear to favor the landlord. A winning farmer pair, however, earns two units of net profit. That payout is sufficient to offset the lower win rate: the exact full-deck expected return of a one-unit bet on one farmer is `+0.0088988`, or approximately `+0.8899%`.

A bettor who also observes the remaining deck, skips negative-expectation states, and sizes equal bets across the three farmer positions from their joint return distribution can achieve positive expected long-run log growth within this model. The edge comes from payout asymmetry, deck information, and strategy selection—not from a farmer win rate above 50%—and it is not a guarantee of real-world profit.

## Abstract

This report studies a four-hand card game whose settlement rules appear to favor the landlord but still allow a rational bettor to obtain positive expected returns. The 32-card deck contains four copies of ranks 1 through 8, and a landlord and three farmer positions each receive two cards. Ties go to the landlord, while a farmer pair wins two units of net profit. Exact enumeration is used to obtain the outcome distribution for every observable deck state over four consecutive deals. The resulting distributions are used to compare single-farmer, two-gate, and all-three-farmer bets and to calculate an equal-stake Kelly strategy.

The unconditional expected net return of a one-unit bet on one farmer is 0.0088988. This average is the same in every deal, but conditional returns spread out as the deck becomes smaller. Deals two, three, and four contain 1, 559, and 653 negative-expectation farmer states respectively. A positive unconditional average therefore does not imply that every observable state should be bet. A state-aware strategy skips negative-expectation states and sizes positive bets from the full joint return distribution.

## 1 Game model

### 1.1 Deck and dealing

- The deck contains four cards of every rank from 1 through 8, for 32 cards in total.
- Two cards are dealt to landlord `M` and to farmer positions `X`, `Y`, and `Z`, consuming eight cards per deal.
- The deck is reset after four consecutive deals.
- The model assumes that the remaining count of every rank is observable before betting, while the next hands remain unknown.

### 1.2 Scoring and settlement

A non-pair scores

$$
(r_1+r_2)\bmod 10.
$$

A pair scores

$$
10+r_1.
$$

Each farmer is compared separately with the landlord, and ties go to the landlord. For a one-unit stake, a winning non-pair has net return `+1`, a winning pair has net return `+2`, and a loss has return `-1`.

The two-gate bet returns `+1` when at least two farmers win and `-1` otherwise. The all-three bet returns `+3` when every farmer wins and `-1` otherwise.

## 2 Exact enumeration

One two-card hand has 36 unordered rank combinations: 8 pairs and 28 non-pairs. Four positions therefore generate $36^4$ candidate rank configurations before configurations using more than four copies of any rank are removed.

Rank configurations are not equally likely. Suppose the remaining deck contains $h_r$ cards of rank $r$, and the four hands use $a_{r,M}$, $a_{r,X}$, $a_{r,Y}$, and $a_{r,Z}$ copies of that rank. The physical-deal weight of the rank configuration is

$$
w=\prod_{r=1}^{8}
\frac{h_r!}
{(h_r-a_{r,M}-a_{r,X}-a_{r,Y}-a_{r,Z})!
a_{r,M}!a_{r,X}!a_{r,Y}!a_{r,Z}!}.
$$

For each remaining deck, the implementation accumulates the 27 joint outcomes in which each farmer return is `-1`, `+1`, or `+2`.

The numbers of reachable deck states are:

| Deal | Cards before dealing | Reachable states |
| ---: | ---: | ---: |
| 1 | 32 | 1 |
| 2 | 24 | 5,475 |
| 3 | 16 | 38,165 |
| 4 | 8 | 5,475 |

## 3 Probabilities and expected returns

### 3.1 First deal

The first-deal deck is fixed at `44444444`. The exact single-farmer distribution is:

| Outcome | Probability |
| --- | ---: |
| Non-pair win | 0.3666296 |
| Pair win | 0.0918799 |
| Loss | 0.5414905 |

The expected net return of a one-unit stake is therefore

$$
0.3666296+2\times0.0918799-0.5414905
=0.0088988.
$$

The first-deal alternatives are:

| Bet | Win probability | Expected return per unit |
| --- | ---: | ---: |
| One farmer | 0.4585095 | 0.0088988 |
| Two-gate | 0.4572141 | -0.0855719 |
| All-three | 0.2086946 | -0.1652218 |

### 3.2 Conditional variation in later deals

Exact conditional farmer returns across observable deck states are:

| Deal | States | Weighted mean | Minimum | Maximum | Negative states |
| ---: | ---: | ---: | ---: | ---: | ---: |
| 1 | 1 | 0.0088988 | 0.0088988 | 0.0088988 | 0 |
| 2 | 5,475 | 0.0088988 | -0.0014116 | 0.0468034 | 1 |
| 3 | 38,165 | 0.0088988 | -0.0252747 | 0.0967033 | 559 |
| 4 | 5,475 | 0.0088988 | -0.1285714 | 0.1809524 | 653 |

The unconditional mean is identical because, without conditioning on intermediate deck states, a position has the same marginal sampling distribution as a hand drawn from the full deck. Conditional dispersion grows rapidly as the deck shrinks. The fourth deal is especially state-dependent and should not be evaluated from the unconditional mean alone.

## 4 Joint farmer returns

Let `X`, `Y`, and `Z` denote the one-unit net returns of bets on the three farmer positions, and define

$$
S=X+Y+Z.
$$

The complete first-deal distribution of $S$ is:

| $S$ | -3 | -1 | 0 | 1 | 2 | 3 | 4 | 5 | 6 |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Probability | 0.2903802 | 0.1574865 | 0.0949192 | 0.1660635 | 0.0688137 | 0.1499174 | 0.0611054 | 0.0104256 | 0.0008885 |

When a fixed total stake is divided among the three symmetric farmer positions, equal allocation reduces volatility through their joint dependence. On the first deal, the standard deviation of one farmer's unit return is 1.1294. Dividing the same total stake equally among all three farmers reduces the standard deviation per unit of total stake to 0.8049.

## 5 Kelly sizing

### 5.1 One farmer

Let $p_1$, $p_2$, and $q$ be the probabilities of a non-pair win, pair win, and loss. If fraction $f$ of current wealth is staked, the expected log growth is

$$
G_X(f)=p_1\ln(1+f)+p_2\ln(1+2f)+q\ln(1-f).
$$

Maximizing this function gives the single-farmer Kelly fraction. The first-deal optimum is approximately 0.7% of wealth.

### 5.2 Equal stakes on three farmers

If fraction $f$ of current wealth is placed on each farmer, the wealth multiplier is $1+fS$ and the objective becomes

$$
G(f)=\mathbb{E}[\ln(1+fS)].
$$

Because

$$
G''(f)=-\mathbb{E}\left[\frac{S^2}{(1+fS)^2}\right]<0,
$$

the objective is concave and any interior stationary point is the global optimum. The constraint $0\leq f<1/3$ keeps wealth positive when all three farmer bets lose.

On the first deal, the optimum is 0.45846% of wealth per farmer, or about 1.37537% in total. Its expected log growth is 0.0061167%.

Weighting each state-specific optimum by the probability of its deck state gives:

| Deal | Weighted expected log growth |
| ---: | ---: |
| 1 | 0.0061167% |
| 2 | 0.0078843% |
| 3 | 0.0211917% |
| 4 | 0.1284610% |
| Four-deal total | 0.1636536% |

These values report the Kelly objective itself: expected log growth. They are not the arithmetic expected return $f\mathbb{E}[S]$, and the two quantities should not be interchanged.

## 6 Monte Carlo simulation

[`simulate_player.m`](../simulate_player.m) uses the state lookup table to simulate bankroll paths. Its default model includes:

- initial wealth of 300;
- an integer stake from 0 through 10 on each farmer;
- the same stake on all three farmer positions;
- permanent exit after wealth falls below 30;
- normal dealing and deck advancement even when the stake is zero;
- a default random seed of 1, with all simulation parameters recorded in the statistics file.

Earlier simulation outputs were generated by a version that did not advance the deck on a zero stake and only exited the current inner loop after bankruptcy. Those outputs are excluded from the report. Corrected results should be regenerated with explicit simulation size, cycle count, and seed, for example:

```matlab
simulate_player(1000000, 25, 1)
```

## 7 Limitations

The conclusions depend on the following assumptions:

1. The bettor knows the exact remaining count of every rank before each bet.
2. The landlord honors the fixed payouts without commission, insolvency, or refusal to pay.
3. The deck is not manipulated and is reset only after the prescribed four deals.
4. Integer rounding, table limits, and exit thresholds cause realized bankroll growth to differ from the continuous-fraction Kelly model.
5. The exact positive edge is small; commissions, observation errors, or rule changes can eliminate it.

The results describe the stated mathematical model. They are not gambling advice and do not guarantee real-world profit.

## 8 Reproduction

The full command sequence is documented in the repository [`README.md`](../README.md). The workflow runs the four exact enumerations, adds volatility and Kelly columns to every result file, builds the lookup table, and then runs a seeded simulation.

An open-source reproduction should verify these invariants:

- deck-state probabilities sum to approximately 1 in every deal;
- the 27 joint outcome probabilities sum to approximately 1 for every state;
- eight-digit padded deck keys are unique;
- the four result files contain 1, 5,475, 38,165, and 5,475 states.

## Conclusion

The win conditions do favor the landlord: ties go to the landlord, and one farmer position wins only about 45.85% of deals. Win probability is not return, however. The two-unit net payout on a winning pair gives a full-deck farmer bet an expected advantage of approximately 0.8899% per unit stake. This is the central counterintuitive result of the study.

The unconditional edge remains the same over four deals, but conditional risk and return diverge sharply in later deck states. A bettor should therefore avoid betting mechanically on every deal. Within the model, observing the remaining deck, skipping negative-expectation states, and calculating an equal-stake Kelly fraction from the joint distribution of the three farmer returns produces positive expected log growth. Commissions, observation errors, and rule changes can eliminate that edge in practice.
