# Pick432 1Y — Arbitrum One

**A weekly prediction game built on Chainlink price feeds and Aave yield.**

Players pick four crypto assets they believe will outperform that week, ranked in order. Prizes are awarded across four tiers, so you can win without matching the exact ranking. Winners share a prize pool funded by Aave V3 yield on the collective pot plus 85% of all player payments, including ticket purchases and OG contributions. Loyal early members, called OGs, are designed to recover their full or partial stake by the end of the 52-draw season, regardless of whether they win prizes along the way.

This repository is the DYBL Foundation's **canonical reference implementation** for the Pick432 protocol family. It carries the internal audit trail, NatSpec documentation, and the master changelog covering every version from initial fork through the current release. Sister deployments, including the ETH Mainnet variant, NearestTheETH, and SuperWhale, are verified forks that inherit this codebase and document only their divergences from it.

---

## How the Game Works

Each week, registered players submit four ranked picks from a list of 32 Chainlink-tracked crypto assets. At draw resolution, Chainlink price feeds determine which assets moved the most. Players whose picks best match the ranked outcomes share prizes from that week's pool across four tiers: exact order, any order, three exact, and three any order.

85% of all player payments flows into the prize pot. Aave V3 yield on the collective pot accrues continuously on top of that. The game runs for 52 draws, roughly one year, before the endgame settlement distributes remaining funds to qualifying OG members.

**Ticket price:** $10 USDC (inhale draws 1–36), $15 USDC (exhale draws 37–52)
**OG upfront cost:** $1,040 USDC
**Weekly OG cost:** $20 USDC per draw
**Maximum players:** 55,000
**Draws:** 52 (weekly)
**Target chain:** Arbitrum One

---

## Protocol Primitives

Pick432 1Y is built on a set of reusable protocol primitives that emerged from the DYBL Foundation's broader Lettery and Crypto42 development lineage. These primitives are available to any builder who forks this codebase.

### The Eternal Seed
A fixed percentage of every prize pool, currently 10%, is retained permanently in the pot and continues earning Aave yield throughout the game. The seed does not leave the protocol until endgame settlement. Over successive game cycles it compounds quietly, providing a growing foundation for future prize pools. No equivalent mechanism appears to exist in comparable on-chain prize protocols at the time of writing.

### The Breathing Mechanism
An autonomous closed-loop controller adjusts the weekly prize rate every draw based on the pot's trajectory toward the endgame obligation. Post draw 10, it solves for an optimal breath rate using an exponential moving average of ticket revenue and remaining draws, setting the rate directly rather than stepping it incrementally. The protocol breathes out generously when healthy and tightens when it needs to conserve. The mechanism is designed to operate autonomously, and the long-term goal is minimal human intervention. The first deployed game will run with owner oversight available via timelocked breath override and rail adjustment functions. That oversight is there by design, not by accident. The first live season will serve as the real-conditions calibration reference that informs how much human hand future deployments will need.

### The OG Principal Return Model
Players who commit from the pregame as upfront OG members contribute $1,040 into the pot. The breathing mechanism is calibrated to strive toward returning that full amount to qualifying OGs at draw 52, alongside whatever prizes they won during the game. The target return scales with the OG-to-player ratio at game launch: a lower OG concentration targets 100% return, a higher concentration calibrates to a more conservative figure. This calibration is enforced in code, written on-chain at game start, and publicly readable throughout the season.

### The Four-Step Dormancy Waterfall
If the game enters dormancy early for any reason, a four-step priority model determines how remaining funds are distributed. OG principal is returned first, casual last-draw ticket costs second, a charity allocation third, and any per-head surplus to all recent participants fourth. Players are protected in order of commitment. The treasury takes nothing from the dormancy distribution. No equivalent ordered-waterfall dormancy model appears to exist in current DeFi prize protocols.

### The Intent Queue
A fair FIFO queue system manages OG slot allocation during the pregame. Players register intent, pay upfront, and are offered a confirmed slot in timestamp order. A 72-hour decline window allows any player to exit before the game starts. The queue was designed to address several problems common in on-chain prize protocols: it significantly reduces the ability of coordinated capital, bots, and slot-rush dynamics to crowd out genuine participants; it creates a meaningful commitment signal by requiring upfront payment at registration; and it gives all players a fair ordered path to OG status rather than a gas-war first-come-first-served race.

### Breath Calibration
At game start and again at draw 7, the protocol reads the actual OG-to-player ratio and sets `targetReturnBps`, the return percentage the breathing mechanism will strive toward, using a four-segment piecewise scale. This value is written on-chain and publicly readable from the moment the game launches. A higher OG concentration results in a more conservative calibration. The calibration is immutable once set.

---

## Repository Contents

| File | Description |
|---|---|
| `Pick432_1Y.sol` | Current canonical contract source |
| `Pick432_1Y_Changelog.md` | Full version history from v1.0 to current, 141 entries, 6,466 lines |
| `docs/lineage/Crypto42_Master_Changelog.md` | Parent lineage document covering Crypto42 3Y v1.0 through 1Y v2.73, the codebase from which Pick432 was forked |
| `README.md` | This file |

---

## Audit Status

Pick432 1Y has undergone extensive internal audit work prior to formal submission. The development methodology follows a build, attack, harden, prove cycle across every version.

- **Internal audit passes completed:** 15+ distinct passes using triple-lens internal simulation across registration, draw lifecycle, dormancy, settlement, and governance surfaces
- **Findings resolved:** 215+ across all severity levels from v1.0 through v2.05
- **Current open findings:** Zero at Critical, High, Medium, or Low severity
- **NatSpec coverage:** All external and public functions documented

The full finding register with severity, description, and resolution version for every issue is contained in `Pick432_1Y_Changelog.md`.

---

## Chainlink Dependencies

| Dependency | Purpose |
|---|---|
| `AggregatorV3Interface` | 32 price feeds for weekly asset performance |
| `AggregatorMinMax` | Circuit-breaker bounds check on each feed |
| Chainlink Automation | `checkUpkeep` / `performUpkeep` draw lifecycle progression and auto-pick assignment |
| L2 Sequencer Uptime Feed | Arbitrum sequencer liveness check before each draw resolution |

Feed staleness threshold is 25 hours (24-hour heartbeat plus one hour buffer). Circuit-breaker bounds are checked independently per feed. The sequencer must have been live for at least one hour before a draw can resolve.

---

## Aave Dependency

All deposited capital, ticket revenue, OG payments, and commitment deposits are supplied to Aave V3 on Arbitrum. Yield accrues continuously and is captured into `prizePot` at each draw. A managed exit path, an emergency exit, and a forced exit at game settlement are all available. The infinite USDC approval to Aave is revoked at every exit point.

A future variant of the protocol without any external lending platform dependency is in early design. The Eternal Seed primitive in particular is being considered as a standalone yield source for successor contracts.

---

## Lineage

Pick432 1Y is a fork of Crypto42 1Y v2.81, an internal contract that does not have its own public repository. The Crypto42 lineage itself is a one-year adaptation of a six-year game design, spanning 3Y v1.0 through 1Y v2.81 across 13 internal audit passes and representing the accumulated foundation from which the Pick432 primitives were drawn.

The Crypto42 Master Changelog is included in `docs/lineage/` for development provenance. Auditors reviewing Pick432 1Y need only the Pick432 changelog. The Crypto42 document is reference material for those who want to understand the full protocol history and where the core primitives originated.

Earlier versions of the codebase and additional context on design decisions are available on request. Questions from auditors, researchers, and builders are welcome via the contact details below.

---

## Protocol Family

The following contracts share this codebase and document divergences from this reference implementation.

| Contract | Chain | Key Differences |
|---|---|---|
| Pick432ETH 1Y | ETH Mainnet | Higher ticket and OG costs, no sequencer feed, no charity address |
| NearestTheETH 1Y | ETH Mainnet | Price proximity prediction mechanic rather than ranked performance |
| Pick432 SuperWhale | ETH Mainnet | 5 draws, Pick 3 of 24, high-value tickets, no OG layer |
| Lettery 1Y | TBD | Chainlink VRF randomness-based prize draw, Eternal Seed primitive |
| Weather32 | TBD | Temperature prediction across 32 global cities using Chainlink Functions and AccuWeather data. No crypto assets. |

---

## Contact

DYBL Foundation — Scarborough, England

Auditors, grant reviewers, and builders interested in the protocol or its primitives are welcome to reach out. The DYBL Foundation is actively seeking engagement with the Cyfrin and Chainlink communities and is open to questions on any aspect of the design, audit history, or development methodology.

| Channel | Address |
|---|---|
| Email | dybl7@proton.me |
| Discord | dybl777 |
| X | @DYBL77 |

---

## License

BUSL-1.1. Change Date: 24 February 2030. On the Change Date, this code becomes available under the MIT License.

---

*Built by a non-coder using AI-assisted development, behavioral economics principles, and approximately 800 hours of iterative security work between November 2025 and March 2026.*
