Pick432 1Y -- Master Changelog
Contract: Pick432_1Y
Target chain: Arbitrum One
Current version: v1.99.90
---
Changelog conventions
Versions are Pick432 1Y-specific. This contract does not share version numbers with Crypto42 1Y or Pick432Whale.
All Crypto42 1Y security history (v2.35 through v2.81, 70+ bugs found and fixed) is inherited in full at fork time and documented in the Crypto42 1Y Master Changelog. See cross-reference below.
Severity labels: C = Critical, H = High, M = Medium, L = Low, I = Info.
No em dashes in this document. Use double-hyphen (--) where a dash is needed.
No absolute language ("always", "never", "guaranteed") in finding headers.
---
Inherited security baseline -- Crypto42 1Y v2.81
Pick432 1Y v1.0 is forked from Crypto42 1Y v2.81. All security work accumulated across the Crypto42 1Y audit cycle is present in this contract at the point of fork. That history is not duplicated here. Refer to:
Crypto42 1Y Master Changelog -- documents every finding from v2.35 through v2.81 including:
3 Critical, 4 High, 5 Medium, 1 Low resolved across the triple audit cycle (v2.2 series)
Intent queue: H-01 startGame guard, M-01 dual ogList entry, M-02 AlreadyInIntentQueue guards (v2.67-v2.75)
Commitment deposit mechanic: 15% treasury slice retained on voluntary OG exit (v2.81)
upgradeToUpfrontOG: drain-and-shortfall payment, no dual ogList entry, currentDraw > firstPlayedDraw guard (v2.76-v2.79)
payUpgradeBlock, honest obligation formula, upgraderOGCount, upgradedFromWeekly (v2.80)
Dormancy refund cap for upgraders, FailedPregameSwept / DormancyRemainderSwept separation (v2.80)
Predictive optimal breath, EMA revenue seeding, OG_ABSOLUTE_FLOOR, breath rails (v2.70-v2.73)
Solvency check, emergencyResetDraw full unwind machinery, commitment refund pool (v2.35-v2.60 series)
The Pick432 1Y changelog begins at v1.0 and records only changes specific to this contract from that point forward.
---
Version index
Version	Summary
v1.0	Initial release. Fork of Crypto42 1Y v2.81. 6/42 bitmask mechanic replaced with 4/32 ordered-rank mechanic. Prize tiers corrected to strict descending order. 4 info findings resolved.
v1.1	Triple audit findings resolved. 1H (BPS divisor), 2M (FEED_STALENESS regression, sequencer feed constructor enforcement), 1 design note NatSpec (T-03). 2 additional info findings from independent double-audit resolved as NatSpec.
v1.2	NatSpec and documentation consistency pass. 2H (stale NatSpec contradicting live code), 1M (dead branch not annotated), 1I (ambiguous inline comment). All documentation-only changes, no logic changes.
v1.3	Deferred NatSpec additions (I-02, I-03) that were marked resolved in v1.1 but never written. Changelog INHALE_DRAWS/EXHALE_DRAWS corrected from 39/13 to 36/16. No logic changes.
v1.4	NON_SEED_BPS annotated as dead constant post C-01. Misleading tier BPS comment corrected. Changelog: v1.1 audit result header corrected, v1.3 finding labels normalised, v1.0 INFO-01 misleading text replaced. NON_SEED_BPS added to carry-forward list.
v1.5	Triple audit code fixes. 2M (lastDrawHadJPMiss removed, committedPlayerCount draw-1 fix), 1L (payUpgradeBlock EMA fix), 3 dead constants removed, _getCurrentTreasuryBps() inlined, I-02 dual-claim NatSpec added.
v1.6	Fresh audit pass. 1L NatSpec (payUpgradeBlock reset limitation), 1L dead constant (BREATH_CEIL_BPS), 1L safety floor (claimSignupRefund treasury), 3 dead errors removed, 1 dead event removed, I-03 per-iteration gas guard in _continueUnwind.
v1.7	NatSpec coverage pass. @dev blocks added to 12 high-priority functions. pruneStaleOGs was missing both @notice and @dev -- now fully documented. NatSpec coverage: 8.0% to 10.6% (427 NatSpec lines).
v1.71	L-05 batch size guards on confirmOGSlots and pruneStaleOGs. NEW: forceDeclineIntent() -- owner escape valve for PENDING+isWeeklyOG stuck state that can permanently block startGame(). 100% refund, distinct event, PREGAME only.
v1.72	forceDeclineIntent audit follow-up: M-01 refund zero bug fixed, M-02 setBreathRails timelocked (C-04 resolved), L-01 try/catch in loop, L-02 guard, L-03 expiry cleared, L-04/L-05 RUNBOOK updates, I-01/I-05 NatSpec corrections.
v1.73	proposeBreathRails/executeBreathRails audit follow-up: M-01 gamePhase guards (ACTIVE only), L-NEW-01 claimDormancyRefund bare decrement, L-01 rails cancellation in proposeDormancy/forceDeclineIntent, L-02 stuck override fix, L-03/I-04 NatSpec, L-04 no-op guard, I-05 reason field added.
v1.74	Knock-on analysis: dead cancel block removed from forceDeclineIntent, emergencyResetDraw cancels breathRailsEffectiveTime, proposeBreathOverride phase guard reordered before _captureYield, _checkAutoAdjust cooldown subtraction safety NatSpec.
v1.75	Final pre-submission NatSpec: EMA alpha 0.5 design choice documented in _checkAutoAdjust(), AUDIT-03 obligation return value clarified in getProjectedEndgamePerOG(). audit submission ready.
v1.76	Fresh area audit: L-01 sweepFailedPregame bricking fix (signupDeadline gate), L-02 transferOwnership sliding window NatSpec, I-01 proposePrizeRate drawPhase asymmetry NatSpec x2, I-04 StreakBroken streak-of-1 NatSpec, getPreGameStats pendingIntentCount caveat.
v1.77	Three carry-forwards resolved: M-02 activateAaveEmergency inverted gate removed (was blocking exit in crisis), L-01 acceptOwnership misleading error fixed (NoTimelockPending guard added), L-03 draw 52 zero-prize edge case documented in buyTickets NatSpec.
v1.78	Group B+C audit: L-01 _cleanupOGOnRefund four bare decrements guarded, L-02 SWEPT ogIntentAmount stale storage cleared, L-03 cancelPrizeRate direction check NatSpec, I-01 register/topUpCredit mid-draw NatSpec, I-03 withdrawTreasury phase-unrestricted NatSpec.
v1.79	Group C+D audit: duplicate @notice removed, L-02 _withdrawAndTransfer transfers amount not received, I-03 proposeFeedChange SEQUENCER_FEED guard, I-01 proposeAaveExit NatSpec, I-02 batchMarkLapsed silent skips NatSpec, L-01 proposeFeedChange concurrent safety NatSpec.
v1.80	Group D remaining + Group E view functions: L-02 getProjectedEndgamePerOG /9000 dual-purpose buffer NatSpec, I-01 getPlayerInfo PREGAME false positive, I-02 getCurrentPrizeRate draw 52 zero warning, I-03 getWeekPerformance sentinel, I-04 encodePicks silent truncation.
v1.81	Regression pass: duplicate @notice removed from proposeFeedChange, I-02 claimOGIntentRefund OFFERED path two unguarded decrements guarded (upfrontOGCount, committedPlayerCount).
v1.82	Internal audit simulation: M-01 upgradeToUpfrontOG bare decrements guarded, L-01 commitment credit game-failure forfeiture documented (accepted design), L-02 bestIdx explicit init, L-03 getProjectedEndgamePerOG settled path obligation consistent, I-01 dead SEQUENCER_FEED null check removed.
---
[v1.0]: Initial Release -- Fork of Crypto42 1Y v2.81
Date: March 2026
Lines: 3,750
Audit result: 0C 0H 0M 0L 4I -- all resolved as documentation-only changes.
What this contract is
Pick432 1Y is a weekly price-prediction game for Arbitrum One. Players pick 4 of 32 crypto assets in ranked order (rank 1 = predicted best performer, rank 4 = predicted fourth best). Each draw, Chainlink price feeds determine the actual top-4 ranked performers. Scoring rewards both exact-order and any-order matches across four prize tiers. The game runs for 52 weekly draws (~1 year). The Eternal Seed primitive (10% of every weekly pool returns to prizePot permanently) ensures the prize floor only rises over the life of the game.
Mechanic changes from Crypto42 1Y v2.81
The 6/42 bitmask mechanic (pick any 6 of 42 assets, popcount matching) is fully replaced by the 4/32 ordered-rank mechanic (pick 4 of 32 assets in predicted rank order, exact/any position matching).
Encoding change:
`uint64 picks` (bitmask, 1 bit per asset) -- removed
`uint32 picks` (5 bits per rank position, 4 ranks packed) -- new
`VALID\_BITS\_MASK` -- removed
`PICKS\_BITS = 5`, `PICKS\_MASK = 0x1F`, `FULL\_PICKS\_MASK = 0xFFFFF` -- new
`\_popcount()` -- removed
`decodePicks()`, `encodePicks()` -- added
Asset pool change:
`NUM\_ASSETS`: 42 -- 32
`NUM\_PICKS`: 6 -- 4
resolveWeek -- winningResult build:
Old: bitmask of top-6 asset indices (`mask |= 1 << bestIdx`), stored as `uint64 winningMask`.
New: packed uint32 where rank-i asset index sits at bits `i\*5..i\*5+4` (`result |= uint32(bestIdx) << (rank \* PICKS\_BITS)`), stored as `uint32 winningResult`.
Tie-break: lower feed array index wins among equal-performance assets (unchanged from C42).
_matchAndCategorize -- scoring:
Old: `\_popcount(picks \& winningMask)` counts bit overlaps, no positional awareness.
New: decode both player picks and winningResult into four 5-bit indices. Compute `exactMatches` (correct asset at correct rank) and `anyMatches` (correct asset at any rank). Tier assignment:
JP: `exactMatches == 4` (all 4, exact order)
P2: `anyMatches == 4`, `exactMatches < 4` (all 4, any order)
P3: `exactMatches == 3` (3 exact position)
P4: `anyMatches >= 3`, `exactMatches < 3` (3 any order)
Branches are mutually exclusive and evaluated in the correct priority sequence.
Winner arrays renamed:
`m5Winners`, `m4Winners`, `m3Winners` -- removed
`p2Winners`, `p3Winners`, `p4Winners` -- new
All assembly `sstore` reset blocks updated in both `resolveWeek` and `emergencyResetDraw`.
_validatePicks:
Old: bitmask checks -- non-zero, no out-of-range bits, popcount == 6.
New: 5-bit packing checks -- non-zero, no bits above position 19, all four indices unique. No range guard needed (5-bit field gives 0-31, exactly matching NUM_ASSETS=32).
Prize tier correction
Finding: Both Crypto42 1Y and the initial Pick432 1Y fork had the bottom prize tier (M3 / P4) larger than the tier above it because it was calculated as a remainder without an explicit BPS constant. This inverted the intended descending prize structure.
Root cause: `tierPools\[3] = distributable - t\[0] - t\[1] - t\[2]` with no M3/P4 constant meant the bottom tier absorbed whatever was left after the upper three tiers, which happened to exceed M4/P3 in both contracts.
Fix -- Crypto42 1Y: JP/M5/M4 BPS redesigned so M3 remainder is explicitly controlled:
Tier	Match	% of weekly pool	BPS of distributable
JP	6/6	30%	3333
M5	5/6	25%	2778
M4	4/6	20%	2222
M3	3/6	15%	1667 (remainder)
SEED	--	10%	--
Sum = 10000 bps exactly. No dust.			
Fix -- Pick432 1Y: Same principle, different values appropriate to the 4/32 game:
Tier	Match	% of weekly pool	BPS of distributable
JP	4/4 exact	33%	3667
P2	4/4 any	24%	2667
P3	3 exact	19%	2111
P4	3 any	14%	1555 (remainder)
SEED	--	10%	--
Sum = 10000 bps exactly. No dust. Strictly descending.			
JP miss redistribution -- unchanged and intentionally inverse:
When JP has no winners, 70% of the JP pool seeds prizePot (Eternal Seed mechanic). 30% redistributes to lower tiers with M3/P4 receiving the largest slice, then M4/P3, then M5/P2. This intentional inversion rewards the broadest tier most during a jackpot miss -- distinct from the normal weekly pool allocation which is strictly descending. Constants:
`JP\_MISS\_P2\_BPS = 4000` (40% of the 30%)
`JP\_MISS\_P3\_BPS = 3500` (35% of the 30%)
P4 gets remainder (25% of the 30%)
Economics -- unchanged from Crypto42 1Y
All economic constants are identical to the 6/42 Crypto42 1Y game. The mechanic change does not affect pricing, OG structure, or game duration.
Parameter	Value
TICKET_PRICE	$10 USDC
EXHALE_TICKET_PRICE	$15 USDC
OG_UPFRONT_COST	$1,040 USDC
OG_PREPAY_AMOUNT	$80 USDC (4 weeks)
TOTAL_DRAWS	52
INHALE_DRAWS	36
EXHALE_DRAWS	16
DRAW_COOLDOWN	7 days
PICK_DEADLINE	4 days
FEED_STALENESS	24 hours (corrected to 25 hours in v1.1 -- see C-02)
MAX_PLAYERS	55,000
Chain-specific configuration -- Arbitrum One
Parameter	Value
SEQUENCER_FEED	Arbitrum L2 sequencer uptime feed (must not be address(0))
AAVE_POOL	Aave V3 on Arbitrum One
NUM_ASSETS	32 (Arbitrum Chainlink feed ecosystem supports 35-45 clean altcoin/USD feeds)
Arbitrum sequencer uptime feed address (at time of writing): `0xFdB631F5EE196F0ed6FAa767959853A9F217697D`. Verify against Chainlink documentation before deployment.
Audit findings resolved -- v1.0
INFO-01 -- No constructor revert if SEQUENCER_FEED is address(0) on Arbitrum
Severity: Info | Status: Resolved (NatSpec)
The constructor emits `SequencerFeedDisabled()` when `\_sequencerFeed == address(0)` but does not revert. This pattern was inherited from Pick432Whale where ETH Mainnet deployment uses address(0) legitimately (no L2 sequencer exists on Mainnet). For this Arbitrum-only contract, address(0) was never valid -- it would silently disable sequencer protection, allowing draw resolutions during sequencer downtime. Resolution: explicit `ARBITRUM DEPLOYER WARNING` NatSpec block added to constructor documenting the required feed address and the consequence of passing zero. The constructor revert was added in v1.1 (C-03). Shared pattern with Pick432Whale v1.5.
INFO-02 -- Dead guard in isValidPicks() without explanation
Severity: Info | Status: Resolved (NatSpec)
`isValidPicks()` contains `if (idx\[i] >= NUM\_ASSETS)` which is permanently false -- a 5-bit field gives values 0-31 and NUM_ASSETS=32, so the condition can never fire. The internal `\_validatePicks()` correctly has this guard removed. The guard is intentionally retained in the external view function for front-end diagnostic clarity (returns "Asset index out of range (0-31)" for any future encoding change). NatSpec added explaining the retention rationale and cross-referencing `\_validatePicks()`. Same resolution pattern as Pick432Whale v1.5 INFO-01-P.
INFO-03 -- Duplicate @notice tag on getWinnerCounts()
Severity: Info | Status: Resolved (NatSpec removed)
`getWinnerCounts()` had two identical `@notice` lines, introduced during the fork surgery that replaced the m5/m4/m3 NatSpec with p2/p3/p4. Compiler ignores the duplicate but NatSpec linters flag it. One line removed.
INFO-04 -- DRAWS_FROM_OBLIGATION_LOCK comment references Crypto42 versioning
Severity: Info | Status: Resolved (comment updated)
The inline comment read `\[v2.80 I-01]` -- a Crypto42 version tag. The constant value is correct (52 - 9 - 1 = 42). Comment updated to `\[Pick432 1Y v1.0 / INFO-04]` to reflect this contract's own versioning context.
---
[v1.1]: Triple Audit Findings -- Internal triple audit
Date: March 2026
Lines: 3,787
Audit result: 0C 1H 2M 0L 4I -- H and M findings resolved in v1.1. I-01 (T-03 design note) resolved in v1.1. I-02 and I-03 (deferred NatSpec) resolved in v1.3. Plus 2 additional info findings from independent double-audit: I-02 and I-03 planned here, completed in v1.3.
Source: Internal triple audit pass against Pick432_1Y v1.0.
H-01 / C-01 (Internal audit + Internal audit) -- Prize tier BPS wrong denominator -- P4 receives ~60% less than designed
Severity: High | Status: Resolved (code fix)
Location: `\_calculatePrizePools()`, tier constant declarations
Finding: The BPS constants JP_BPS=3667, P2_BPS=2667, P3_BPS=2111 were designed as fractions of the full weekly pool expressed in bps-of-10000. The formula divided by NON_SEED_BPS (9000) instead of 10000.
Impact: With division by 9000, each of JP/P2/P3 received approximately 11% more than intended. P4, calculated as the remainder, received only 5.5% of the weekly pool instead of the designed 14%. P4 is the most commonly hit tier (3 picks in any order). Internal audit verified numerically: with a $10,000 weekly pool, P4 winners received $555 instead of $1,400 -- 39.7 cents on the dollar.
The BPS comment `// JP\_BPS+P2\_BPS+P3\_BPS+P4\_BPS = 10000 exactly, no dust` was only true if an implied P4_BPS of 1555 was used with denominator 10000. With the actual /NON_SEED_BPS formula, the implicit P4 fraction was 555/9000, not 1555/10000.
No funds leaked. All of distributable was allocated. Only the proportions were wrong.
The same bug was independently present in Pick432Whale v1.6 (same BPS constants, same formula). Both contracts fixed simultaneously. Pick432Whale bumped to v1.7.
Root cause: BPS values from the 4/32 tier redesign were computed as "% of distributable expressed in bps of 10000" (e.g. 33% / 90% * 10000 = 3667). They required division by 10000. The formula was carried forward unchanged from Crypto42 1Y where the original tier constants (3333/2778/2222) were designed for a /NON_SEED_BPS divisor and coincidentally worked correctly.
Fix (Fix A -- change divisor): Three lines in `\_calculatePrizePools()`:
```
Before: tierPools\[0] = distributable \* JP\_BPS / NON\_SEED\_BPS;
Before: tierPools\[1] = distributable \* P2\_BPS / NON\_SEED\_BPS;
Before: tierPools\[2] = distributable \* P3\_BPS / NON\_SEED\_BPS;

After:  tierPools\[0] = distributable \* JP\_BPS / 10000;
After:  tierPools\[1] = distributable \* P2\_BPS / 10000;
After:  tierPools\[2] = distributable \* P3\_BPS / 10000;
```
P4 remains as remainder. Post-fix tier distribution:
Tier	Intended % of weekly	Actual % post-fix	Delta
JP	33%	33.0%	0
P2	24%	24.0%	0
P3	19%	19.0%	0
P4	14%	14.0%	0
SEED	10%	10%	0
BPS constants and tier percentage comments are correct as written. Only the divisor changed.
---
M-01 / C-02 (Internal audit) -- FEED_STALENESS = 24h is a regression from Whale's corrected 25h
Severity: Medium | Status: Resolved (constant updated)
Location: `FEED\_STALENESS` constant
Finding: `FEED\_STALENESS = 24 hours` (86400 seconds). Many Chainlink feeds on Arbitrum have a 24-hour heartbeat -- they update only on >0.5% price deviation OR after 24 hours have elapsed. The staleness check `block.timestamp - updatedAt > FEED\_STALENESS` means any feed last updated 86401 seconds ago returns 0 and falls back to `lastValidPrices`.
In a 7-day draw window, this creates a narrow but real risk: if `resolveWeek()` is called within seconds of a feed's heartbeat crossing the 24-hour boundary, that feed silently reports stale. With correlated heartbeats across multiple Arbitrum feeds, `validAssets < NUM\_PICKS` could trigger and revert the draw entirely.
Pick432Whale v1.5 explicitly fixed this same issue (NatSpec: "25 hours = 24h Chainlink heartbeat + 1h buffer"). v1.0 of this contract regressed to 24h during the fork.
Fix: `FEED\_STALENESS = 25 hours`. Matches Pick432Whale and Internal audit recommended pattern for this architecture.
---
M-02 / C-03 (Internal audit) -- Constructor does not enforce non-zero SEQUENCER_FEED on Arbitrum
Severity: Medium | Status: Resolved (constructor hardened)
Location: Constructor
Finding: The constructor accepted `address(0)` for `\_sequencerFeed` and emitted `SequencerFeedDisabled()` as a warning only. The NatSpec block was explicit that this is wrong on Arbitrum: "Passing address(0) disables sequencer protection silently." Despite the warning, no code enforcement existed. A deployment error or a testnet-to-mainnet copy omitting the sequencer feed address would ship a game without L2 protection.
Pick432Whale correctly documents `address(0)` as the ETH Mainnet mode. Pick432 1Y has no ETH Mainnet mode. `address(0)` is always wrong here.
During Arbitrum sequencer downtime, the L2 freezes but ETH Mainnet keeps producing blocks. Without sequencer checking, `resolveWeek()` and `startGame()` can execute against potentially stale L2 prices. An actor who knows the sequencer is about to come back up can front-run draw resolution.
Fix: Constructor now reverts `InvalidAddress()` if `\_sequencerFeed == address(0)`. The `SequencerFeedDisabled` event is removed from this contract -- it served no purpose once address(0) is banned.
```
Before: if (\_sequencerFeed == address(0)) emit SequencerFeedDisabled();
After:  if (\_sequencerFeed == address(0)) revert InvalidAddress();
```
---
I-01 / T-03 (Internal audit) -- Calibrated endgame cap creates apparent loss at high OG concentration
Severity: Info/Design | Status: Resolved (NatSpec added to `closeGame()`)
Location: `closeGame()`, `getProjectedEndgamePerOG()`
Finding: The endgame cap `OG\_UPFRONT\_COST \* targetReturnBps / 10000` is calibrated to OG concentration. At 100% OG concentration (targetReturnBps = 4000), maxPerOG = $416 on a $1,040 entry. `getProjectedEndgamePerOG()` returns this value as `obligation`, which front-ends could display as "projected endgame payout: $416" -- reading as a projected loss.
This is not a security issue and not a bug. The endgame distribution is surplus redistribution. The primary OG return path is weekly prizes across 52 draws: an upfront OG is auto-matched every draw without buying tickets. At low OG concentration (20% OG, targetReturnBps = 10000), maxPerOG = $1,040 -- full cost recovery from endgame alone is possible.
Contrast with Pick432Whale, which uses a flat $4,995 cap (111% of $4,500) regardless of concentration. The 1Y calibrated approach is an intentional design divergence.
Resolution: NatSpec added to `closeGame()` documenting the design intent, the weekly prize primary return path, and the front-end responsibility to present both values together. audit review narrative: acknowledged design delta, not a code issue.
---
I-02 (Internal double-audit) -- Draw 10 prizes calculated with pre-lock breath rate
Severity: Info | Status: Resolved (NatSpec added to `resolveWeek()`)
Location: `resolveWeek()` -- ordering of `\_calculatePrizePools()` and `\_lockOGObligation()`
Finding: In `resolveWeek()`, `\_calculatePrizePools()` is called before `\_lockOGObligation()`. At draw 10, this means draw 10's prizes are computed using the pre-lock (startGame() preview) breath rate. `\_lockOGObligation()` then fires and recalibrates `breathMultiplier` to the definitive post-lock value. Draws 11 through 52 use the recalibrated rate.
This is a one-draw transition artifact. It is not a bug -- draw 10 prizes are computed with a valid, calibrated rate. The rate just changes for the next draw immediately after. No funds are at risk and the behaviour is fully deterministic.
Resolution: NatSpec note added to `resolveWeek()` in v1.3 clarifying the ordering so auditors do not flag it as a sequencing error. (Originally planned for v1.1; NatSpec was inadvertently omitted until v1.3.)
---
I-03 (Internal double-audit) -- Dual reset pool eligibility requires two transactions
Severity: Info | Status: Resolved (NatSpec added to `claimResetRefund()`)
Location: `claimResetRefund()`
Finding: A player who bought tickets in two different emergency-reset draws can be simultaneously eligible for both `resetDrawRefundPool` (pool 1) and `resetDrawRefundPool2` (pool 2). The function pays pool 1 on the first call and silently skips pool 2. A second call is required to collect from pool 2.
No double-payment risk exists and no funds are lost -- pool 2 remains claimable until its deadline. The UX risk is that a player calls once, sees a successful refund, and assumes they have been fully compensated when they have not.
Resolution: NatSpec note added to `claimResetRefund()` in v1.3 documenting that dual eligibility requires two calls and that both pools remain independently claimable. (Originally planned for v1.1; NatSpec was inadvertently omitted until v1.3.)
---
Economics update -- v1.1
`FEED\_STALENESS` corrected from 24 hours to 25 hours. All other economic constants unchanged from v1.0.
Parameter	v1.0	v1.1
FEED_STALENESS	24 hours	25 hours
---
[v1.2]: NatSpec and Documentation Consistency Pass
Date: March 2026
Lines: 3,798
Audit result: 0C 0H 0M 0L 4 doc findings -- all resolved. No logic changes.
Source audit: Internal triple audit consistency review of v1.1.
All changes in this version are documentation-only. No constants, no logic, no event signatures were modified. The contract ABI is identical to v1.1.
---
CF-03 / T-01 (Internal audit + Internal audit) -- HIGH: Constructor NatSpec contradicts constructor code
Severity: High (documentation) | Status: Resolved (NatSpec rewritten)
Location: Constructor NatSpec block
Finding: The v1.1 code fix (C-03) made the constructor revert on `address(0)`. However, the NatSpec block was not updated. It still read:
> "Passing address(0) disables sequencer protection silently -- the contract will accept draw resolutions even during sequencer downtime. This is only appropriate for ETH Mainnet deployments."
This was factually wrong in two ways: the contract no longer silently disables protection (it reverts), and there is no ETH Mainnet mode for this contract. The tag still referenced `\[v1.0 / INFO-01]`. An auditor reading this NatSpec would conclude C-03 was never applied.
Three claims in the contract were simultaneously inconsistent: the v1.1 header changelog (correct), the constructor NatSpec (wrong), and the constructor code (correct). Internal audit formally elevated this as the highest-priority documentation defect.
Fix: Constructor NatSpec rewritten to match the live code:
Tag updated from `\[v1.0 / INFO-01]` to `\[v1.1 / C-03]`
"Passing address(0) disables..." replaced with "Passing address(0) reverts"
"ETH Mainnet deployments" reference removed -- this contract has no ETH Mainnet mode
Retained: feed address, Chainlink verification reminder
---
AUDIT-01 (Internal audit) -- HIGH: resolveWeek() and proposeFeedChange() say "42 price feeds"
Severity: High (documentation) | Status: Resolved (NatSpec corrected)
Location: `resolveWeek()` NatSpec, `proposeFeedChange()` NatSpec
Finding: Both functions had NatSpec stating "42 price feeds." This contract has 32 (NUM_ASSETS = 32). The number 42 is the asset count for Crypto42, the parent contract. These strings were not updated during the fork surgery that produced Pick432 1Y v1.0 and carried forward through v1.1.
Any deployer, integrator, or auditor counting assets against the NatSpec would find a discrepancy of 10 feeds and no explanation.
Fix: Both occurrences updated from "42" to "32."
---
AUDIT-02 (Internal audit) -- MEDIUM: Dead _checkSequencer() zero-address branch not annotated
Severity: Medium (documentation) | Status: Resolved (comment added)
Location: `\_checkSequencer()`
Finding: `\_checkSequencer()` opens with `if (SEQUENCER\_FEED == address(0)) return`. Since C-03 (v1.1) made the constructor revert on address(0), this branch is permanently unreachable at runtime. Without annotation, future readers may conclude there is a silent no-sequencer mode that can be triggered -- or that C-03 was not actually effective.
In Pick432Whale this branch is legitimate (ETH Mainnet mode). In this contract it is dead code with no explanation.
Fix: Four-line comment block added immediately above the guard explaining it is unreachable post-C-03, retained as a defensive fallback only, and distinguishing it from the Whale's live no-sequencer path.
---
AUDIT-04 (Internal audit) -- INFO: Inline BPS comment used ambiguous notation
Severity: Info | Status: Resolved (comment rewritten)
Location: `\_calculatePrizePools()` inline comment
Finding: The v1.1 inline comment explaining the C-01 fix contained:
`// (e.g. 3667 = 36.67% → NO, 3667/10000 = 36.67% of dist = 33% of weekly pool).`
The `→ NO` notation intended to dismiss a wrong interpretation. A reader unfamiliar with the bug could parse "3667 = 36.67%" as the correct reading being confirmed rather than the wrong one being struck through.
Fix: Rewritten as an explicit before/after comparison:
```
// Correct reading:
//   JP: 3667/10000 x distributable = 36.67% of distributable = 33.0% of weekly pool.
// Wrong reading (old /9000): 3667/9000 x distributable = 40.7% of distributable = 36.7% of weekly.
```
---
Carry-forward items -- pending audit submission
AUDIT-03: `getProjectedEndgamePerOG()` return value named `obligation` is the calibrated total endgame pool target, not a per-OG figure. Naming may confuse front-end integrators. NatSpec clarification pending.
BREATH_STEP_UP: `BREATH\_STEP\_UP = 50` constant is never read anywhere in the contract. Dead constant. No security impact.
NON_SEED_BPS: `NON\_SEED\_BPS = 9000` was the divisor in the old buggy `\_calculatePrizePools()` formula (C-01). Post-fix it has no callers. Annotated as dead in v1.4. Candidate for removal alongside BREATH_STEP_UP.
---
[v1.3]: Deferred NatSpec Additions and Changelog Correction
Date: March 2026
Lines: 3,815
Audit result: 0C 0H 0M 0L 3 doc findings -- all resolved. No logic changes.
Source audit: Internal triple audit consistency review of v1.2.
All changes in this version are documentation-only. No constants, no logic, no event signatures were modified. The contract ABI is identical to v1.2.
---
CL-01 (Internal audit) -- HIGH: INHALE_DRAWS and EXHALE_DRAWS wrong in changelog economics table
Severity: High (documentation) | Status: Resolved (changelog corrected)
Location: Changelog v1.0, economics table
Finding: The changelog stated `INHALE\_DRAWS = 39` and `EXHALE\_DRAWS = 13`. The contract declares `INHALE\_DRAWS = 36` and `EXHALE\_DRAWS = 16`. Both pairs sum to 52, which is why this was not caught earlier -- the total draw count appeared correct. However the inhale/exhale boundary is wrong. An integrator building exhale-phase pricing logic from the changelog would apply the $15 exhale price from draw 40 onward instead of draw 37. At $15 vs $10 per ticket this is a real UX and pricing error for any front-end consuming the changelog as a spec.
Fix: Changelog economics table corrected to `INHALE\_DRAWS = 36`, `EXHALE\_DRAWS = 16`. Contract constants unchanged -- they were always correct.
---
CL-02 (Internal audit) -- MEDIUM: I-02 marked "resolved" in v1.1 changelog but NatSpec absent from contract
Severity: Medium (documentation integrity) | Status: Resolved (NatSpec added)
Location: v1.1 changelog entry for I-02; `resolveWeek()` NatSpec
Finding: The v1.1 changelog stated "NatSpec note added to `resolveWeek()` clarifying the ordering so auditors do not flag it as a sequencing error." The NatSpec was not present in v1.1 or v1.2. The changelog entry was inaccurate -- it described a fix that did not exist in the contract. Internal audit would find this discrepancy immediately on submission.
Fix: NatSpec block added to `resolveWeek()`:
Tag: `\[v1.3 / I-02]`
Documents that `\_calculatePrizePools()` fires before `\_lockOGObligation()` at draw 10
Explains draw 10 prizes use pre-lock breath; draws 11-52 use recalibrated rate
Clarifies this is a one-draw transition artifact, not a sequencing error
---
CL-03 (Internal audit) -- MEDIUM: I-03 marked "resolved" in v1.1 changelog but NatSpec absent from contract
Severity: Medium (documentation integrity) | Status: Resolved (NatSpec added)
Location: v1.1 changelog entry for I-03; `claimResetRefund()` NatSpec
Finding: The v1.1 changelog stated "NatSpec note added to `claimResetRefund()` documenting that dual eligibility requires two calls." The NatSpec was not present in v1.1 or v1.2. Same discrepancy as I-02 -- the changelog described a fix that did not exist in the contract.
Fix: NatSpec block added to `claimResetRefund()`:
Tag: `\[v1.3 / I-03]`
Documents that dual-pool eligibility requires two separate transactions
Clarifies pool 1 pays on first call, pool 2 pays on second call
Notes both pools remain independently claimable until their deadlines
Flags front-end responsibility to check both pools and prompt a second call
---
[v1.4]: Consistency and Carry-Forward Documentation
Date: March 2026
Lines: 3,828
Audit result: 0C 0H 0M 0L 4 doc findings -- all resolved. No logic changes.
Source audit: Internal triple audit consistency review of v1.3.
All changes in this version are documentation-only. No constants, no logic, no event signatures were modified. The contract ABI is identical to v1.3.
---
F1 (Internal audit / Info) -- NON_SEED_BPS is a dead constant post C-01
Severity: Info | Status: Resolved (constant annotated, comment corrected)
Location: Constants block, `\_calculatePrizePools()` comment
Finding: After C-01 changed the tier pool divisor from `NON\_SEED\_BPS` to `10000`, the constant `NON\_SEED\_BPS = 9000` had no callers anywhere in the contract. The comment above the tier BPS constants still read "of distributable pool, i.e. NON_SEED_BPS portion" -- implying the old formula was still active. `NON\_SEED\_BPS` joins `BREATH\_STEP\_UP` as a documented dead constant.
Fix: Misleading BPS comment corrected -- tiers use `/10000`, not `/NON\_SEED\_BPS`. `NON\_SEED\_BPS` annotated with `\[v1.4 / F1]` explaining it is dead post C-01. Added to carry-forward list alongside `BREATH\_STEP\_UP`.
---
F2 (Internal audit / Low) -- v1.1 changelog audit result header contradicted individual finding entries
Severity: Low (documentation integrity) | Status: Resolved (changelog corrected)
Location: Changelog v1.1 header
Finding: The v1.1 header read "0C 1H 2M 0L 4I -- all resolved." After v1.3 updated I-02 and I-03 to say "resolved in v1.3", the "all resolved" was no longer accurate. A audit reviewor reading top-down would hit "all resolved" and then find individual entries saying "resolved in v1.3" and flag the contradiction.
Fix: v1.1 audit result header updated to accurately describe resolution timeline: H and M findings resolved in v1.1; I-02 and I-03 resolved in v1.3.
---
F3 (Internal audit / Low) -- v1.3 finding labels used inconsistent prefix pattern
Severity: Low (documentation consistency) | Status: Resolved (labels normalised)
Location: Changelog v1.3 section, finding headers
Finding: v1.1 used `H-01 / C-01 (Internal audit + Internal audit)` style labels. v1.2 used `CF-03 / T-01`, `AUDIT-01` etc. v1.3 used plain `Finding 1 (Internal audit)` with no cross-reference codes. Inconsistent labelling across a single audit cycle submission package.
Fix: v1.3 finding labels updated to `CL-01`, `CL-02`, `CL-03` (CL = Changelog finding) matching the auditor-prefix convention used in prior versions.
---
F4 (Internal audit / Info) -- v1.0 INFO-01 described address(0) as intentional for ETH Mainnet
Severity: Info | Status: Resolved (changelog corrected)
Location: Changelog v1.0, INFO-01 resolution note
Finding: INFO-01 stated "On ETH Mainnet this is intentional." In the context of a changelog for an Arbitrum-only contract, this implies a legitimate ETH Mainnet deployment mode existed or was considered. It was never intentional for this contract -- the pattern was inherited from Pick432Whale where ETH Mainnet deployment correctly uses address(0). The note would look misleading to a audit reviewor reading the full submission package.
Fix: Replaced with accurate explanation: the pattern was inherited from Pick432Whale where address(0) is the legitimate ETH Mainnet mode. It was never valid for this Arbitrum-only contract.
---
[v1.5]: Triple Audit Code Fixes
Date: March 2026
Lines: 3,851
Audit result: 0C 0H 2M 1L 2I resolved. Plus 3L (dead constants), 1L (function inlining). No logic changes to game mechanics.
Source audit: Internal triple audit review of v1.4.
---
M-01 (Internal audit / Medium) -- lastDrawHadJPMiss was a dead state variable
Severity: Medium | Status: Resolved (removed)
Location: State var, `distributePrizes()`, `\_checkAutoAdjust()`, `finalizeWeek()`
Finding: `lastDrawHadJPMiss` was set to `true` in `distributePrizes()` when the JP tier had no winners and `obligationLocked` was true. It was cleared unconditionally one draw later in `\_checkAutoAdjust()`. The v2.73 comment read "Clear JP miss flag -- predictive formula accounts for its pot impact directly." That comment confirmed the flag had no effect on any formula output. The flag cost ~20K gas (SSTORE warm write) on every JP-miss draw and was never read by any conditional that changed behaviour.
Fix: Flag and all three read/write sites removed. The EMA captures JP-miss pot impact naturally via the reduced pot level the following draw. `finalizeWeek()` TOTAL_DRAWS guard simplified. The state variable slot is freed.
---
M-02 (Internal audit / Medium) -- committedPlayerCount not decremented when draw-1 commitment credit consumed in buyTickets()
Severity: Medium | Status: Resolved (one line added)
Location: `buyTickets()`, commitment credit path
Finding: When a player spent their draw-1 commitment credit via `buyTickets()`, `p.commitmentPaid` was cleared but `committedPlayerCount` was not decremented. If `emergencyResetDraw()` fired on draw 1 after some players had already consumed their credits, the refund pool was calculated as `committedPlayerCount \* TICKET\_PRICE` -- overstating the pool. Players with `commitmentPaid = false` could not claim from the inflated pool, so excess funds accumulated and were eventually swept to charity rather than returning to the prize pot.
Fix: `if (committedPlayerCount > 0) committedPlayerCount--` added to the `usingCommitment` branch in `buyTickets()`.
---
L-01 (Internal audit / Low) -- payUpgradeBlock() did not update draw revenue counters
Severity: Low | Status: Resolved (two lines added)
Location: `payUpgradeBlock()`
Finding: Every other fund-receiving function updates `currentDrawTicketTotal` and `currentDrawNetTicketTotal`. `payUpgradeBlock()` injected `OG\_PREPAY\_AMOUNT` ($80) directly into `prizePot` but skipped these counters. At draw 10, `\_lockOGObligation()` seeds `avgNetRevenuePerDraw` with `currentDrawNetTicketTotal`. In every subsequent draw, the EMA update uses `currentDrawNetTicketTotal`. Any block payments made on those draws were invisible to the breath formula, causing a systematic conservative bias.
Fix: `currentDrawTicketTotal += blockAmt` and `currentDrawNetTicketTotal += blockAmt - tSlice` added to `payUpgradeBlock()`.
---
L-02 (Internal audit / Low) -- Three dead constants removed
Severity: Low | Status: Resolved (removed)
Location: Constants block
Three constants with no callers removed. All annotated with removal rationale:
`DRAWS\_FROM\_OBLIGATION\_LOCK = 42` -- had one caller (`\_currentTrajectoryTarget()`) removed in v2.73. Computable off-chain as `TOTAL\_DRAWS - WEEKLY\_OG\_REGISTRATION\_DEADLINE - 1`.
`BREATH\_STEP\_UP = 50` -- upward pre-lock auto-step was removed when predictive breath replaced the two-layer step system. Pre-lock only steps DOWN.
`NON\_SEED\_BPS = 9000` -- was the C-01 buggy divisor. Post-fix the formula divides by 10000. No callers remained.
Internal audit's static analyser flags orphaned constants regardless of annotations. Removal is cleaner than documentation.
---
L-03 (Internal audit / Low) -- _getCurrentTreasuryBps() was an unnecessary indirection
Severity: Low | Status: Resolved (function removed, callers inlined)
Location: `\_getCurrentTreasuryBps()`, 4 call sites
Finding: The function returned `TREASURY\_BPS` unconditionally with no logic. It was presumably retained from a design iteration where the treasury rate was context-dependent (exhale vs inhale). v2.75 collapsed it to a flat 15%. The indirection signalled to readers that the rate might vary -- it does not.
Fix: All 4 call sites now reference `TREASURY\_BPS` directly. Function removed.
---
I-02 (Internal audit / Info) -- Dual-claim path for qualified weekly OGs undocumented
Severity: Info | Status: Resolved (NatSpec added to `claimEndgame()`)
Location: `claimEndgame()`
Finding: Qualified weekly OGs can call both `claimDormancyRefund()` (ticket cost refund from `dormancyWeeklyPool`) and `claimEndgame()` (endgame share from `endgameOwed`). Both calls succeed. The guard `dormancyTimestamp > 0 \&\& p.isUpfrontOG` blocks only upfront OGs. This is intentional -- upfront OGs did not buy weekly tickets and have no claim on `dormancyWeeklyPool`. Qualified weekly OGs earned their endgame entitlement through 40 consecutive draws. The two pools are funded separately. Without documentation, Internal audit would flag this as an undocumented design decision.
Fix: NatSpec added to `claimEndgame()` explaining the dual-claim design, the asymmetric guard rationale, and confirming that `qualifiedWeeklyOGCount` is intentionally not decremented at dormancy claim time.
---
I-03 (Internal audit / Info) -- setReserveFeeds() cross-check finding was INCORRECT
Status: Not a finding -- already implemented in v1.0.
The audit flagged that `setReserveFeeds()` does not cross-check reserve feeds against `priceFeeds\[]`. This cross-check is present at lines 1173-1177 of v1.4 (and has been since v1.0):
```solidity
for (uint256 i = 0; i < NUM\_RESERVES; i++) {
    if (\_reserveFeeds\[i] == address(0)) continue;
    for (uint256 k = 0; k < NUM\_ASSETS; k++) {
        if (priceFeeds\[k] == \_reserveFeeds\[i]) revert InvalidAddress();
    }
}
```
No change required.
---
Carry-forward items -- pending audit submission
AUDIT-03: `getProjectedEndgamePerOG()` return value named `obligation` is the calibrated total endgame pool target, not a per-OG figure. NatSpec clarification pending.
Architecture note (breath compounding): The linear approximation in the predictive breath formula diverges from true compounding at high breath rates late in the game. A worked numerical proof of the acceptable divergence envelope is required for the audit submission narrative. This is a proof document / simulation, not a code change.
EMA alpha (I-01): Alpha = 0.5 is deliberately reactive. A slower decay (e.g. 0.25) is more conservative for OG pot protection. This is a design question flagged for the submission narrative -- document the choice and rationale rather than change the formula.
---
[v1.6]: Fresh Audit Pass -- Code Cleanup and Gas Safety
Date: March 2026
Lines: 3,894
Audit result: 0C 0H 0M 3L 3I resolved. No logic changes to game mechanics.
Source audit: Internal triple audit review of v1.5.
---
L-01 new (Internal audit / Low) -- payUpgradeBlock() reset pool limitation documented
Severity: Low | Status: Resolved (NatSpec added)
Location: `payUpgradeBlock()` NatSpec
Finding: The v1.5 L-01 fix correctly added block payments to `currentDrawNetTicketTotal` for EMA accuracy. Side effect: `emergencyResetDraw()` uses that counter to fund `resetDrawRefundPool`. Upfront OGs cannot call `claimResetRefund()`. If a draw is reset in the same window as a block payment, the upgrader's $80 is swept to charity after 30 days rather than returned.
Not theft -- funds go to charity. Scenario requires an emergency reset in the same draw window as a block payment. Rare, bounded, not fixable without a separate counter that would add complexity.
Fix: NatSpec warning added to `payUpgradeBlock()` documenting the limitation, the mechanism, and the bounded economic exposure.
---
L-02 (Internal audit / Low) -- BREATH_CEIL_BPS dead constant missed in v1.5 pass
Severity: Low | Status: Resolved (removed)
Location: Constants block
Finding: `BREATH\_CEIL\_BPS = 2000` was declared but has no callers. `setBreathRails()` validates against `ABSOLUTE\_BREATH\_CEILING`. `\_checkAutoAdjust()` clamps against `breathRailMax`. Neither reads `BREATH\_CEIL\_BPS`. Was not identified in the v1.4 audit and missed in the v1.5 L-02 dead constant removal pass.
Fix: Constant removed with explanation comment.
---
L-03 (Internal audit / Low) -- claimSignupRefund() lacks treasury underflow safety floor
Severity: Low | Status: Resolved (two lines added)
Location: `claimSignupRefund()`
Finding: `claimOGIntentRefund()` protects against treasury underflow with an explicit safety floor when pulling from treasury. `claimSignupRefund()` did not -- it used a bare `treasuryBalance -= fromTreasury`. In Solidity 0.8.x this reverts on underflow rather than wrapping. If treasury is depleted by commitment deposits from many declined OGs (each keeping 15% of their transfer), the last few `claimSignupRefund()` callers would revert permanently with no recovery path until an owner treasury injection.
Fix: Safety floor added mirroring `claimOGIntentRefund()`:
```
if (treasuryBalance >= fromTreasury) {
    treasuryBalance -= fromTreasury;
} else {
    treasuryBalance = 0;
}
```
---
I-01 (Internal audit / Info) -- Three dead error declarations removed
Severity: Info | Status: Resolved (removed)
Location: Custom errors block
Three errors declared but never used in any `revert` statement:
`NoActiveResetRefundPool` -- prior version of the reset refund guard before dual-pool architecture
`ResetRefundAlreadyClaimed` -- superseded by the `resetRefundClaimedAtDraw` field check pattern
`UpfrontOGRegistrationClosed` -- `registerAsOG()` in ACTIVE reverts `NotWeeklyOG()` instead
Internal audit's static analyser flags unused error declarations. Removed with explanation comment.
---
I-02 (Internal audit / Info) -- Dead DormancyEndgame event removed
Severity: Info | Status: Resolved (removed)
Location: Events block
`event DormancyEndgame(uint256 perOG, uint256 charityAmount, uint256 qualifiedOGs)` was declared but never emitted. `sweepDormancyRemainder()` uses `DormancyRemainderSwept` and `CharityClaimed` instead. Removed with explanation comment.
---
I-03 (Internal audit / Info) -- _continueUnwind() per-iteration gas guard added
Severity: Info (Gas Safety) | Status: Resolved (guard added)
Location: `\_continueUnwind()`
Finding: `MAX\_UNWIND\_PER\_TX = 3000`. In the worst case, each OG iteration reverts both `weeklyOGStatusLost` and `mulliganUsed` status, writing 6-8 storage slots (~120K gas per iteration). At 3000 entries: ~360M gas -- 11x Arbitrum's block gas limit. The 150K entry guard at the function top does not protect against the loop body itself exhausting the block. A revert mid-loop does NOT advance `emergencyUnwindIndex`, so the same oversized batch is retried on the next call. The unwind is bricked.
Normal case (clean reads, no status changes) is ~500 gas per iteration = 1.5M total. The risk is real only when many OGs simultaneously changed status in the reset draw.
Fix: Per-iteration gas check added inside the loop:
```solidity
if (gasleft() < 50\_000) {
    end = i;  // save how far we got
    break;
}
```
`emergencyUnwindIndex = end` is written after the loop, so partial progress is always saved. The next call resumes exactly where this one stopped. No batch can brick the unwind regardless of status-change density.
---
Carry-forward items -- pending audit submission
AUDIT-03: `getProjectedEndgamePerOG()` return value `obligation` label ambiguity. NatSpec clarification pending.
EMA alpha (I-04): Alpha = 0.5 should be documented as a deliberate design choice in `\_checkAutoAdjust()` NatSpec. Auditors will ask why fast decay was preferred.
Architecture note (breath compounding): Linear approximation diverges from true compounding at high breath rates. Worked proof document showing acceptable divergence envelope required for submission narrative.
---
[v1.7]: NatSpec Coverage Pass
Date: March 2026
Lines: 4,017
NatSpec lines: 427 (10.6%, up from 8.0% in v1.6)
Changes: Documentation only. No logic, constants, events, or errors modified. ABI identical to v1.6.
A full NatSpec audit identified 66 public/external functions. 16 were fully documented. 1 was missing both @notice and @dev. 49 had @notice but no @dev. This version addresses the 12 highest-priority functions -- those with complex guard logic, multi-path behaviour, or audit-critical design choices that are not obvious from the function name alone.
---
Functions documented in this version
pruneStaleOGs() -- was missing both @notice and @dev. Now documents: swap-and-pop removal mechanic, which player types are pruned, field clearing, IDLE phase requirement, maxPrune batch bound.
registerAsWeeklyOG() -- @dev documents: PREGAME/ACTIVE dual entry paths, consecutive streak requirement for ACTIVE registration, commitment credit application, prepaidCredit top-up for upgradeToUpfrontOG(), intent queue conflict guard, OG cap formula.
buyTickets() -- @dev documents: one-call-per-draw guard, 5-bit packed picks format, inhale/exhale ticket count rules, treasury slice, prepaidCredit consumption order, draw-1 commitment credit and committedPlayerCount decrement (M-02), player capacity accounting.
processMatches() -- @dev documents: two-phase OG-then-non-OG structure, ogMatchingDone flag, _matchAndCategorize() scoring, skip conditions for picks=0 and statusLost OGs, mulligan logic, automatic DISTRIBUTING transition.
distributePrizes() -- @dev documents: tier iteration order, per-winner credit to unclaimedPrizes, currentTierPerWinner set-once-per-tier pattern, dust handling, JP miss redistribution path, seed return to prizePot, distTierIndex/distWinnerIndex resumption tracking.
finalizeWeek() -- @dev documents: normal vs RESET_FINALIZING dual path, lapse marking, schedule anchoring, TOTAL_DRAWS game-close transition, relationship to _lockOGObligation().
activateDormancy() -- @dev documents: yield capture, dormancyOGPool pro-rata calculation, partial cover flag, dormancyWeeklyPool remainder, prizePot zeroing, DORMANCY_CLAIM_WINDOW before sweep.
claimDormancyRefund() -- @dev documents: three refund paths (upfront OG, weekly OG, regular buyer), upgrader cap at totalPaid, prepaidCredit return, cross-reference to dual-claim design (I-02).
sweepDormancyRemainder() -- @dev documents: Aave exit, endgame distribution to qualified weekly OGs, calibrated cap, charity surplus, endgameOwed set to ogTotal only, intentional qualifiedWeeklyOGCount retention, upfront OG exclusion.
setBreathRails() -- @dev documents: absolute bound constraints, immediate breathMultiplier clamp behaviour, no-timelock rationale (carry-forward C-04), why rails alone cannot extract funds.
executeFeedChange() -- @dev documents: lastValidPrices/weekStartPrices zeroing for clean feed start, duplicate feed cross-check, pendingFeedChanges cleanup.
emergencyResetDraw() -- @dev documents: caller eligibility (owner vs public timeout), fund recovery from in-progress distribution, two refund pool paths, unwind reversal of status changes, per-iteration gas guard, RESET_FINALIZING transition.
---
Remaining lower-priority functions (no @dev, not critical path)
The following 37 functions have @notice but no @dev. These are simple, self-explanatory, or covered by their @notice alone. No action required for audit submission:
`renounceOwnership`, `transferOwnership`, `acceptOwnership`, `register`, `topUpCredit`, `registerInterest`, `payCommitment`, `setReserveFeeds`, `submitPicks`, `claimUnusedCredit`, `claimCharity`, `sweepUnclaimedEndgame`, `sweepUnclaimedPrizes`, `proposeDormancy`, `cancelDormancy`, `sweepFailedPregame`, `claimCommitmentRefund`, `sweepResetRefundRemainder`, `markLapsed`, `batchMarkLapsed`, `claimPrize`, `withdrawTreasury`, `proposePrizeRateReduction`, `executePrizeRateReduction`, `cancelPrizeRateReduction`, `cancelPrizeRateIncrease`, `proposePrizeRateIncrease`, `executePrizeRateIncrease`, `cancelBreathOverride`, `proposeAaveExit`, `executeAaveExit`, `cancelAaveExit`, `activateAaveEmergency`, `proposeFeedChange`, `cancelFeedChange`, `getCreditBalance`, `getWeekPerformance`, `getOGListIndex`.
---
[v1.71]: forceDeclineIntent + Batch Size Guards
Date: March 2026
Lines: 4,128
Changes: 1 new function, 1 new event, 2 guard additions. No logic changes to existing functions.
---
NEW: forceDeclineIntent() -- Owner escape valve for PENDING+isWeeklyOG stuck state
Severity: High (operational risk) | Status: Resolved (function added)
Location: New function in OG intent queue section, between sweepExpiredDeclines() and registerAsWeeklyOG()
The stuck state:
A player can call registerAsOG() (enters queue as PENDING) and then registerAsWeeklyOG() (isWeeklyOG = true). When confirmOGSlots() reaches this player, the backstop check fires: `if (p.isWeeklyOG) continue` -- the slot is skipped and pendingIntentCount is NOT decremented. startGame() requires `pendingIntentCount == 0`. Without an escape valve, one such player -- whether griefing, unresponsive, or holding a lost wallet -- can block the entire game from launching indefinitely.
The prior mitigation was off-chain contact + player self-exit via claimOGIntentRefund(). This is fragile. A griefer has no incentive to exit. A lost wallet cannot.
The fix:
`forceDeclineIntent(address\[] calldata players\_)` allows the owner to force-decline up to 100 PENDING or OFFERED intent entries in one call.
Key design decisions:
100% refund -- this is owner-forced, not voluntary. The player did nothing wrong by ending up in this state. Unlike claimOGIntentRefund() which keeps 15% as a commitment deposit, this function returns the full ogIntentAmount. Pulls from prizePot first, then treasuryBalance, with safety floors on both.
PENDING path -- decrements pendingIntentCount, unblocking startGame().
OFFERED path -- also reverses OG status (isUpfrontOG = false, swap-and-pop from ogList, upfrontOGCount--). Handles the case where a player was offered a slot and neither accepted nor declined.
Distinct event -- `OGIntentForcedDeclined(player, refund, grossAmount)` with no depositKept field, distinguishable from voluntary `OGIntentDeclined` by indexers.
CEI compliant -- all state changes before transfer.
nonReentrant -- standard protection.
Batch cap 100 -- prevents accidental gas exhaustion.
---
L-05 (Internal audit / Low) -- Batch size guards added to confirmOGSlots() and pruneStaleOGs()
Severity: Low | Status: Resolved
Location: confirmOGSlots(), pruneStaleOGs()
Both functions accept caller-supplied batch sizes with no upper bound. Owner-only so gas revert is the practical backstop, but unbounded input is bad hygiene Auditors will flag.
confirmOGSlots: `if (batchSize > 1000) revert ExceedsLimit()`
pruneStaleOGs: `if (maxPrune > MAX\_LAPSE\_BATCH) revert ExceedsLimit()` (500, consistent with batchMarkLapsed)
---
[v1.72]: forceDeclineIntent Audit Follow-Up + setBreathRails Timelock
Date: March 2026
Lines: 4,198
Changes: 2M fixes, 1 new function pattern, 4L fixes, 2I NatSpec corrections. C-04 carry-forward resolved.
---
M-01 -- forceDeclineIntent() refund zero bug
Severity: Medium | Status: Resolved
Location: `forceDeclineIntent()` refund calculation
After both `prizePot` and `treasuryBalance` were zeroed, `refund` was overwritten as `prizePot + treasuryBalance = 0 + 0 = 0`. Player received nothing. `\_withdrawAndTransfer(player, 0)` transferred nothing. Event emitted `refund=0, amount=nonzero`.
Fix: Snapshot `availablePot = prizePot` before zeroing. Then `refund = availablePot + treasuryBalance` uses the pre-zero values.
---
M-02 -- setBreathRails() timelocked (resolves C-04 carry-forward)
Severity: Medium | Status: Resolved
Location: `setBreathRails()` replaced by `proposeBreathRails()` / `executeBreathRails()` / `cancelBreathRails()`
Without a timelock, a compromised owner key could instantly set `breathRailMin = breathRailMax = 2000`, clamping the predictive formula to 20% and extracting 20% of prizePot in the next draw. The NatSpec justification ("rails alone cannot extract funds") was insufficient for submission. 7-day `TIMELOCK\_DELAY` now matches all other rate controls. C-04 is resolved.
New state: `pendingBreathRailMin`, `pendingBreathRailMax`, `breathRailsEffectiveTime`. New events: `BreathRailsProposed`, `BreathRailsProposalCancelled`.
---
L-01 -- forceDeclineIntent() Aave failure reverts whole batch
Severity: Low | Status: Resolved
Location: `forceDeclineIntent()` loop, `\_withdrawAndTransfer`
Single Aave withdrawal failure rolled back all state changes for all players in the batch. Stuck player could not be unblocked. Fix: `\_withdrawAndTransfer` wrapped in `try this.\_externalTransfer() catch`. State changes (DECLINED status, ogList cleanup, count decrements) are committed regardless of transfer outcome. Failed transfers emit `OGIntentForceDeclineFailed(player, amount)` so owner can arrange off-chain recovery.
`\_externalTransfer()` is a public helper with `onlySelf` guard (`msg.sender != address(this)` reverts). Required because Solidity try/catch only works on external calls.
---
L-02 -- upfrontOGCount bare decrement in forceDeclineIntent
Severity: Low | Status: Resolved
Added `if (upfrontOGCount > 0) upfrontOGCount--` consistent with all other decrement sites.
---
L-03 -- ogIntentWindowExpiry not cleared in forceDeclineIntent OFFERED path
Severity: Low | Status: Resolved
Added `ogIntentWindowExpiry\[player] = 0` in OFFERED branch. Mirrors `claimOGIntentRefund()` and `sweepExpiredDeclines()`.
---
L-04 / L-05 -- Two stale RUNBOOK comments
Severity: Low | Status: Resolved
`startGame()` NatSpec and `confirmOGSlots()` backstop comment both said "no owner force-exit exists." Updated to reference `forceDeclineIntent()` as the primary resolution path.
---
I-01 -- forceDeclineIntent NatSpec: $10 commitment credit not in refund
Severity: Info | Status: Resolved (NatSpec)
Added clarification: a prior $10 commitment fee applied as credit at OG registration reduced `ogTransfer` and is not included in `ogIntentAmount`. The forced refund returns 100% of `ogIntentAmount` -- the $10 is a separate prior payment and is not restored.
---
I-05 -- finalizeWeek() NatSpec described actions that happen elsewhere
Severity: Info | Status: Resolved (NatSpec corrected)
`finalizeWeek()` does not mark lapsed players or update streak tracking. Those are `markLapsed()`/`batchMarkLapsed()` (owner-called) and `\_updateStreakTracking()` (called from `buyTickets()`). NatSpec now accurately describes only what this function does.
---
[v1.73]: proposeBreathRails/executeBreathRails Audit Follow-Up
Date: March 2026
Lines: 4,255
Changes: 1M fix, 6L fixes, 2I NatSpec. All consequences of new breath rails timelock introduced in v1.72.
---
M-01 -- proposeBreathRails() and executeBreathRails() lacked gamePhase guard
Severity: Medium | Status: Resolved
Both functions can now only be called in ACTIVE phase with drawPhase IDLE. Without this, a proposal queued in PREGAME could fire 7 days later mid-game with whatever rails the owner chose before deployment. executeBreathRails() in DORMANT/CLOSED would write to dead state. Consistent with proposePrizeRateReduction() which is also ACTIVE-only.
---
L-NEW-01 -- claimDormancyRefund() bare committedPlayerCount--
Severity: Low | Status: Resolved
Changed to `if (committedPlayerCount > 0) committedPlayerCount--`. Consistent with all other decrement sites. One line.
---
L-01 -- proposeDormancy() and forceDeclineIntent() did not cancel pending breath rails
Severity: Low | Status: Resolved
Both functions cancel `pendingBreathOverride` when they fire. Neither cancelled `breathRailsEffectiveTime`. Added consistent cancellation block to both, emitting `BreathRailsProposalCancelled`.
---
L-02 -- executeBreathRails() stuck override when clamp == pendingBreathOverride
Severity: Low | Status: Resolved
If rails narrow and breathMultiplier is clamped to newMax, and pendingBreathOverride equals newMax, the override is technically "in range" so not cancelled -- but executing it would revert BreathUnchanged(). Added `|| pendingBreathOverride == breathMultiplier` to the cancellation check.
---
L-03 / I-04 -- _externalTransfer reentrancy and ABI visibility
Severity: Low/Info | Status: Resolved (NatSpec)
Expanded NatSpec on `\_externalTransfer()` explaining: (a) no nonReentrant needed because the only caller forceDeclineIntent() IS nonReentrant, and (b) external visibility is required for try/catch -- the onlySelf guard makes it uncallable by anyone outside the contract.
---
L-04 -- proposeBreathRails() accepted no-op proposals
Severity: Low | Status: Resolved
Added: `if (newMin == breathRailMin \&\& newMax == breathRailMax) revert BreathUnchanged()`. Consistent with proposeBreathOverride() and proposeFeedChange().
---
I-05 -- proposeBreathRails() missing bytes32 reason parameter
Severity: Info | Status: Resolved
Added `bytes32 reason` to `proposeBreathRails()` signature and `BreathRailsProposed` event. Consistent with all other timelocked proposals in the contract.
---
[v1.74]: Knock-on Analysis and Deep Pass Clean-Up
Date: March 2026
Lines: 4,274
Changes: 4 targeted fixes. All consequences of phase-guard analysis on v1.73 changes.
Deep pass: Winner array clearing, emergency reset mid-DISTRIBUTING accounting, scheduleAnchor math, dormancy refund ticket path, closeGame() accounting, upgradeToUpfrontOG() payment drain -- all verified correct on first audit.
---
Knock-on 1 -- Dead breathRails cancel block removed from forceDeclineIntent()
Dead code from v1.73. `forceDeclineIntent()` is PREGAME-only. `proposeBreathRails()` is ACTIVE-only (v1.73 M-01). `breathRailsEffectiveTime` cannot be non-zero in PREGAME. The cancel block cost one SLOAD on every call and could never fire. Removed and replaced with an explanatory comment. The equivalent block in `proposeDormancy()` is retained -- both that function and `proposeBreathRails()` are ACTIVE, so the condition IS reachable there.
---
Knock-on 2 -- emergencyResetDraw() now cancels breathRailsEffectiveTime
`emergencyResetDraw()` cancelled `pendingBreathOverride` but not `breathRailsEffectiveTime`. A pending rails proposal would survive an emergency reset and remain queued for the owner to execute manually. `proposeDormancy()` cancels both. Added consistent cancel block to `emergencyResetDraw()`.
---
I-05 -- proposeBreathOverride() phase guard reordered before _captureYield()
`\_captureYield()` was called before the `gamePhase` guard. If called in DORMANT/CLOSED, the Aave balance read fired unnecessarily before the revert. Phase and drawPhase guards moved to the top of the function. Gas improvement on all invalid-phase calls.
---
L-02 NatSpec -- _checkAutoAdjust() cooldown subtraction safety
Added inline comment explaining why `currentDraw - lastBreathAdjustDraw` cannot underflow: `lastBreathAdjustDraw` is always set to `currentDraw` at adjustment time, and `currentDraw` only increments in `finalizeWeek()` after `\_checkAutoAdjust()` has already run. Prevents future modification errors.
---
[v1.75]: Final Pre-Submission NatSpec Pass
Date: March 2026
Lines: 4,296
Changes: 2 NatSpec additions. No logic changes. audit submission ready.
---
I-02 (carry-forward) -- EMA alpha = 0.5 documented
Location: `\_checkAutoAdjust()`, post-lock EMA update
Added inline comment explaining the design choice: alpha = 0.5 (2-period SMA) was chosen for fast convergence on the short 42-draw post-lock window. A slower alpha (0.1-0.25) would take 8-10 draws to incorporate new revenue signals -- too slow for a game where player count can swing materially week to week. The predictive formula recalculates every draw and self-corrects; EMA reactivity is a feature, not a bug.
---
AUDIT-03 (carry-forward) -- obligation return value clarified
Location: `getProjectedEndgamePerOG()` NatSpec
Added explicit clarification: `obligation` is the total calibrated endgame pool target across all OGs combined -- not a per-OG promise. Front-ends must not display `obligation` as a player's expected payout. Use `currentPerOG` for that. `obligation` is a dashboard metric for pot health vs target. Cross-references closeGame() T-03 NatSpec for the full calibrated cap design explanation.
---
Companion document: Breath Compounding Proof
File: `Pick432\_1Y\_Breath\_Compounding\_Proof.md`
Full-game simulation confirming the linear approximation in the predictive breath formula is acceptable. Key findings:
Self-correcting: per-draw recalculation means errors cancel, not compound.
Approximation error: under $700 ($0.29% of requiredEndPot) in worst case.
Draw 52 exact landing: hard floor -- formula error cannot cause OG pot undershoot.
Scenarios where pot falls short are genuine economic underfunding (insufficient tickets), not formula defects. Exact compounding gives the same result.
---
Internal audit Submission Status
All open findings resolved. No C, H, or M issues remain. Carry-forwards documented:
Item	Status
EMA alpha 0.5	Documented in code (v1.75)
AUDIT-03 obligation label	Clarified in NatSpec (v1.75)
Breath compounding proof	Simulation document produced (v1.75)
forceDeclineIntent commitment credit gap	NatSpec acknowledges $10 not refunded (v1.72)
---
[v1.76]: Fresh Area Audit -- sweepFailedPregame Fix + NatSpec Pass
Date: March 2026
Lines: 4,326
Changes: 1 code fix, 4 NatSpec clarifications. Clean audit pass on previously unexamined areas.
---
L-01 -- sweepFailedPregame() deployment-day bricking vector
Severity: Low | Status: Resolved
`committedPlayerCount` is zero at deployment. `allRefunded = committedPlayerCount == 0` was immediately true, allowing any actor to call `sweepFailedPregame()` before a single player committed, permanently setting `gamePhase = CLOSED, gameSettled = true`. No funds are lost (nothing in the contract yet) but the deployment is permanently bricked.
Fix: `bool allRefunded = committedPlayerCount == 0 \&\& block.timestamp >= signupDeadline`
The "all refunded" path now only opens after the signup deadline has passed, preventing immediate-post-deployment exploitation.
---
L-02 -- transferOwnership() acceptance window is a sliding deadline, not a hard one
Severity: Low | Status: Resolved (NatSpec)
Calling `transferOwnership()` again before `acceptOwnership()` resets `ownershipTransferExpiry` to a fresh 7 days. The window can be extended indefinitely. NatSpec now documents this explicitly.
---
I-01 -- proposePrizeRateReduction/Increase drawPhase asymmetry
Severity: Info | Status: Resolved (NatSpec)
Both rate proposal functions intentionally permit calls during active draw phases (no drawPhase guard at proposal time). This differs from breath proposals which require IDLE. NatSpec added to both functions explaining the asymmetry is by design -- rate proposals write only to `pendingMultiplier` without reading sensitive financial state.
---
I-04 -- StreakBroken emits for streak-of-1 breaks
Severity: Info | Status: Resolved (NatSpec)
`StreakBroken(addr, 1)` is emitted when a weekly OG misses any draw including their very first. Semantically correct but potentially confusing for front-ends displaying "your streak was broken." NatSpec added: `prevStreak == 1` is a valid emission. Front-ends should filter by threshold if they want to suppress trivial streak events.
---
getPreGameStats readyToStart missing pendingIntentCount
Severity: Info | Status: Resolved (NatSpec)
`readyToStart` returns true even when `pendingIntentCount > 0`, which would cause `startGame()` to revert on `IntentQueueNotEmpty`. NatSpec added directing front-ends to check `pendingIntentCount` separately and use `forceDeclineIntent()` to clear stuck entries.
---
[v1.77]: Three Carry-Forward Resolutions
Date: March 2026
Lines: 4,342
Changes: 2 code fixes, 1 NatSpec. No new findings introduced.
---
M-02 -- activateAaveEmergency() inverted pre-check gate removed
Severity: Medium | Status: Resolved
The prior gate `if (aBalance < effectiveObligation / 2) revert AaveLiquidityLow()` had inverted logic. It blocked emergency Aave exit precisely when Aave liquidity was genuinely failing -- the exact scenario the function exists for. A falling `aBalance` means crisis; the gate treated it as a reason to refuse exit.
Fix: Removed the entire `effectiveObligation` calculation and pre-check. `onlyOwner + nonReentrant` is sufficient access control. The post-withdraw check `if (received < aBalance) revert AaveLiquidityLow()` is retained -- it catches genuine mid-call Aave withdrawal failures, which is a distinct and valid safety check.
---
L-01 -- acceptOwnership() misleading error when no transfer pending
Severity: Low | Status: Resolved
`ownershipTransferExpiry` initialises to zero. `block.timestamp > 0` is always true, so calling `acceptOwnership()` with no pending transfer reverted `OwnershipTransferExpired` -- a lie. The accurate error in this state is `NoTimelockPending`.
Fix: Added `if (ownershipTransferExpiry == 0) revert NoTimelockPending()` before the expiry check.
---
L-03 -- Draw 52 zero-prize edge case
Severity: Low | Status: Resolved (NatSpec -- accepted design)
If `prizePot == requiredEndPot` exactly at draw 52, `surplus = 0`, `weeklyPool = 0`, and all prize tiers pay zero. Players who buy draw 52 tickets in this scenario win nothing. Probability of exact equality is negligible in practice.
Decision: Accepted design. `buyTickets()` does not revert -- participation remains valid even with no prizes available. NatSpec added to `buyTickets()` explaining the edge case and directing front-ends to display projected draw-52 prize pool via `getSolvencyStatus()` so players can make an informed decision.
---
Internal audit Submission Status -- COMPLETE
All findings resolved across v1.0 through v1.77. No C, H, or M issues remain open.
Carry-forward	Resolved
C-04 setBreathRails no timelock	v1.72
EMA alpha 0.5	v1.75
AUDIT-03 obligation label	v1.75
Breath compounding proof	v1.75 doc
M-02 activateAaveEmergency gate	v1.77
L-01 acceptOwnership misleading error	v1.77
L-03 draw 52 zero-prize	v1.77
Pick432 1Y is ready for audit submission.
---
[v1.77 addendum]: v1.76 Audit Follow-Up (applied to v1.77)
Date: March 2026
Note: Four additional items from the v1.76 triple audit applied directly to v1.77.
Duplicate @notice on getPreGameStats -- removed
The v1.76 NatSpec addition left the original `@notice Returns a summary of PREGAME signup progress` alongside the new one. Internal audit NatSpec pass would flag it. Removed the stale tag.
L-02 carry-forward -- buyTickets() silent commitment clear now decrements committedPlayerCount
`if (p.commitmentPaid \&\& currentDraw > 1 \&\& commitmentRefundPool == 0)` silently zeroed `p.commitmentPaid` without decrementing `committedPlayerCount`. Every other clear site uses `if (committedPlayerCount > 0) committedPlayerCount--`. Added the guard. Low probability drift but real counter discrepancy.
distributePrizes() redundant jpPool variable removed
`uint256 jpPool = tierPools\[0]` was declared inside the JP miss block where `pool = tierPools\[distTierIndex]` was already in scope and equal (distTierIndex == 0 at that point). Replaced `jpPool` with `pool` throughout. Cosmetic -- no logic change.
sweepResetRefundRemainder() permissionless design documented
Added NatSpec explaining the intentional lack of `onlyOwner`: any caller can sweep expired pools so the protocol does not depend on owner liveness. Phase-gating confirmed to make DORMANT and CLOSED routing mutually exclusive. Auditors will ask about the missing access control -- now answered in code.
---
[v1.78]: Group B+C Registration Flow Audit
Date: March 2026
Lines: 4,389
Changes: 2 code fixes (6 lines total), 4 NatSpec additions. Clean pass on registration flows.
---
L-01 -- _cleanupOGOnRefund() four bare decrements guarded
Severity: Low | Status: Resolved
`upfrontOGCount--`, `weeklyOGCount--`, `earnedOGCount--`, and `committedPlayerCount--` were all unguarded. In Solidity 0.8.x an underflow on any of these reverts the entire transaction -- permanently bricking `claimSignupRefund()` for that player if any invariant ever broke. All four now use `if (x > 0) x--`, consistent with every other decrement site in the contract.
---
L-02 -- _cleanupOGOnRefund() SWEPT branch added
Severity: Low | Status: Resolved
`sweepExpiredDeclines()` sets `ogIntentStatus = SWEPT` but never clears `ogIntentAmount`. A SWEPT player calling `claimSignupRefund()` on a failed pregame arrived in `\_cleanupOGOnRefund()` with a stale non-zero `ogIntentAmount` in storage. No funds at risk -- the money was already routed at registration -- but misleading to auditors and off-chain tooling. Added `else if (ogIntentStatus\[addr] == OGIntentStatus.SWEPT) { ogIntentAmount\[addr] = 0; }` branch.
---
L-03 NatSpec -- cancelPrizeRateReduction/Increase direction check
Severity: Low (confirmed safe) | Status: Resolved (NatSpec)
The cancel functions distinguish reduction from increase by comparing `pendingMultiplier` to `prizeRateMultiplier` at cancel time. Auditor confirmed safe: `prizeRateMultiplier` only changes via execute functions that simultaneously clear `pendingMultiplier`, so a pending proposal and a changed multiplier cannot coexist. NatSpec added to both functions.
---
I-01 NatSpec -- register() and topUpCredit() mid-draw permitted by design
Severity: Info | Status: Resolved (NatSpec)
Neither function has a `drawPhase` guard, unlike `buyTickets()`. Intentional: the state they write (`prepaidCredit`, `totalPrepaidCredit`) is draw-agnostic. Internal audit asymmetry question pre-answered in NatSpec on both functions.
---
I-03 NatSpec -- withdrawTreasury() phase-unrestricted by design
Severity: Info | Status: Resolved (NatSpec)
`withdrawTreasury()` works at any game phase. Intentional: treasury is protocol revenue (15% slices), segregated from all player-facing pools. Withdrawing during DORMANT or CLOSED cannot reduce player refund entitlements. NatSpec added with explicit reference to the pool separation.
---
[v1.79]: Group C+D Audit
Date: March 2026
Lines: 4,418
Changes: 2 code fixes, 4 NatSpec additions, 1 cosmetic. Clean audit pass on Aave/feed/lapse functions.
---
Duplicate @notice removed from cancelPrizeRateReduction()
The v1.78 NatSpec addition accidentally left the original `@notice` alongside the new one. Cosmetic carry-forward from v1.78 audit. Removed.
---
L-02 -- _withdrawAndTransfer() transfers amount not received
Severity: Low | Status: Resolved
`safeTransfer(recipient, received)` was used instead of `safeTransfer(recipient, amount)`. The `received >= amount` guard already ran, confirming funds exist. Transferring `received` instead of `amount` could send Aave-return dust to the recipient and leave the contract USDC balance marginally below accounting expectations. Changed to `safeTransfer(recipient, amount)`. The `received` variable is retained for the guard check only.
---
I-03 -- proposeFeedChange() missing SEQUENCER_FEED guard
Severity: Info (one-line fix applied) | Status: Resolved
`SEQUENCER\_FEED` was not in the address exclusion list. An owner could accidentally propose replacing a price feed with the sequencer uptime feed address (which returns 0/1, not an asset price). `\_readPrice()` would silently fall back to `lastValidPrices` rather than reverting. Added `if (SEQUENCER\_FEED != address(0) \&\& newFeed == SEQUENCER\_FEED) revert InvalidAddress()`. The null check handles networks where the sequencer feed is not set.
---
I-01 NatSpec -- proposeAaveExit() no phase guard
Severity: Info | Status: Resolved (NatSpec)
No `gamePhase` or `drawPhase` guard. Intentional: the 7-day timelock is the protection. `\_withdrawAndTransfer()` handles `aaveExited` correctly throughout the draw cycle. NatSpec added.
---
I-02 NatSpec -- batchMarkLapsed() silent skip behaviour
Severity: Info | Status: Resolved (NatSpec)
Players failing guard conditions are silently skipped with no event or revert. Operators get no on-chain trace of which addresses were skipped. NatSpec added directing operators to `markLapsed()` (single-address, reverts on failed guards) for validation.
---
L-01 NatSpec -- proposeFeedChange() concurrent pending changes confirmed safe
Severity: Low (confirmed safe) | Status: Resolved (NatSpec)
`executeFeedChange()` re-runs the cross-check at execution time, not just proposal time. Concurrent proposals cannot produce a duplicate-feed state regardless of ordering. NatSpec added to `proposeFeedChange()`.
---
[v1.80]: Group D Remaining + Group E View Function Audit
Date: March 2026
Lines: 4,468
Changes: 5 NatSpec additions. No code changes. Clean pass on view functions.
---
L-02 -- getProjectedEndgamePerOG() /9000 vs /10000 buffer documented
Severity: Low (confirmed correct design) | Status: Resolved (NatSpec)
`requiredEndPot` uses `/9000` while `obligation` and `maxPerOG` use `/10000`, making `requiredEndPot` approximately 11% larger than the minimum needed to pay `obligation` in full. `potHealth = 10000` means the breathing target is reached -- not that payouts are exactly covered.
The ~11% buffer serves two simultaneous purposes documented in the NatSpec:
(a) Safety margin: Throughout draws 10-51, the pot can fall up to ~11% below `requiredEndPot` and OG endgame payouts remain on track. The breathing formula tightens prizes before any shortfall becomes critical.
(b) Final prize pool: At draw 52, surplus = `prizePot - requiredEndPot` flows entirely to players as prizes. The buffer is not retained by the protocol. A pot landing above `requiredEndPot` pays the full excess as prizes -- not just the ~11%. Front-ends should present `potHealth = 10000` as "OG obligations fully covered with safety buffer intact."
---
I-01 -- getPlayerInfo() boughtThisWeek false positive in PREGAME
Severity: Info | Status: Resolved (NatSpec)
In PREGAME, `currentDraw == 0` and `p.lastBoughtDraw` initialises to 0 for all players. `boughtThisWeek = (p.lastBoughtDraw == currentDraw)` is therefore true for every player before the game starts. No funds at risk -- `buyTickets()` requires ACTIVE phase. Front-ends should suppress or ignore `boughtThisWeek` when `gamePhase != ACTIVE`.
---
I-02 -- getCurrentPrizeRate() returns 0 at draw 52, but draw 52 prizes exist
Severity: Info | Status: Resolved (NatSpec)
At `currentDraw == TOTAL\_DRAWS`, this function returns 0. Draw 52 prizes come from the exact-landing branch (`prizePot - requiredEndPot`), independent of `breathMultiplier`. A front-end displaying "0% prize rate" at draw 52 would mislead players. NatSpec directs front-ends to `getSolvencyStatus()` for projected draw 52 prizes.
---
I-03 -- getWeekPerformance() type(int256).min sentinel undocumented
Severity: Info | Status: Resolved (NatSpec)
When an asset has no valid price at any stage (no weekStart, no current, no lastValid fallback), performance is set to `type(int256).min`. Front-ends treating this as a real performance figure would display absurdly negative numbers. Documented as a sentinel meaning "no data."
---
I-04 -- encodePicks() silent truncation undocumented
Severity: Info | Status: Resolved (NatSpec)
Inputs > 31 are silently masked: `rank1 = 32` becomes `0`. The result is a valid-looking but wrong picks value. Callers must validate with `isValidPicks()`. Documented with a concrete example.
---
[v1.81]: Regression Pass
Date: March 2026
Lines: 4,474
Changes: 2 fixes. No new findings from full regression pass.
---
I-01 -- Duplicate @notice on proposeFeedChange() removed
Cosmetic. The v1.79 NatSpec block was inserted after the original `@notice` without removing it. Identical duplicate on lines 3472-3473. One line removed.
---
I-02 -- claimOGIntentRefund() OFFERED path two unguarded decrements
Severity: Info | Status: Resolved
`upfrontOGCount--` and `committedPlayerCount--` in the OFFERED path had no `> 0` guards. Both are logically safe -- the corresponding increments are guaranteed before OFFERED status is reachable. However they were inconsistent with every other decrement site in the contract. Guards added: `if (upfrontOGCount > 0) upfrontOGCount--` and `if (!ogIntentUsedCredit\[msg.sender] \&\& committedPlayerCount > 0) committedPlayerCount--`.
---
[v1.82]: Internal audit / OZ / Internal audit Simulation Pass
Date: March 2026
Lines: 4,504
Changes: 3 code fixes, 1 NatSpec, 1 dead-code removal.
---
M-01 (Internal audit Medium) -- upgradeToUpfrontOG() bare decrements
Severity: Medium | Status: Resolved
`weeklyOGCount--` and `earnedOGCount--` had no `> 0` guards. Same issue as v1.78 (claimOGIntentRefund OFFERED path) and v1.81 (claimOGIntentRefund OFFERED path again). Under correct invariants both counters are positive when reached. But an underflow to `type(uint256).max` would permanently corrupt all OG cap checks, solvency checks, and endgame accounting. Added `if (weeklyOGCount > 0) weeklyOGCount--` and `if (earnedOGCount > 0) earnedOGCount--`.
---
L-01 (Internal audit Low) -- Commitment credit unrecoverable on voluntary exit + game failure
Severity: Low | Status: Resolved (accepted design, NatSpec)
After `claimOGIntentRefund()`, `p.totalPaid = 0`. If the game later fails, `claimSignupRefund()` reverts `NothingToClaim` since both `totalPaid` and `prepaidCredit` are zero. The ~$8.50 commitment fee net (after treasury slice) remains in prizePot unrecoverable, despite `claimSignupRefund()` documenting a 100% game-failure guarantee.
Decision: Option (b) -- document, not fix. Voluntary exit is an active choice to forfeit the commitment signal permanently, including in the game-failed scenario. Preserving pre-OG `totalPaid` state would require additional state complexity for an $8.50 exposure. NatSpec in `claimOGIntentRefund()` now explicitly documents this behaviour, including a front-end warning to display the consequence before a player confirms voluntary exit.
---
L-02 (Internal audit Low) -- bestIdx uninitialized in resolveWeek() winningResult loop
Severity: Low | Status: Resolved
`uint256 bestIdx` was implicitly initialised to 0 in Solidity. Static analysers flag uninitialized variables used as array indices regardless of loop invariant safety. Changed to explicit `uint256 bestIdx = 0` with a comment confirming the loop always overwrites it.
---
L-03 (OZ Low) -- getProjectedEndgamePerOG() obligation discontinuity at settlement
Severity: Low | Status: Resolved
The settled path returned raw `ogEndgameObligation`, while the live path returns `ogEndgameObligation \* targetReturnBps / 10000`. At maximum OG concentration (`targetReturnBps = 4000`), this caused a ~60% drop in the returned `obligation` value the moment `closeGame()` fired. Dashboards watching this over time would see a sudden crash at settlement. Fixed: settled path now returns `ogEndgameObligation \* targetReturnBps / 10000` for consistent semantics across both paths.
---
I-01 (OZ Info) -- Dead SEQUENCER_FEED null check removed
Severity: Info | Status: Resolved
`if (SEQUENCER\_FEED != address(0) \&\& newFeed == SEQUENCER\_FEED)` -- the first condition is permanently true because the constructor (C-03, v1.1) reverts if `\_sequencerFeed == address(0)`, and `SEQUENCER\_FEED` is immutable. Simplified to `if (newFeed == SEQUENCER\_FEED) revert InvalidAddress()`.
---
[v1.83]: Internal audit Second Pass
Date: March 2026
Lines: 4,535
Changes: 2 code fixes, 1 code change, 1 NatSpec. No new C/H/M findings.
Finding	Fix
AUDIT-L-01 emergencyResetDraw missing dormancyEffectiveTime cancel	Added cancel block alongside existing breath cancellations
AUDIT-I-01 (false positive) dual @notice on getPlayerInfo	Already clean in v1.81
AUDIT-I-01 assembly length-zero orphaned storage	Comment added at all 3 assembly clear sites
AUDIT-I-01 registerAsOG ACTIVE terminal revert misleads non-weekly callers	revert NotWeeklyOG() → revert WrongPhase()
AUDIT-I-02 proposeFeedChange missing reserveFeeds cross-check	4-line loop added rejecting any reserveFeeds address
---
[v1.84]: Internal audit Pass 2 -- Structural Fixes
Date: March 2026
Lines: 4,589
Changes: 2 structural code fixes (new storage fields), 1 logic fix, 2 NatSpec.
---
AUDIT-L-01 -- Dual reset pool snapshot overwrite permanently blocks pool1 recovery
Severity: Low | Status: Resolved
`lastResetBoughtDraw / lastResetTicketCost` was a single shared pair across both reset pools. The snapshot block in `buyTickets()` and `registerAsWeeklyOG()` used `if / else if` -- pool2 snapshot overwrote pool1. After overwrite, the pool1 eligibility check compared the pool2 draw value against pool1's draw, failed permanently, and the player's pool1 refund entitlement was gone with no recovery path.
Fix: Two independent indexed pairs: `lastResetBoughtDraw1/Cost1` and `lastResetBoughtDraw2/Cost2`. Each pool's snapshot writes only its own pair. Eligibility checks, cost calculations, and cleanup zeroes all updated to use the correctly indexed field. 14 total occurrences updated.
---
AUDIT-L-01 -- upgradeToUpfrontOG() join-by-draw guard bypassable via prior regular play
Severity: Low | Status: Resolved
Guard used `p.firstPlayedDraw` which tracks first `buyTickets()` in ANY capacity. A player who bought tickets as a regular player in draw 1 (`firstPlayedDraw = 1`) could register as weekly OG in draw 5 and upgrade immediately -- `5 <= 1` is false, zero draws as weekly OG required. Economic gap: $100 effective cost vs $1,040 for PREGAME upfront OG.
Fix: New `weeklyOGJoinDraw` field set in `registerAsWeeklyOG()` to `currentDraw`. Guard changed to `currentDraw <= p.weeklyOGJoinDraw`. Field cleared in `\_cleanupOGOnRefund()`.
---
AUDIT-I-01 -- allRefunded fast-track blocked for PENDING credit-path players
Severity: Info | Status: Resolved
`payCommitment()` increments `committedPlayerCount`. When a credit-path PENDING player calls `claimSignupRefund()`, the decrement was gated on `!ogIntentUsedCredit` -- never firing for credit-path players. Ghost count permanently blocked `sweepFailedPregame()` allRefunded fast-track. Decrement now unconditional with `> 0` guard.
---
AUDIT-I-01 / AUDIT-L-01 NatSpec
EMA seed at draw 10 documented as reflecting only draw 10 revenue -- upgrade-window payUpgradeBlock() payments in draws 5-9 are excluded. Conservative bias only.
Dormancy upgrader cap (`p.totalPaid`) clarified as floor-side protection only. High-payUpgradeBlock players receiving full pro-rata refund is accepted design.
---
[v1.85]: CRITICAL Regression Fix + Pass 3 Findings
Date: March 2026
Lines: 4,612
Root cause of C-01 and M-01: The v1.83 AUDIT-I-01 assembly comment insertion (`// \[v1.83 / AUDIT-I-01] Length-zero clear...`) accidentally deleted two lines from finalizeWeek(): the `if (isResetFinalize) {` opening brace and the `emit DrawResolved(currentDraw, result)` line from resolveWeek().
---
AUDIT-C-01 CRITICAL -- finalizeWeek() missing if(isResetFinalize) guard
Contract would not compile and, if deployed, would eliminate the 7-day draw cooldown.
The `if (isResetFinalize) {` opening brace was deleted, leaving an orphaned `}` and `scheduleAnchor = block.timestamp - currentDraw \* DRAW\_COOLDOWN` executing unconditionally on every `finalizeWeek()` call. This set `lastDrawTimestamp = block.timestamp` after every draw, making `block.timestamp < lastDrawTimestamp + DRAW\_COOLDOWN` trivially true immediately -- all 52 draws could resolve in rapid succession. Guard restored.
---
AUDIT-M-01 MEDIUM -- resolveWeek() emit DrawResolved missing
All draw resolutions silent to off-chain indexers. `emit DrawResolved(currentDraw, result)` was dropped by the same v1.83 edit. The event is in the ABI; indexers, dashboards, and Subgraphs listening for it received nothing. On-chain state was correct. Emit restored.
---
AUDIT-L-01 -- processMatches() weeklyOGCount-- unguarded
One line: `if (weeklyOGCount > 0) weeklyOGCount--`. Adjacent `earnedOGCount--` already had the guard; inconsistency closed.
---
AUDIT-I-01 -- distributePrizes() NatSpec dust correction
NatSpec said dust goes "to the last winner in each tier." Code sends dust to `prizePot`. NatSpec corrected.
---
AUDIT-I-01 -- setReserveFeeds() missing SEQUENCER_FEED guard
Added `if (\_reserveFeeds\[i] == SEQUENCER\_FEED) revert InvalidAddress()` alongside existing per-entry guards. Symmetric with `proposeFeedChange()` hardened in v1.82.
---
AUDIT-I-02 (false positive) -- getPlayerInfo() dual @notice
No duplicate `@notice` exists on `getPlayerInfo()` in v1.84/v1.85. Auditor was reviewing an earlier version.
---
[v1.86]: Audit Passes 4+5 -- Aave Approvals, Counter Guards, EMA Fix
Date: March 2026
Lines: 4,654
Changes: 4 code fixes, 5 NatSpec additions, 1 cosmetic removal. Strong cumulative health.
---
AUDIT-I-01 -- Duplicate @notice on getPlayerInfo() removed
Six versions outstanding since v1.80. One line. Done.
---
P4-AUDIT-L-01 -- IERC20(USDC).approve(AAVE_POOL, 0) missing from three settlement functions
Severity: Low | Status: Resolved
`closeGame()`, `sweepDormancyRemainder()`, and `sweepFailedPregame()` all perform an inline Aave exit (`IPool(AAVE\_POOL).withdraw(...)`, `aaveExited = true`) when `!aaveExited`. None revoked the infinite USDC approval to Aave after exiting. The approval stayed live even after the last aUSDC was withdrawn. `executeAaveExit()` and `activateAaveEmergency()` already had `IERC20(USDC).approve(AAVE\_POOL, 0)` -- these three functions were simply missed. Added to all three.
---
P4-AUDIT-L-01 / P5-AUDIT-I-02 -- _continueUnwind() qualifiedWeeklyOGCount-- guarded
One line: `if (qualifiedWeeklyOGCount > 0) qualifiedWeeklyOGCount--` in the mulligan reversal block. The fourth unguarded qualifiedWeeklyOGCount site across the codebase. Now consistent.
---
P5-AUDIT-L-01 -- _updateStreakTracking() qualifiedWeeklyOGCount-- guarded
Same pattern applied to the streak-break path. Guard added inline: `\&\& qualifiedWeeklyOGCount > 0`.
---
P5-AUDIT-L-01 -- pregameWeeklyOGNetTotal overstated for credit-path players
`pregameOGNet` was computed as `cost \* 0.85` for all PREGAME weekly OG registrations. Credit-path players (who had paid `payCommitment()` previously) only transfer `transferCost = cost - TICKET\_PRICE = $10` fresh. The commitment credit's pot contribution was already counted at `payCommitment()` time. Using `cost` double-counted $8.50 per credit-path player in the EMA seed at draw 10. Fixed to `transferCost \* 0.85`.
---
NatSpec additions
Item	Location
P4-AUDIT-I-01	`claimEndgame()` -- `endgameOwed < endgamePerOG` guard explained (belt-and-suspenders against rounding shortfall)
P4-AUDIT-I-01	`\_captureYield()` -- `currentDrawSeedReturn` term documented (10% seed set aside mid-draw, excluded from yield calc to avoid double-counting)
P4-AUDIT-I-01	`getOGCapInfo()` -- `ogCapDenominator` fixed at launch by design; caps lock in at startGame()
P5-AUDIT-I-01	`resetRefundClaimedAtDraw` field -- single-field design explained; pool2 double-claim prevented via snapshot erasure not this field
P5-AUDIT-I-01	`sweepResetRefundRemainder()` -- DORMANT/CLOSED mutual exclusivity relies on EVM single-threaded execution, not an explicit lock
---
[v1.87]: Audit Pass 6 -- Pregame Accounting Symmetry + Constructor Guards
Date: March 2026
Lines: 4,693
Changes: 2 code fixes (one adds a new storage field), 2 constructor guards, 1 NatSpec merge, 2 NatSpec additions, 1 comment.
---
AUDIT-L-01 -- _cleanupOGOnRefund() pregame net reversal asymmetry
Severity: Low | Status: Resolved
P5-AUDIT-L-01 (v1.86) fixed `registerAsWeeklyOG()` to add `transferCost \* 0.85 = $8.50` to `pregameWeeklyOGNetTotal` for credit-path players instead of `cost \* 0.85 = $17`. But `\_cleanupOGOnRefund()` still reversed the full `$17`. Net result: a $8.50 undercount per credit-path refundee -- opposite bias direction from the original bug.
Fix: New field `pregameOGNetContributed` stored in `PlayerData` at registration time, holding the exact net amount added. Cleanup reads and subtracts this field directly. Fallback to the old formula for any pre-v1.87 storage state. Field cleared after use.
---
AUDIT-I-01 -- getOGCapInfo() duplicate @notice
v1.86 P4-AUDIT-I-01 fix added a second `@notice` + `@dev` block instead of extending the existing one. Two `@notice` lines merged into one. Single `@dev` block now covers both v2.69 and v1.86 content.
---
AUDIT-L-01 -- claimDormancyRefund() qualified OG isWeeklyOG state NatSpec
For qualified weekly OGs (streak intact, consecutive weeks met), `p.isWeeklyOG` is intentionally left `true` after `claimDormancyRefund()` so `\_isQualifiedForEndgame()` still passes for `claimEndgame()`. `weeklyOGCount` is decremented but the flag stays set -- a deliberate mismatch. Documented in NatSpec: off-chain tools should not assume `weeklyOGCount` equals the count of `ogList` entries with `isWeeklyOG = true` after dormancy begins.
---
AUDIT-I-01 -- Constructor missing _aavePool cross-checks
Two guards added: `\_aavePool == \_usdc` and `\_aavePool == \_aUSDC`. A misconfigured `\_aavePool` pointed at a price feed would corrupt `\_captureYield()` on every yield capture -- caught at deployment test time but worth explicit validation. Symmetric with the SEQUENCER_FEED vs `\_priceFeeds` guard added in v1.85.
---
AUDIT-I-01 -- pregameWeeklyOGTicketTotal gross/net asymmetry documented
`pregameWeeklyOGTicketTotal += cost` intentionally uses the full face value (`$20`), not `transferCost`. This counter feeds `currentDrawTicketTotal` for front-end display only -- it is not read by the predictive breath formula. Comment added explaining the deliberate asymmetry vs the net total fix.
---
[v1.87]: Audit Pass 6 -- Pregame Accounting Symmetry + Constructor Guards
Date: March 2026
Lines: 4,702
Changes: 2 code fixes, 2 constructor guards, 2 NatSpec additions, 1 cosmetic fix.
---
AUDIT-L-01 -- _cleanupOGOnRefund() pregameWeeklyOGNetTotal reversal asymmetry
Severity: Low | Status: Resolved
P5-AUDIT-L-01 (v1.86) fixed `registerAsWeeklyOG()` to add `transferCost \* 0.85 = $8.50` for credit-path players instead of `cost \* 0.85 = $17`. But `\_cleanupOGOnRefund()` still subtracted `ogGross \* 0.85 = $17` on refund -- a net undercount of $8.50 per credit-path PREGAME refunder.
Fix: New `PlayerData` field `pregameOGNetContributed` stores the exact net amount added at registration. `\_cleanupOGOnRefund()` subtracts that stored value, with a `> 0` fallback to the old formula for any state that predates v1.87 (impossible on fresh deploy but defensive). Field zeroed after use.
---
AUDIT-I-01 -- getOGCapInfo() duplicate @notice
v1.86 P4-AUDIT-I-01 fix added a second `@notice` and `@dev` block instead of extending the existing `@dev`. NatSpec parsers take the last `@notice`; the first was invisible to tooling. Two blocks merged into one.
---
AUDIT-L-01 -- claimDormancyRefund() qualified OG state NatSpec
For qualified weekly OGs, `p.isWeeklyOG` is intentionally left `true` after `claimDormancyRefund()` so `\_isQualifiedForEndgame()` still passes at `claimEndgame()`. `weeklyOGCount` is decremented, creating a deliberate counter/flag mismatch. Documented in NatSpec: no financial impact -- `weeklyOGCount` is not read post-DORMANT. Re-entry blocked by `AlreadyRefunded` guard on `dormancyRefunded`.
---
AUDIT-I-01 -- Constructor missing _aavePool cross-checks
Severity: Info | Status: Resolved
`\_aavePool == \_usdc` and `\_aavePool == \_aUSDC` checks added to constructor. Symmetric with the `SEQUENCER\_FEED vs \_priceFeeds` guard added in v1.85. Deploying with `\_aavePool` set to either token address would corrupt `\_captureYield()` balance reads silently. Two `revert InvalidAddress()` guards.
---
AUDIT-I-01 -- pregameWeeklyOGTicketTotal gross asymmetry documented
`pregameWeeklyOGTicketTotal += cost` intentionally uses the full `$20` (not `transferCost`) because it feeds `currentDrawTicketTotal` for front-end display only -- not the predictive breath formula which reads `currentDrawNetTicketTotal`. The gross total correctly represents total ticket volume including committed credit. Comment added in code.
---
[v1.88]: Audit Pass 7 -- Final Known Findings
Date: March 2026
Lines: 4,721
Changes: 2 code guards, 1 regression removal, 1 comment reword, 2 NatSpec additions.
Status: No open C/H/M findings. Seven passes complete. Internal audit-ready.
---
REGRESSION -- Duplicate _aavePool constructor guards removed
v1.87 AUDIT-I-01 fix was pasted twice. Four lines where two were correct -- second pair unreachable dead code. Second comment block and guard pair removed.
---
AUDIT-L-01 -- processMatches() qualifiedWeeklyOGCount-- guarded
The last two unguarded decrements in the contract. v1.85 guarded `weeklyOGCount--` and `earnedOGCount--` in this block but the immediately adjacent `qualifiedWeeklyOGCount--` was missed across all seven prior passes. Guard added: `\&\& qualifiedWeeklyOGCount > 0`.
---
AUDIT-L-01 -- upgradeToUpfrontOG() qualifiedWeeklyOGCount-- guarded
Second of the two remaining unguarded sites. Same pattern. Guard added inline.
Every `qualifiedWeeklyOGCount--` site in the contract is now guarded with `> 0`. This closes the counter underflow audit thread that began in pass 3.
---
AUDIT-I-01 -- pregameOGNetContributed fallback comment reworded
"fallback for pre-v1.87 state" implied an upgrade path from a prior deployment. Pick432 1Y is always freshly deployed. Reworded to "defensive fallback: unreachable if isWeeklyOG invariant holds."
---
AUDIT-I-01 -- emergencyResetDraw() NatSpec corrected
Prior NatSpec stated "callable by owner at any non-IDLE draw phase." Incorrect on two counts: (1) owner must also wait DRAW_STUCK_TIMEOUT -- no owner bypass exists. (2) FINALIZING and RESET_FINALIZING both revert WrongPhase(). NatSpec now accurately describes each phase's access rules and the 48-hour timeout applying equally to all callers.
---
AUDIT-I-01 -- getPreGameStats() sequencer liveness note
`readyToStart` does not check Arbitrum sequencer liveness. `startGame()` calls `\_checkSequencer()` internally and will revert if the feed is stale or reports downtime. NatSpec note added alongside the existing `pendingIntentCount` caveat.
---
[v1.89]: Audit Pass 8 -- Final Two Items. Contract Complete.
Date: March 2026
Lines: 4,732
Status: ZERO open findings across all severity levels. Eight passes complete. Internal audit-ready.
---
AUDIT-INFO-01 -- claimSignupRefund() committedPlayerCount-- guarded
The last unguarded `committedPlayerCount--` in the contract. The `commitmentPaid` branch in `claimSignupRefund()` was the sole exception to the contract-wide pattern of `> 0` guards on all counter decrements. Guard added. Every `committedPlayerCount--`, `weeklyOGCount--`, `earnedOGCount--`, and `qualifiedWeeklyOGCount--` in the contract is now guarded.
---
AUDIT-INFO-01 -- ACTIVE registerAsWeeklyOG() pregameOGNetContributed note
`pregameOGNetContributed` is intentionally not written in the ACTIVE branch -- ACTIVE registrations do not feed `pregameWeeklyOGNetTotal`, and `\_cleanupOGOnRefund()` is unreachable from ACTIVE paths. Comment added to prevent future developer confusion.
---
Cumulative Audit Summary
Metric	Value
Total versions	v1.0 through v1.89
Audit passes	8 (Internal audit + OZ + Internal audit framing)
Critical findings	1 (C-04 v1.72; P3 regression fixed v1.85)
High findings	0
Medium findings	2 (both resolved)
Low findings	18 (all resolved)
Info findings	30+ (all addressed)
Open findings	0
---
[v1.90]: Audit Pass 9 -- Final Submission Version
Date: March 2026
Lines: 4,762
Status: SUBMISSION READY. Nine passes. Zero open findings at any severity.
---
AUDIT-INFO-01 -- getPreGameStats() readyToStart window gap documented
Between `signupDeadline` and `signupDeadline + MAX\_PREGAME\_DURATION`, `readyToStart=true` but `payCommitment()` reverts `PregameWindowExpired`. Front-ends should independently check `block.timestamp < signupDeadline` before showing a commitment call-to-action. NatSpec note added alongside existing pendingIntentCount and sequencer caveats.
---
AUDIT-INFO-02 -- _continueUnwind() qualifiedWeeklyOGCount++ accepted design documented
The increment has no upper-bound guard, asymmetric with the `> 0` guards on all decrements. Documented as accepted design: overflow requires restoring a status-loss that the invariant prevents. The increment fires only for players whose `weeklyOGStatusLost` was set by this exact draw's `processMatches()` -- a trusted path.
---
AUDIT-INFO-01 -- activateAaveEmergency() emits AaveExitCancelled for abandoned proposals
If `proposeAaveExit()` was pending when the emergency fires, the timelock is bypassed and the proposal silently voided. Off-chain monitors had no signal this happened. Fix: `if (aaveExitEffectiveTime != 0) emit AaveExitCancelled()` before zeroing the field.
---
AUDIT-INFO-01 -- claimResetRefund() cost fallback documented as accepted approximation
When `lastResetBoughtDrawN == 0` (snapshot not captured), cost falls back to `lastTicketCost` -- the player's most recent ticket cost, which may differ from the reset-draw cost if they bought tickets at a different price between the reset and the claim. Documented at both pool1 and pool2 sites. Exposure bounded to the difference between two draw ticket costs ($10-$15). Single-pool scenario (common case) is always exact. Accepted approximation.
---
Final Audit Record
Pass	Versions	C	H	M	L	Info
1	v1.0 → v1.72	1	0	0	5	5
2	v1.73 → v1.83	0	0	1	2	3
3	v1.84 → v1.85	1*	0	1	1	3
4	v1.85 → v1.86	0	0	0	2	3
5	v1.86 → v1.87	0	0	0	2	2
6	v1.87 → v1.87	0	0	0	2	3
7	v1.87 → v1.88	0	0	0	2	4
8	v1.88 → v1.89	0	0	0	0	2
9	v1.89 → v1.90	0	0	0	0	4
*Pass 3 Critical was a regression introduced during v1.83 editing -- caught and fixed in v1.85.
Total: 1C (self-introduced regression), 0H, 2M, 14L, 29 Info. All resolved.
---
[v1.91]: Pass 9 Supplemental -- Three Accepted Design Acceptances
Date: March 2026
Lines: 4,789
Changes: 3 NatSpec additions only. No code changes.
Status: FINAL SUBMISSION VERSION. All findings resolved or explicitly accepted with rationale.
---
#4 -- claimDormancyRefund() commitment-payer pool sourcing documented
A player who paid `payCommitment()` but never bought a weekly ticket refunds from `dormancyWeeklyPool` during dormancy. Auditor flagged this as a pool-funding mismatch. Accepted design: `dormancyWeeklyPool` is the non-OG protection fund, and commitment-only players are exactly the non-OG participants it protects. Their payment is part of the pregame commitment revenue that sizes the pool.
---
#5 -- buyTickets() weeklyNonOGPlayers duplicate guard documented
`AlreadyBoughtThisWeek` (via `p.lastBoughtDraw == currentDraw`) is the sole duplicate guard for `weeklyNonOGPlayers.push()`. An array-level dedup check would be O(n) per push across up to 55,000 entries -- gas-prohibitive. NatSpec notes the guard is robust and flags it as a maintenance concern: any future code path that fails to update `lastBoughtDraw` on a successful buy would be the single point of failure.
---
#6 -- _checkAutoAdjust() pre-lock upgrader cost overstatement documented
In draws 1-9 (pre-obligation-lock), `proxyObligation = enrolledOGs \* OG\_UPFRONT\_COST`. Upgrader OGs who paid $80 are counted at $1,040, inflating `proxyObligation` and mildly suppressing breath step-downs in draws 7-9. Effect is bounded (upgraders are a small fraction, window is 3 draws max) and self-correcting: the draw-10 lock uses the honest `upgraderOGCount`-aware formula. Accepted design.
---
Final Submission Summary
Nine audit passes. 91 versions. 4,789 lines. Zero open findings.
All Critical, High, Medium, Low, and Info findings either resolved in code or explicitly accepted with documented rationale. The contract is Internal audit-ready.

---
[v1.92]: Design Rethink -- PREGAME-Only Weekly OG + Draw 7 Snapshot
Date: March 2026
Lines: 4,640 (down from 4,789 -- net ~150 lines removed)
Changes: Structural redesign. Multiple functions, constants, fields changed.
---
Design Intent
Weekly OGs must play from draw 1. No late joiners. No ambiguity about when "OG status" began. The draw 7 upgrade window close is now the natural first calibration point for breath -- all OGs are known, counts can only decrease from here. Draw 10 confirms and locks.
---
Constants
Constant	Change
`WEEKLY\_OG\_REGISTRATION\_DEADLINE = 9`	Removed -- PREGAME gate replaces it
`OG\_UPGRADE\_FIRST\_DRAW = 5`	Removed -- draw-5 minimum was ACTIVE-registration artefact
`OG\_UPGRADE\_JOIN\_BY\_DRAW = 5`	Removed -- moot with PREGAME-only
`OG\_OBLIGATION\_LOCK\_DRAW = 10`	Added -- explicit constant replacing `DEADLINE + 1` semantic
`WEEKLY\_OG\_QUALIFICATION\_WEEKS`	40 → 51 -- PREGAME joiners have all 52 draws; 51 = played every draw, one mulligan
`OG\_UPGRADE\_LAST\_DRAW = 7`	Kept -- snapshot trigger and upgrade deadline
---
Errors Removed
`WeeklyOGRegistrationClosed`, `NotEligibleForOG`, `MustJoinByDrawFive` -- all unused once ACTIVE registration path removed.
---
PlayerData Fields Removed
`weeklyOGJoinDraw` (v1.84 AUDIT-L-01 bypass fix -- moot PREGAME-only), `pregameOGNetContributed` (v1.87 AUDIT-L-01 credit-path asymmetry fix -- moot PREGAME-only, all registrations use same cost path).
---
registerAsWeeklyOG() -- PREGAME-only rewrite
~120 lines removed, ~45 clean lines. ACTIVE path gone entirely: no `requiredStreak`, no `weeklyOGJoinDraw`, no `ogPrepayTopUp`, no ACTIVE max-players check, no ACTIVE snapshot writes. Single PREGAME path: validate, pay, push to ogList.
---
_cleanupOGOnRefund() -- simplified
Returns to simple `ogGross \* 0.85` reversal. The `pregameOGNetContributed` field and fallback logic removed.
---
upgradeToUpfrontOG() -- guards simplified
Three guards removed (`OG\_UPGRADE\_FIRST\_DRAW` lower bound, `MustJoinByDrawFive`, `weeklyOGJoinDraw` one-draw enforcement). Single upper bound remains: `currentDraw > OG\_UPGRADE\_LAST\_DRAW`. Upgrade window: draws 1-7.
---
_calibrateBreathTarget() -- new internal function
Fires at draw 7 close in `finalizeWeek()`. Sets `targetReturnBps` from true OG ratio and recalibrates `breathMultiplier`. Draws 8-9 breathe against the real ratio. Does NOT set `obligationLocked`, `ogEndgameObligation`, or `requiredEndPot` -- those remain draw-10 operations.
---
_lockOGObligation() -- simplified
`targetReturnBps` already set at draw 7. Draw 10 reads it directly, sets obligation and `requiredEndPot`, seeds EMA, sets `obligationLocked`. Breath recalibration block removed (done at draw 7). Trigger changed from `WEEKLY\_OG\_REGISTRATION\_DEADLINE + 1` to `OG\_OBLIGATION\_LOCK\_DRAW`.
---
_isQualifiedForEndgame() -- upgrader parity gate
Upgraders must have `totalPaid >= OG\_UPFRONT\_COST` to qualify for endgame. They committed to block-payment parity via `payUpgradeBlock()`. Full upfront OGs (not upgraded) always qualify regardless of totalPaid.
---
closeGame() + sweepDormancyRemainder() -- cap raised
`maxPerOG` raised from `OG\_UPFRONT\_COST \* targetReturnBps / 10000` to flat `OG\_UPFRONT\_COST`. Survivors get up to 100% return when dropout reduces qualified count. Pot was sized at draw 10 for the full OG cohort -- surplus funds the survivor bonus.
---
[v1.93]: Post-Redesign Audit -- Endgame Denominator Fix
Date: March 2026
Lines: 4,672
Changes: 1 new state variable, 4 lines in payUpgradeBlock(), _countQualifiedOGs() rewrite, 2 NatSpec fixes.
---
MEDIUM -- _countQualifiedOGs() denominator corrected
`\_countQualifiedOGs()` previously returned `upfrontOGCount + qualifiedWeeklyOGCount`. `upfrontOGCount` includes ALL upgraders from the moment they call `upgradeToUpfrontOG()` -- regardless of whether they ever call `payUpgradeBlock()`. At settlement, `closeGame()` sized `endgamePerOG` against this inflated denominator. Upgraders who never paid up were blocked at `claimEndgame()` via `\_isQualifiedForEndgame()`, leaving their share in `endgameOwed` until `sweepUnclaimedEndgame()` sent it to charity. Every qualified OG received a diluted share.
Fix: New `qualifiedUpgraderOGCount` state variable. Incremented in `payUpgradeBlock()` when `p.totalPaid` reaches `OG\_UPFRONT\_COST` (the parity threshold). The entry guard `p.totalPaid >= OG\_UPFRONT\_COST -> revert ExceedsLimit()` ensures this fires exactly once per upgrader. `\_countQualifiedOGs()` now: `(upfrontOGCount - upgraderOGCount) + qualifiedUpgraderOGCount + qualifiedWeeklyOGCount`. Threshold consistent with `\_isQualifiedForEndgame()` upgrader gate.
---
LOW -- startGame() NatSpec BreathRecalibrated draw 7 correction
"BreathRecalibrated event at draw 10 is the definitive on-chain record" corrected to draw 7. `\_calibrateBreathTarget()` fires at draw 7 close and emits `BreathRecalibrated`. `\_lockOGObligation()` at draw 10 no longer emits it.
---
INFO -- upgradeToUpfrontOG() draw-1 upgrade documented as intentional
A PREGAME weekly OG can call `upgradeToUpfrontOG()` on the first IDLE window of draw 1 with zero active draws completed. This is intentional: PREGAME registration IS the commitment. The old minimum-grind guard (`currentDraw > firstPlayedDraw`) existed only for ACTIVE late joiners. NatSpec clarifies this explicitly.
---
[v1.94]: Pass 9 -- View Accuracy + Two NatSpec Edge Cases
Date: March 2026
Lines: 4,692
Changes: 1 code fix (view function), 2 NatSpec additions.
---
P9-AUDIT-L-01 -- getProjectedEndgamePerOG() ogCount corrected
`getProjectedEndgamePerOG()` used `upfrontOGCount + qualifiedWeeklyOGCount` as its denominator -- the same stale formula fixed in `closeGame()` by v1.93. Unpaid upgraders inflated the count, systematically understating the projected per-OG payout shown to dashboards and front-ends. Fixed to call `\_countQualifiedOGs()` directly for perfect consistency with actual settlement.
---
P9-AUDIT-I-01 -- _lockOGObligation() NatSpec edge case documented
The comment "No new OGs since draw 7 so the ratio is unchanged" was falsifiable: `\_continueUnwind()` during an emergency reset in draws 8-9 can restore `weeklyOGStatusLost` OGs, incrementing `earnedOGCount`. If so, `targetReturnBps` at draw 10 slightly underestimates the actual ratio, making `requiredEndPot` mildly conservative. `ogEndgameObligation` is unaffected (uses live counts). Effect is self-correcting, bounded to two draws, and emergency-reset-only. NatSpec acknowledges this edge case.
---
P9-AUDIT-I-01 -- _calibrateBreathTarget() RESET_FINALIZING path documented
If draw 7 itself is emergency-reset, `finalizeWeek()` runs on the RESET_FINALIZING path and `\_calibrateBreathTarget()` still fires. At that point `earnedOGCount` reflects the post-unwind state (restored OGs), making the calibration MORE accurate than the normal path. Not a bug -- the function uses the truest available OG count at upgrade window close. NatSpec notes this explicitly.
---
[v1.95]: Two Comment Fixes -- Event Declaration and Fragmented Block
Date: March 2026
Lines: 4,699
Changes: 2 comment fixes only. No code changes.
---
INFO-01 -- BreathRecalibrated event declaration comment
The event declaration still said "Emitted once at draw 10 obligation lock. Definitive on-chain record." Since v1.92 it fires at draw 7 in `\_calibrateBreathTarget()`. The `startGame()` NatSpec was corrected in v1.93 but the event declaration itself was missed. Updated to reference draw 7 close.
---
INFO-02 -- _lockOGObligation() fragmented comment block cleaned
The opening comment block of `\_lockOGObligation()` had a `\[v2.80]` comment interrupted mid-sentence by `\[v1.92]` and `\[v1.94]` inserts, then repeated in full. Reordered into clean sequential blocks: v1.92 note first, v1.94 edge case second, v2.80 formula explanation third. No semantic change -- purely editorial.
---
Note on P9-AUDIT-L-01 false positive
The auditor's report flagged `getProjectedEndgamePerOG()` as still using the old denominator. This was fixed in v1.94. `\_countQualifiedOGs()` is called correctly. The `upfrontOGCount + qualifiedWeeklyOGCount` string still appears in the NatSpec comment documenting what the prior code did -- not in live code.
---
[v1.96]: Two Stale Comment Fixes
Date: March 2026
Lines: 4,699
Changes: 3 comment lines only. No code changes.
`targetReturnBps` state variable declaration: "Recalibrated once more at draw 10" → draw 7
`getCurrentPrizeRate()` NatSpec: "Recalibrated again at draw 10" → draw 7
`\_calculatePrizePools()` NatSpec: same draw 10 → draw 7
All three referenced `\_lockOGObligation()` recalibrating `targetReturnBps` at draw 10. That responsibility moved to `\_calibrateBreathTarget()` at draw 7 in v1.92. `\_lockOGObligation()` reads `targetReturnBps` without changing it.

---
[v1.97]: Full Comment Sweep -- Three Stale NatSpec Fixes
Date: March 2026
Lines: 4,701
Changes: 3 NatSpec/comment fixes. No code changes.
---
FIX 1 -- resolveWeek() draw 10 breath transition note (WRONG)
The [v1.3 / I-02] note said draw 10 prizes use the "pre-lock (startGame() preview) breath rate" and that `\_lockOGObligation()` "recalibrates breathMultiplier to the definitive post-lock value." Both were wrong since v1.92. `\_calibrateBreathTarget()` set `breathMultiplier` at draw 7. `\_lockOGObligation()` does not change it. Draw 10 prizes use the draw-7-calibrated rate. There is no transition artifact at draw 10. Note completely rewritten.
---
FIX 2 -- startGame() NatSpec "recalibrated at draw 10 after ACTIVE registrations" (STALE)
The [v2.70] preview note said `targetReturnBps` would be "recalibrated once more at draw 10 (_lockOGObligation) using the actual OG ratio after ACTIVE registrations." Two errors: recalibration moved to draw 7 in v1.92, and there are no ACTIVE weekly OG registrations since v1.92 redesign.
---
FIX 3 -- claimEndgame() NatSpec "40 consecutive draws" (STALE)
`WEEKLY\_OG\_QUALIFICATION\_WEEKS` changed from 40 to 51 in v1.92. The NatSpec reference to "earned through 40 consecutive draws" was missed in that sweep. Updated to 51.
---
[v1.98]: Triple-Audit Pass -- Two Pre-existing INFOs + Cosmetic
Date: March 2026
Lines: 4,709
Changes: 3 comment/NatSpec fixes. No code changes.
---
INFO-01 -- _checkAutoAdjust() NatSpec "draws 10-51" corrected to "draws 11-51"
Draw 10 runs `\_checkAutoAdjust()` via `\_calculatePrizePools()` before `\_lockOGObligation()` sets `obligationLocked = true`. The post-lock predictive formula therefore starts at draw 11, not draw 10. The v1.97 `resolveWeek()` fix already said "Draws 11 through 51"; this brings `\_checkAutoAdjust()` NatSpec into alignment.
---
INFO-02 -- OGIntentDeclined event comment clarified
"this event is ACTIVE-only" was ambiguous -- could be read as "only emitted during ACTIVE phase." Intended meaning: not emitted on game failure. Updated to: "Not emitted on game failure -- claimSignupRefund() handles that path."
---
COSMETIC -- getCurrentPrizeRate() NatSpec line wrap
Long v1.92 comment split cleanly across two lines for submission presentation hygiene.
---
[v1.99.1]: Adversarial Audit -- Credit-Path Asymmetry Restored + EMA Count Fix
Date: March 2026
Lines: 4,736
Changes: 1 PlayerData field restored, 2 code sites updated, 1 comment fix.
---
LOW -- pregameOGNetContributed restored (v1.87 / AUDIT-L-01 symmetry fix)
Root cause: v1.92 removed `pregameOGNetContributed` with the stated rationale that PREGAME-only registration eliminated the credit-path asymmetry. That was wrong. The credit path survived: players who paid the $10 commitment deposit before `registerAsWeeklyOG()` have `commitmentPaid = true`, pay only $10 fresh (`transferCost = $10`), and add `$8.50` to `pregameWeeklyOGNetTotal`. But `\_cleanupOGOnRefund()` subtracted a flat `ogGross \* 0.85 = $17.00` -- an $8.50 undercount per credit-path refund. `p.commitmentPaid` is cleared at registration time so cannot be read during cleanup.
Fix: `pregameOGNetContributed` restored to `PlayerData`. Set in `registerAsWeeklyOG()` to `pregameOGNet` (the exact amount added). `\_cleanupOGOnRefund()` uses the stored value for symmetric reversal, with a defensive fallback to `ogGross \* 0.85` if the field is zero.
---
INFO -- EMA alpha comment corrected
"post-lock window is only 42 draws (draws 10-51)" corrected to "41 draws (draws 11-51)". Post-lock predictive formula first fires at draw 11. Draws 11-51 inclusive = 41 draws.
---
[v1.99.2]: Triple Audit Pass -- Regression Trap Closed + Three Disclosures
Date: March 2026
Lines: 4,759
Changes: 1 new error + revert (code), 3 NatSpec disclosures (accepted design).
---
AUDIT-L-01 -- _cleanupOGOnRefund() fallback replaced with revert
The fallback `ogGross \* 0.85` was a silent regression trap: it applied the exact flat $17 subtraction that v1.99.1 fixed, meaning any future code path that sets `isWeeklyOG = true` without setting `pregameOGNetContributed` would silently re-introduce the $8.50 undercount per credit-path refund. New `PregameOGNetNotSet()` error added. Cleanup now reverts if the field is zero. The invariant must be maintained at the source.
---
AUDIT-M-01 -- EMA seed inflation (accepted design, documented)
`\_lockOGObligation()` EMA seed uses `currentDrawNetTicketTotal` which includes any `payUpgradeBlock()` contributions from draw 10's IDLE window. Upgrade blocks are not weekly ticket revenue. A cluster of block payments at draw 10 inflates the seed, opening breath modestly wider for draws 11-14. Self-correcting via EMA decay: alpha=0.5 means inflated seed decays to 12.5% weight after 3 draws. No funds at risk. Disclosed proactively in audit submission narrative.
---
AUDIT-I-01 -- _calibrateBreathTarget() indexer note
`\_calibrateBreathTarget()` emits `BreathRecalibrated`, not `BreathMultiplierAdjusted`. Off-chain indexers watching only `BreathMultiplierAdjusted` will miss the draw-7 `breathMultiplier` change. NatSpec now explicitly states this. Integration tooling must consume both events.
---
AUDIT-L-01 -- activateDormancy() pool oversizing for upgraders (accepted design, documented)
`dormancyOGPool` is sized using `perOGFull \* upfrontOGCount` where `perOGFull` assumes a full $1,040 OG contribution. Upgraders paid less. Their `claimDormancyRefund()` is capped at `p.totalPaid` -- they receive exactly what they paid. The residual flows to `sweepDormancyRemainder()` benefiting qualified weekly OGs. No player is shorted. Accepted design. NatSpec comment added at the sizing calculation.
---
[v1.99.3]: Fresh Audit Pass -- Three NatSpec Disclosures
Date: March 2026
Lines: 4,788
Changes: 3 NatSpec additions. No code changes.
---
sweepDormancyRemainder() -- Yield routing disclosed
Aave yield accrued during the 90-day dormancy claim window flows entirely to qualified weekly OGs via `yieldBonus` -- not pro-rata to dormancy claimants. Upfront OGs who claimed early had their refund principal sitting in Aave generating yield that routes here. This is intentional: upfront OGs take a clean exit (full principal back); the yield windfall rewards qualified weekly OGs who played 51 consecutive draws. Consistent with the Eternal Seed design -- yield flows to the committed collective, not to those who already exited. Disclosed proactively in audit submission narrative.
---
emergencyResetDraw() -- EmergencyReset event amountReturned field
`amountReturned` in the `EmergencyReset` event reflects recovered undistributed tier pool funds only. Prizes already credited to `p.unclaimedPrizes` in completed tiers are NOT included -- they remain in `totalUnclaimedPrizes`, correctly accounted for. Full draw disruption = `amountReturned + (distWinnerIndex \* currentTierPerWinner)`. On-chain accounting is correct; the event field reflects recovery, not total impact.
---
_continueUnwind() -- Streak not restored for non-buyers
`weeklyOGStatusLost` and `mulliganUsed` are restored by `\_continueUnwind()` but `consecutiveWeeks` and `lastActiveWeek` are not. An OG who missed the reset draw has their status restored but their `lastActiveWeek` remains at draw N-1. When draw N+1 opens, `\_updateStreakTracking()` sees a gap of 2 and resets their streak to 1. An OG approaching 51 consecutive weeks could lose endgame qualification. Low probability, defensible semantics. Disclosed for submission. Operator runbooks should include a player communication plan for emergency reset events.
---
[v1.99.4]: Dormancy Redesign -- Four-Step Model
Date: March 2026
Lines: 4,988 (net +200 from v1.99.3)
Changes: 6 state vars removed, 11 state vars added, 1 new event, 18 code change categories, 20 bugs found across 4 ghost-mode audit passes before code was written.
---
DESIGN RATIONALE
The prior dormancy model gave upfront OGs a pro-rata refund of their $1,040 entry based only on remaining draws. Dormancy at draw 26 returned approximately $459 regardless of pot size. If the pot contained $5 million, the $4.97 million surplus flooded entirely to last-draw weekly players. A weekly player who paid $20 in the final draw could double their money on yield the OG funded. The OG who funded that pot received a 56% loss on their entry. The owner had a timing incentive. The formula was never stress-tested against 10-20x pot scenarios.
---
NEW FOUR-STEP PRIORITY MODEL
STEP 1 -- OG principal pool. Every active OG receives full `totalPaid` back. Upfront OGs: `OG\_UPFRONT\_COST`. Weekly OGs: full accumulated `totalPaid` including all draws played. Proportional if pot insufficient. Snapshot frozen at activation.
STEP 2 -- Casual last-draw ticket refunds. Non-OG buyers who bought tickets in the final draw receive their net ticket cost back. Only funded if step 1 achieved full cover. Snapshot frozen.
STEP 3 -- Charity. 10% of gross OG returns sent immediately at activation. Only fires when both steps 1 and 2 fully covered and surplus remains. Players take priority over charity.
STEP 4 -- Per-head surplus. All last-draw participants share remaining surplus equally. Count: `upfrontOGCount + weeklyOGCount + weeklyNonOGPlayers.length`. `ogList.length` excluded -- contains stale status-lost OGs.
Commitment-only players receive up to net $8.50 from `dormancyPerHeadPool`. Not counted in participant count. In underfunded scenarios they receive nothing. Accepted design.
Owner timing incentive eliminated: the model produces a fair, deterministic outcome regardless of which draw dormancy activates.
---
STATE VARIABLES REMOVED (6)
`dormancyPerOGRefund`, `dormancyFullOGCover`, `dormancyWeeklyPool`, `dormancyWeeklyPoolForCalc`, `dormancyWeeklyTicketTotal`, `dormancyWeeklyFullCover`.
---
STATE VARIABLES ADDED (11)
`totalOGPrincipal`: running total of all active OG gross payments. Maintained at 6 increment sites and 5 decrement sites. Enables dormancy pool sizing without iterating `ogList`.
`dormancyOGPool` / `dormancyOGPoolSnapshot`: step 1 pool and frozen snapshot.
`dormancyPrincipalFullCover`: true if each OG receives exact `totalPaid` back.
`dormancyCasualRefundPool` / `dormancyCasualRefundPoolSnapshot`: step 2 pool.
`dormancyCasualTicketTotal`: snapshot of non-OG net ticket total at activation.
`dormancyCasualFullCover`: true if each casual buyer gets full net cost back.
`dormancyPerHeadPool` / `dormancyPerHeadShare`: step 4 pool and pre-calc share.
`dormancyParticipantCount`: head count at activation for per-head calculation.
`currentDrawCasualNetTicketTotal`: running counter for non-OG net tickets per draw. Not a fund pool -- excluded from solvency accounting.
---
NEW EVENT
`DormancyCharitySent(uint256 amount)`: emitted when charity is sent immediately at dormancy activation. Distinct from `CharityClaimed`.
---
totalOGPrincipal MAINTENANCE SITES
Increments (6): `confirmOGSlots`, `registerAsWeeklyOG`, `buyTickets` (weekly OG path), `upgradeToUpfrontOG`, `payUpgradeBlock`, `\_continueUnwind` (BEFORE flag clear -- symmetric with `processMatches` decrement).
Decrements (5): `claimOGIntentRefund` (OFFERED only), `forceDeclineIntent` (OFFERED only), `\_cleanupOGOnRefund` (upfront: `OG\_UPFRONT\_COST`, weekly: `TICKET\_PRICE \* MIN\_TICKETS\_WEEKLY\_OG`), `processMatches` (BEFORE `weeklyOGStatusLost = true`).
---
20 BUGS FOUND ACROSS 4 GHOST-MODE AUDIT PASSES
1-2: Proportional formulas used shrinking pool as numerator. Fixed by freezing snapshots.
3-4: Weekly OG cleanup missing `earnedOGCount--` and `qualifiedWeeklyOGCount--`. Added.
5-6: Status-lost OG flags not cleared for PATH 3 and PATH 5. Universal cleanup block added.
7: Two snapshot variables missing from original plan. Added.
8: Commitment-only pool sourcing wrong -- was casual pool, now per-head pool.
9-10: Safety floor guards missing for last claimant. Dust clamps added.
11: `\_continueUnwind()` missing from `totalOGPrincipal` increment plan. Added.
12: `buyTickets()` draw 1 double-count risk confirmed absent.
13: `dormancyParticipantCount` used `ogList.length` (includes stale OGs). Corrected to `upfrontOGCount + weeklyOGCount + weeklyNonOGPlayers.length`.
14: `currentDrawCasualNetTicketTotal` reset missing in `finalizeWeek()` and `emergencyResetDraw()`. Both added.
15: `sweepDormancyRemainder()` accounting block missing new pools substitution. Fixed.
16: `sweepResetRefundRemainder()` DORMANT routing directed to `dormancyWeeklyPool`. Rerouted to charity.
17: Charity fires when `totalOGPrincipal = 0`. Guard added.
18: Division by zero in proportional paths. Guards added.
19: Per-head dust clamp missing for last claimant. Min-clamp applied.
20: `\_captureYield()` inside `!aaveExited` block in `sweepDormancyRemainder()`. Moved outside.
---
[v1.99.5]: Triple Audit -- Two Fixes, Four Disclosures
Date: March 2026
Lines: 4,904
Changes: 1 medium code fix, 1 low code fix, 4 NatSpec disclosures.
---
AUDIT-M-01 MEDIUM -- claimResetRefund() weekly OG double-recovery after dormancy
`claimResetRefund()` refunds a weekly OG's net ticket cost but did not decrement `p.totalPaid` or `totalOGPrincipal`. If dormancy subsequently activated with full principal cover, the PATH 2 formula `principal = p.totalPaid` still included that draw's ticket cost. The weekly OG recovered the same cost twice.
Fix: After computing `claim` and before transfer, decremented both fields for active weekly OG claimants in both `eligiblePool1` and `eligiblePool2` paths.
```solidity
if (p.isWeeklyOG \&\& !p.weeklyOGStatusLost) {
    if (p.totalPaid >= claim) p.totalPaid -= claim;
    else p.totalPaid = 0;
    if (totalOGPrincipal >= claim) totalOGPrincipal -= claim;
    else totalOGPrincipal = 0;
}
```
---
AUDIT-L-01 LOW -- sweepDormancyRemainder() left five state variables non-zero
`dormancyParticipantCount`, `dormancyCasualTicketTotal`, `dormancyPrincipalFullCover`, `dormancyCasualFullCover`, and `totalOGPrincipal` were not zeroed post-settlement. NatSpec states "Zeroes all dormancy state." Five additional zero assignments added to the sweep block.
---
AUDIT-I-01 INFO -- totalOGPrincipal not decremented in claimDormancyRefund() -- intentional
`totalOGPrincipal` must remain frozen at its activation value throughout the 90-day claim window. The proportional formula uses `dormancyOGPoolSnapshot / totalOGPrincipal` -- decrementing it would cause later claimants to receive a different proportion than earlier ones. NatSpec added to PATH 1 and PATH 2.
---
AUDIT-I-02 INFO -- PATH 3 casual refund silently skipped when pool drained
If `dormancyCasualRefundPool` is exactly drained, the casual refund block skips without error. The player still receives their per-head share. Accepted design. NatSpec added.
---
AUDIT-I-01 INFO -- claimEndgame() dual guard confirmed correct belt-and-suspenders
`if (dormancyTimestamp > 0) revert NothingToClaim()` fires before the `endgamePerOG == 0` check. Both independently block the dormancy path. Dual redundancy confirmed correct.
---
AUDIT-I-01 INFO -- weeklyNonOGPlayers.length in activateDormancy() confirmed correct
After `assembly { sstore(weeklyNonOGPlayers.slot, 0) }` in `finalizeWeek()`, `.length` correctly returns 0. Both IDLE timing scenarios (pre-resolve and post-finalize) produce correct participant counts. NatSpec documents both scenarios.
---
[v1.99.6]: Triple Audit Response -- Two Mediums, One Low, Four NatSpec
Date: March 2026
Lines: 4,944 (net +40 from v1.99.5)
Changes: 2 medium code fixes (5 lines), 1 low code fix (2 lines removed), 4 NatSpec updates.
Source audit: Internal triple audit triple review of v1.99.5.
---
AUDIT-M-01 MEDIUM -- currentDrawCasualNetTicketTotal not reset between draws
Severity: Medium | Status: Resolved
`currentDrawCasualNetTicketTotal` is incremented in `buyTickets()` per draw but was never zeroed in `finalizeWeek()` or `emergencyResetDraw()`. At dormancy activation, `activateDormancy()` reads this as `dormancyCasualTicketTotal` -- intended to represent current-draw casual net spend only. Without reset, by draw 20 the counter holds all-time cumulative casual revenue across 19 draws. The proportional formula in PATH 3:
```solidity
casualRefund = dormancyCasualRefundPoolSnapshot \* playerNetCost / dormancyCasualTicketTotal;
```
divides by a denominator ~20x too large. Every eligible last-draw buyer receives near-zero. The entire casual pool sweeps to charity. No funds lost but the casual refund path is functionally broken at any dormancy beyond draw 1.
Fix: Added `currentDrawCasualNetTicketTotal = 0;` to both `finalizeWeek()` and `emergencyResetDraw()` alongside the existing `currentDrawNetTicketTotal = 0` resets.
---
AUDIT-M-01 MEDIUM -- totalOGPrincipal overstated by $10 per credit-path upfront OG
Severity: Medium | Status: Resolved (3 sites)
`confirmOGSlots()` always added `OG\_UPFRONT\_COST` ($1,040) to `totalOGPrincipal` regardless of payment path. A credit-path upfront OG (who paid `payCommitment()` first) transferred only `OG\_UPFRONT\_COST - TICKET\_PRICE` = $1,030, stored in `ogIntentAmount\[player]`. Their `p.totalPaid` = $1,030. The constant $1,040 increment overstated the proportional denominator by $10 per credit-path OG, slightly reducing every OG's dormancy claim.
The two decrement sites (`claimOGIntentRefund` and `forceDeclineIntent` OFFERED paths) also used the constant, creating asymmetry.
Fix: Three sites updated for full symmetry:
`confirmOGSlots`: `totalOGPrincipal += ogIntentAmount\[player]` (actual payment, pre-zero)
`claimOGIntentRefund` OFFERED: `totalOGPrincipal -= amount` (local var captured pre-zero)
`forceDeclineIntent` OFFERED: `totalOGPrincipal -= amount` (same pattern)
`totalOGPrincipal` now exactly equals the sum of `p.totalPaid` for all active OGs at all times.
---
AUDIT-L-01 LOW -- Dead else-if(CLOSED) branches in sweepResetRefundRemainder()
Severity: Low | Status: Resolved
Pool2 and commitment pool blocks both had:
```solidity
if (gamePhase == GamePhase.DORMANT || gamePhase == GamePhase.CLOSED) { ... }
else if (gamePhase == GamePhase.CLOSED) { ... }  // unreachable
```
The second `else if` is permanently unreachable -- CLOSED is already handled by the first condition. Copy-paste artifact from the v1.99.4 refactor. Removed from both blocks. Pool1 block was already clean.
---
AUDIT-I-01 INFO -- claimEndgame() NatSpec: dual-claim design superseded
Prior NatSpec described a dual-claim design (endgame pool + dormancy refund as separate entitlements). This was superseded in v1.99.4. The `dormancyTimestamp > 0` guard now blocks `claimEndgame()` for all player types. All players settle exclusively via the four-step dormancy model. NatSpec updated to reflect v1.99.4 design change.
---
AUDIT-I-01 INFO -- getDormancyInfo() flags invalid post-settlement
`sweepDormancyRemainder()` zeroes `dormancyPrincipalFullCover = false` and `dormancyCasualFullCover = false`. Off-chain tooling reading these after settlement would see "partial cover" even if full cover occurred. NatSpec note added: these flags are invalid after `gameSettled = true`.
---
AUDIT-I-02 INFO -- PATH 4 integer-dust edge case NatSpec
If PATH 1-3 claimants drain `dormancyPerHeadPool` to zero via integer dust accumulation, a PATH 4 (commitment-only) player with no other refund source reverts `NothingToClaim`. Accepted corner case -- commitment-only players have no principal at risk. NatSpec updated to document the edge case explicitly alongside the existing underfunded-scenario disclosure.
---
INFO -- sweepResetRefundRemainder() NatSpec stale dormancyWeeklyPool reference
NatSpec referenced `dormancyWeeklyPool` in the DORMANT routing description. Since v1.99.4, DORMANT routes directly to charity. Reference removed, NatSpec updated.
---
[v1.99.7]: Triple Audit Response -- INFO Fixes, Internal audit Pushback Prep
Date: March 2026
Lines: 4,975 (net +31 from v1.99.6)
Changes: 1 code fix, 1 cosmetic reformat, 4 NatSpec updates.
Source audit: Internal triple audit triple review of v1.99.6. No new Critical, High, or Medium findings. All prior findings confirmed fixed.
---
AUDIT-I-01 INFO -- _cleanupOGOnRefund() $10 asymmetry from AUDIT-M-01 fix
Severity: Info | Status: Resolved (code fix)
The AUDIT-M-01 fix in v1.99.6 made `confirmOGSlots()` increment `totalOGPrincipal` by `ogIntentAmount\[player]` (actual payment). However, `\_cleanupOGOnRefund()` upfront branch still decremented by the constant `OG\_UPFRONT\_COST`. For credit-path OGs, this created a $10 asymmetry: `+$1,030` at grant, `-$1,040` at cleanup. The floor guard prevents underflow. Impact is zero in practice since `\_cleanupOGOnRefund` is only reachable in a failed PREGAME, and dormancy can only activate in ACTIVE.
Fix: `\_cleanupOGOnRefund` upfront branch now uses:
```solidity
uint256 upfrontActual = OG\_UPFRONT\_COST - (ogIntentUsedCredit\[addr] ? TICKET\_PRICE : 0);
```
This restores full symmetry with `confirmOGSlots`. Stale "Use constant" comment replaced with explanation of the credit-path calculation.
---
AUDIT-I-02 INFO -- withdrawTreasury() NatSpec referenced removed dormancyWeeklyPool
Severity: Info | Status: Resolved (NatSpec)
`withdrawTreasury()` NatSpec listed `dormancyWeeklyPool` as a separately tracked pool justifying unrestricted treasury withdrawal. That variable was removed in v1.99.4. NatSpec updated to list `dormancyCasualRefundPool` and `dormancyPerHeadPool` as the replacement pools.
---
AUDIT-I-01 INFO -- PATH 4 pool depletion before PATH 1-3 claimants
Severity: Info | Status: Resolved (NatSpec)
`dormancyParticipantCount` does not include commitment-only (PATH 4) players, but PATH 4 players consume from the same `dormancyPerHeadPool`. If PATH 4 players claim before PATH 1-3 players, the pool depletes faster than the per-head calculation assumed. Late PATH 1-3 claimants receive `min(dormancyPerHeadShare, dormancyPerHeadPool)` -- the dust clamp handles this gracefully, no revert. Accepted design: PATH 4 players have no principal at risk and the per-head pool is surplus only.
`activateDormancy()` STEP 4 NatSpec updated to document this edge case explicitly.
---
AUDIT-I-01 INFO -- sweepResetRefundRemainder() pool1 block inline style inconsistency
Severity: Info | Status: Resolved (reformat)
Pool2 and commitment blocks were reformatted to multi-line style in v1.99.6. Pool1 retained the single-line inline style, creating a maintenance inconsistency. Reformatted to match.
---
Internal audit Pushback Preparation -- Three pre-emptive NatSpec additions
Based on audit team prediction of three likely audit submission challenges:
1. STEP 3 immediate charity send (activateDormancy): NatSpec now states explicitly that STEP 3 only fires when both `dormancyPrincipalFullCover` and `dormancyCasualFullCover` are true, meaning all player obligations are already fully allocated. The charity amount is pure surplus above all player entitlements. No player's refund is reduced by this send.
2. claimEndgame() blocking all players after dormancy: NatSpec updated in v1.99.6 (AUDIT-I-01) to state the dual-claim design is fully superseded in v1.99.4. All players settle exclusively via the four-step model. Rationale: endgame distribution after dormancy would be redundant and potentially inconsistent with the four-step settlement already completed.
3. totalOGPrincipal frozen during claim window: Documented in v1.99.5 (AUDIT-I-01 note in claimDormancyRefund PATH 1 and PATH 2). Denominator must remain frozen at activation value -- decrementing as claims arrive would break proportional fairness for late claimants in partial-cover scenarios.
---
[v1.99.8]: Pregame-to-Draw-15 Audit Response
Date: March 2026
Lines: 5,047 (net +72 from v1.99.7)
Changes: 1 code fix, 11 NatSpec additions.
Source audit: Internal triple audit triple review of v1.99.8 scope: constructor through draw 15 (pregame + draws 1-15).
---
CODE FIX: _continueUnwind() streak preservation (I-05, promoted to LOW)
Prior behaviour: `p.lastActiveWeek = lastResetDraw > 0 ? lastResetDraw - 1 : 0`. On the next draw after an emergency reset, `\_updateStreakTracking()` saw a gap of 2 between `lastActiveWeek` and `currentDraw`, resetting streak to 1. An OG at 50 consecutive weeks could lose endgame qualification through no fault of their own.
Fix: `p.lastActiveWeek = lastResetDraw`. Emergency reset voids draw N entirely. Setting `lastActiveWeek` to draw N means the next buy (draw N+1) is consecutive. Streak preserved correctly for all restored OGs.
---
NATSPEC ADDITIONS (11)
M-01 (registerAsWeeklyOG + activateDormancy STEP 1): Face-value vs net-contribution asymmetry for credit-path weekly OGs documented. Maximum exposure bounded at `TICKET\_PRICE` ($10) per credit-path weekly OG. Design rationale: face-value tracking is simpler, the delta is absorbed by yield and casual revenue, and in DeFi no player expects principal recovery from a dormant game. The four-step model is materially more protective than the norm.
M-02 (confirmOGSlots): PENDING+isWeeklyOG griefing worst-case quantified. `OG\_INTENT\_HARD\_CAP / 100 = 50` owner `forceDeclineIntent` transactions to resolve. Economic attack cost ~$5.15M -- not a practical attack vector. Primary mitigation is the hard cap.
L-01 (register()): `PREPAY\_WEEKS \* TICKET\_PRICE` loads inhale price credit regardless of registration phase. Players registering near the exhale boundary receive fewer than 4 weeks of effective coverage. No funds lost. Full fix deferred to full-game audit scope (draws 1-36 unaffected).
L-02 (claimSignupRefund): Treasury floor guard explained. Under Aave solvency `\_captureYield()` synchronises `prizePot` to real balance. Under Aave insolvency `\_withdrawAndTransfer` reverts `AaveLiquidityLow` -- correct behaviour. Accepted risk.
L-03 (sweepExpiredDeclines): Indexers must treat `OFFERED` status as permanent OG confirmation once `gamePhase == ACTIVE`. A non-zero `ogIntentWindowExpiry` post-`startGame()` is stale and does not indicate an open refund option.
L-04 (_lockOGObligation): EMA double-count quantified. At 500 weekly OGs and a $5M pot: ~20 BPS breath inflation maximum, self-correcting over draws 11-13 via EMA alpha = 0.5.
I-01 (buyTickets): Draw-2+ commitment forfeiture documented. Players who pay `payCommitment()` in PREGAME then miss draw 1 have their $10 commitment cleared with no credit applied in draw 2+. The fee serves only as a draw-1 ticket credit. This fires silently with no event.
I-02 (getDormancyInfo): Upgrader `p.totalPaid` may exceed `OG\_UPFRONT\_COST`. Accumulated from: PREGAME registration + pre-upgrade weekly tickets + initial upgrade payment + block payments. `payUpgradeBlock()` caps block payments but not pre-upgrade ticket contributions. At dormancy PATH 1 refunds the full `p.totalPaid` -- correct by design.
I-03 (_calibrateBreathTarget): Uses `earnedOGCount` not `qualifiedWeeklyOGCount` intentionally. At draw 7, no player can have 51 consecutive weeks so `qualifiedWeeklyOGCount = 0`. `earnedOGCount` correctly captures all active weekly OGs at upgrade window close -- the right denominator for the OG concentration ratio.
_continueUnwind NatSpec: Updated to reflect the lastActiveWeek fix. Streak restoration rationale documented: reset voids draw N, so restored OGs should see draw N+1 as consecutive.
---
[v1.99.9]: Draw 15 Audit Response -- Pick-Window Guard + Three NatSpec
Date: March 2026
Lines: 5,076 (net +29 from v1.99.8)
Changes: 1 code fix, 3 NatSpec additions.
Source audit: Internal triple audit. No new Critical, High, or Medium findings.
---
CODE FIX: activateDormancy() pick-window guard (L-03)
`DORMANCY\_TIMELOCK` is 24 hours. `PICK\_DEADLINE` is 4 days. Without a guard, a rogue owner could propose dormancy at draw start then activate it 24 hours later while the pick window was still open for 3 more days -- cancelling a live draw faster than the 48-hour `emergencyResetDraw()` stuck timeout.
Fix: One guard added immediately after the existing timelock check:
```solidity
if (block.timestamp <= lastDrawTimestamp + PICK\_DEADLINE) revert PicksLocked();
```
`activateDormancy()` now requires the current pick window to have fully elapsed before dormancy can fire. The timelock still starts at `proposeDormancy()` (no restriction there -- IDLE only). The guard fires only at activation. Players who bought tickets in the pre-dormancy window still receive PATH 3 refunds. This gives every player at least one full draw cycle of notice before dormancy can activate.
---
NATSPEC: _checkAutoAdjust() effective rate note (L-01)
The predictive breath formula targets `breathMultiplier` directly. Effective prize rate = `breathMultiplier \* prizeRateMultiplier / 10000`. When `prizeRateMultiplier < 10000` (crisis reduction via `executePrizeRateReduction()`), actual prizes are lower than projected, so the pot builds faster and arrives above `requiredEndPot` at draw 52. Surplus flows to draw-52 prizes. This conservative behaviour is intentional -- the multiplier reduction signals the owner wants to slow prize flow and the formula should not compensate by pushing breath back up. Off-chain dashboards must use `getCurrentPrizeRate()` (which applies `prizeRateMultiplier`) not `breathMultiplier` alone for accurate trajectory projections.
---
NATSPEC: sweepResetRefundRemainder() per-player deadline note (L-02)
`ResetRefundExpiredSwept` fires at pool level but does not enumerate individual unclaimed players. A player who misses the 30-day refund window receives no on-chain notification of forfeiture. Front-ends must prominently display `resetDrawRefundDeadline` with a countdown for all eligible claimants.
---
NATSPEC: proposeDormancy() L-03 timelock gap explanation
Documents the 24h vs 4-day overlap and explains that the pick-window guard in `activateDormancy()` closes it. Proposal may still be submitted at any IDLE time. The guard fires only at activation, not at proposal.
---
[v1.99.10]: Final Settlement Audit Response
Date: March 2026
Lines: 5,104 (net +28 from v1.99.9)
Changes: 1 code fix, 3 NatSpec additions.
Source audit: Internal triple audit. Scope: draws 39-52, closeGame(), endgame settlement, all dormancy/CLOSED paths. Prior fix verification: all v1.99.9 fixes confirmed correct.
---
CODE FIX: claimPrize() post-sweep double-pay guard (L-01)
`sweepUnclaimedPrizes()` zeros `totalUnclaimedPrizes` and sends all unclaimed prize USDC to charity. After it runs, a player with stale `p.unclaimedPrizes > 0` calling `claimPrize()` would pass the existing `amount == 0` guard and attempt a transfer. If `aaveExited = true` and treasury USDC remains in the contract, `safeTransfer` succeeds -- the player receives a double payment from treasury funds they have no entitlement to.
Fix: First guard added to `claimPrize()`:
```solidity
if (totalUnclaimedPrizes == 0) revert NothingToClaim();
```
After `sweepUnclaimedPrizes()` runs, `totalUnclaimedPrizes == 0` is a permanent post-sweep sentinel. All stale prize claims correctly revert. Parallel with `claimEndgame()` which uses `endgameOwed < endgamePerOG` as its sentinel after `sweepUnclaimedEndgame()`.
---
NATSPEC: emergencyResetDraw() draw-52 edge case (L-02)
Documents the degenerate scenario where emergency reset fires during draw 52's DISTRIBUTING phase (requires a 48h+ protocol stall on the final draw). Undistributed tier funds return to `prizePot`. After refinalize, `resolveWeek()` reverts `GameAlreadyClosed` so draw 52 cannot re-run. Prizes already credited before the reset stay with winners. Prizes not yet distributed flow through `closeGame()` as OG endgame surplus rather than to casual ticket buyers. Mechanically correct, economically visible.
---
NATSPEC: _checkAutoAdjust() draw-51 formula behaviour (I-01)
At draw 51, `remainingDraws = 1`. The formula correctly produces a high `optimalBreathBps` to distribute nearly all surplus above `requiredEndPot` as prizes, positioning the pot for the draw-52 exact-landing branch. May clamp to `breathRailMax`. Dashboard integrators should use `getCurrentPrizeRate()` for live effective rate.
---
NATSPEC: ENDGAME_SWEEP_WINDOW = 548 days intent confirmation (I-03)
548 = exactly 1.5 years (365 + 183 days). Deliberate design: the 1-year game run plus a 6-month unclaimed-funds window. Not 365 or 730 days.
---
[v1.99.11]: External Dependency Audit Response
Date: March 2026
Lines: 5,210 (net +106 from v1.99.10)
Changes: 2 code fixes, 1 new interface, 2 new events, 8 NatSpec additions.
Source audit: Internal triple audit. Scope: external dependencies (Chainlink, Aave, USDC). No new Critical findings.
---
NEW INTERFACE: AggregatorMinMax (H-01)
Minimal interface added above the contract definition to read Chainlink aggregator circuit-breaker bounds. `AggregatorV3Interface` does not expose `minAnswer()` or `maxAnswer()`. Only these two functions are needed; cast applied at call site in `\_readPrice()` and `\_readPriceFeed()`.
```solidity
interface AggregatorMinMax {
    function minAnswer() external view returns (int192);
    function maxAnswer() external view returns (int192);
}
```
---
CODE FIX: Chainlink circuit-breaker bounds check in _readPrice() and _readPriceFeed() (H-01)
Chainlink price feeds clamp returned prices to `\[minAnswer, maxAnswer]` at the aggregator level when real market prices exceed those bounds. A 95% BTC crash would return `minAnswer` (e.g. $1) instead of the real market price. The contract only checked `price <= 0` -- it would have used the clamped value and produced incorrect weekly performance rankings.
Fix: After existing staleness/zero checks, both `\_readPrice()` and `\_readPriceFeed()` now attempt to read `minAnswer` and `maxAnswer` via the `AggregatorMinMax` cast. If `price <= minAnswer || price >= maxAnswer`, return 0 and fall back to `lastValidPrices`. Inner try/catch handles legacy feeds that do not expose these functions.
Impact: prize fairness only (no fund loss). Correct fix closes the prize-manipulation vector.
---
CODE FIX: All Aave supply() calls wrapped in try/catch (M-01)
All 8 `IPool(AAVE\_POOL).supply()` calls across the protocol were bare (not try/caught). `\_withdrawAndTransfer()` correctly wraps `withdraw()` but supply was asymmetric. If Aave pauses or freezes the USDC market (supply cap hit, guardian pause, frozen market), every payment function would revert, halting all game activity.
Fix: All 8 supply calls now use:
```solidity
if (!aaveExited) {
    try IPool(AAVE\_POOL).supply(USDC, amount, address(this), 0) {}
    catch { emit AaveSupplyFailed(amount); }
}
```
On supply failure, funds are held as raw USDC in the contract. `\_captureYield()` handles `aaveExited = false` with USDC balance correctly once `activateAaveEmergency()` is called. Play continues during Aave supply issues; yield accrual stops until supply resumes or owner exits.
New event: `AaveSupplyFailed(uint256 amount)` for off-chain monitoring.
---
NEW EVENT: FeedStaleFallback(uint256 indexed feedIndex) (L-03)
Emitted in `resolveWeek()` when `lastValidPrices\[i]` historical fallback is used because `\_readPrice()` returned 0. If a feed stays down for multiple consecutive draws, this value ages without any on-chain signal. `FeedStaleFallback` gives off-chain monitoring a per-feed signal. Operator should call `proposeFeedChange()` if a feed is repeatedly stale.
---
NATSPEC ADDITIONS (8)
M-02 (activateAaveEmergency): Full Aave withdraw pause accepted risk documented. A full pause (supply AND withdraw) has never occurred in Aave V3 production. Adding try/catch would set `aaveExited = true` without receiving USDC, breaking `\_captureYield()` accounting entirely. Correct response is to wait for Aave to unfreeze.
L-01 (_checkSequencer): Arbitrum-specific NatSpec for audit review. `startedAt` represents when the sequencer last came back online. Normal path (sequencer never down) resolves correctly. L1 reorg edge case (`updatedAt > block.timestamp`) handled by existing guard.
L-02 (constructor): Infinite USDC approval to `AAVE\_POOL` documented as intentional. Revoked at all five exit points. `activateAaveEmergency()` provides instant no-timelock revocation in emergency.
L-03 (resolveWeek fallback site): Historical fallback comment documents that multi-draw stale prices have no age-out. `FeedStaleFallback` event is the monitoring signal.
I-01 (contract header): USDC Circle blacklist systemic risk documented. Outside contract control.
I-02 (event comment): Aave referral code 0 confirmed intentional (no-referral default).
I-03 (_readPrice NatSpec): Zero-round edge case: `roundId == answeredInRound == 0` gives `0 < 0 = false` (passes answeredInRound check), then `price <= 0` returns 0. Correctly handled implicitly.
I-04 (closeGame): `aBalance > 0` guard before `withdraw()` prevents withdraw(0) which may revert. Confirmed intentional across all five exit functions.
---
[v1.99.11 Addendum]: Triple Audit of Code Changes -- Two Fixes Applied
Date: March 2026
Lines: 5,218 (net +8 from v1.99.11 initial)
Changes: 1 critical brace bug fixed, 1 low solvency gap fixed.
Source audit: self-conducted triple audit (Internal audit lenses) of the v1.99.11 code additions.
---
CRITICAL BUG (found and fixed): Five supply try/catch blocks had incorrect brace indentation
Location: `register()`, `registerAsOG()`, `registerAsWeeklyOG()`, `buyTickets()`, `upgradeToUpfrontOG()`.
The regex replacement that wrapped supply calls into try/catch blocks applied 8-space closing braces to blocks that opened at 12-space indentation (inside outer conditional blocks). The 8-space `}` was closing the wrong outer block rather than the `if (!aaveExited)` block. The Solidity compiler would have rejected this file.
Fix: All five closing braces corrected to 12-space indentation, matching their opening blocks.
---
LOW (found and fixed): _solvencyCheck() and getSolvencyStatus() blind to raw USDC after supply failure
Location: `\_solvencyCheck()`, `getSolvencyStatus()`.
When `!aaveExited`, both functions read `aUSDC.balanceOf()` as `totalValue`. After the M-01 supply try/catch fix, Aave supply failures result in raw USDC accumulating in the contract instead of being supplied. This raw USDC is invisible to both functions. Enough supply failures could cause `\_solvencyCheck()` to revert `SolvencyCheckFailed` in `resolveWeek()`, halting new draws. Player claims (`claimPrize`, `claimEndgame`) remain callable and unaffected.
Fix: Both functions now use:
```solidity
totalValue = aaveExited
    ? IERC20(USDC).balanceOf(address(this))
    : IERC20(aUSDC).balanceOf(address(this))
        + IERC20(USDC).balanceOf(address(this));
```
Raw USDC is now correctly counted alongside aUSDC when not yet exited. After `activateAaveEmergency()` sets `aaveExited = true`, only USDC balance is used as before.
---
Triple Audit Findings Summary (v1.99.11 code changes only)
Finding	Severity	Status
Supply try/catch brace mismatch (5 blocks)	Critical	Fixed
_solvencyCheck blind to raw USDC	Low	Fixed
Partial bounds check (minAnswer succeeds, maxAnswer reverts)	Info	Accepted -- Chainlink exposes both or neither in practice
Reserve feed zero-address guard	Confirmed clean	PASS
---
[v1.99.12]: Audit Response -- _captureYield Fix + Circuit-Breaker Hardening
Date: March 2026
Lines: 5,252 (net +34 from v1.99.11)
Changes: 2 code fixes, 3 NatSpec additions.
Source audit: Internal triple audit review of v1.99.11 changes.
---
CODE FIX: _captureYield() now consistent with _solvencyCheck() after M-01 patch (L-01)
`\_solvencyCheck()` and `getSolvencyStatus()` were updated in v1.99.11 to include raw USDC alongside aUSDC when `!aaveExited`. `\_captureYield()` was not. When `supply()` fails and raw USDC accumulates, `nonPotAllocated` already includes the failed amount (accounting runs before the supply call). Without the raw USDC addition, `aUSDC.balanceOf < nonPotAllocated`, so `realPot < prizePot` and the `if (realPot > prizePot)` condition never fires. Genuine Aave yield on successfully-deposited funds cannot be captured into `prizePot` until `activateAaveEmergency()` is called.
Fix: `\_captureYield()` now mirrors `\_solvencyCheck()`:
```solidity
uint256 actualBalance = aaveExited
    ? IERC20(USDC).balanceOf(address(this))
    : IERC20(aUSDC).balanceOf(address(this))
        + IERC20(USDC).balanceOf(address(this));
```
No double-count: `nonPotAllocated` already includes the failed supply amount via the pre-supply accounting. With this fix, `actualBalance = aUSDC + rawUSDC = nonPotAllocated + yield`, so yield capture works correctly throughout the failed-supply window.
All three accounting functions (`\_captureYield`, `\_solvencyCheck`, `getSolvencyStatus`) now use the same formula.
---
CODE FIX: Circuit-breaker maxAns > 0 guard (L-03)
The v1.99.11 bounds check was:
```solidity
if (price <= int256(minAns) || price >= int256(maxAns)) return 0;
```
If a feed returns `maxAnswer = 0` (severe misconfiguration but technically possible on legacy or custom aggregators), then `price >= int256(0)` is true for any positive price. Every call to `\_readPrice()` for that feed would return 0, permanently locking it to `lastValidPrices`.
Fix (applied to both `\_readPrice()` and `\_readPriceFeed()`):
```solidity
if (maxAns > 0 \&\&
    (price <= int256(minAns) || price >= int256(maxAns))) return 0;
```
If `maxAns <= 0`, the bounds check is skipped entirely -- the feed is treated as a legacy feed without circuit-breaker bounds, consistent with the `try/catch` fallback for feeds that don't expose these functions.
---
NATSPEC ADDITIONS (3)
L-02 (_withdrawAndTransfer operator runbook): When `AaveSupplyFailed` has emitted, raw USDC is held but Aave has less than `totalAllocated`. Any `withdraw()` call requesting more than the Aave balance reverts `AaveLiquidityLow`, blocking all player withdrawals. Call `activateAaveEmergency()` immediately after `AaveSupplyFailed` emits.
L-03 (_readPrice deployment verification): Deployers should confirm `minAnswer > 0` and `maxAnswer > 0` on all 32 feeds before deployment. The `maxAns > 0` runtime guard mitigates the zero-maxAnswer case, but a deployment-time check is the cleanest defence.
I-01 (resolveWeek gas note): `\_readPrice()` now makes up to 3 external calls per asset. For 32 feeds: up to 96 additional external calls per draw resolution, ~100-200K additional gas on Arbitrum. Front-end gas estimators should account for this.
---
[v1.99.13]: Circuit-Breaker Independence Fix + Submission Hygiene
Date: March 2026
Lines: 5,273 (net +21 from v1.99.12)
Changes: 2 code fixes, 5 NatSpec additions.
Source audit: Internal triple audit. Third submission review. One unfixed MEDIUM resolved.
---
CODE FIX: Independent circuit-breaker try/catch blocks -- M-01 (three sessions)
The nested try/catch structure in `\_readPrice()` and `\_readPriceFeed()` silently skipped the floor check when `maxAnswer()` reverted:
```solidity
// OLD: nested -- if maxAnswer() reverts, minAnswer floor check never fires
try minAnswer() returns (int192 minAns) {
    try maxAnswer() returns (int192 maxAns) {
        if (maxAns > 0 \&\& (price <= minAns || price >= maxAns)) return 0;
    } catch {}  // maxAnswer failed -- entire bounds check skipped
} catch {}
```
Fix: Fully independent try/catch blocks in both functions:
```solidity
// NEW: independent -- each check fires regardless of the other
try AggregatorMinMax(addr).minAnswer() returns (int192 minAns) {
    if (price <= int256(minAns)) return 0;
} catch {}
try AggregatorMinMax(addr).maxAnswer() returns (int192 maxAns) {
    if (maxAns > 0 \&\& price >= int256(maxAns)) return 0;
} catch {}
```
A feed exposing only `minAnswer()` now gets floor protection. A feed exposing only `maxAnswer()` now gets ceiling protection. The `maxAns > 0` guard stays on the ceiling check only (a zero floor is valid -- means no floor constraint).
Self-audit knock-on checks: All 7 scenarios verified clean. Gas impact neutral in normal operation; 1 extra call only when `minAnswer()` reverts (acceptable trade-off for correct protection). `return price` semantics unchanged.
---
CODE FIX: claimSignupRefund() unguarded pendingIntentCount-- (L-01)
```solidity
// OLD: unguarded
pendingIntentCount--;

// NEW: consistent with all other decrement sites
if (pendingIntentCount > 0) pendingIntentCount--;
```
The invariant holds (PENDING status implies a prior increment), so 0.8.x would revert on underflow rather than corrupt silently. Guard added for consistency with all other decrement sites and to satisfy Internal audit static analysis.
---
NATSPEC ADDITIONS (5)
AUDIT-INFO-01 (claimSignupRefund): "100% of recoverable funds" clarification. Capped by `prizePot + treasuryBalance` at claim time.
AUDIT-INFO-01 (resolveWeek): Zero-performance tie-break documented at the `lastValidPrices == 0` fallback site. Under widespread simultaneous feed failure, the ranking becomes deterministic (lower feed index wins).
AUDIT-INFO-02 (_continueUnwind): Asymmetry cross-reference between `statusLost` path (does not update `lastActiveWeek`) and `mulliganUsed` path (sets `lastActiveWeek = lastResetDraw`). Both are intentional.
AUDIT-INFO-01 (emergencyResetDraw): `alreadyPaid = 0` for completed tiers is correct by the `distributePrizes()` zeroing invariant, not just design intent.
AUDIT-INFO-02 (_checkAutoAdjust): First-draw behaviour when `lastBreathAdjustDraw == 0` -- cooldown block skipped entirely, breath can step down on the very first eligible draw. Intentional.
---

---
[v1.99.14]: NatSpec Triple Audit Response -- Pure Documentation Pass
Date: March 2026
Lines: 5,285 (net +12 from v1.99.13)
Changes: 0 code changes, 13 NatSpec fixes.
Source audit: Internal triple audit NatSpec-only review of v1.99.13.
---
CRITICAL
C-01 [Internal audit] registerAsOG() @dev wrong revert name: Changed "reverts NotWeeklyOG()" to "reverts WrongPhase()" in the ACTIVE-phase block. Code was correct; NatSpec was stale from an earlier refactor.
C-02 [OZ] activateDormancy() stale two-pool @dev block removed: The first @dev block described the old `dormancyWeeklyPool` / `dormancyFullOGCover` two-pool model removed in v1.99.4. Entire stale block removed. The v1.99.4 four-step model @dev is the sole authoritative description.
---
MEDIUM
M-01 [Internal audit] claimEndgame() stale dual-claim @dev removed: The first @dev block (v1.5 dual-claim design referencing `dormancyWeeklyPool`) was superseded in v1.99.4. Removed. The v1.99.4 DORMANCY GUARD @dev block is the correct and complete statement.
M-02 [ToB] sweepResetRefundRemainder() truncated sentence completed: Sentence ending in "and" now reads "and nonReentrant prevents concurrent execution. No sensitive state is read during the sweep beyond the pool balance."
M-03 [OZ] submitPicks() @notice corrected: Changed "Updates asset picks for an OG who has already bought tickets this draw" to "Updates asset picks for an active OG (upfront or weekly) during the pick window of the current draw." Upfront OGs never buy tickets; the old @notice was false for the primary caller.
---
LOW
L-01 [Internal audit] _lockOGObligation() opening claim fixed: Removed "confirms it hasn't drifted (no new OGs since draw 7)." The function does no such check. Replaced with: "This function uses the live OG counts at draw 10. targetReturnBps was set at draw 7 and is not re-checked here."
L-02 [OZ] distributePrizes() totalUnclaimedPrizes stage corrected: Moved the increment description to the per-winner inner loop context. Removed the false "After all tiers complete, totalUnclaimedPrizes is incremented" statement.
L-03 [ToB] getWeekPerformance() NatSpec added: Full @notice and @dev added documenting the `type(int256).min` sentinel for dead feeds, distinguishing it from zero-performance assets.
L-04 [Internal audit] Five missing @dev blocks added: `sweepFailedPregame()`, `claimUnusedCredit()`, `claimCharity()`, `sweepUnclaimedEndgame()`, `sweepUnclaimedPrizes()`. All now document key behaviour including CLOSED-only restriction, permissionless vs onlyOwner, ENDGAME_SWEEP_WINDOW (548 days) gate, and sentinel guard cross-references.
---
INFORMATIONAL
I-01 [OZ] claimPrize() duplicate @notice removed: Two consecutive identical `@notice` lines reduced to one.
I-02 [ToB] getOGCapInfo() @dev updated: "In ACTIVE phase" changed to "In non-PREGAME phases" -- `ogCapDenominator` is also used in DORMANT and CLOSED.
I-03 [Internal audit] _calibrateBreathTarget() dangling fragment fixed: "emergency-reset." standalone sentence replaced with "This function can also fire on the RESET_FINALIZING path after an emergency-reset."
I-04 [OZ] getCurrentPrizeRate() draw-52 guidance corrected: Replaced "Check getSolvencyStatus() for projected draw 52 prizes" with the correct pointer: `getProjectedEndgamePerOG()` for OG endgame and `prizePot - requiredEndPot` for surplus. `getSolvencyStatus()` is a health check, not a prize estimator.
---

---
[v1.99.15]: NatSpec Audit Response -- sweepFailedPregame Rewrite
Date: March 2026
Lines: 5,300 (net +15 from v1.99.14)
Changes: 0 code changes, 5 NatSpec fixes.
Source audit: Fresh Internal triple audit triple pass on v1.99.14.
---
CRITICAL
C-01 [Internal audit] sweepFailedPregame() @dev entirely rewritten: The v1.99.14 @dev was fabricated from memory and wrong in five distinct ways. The complete replacement (written from direct code reading):
Errors corrected:
"Permissionless" -- FALSE. Function is `onlyOwner`.
"batch refunds from commitmentRefundPool" -- FALSE. No individual refunds executed here.
"sets allRefunded = true" -- FALSE. No such variable exists.
"emits PregameRefundComplete" -- FALSE. Emits `FailedPregameSwept` and `CharityClaimed`.
"MAX_PREGAME_DAYS" -- FALSE. Constant is `MAX\_PREGAME\_DURATION`.
Accurate replacement documents: `onlyOwner`. Two entry conditions: (a) `committedPlayerCount == 0 AND block.timestamp >= signupDeadline` (all players refunded individually); (b) `block.timestamp >= signupDeadline + MAX\_PREGAME\_DURATION + FAILED\_PREGAME\_SWEEP\_EXTENSION`. On execution: exits Aave if still active, transitions to CLOSED, transfers all USDC above `treasuryBalance` to CHARITY. Individual player refunds via `claimSignupRefund()` are separate. Emits `FailedPregameSwept` and `CharityClaimed`.
---
LOW
L-01 [OZ] claimCharity() three settlement sources documented: `endgameCharityAmount` has three sources in `closeGame()`: (a) full `prizePot` if `qualifiedOGs == 0`, (b) cap-overflow surplus when `rawPerOG > OG\_UPFRONT\_COST`, (c) OG share rounding dust in normal settlement. Prior NatSpec mentioned only "OG dust and zero-OG surplus."
---
INFORMATIONAL
I-01 [Internal audit] _calibrateBreathTarget() "MORE accurate" removed: Editorial claim was only valid if OG status changed during the reset. Replaced with neutral: "correctly accounting for any OG status restorations" and a note that accuracy is identical to the normal path if no status changed.
I-02 [ToB] getCurrentPrizeRate() draw-52 surplus -- no single view call: Added note that callers need `getGameState()` for `prizePot` and `requiredEndPot` separately, then compute the difference manually. No single view function returns surplus directly.
I-03 [OZ] claimUnusedCredit() PATH 5 mechanism clarified: PATH 5 returns `prepaidCredit` via the universal cleanup block, not as a dedicated direct path. Wording updated to reflect the actual mechanism.
---

---
[v1.99.16]: PREGAME Yield Capture + Constructor Guard Order + NatSpec
Date: March 2026
Lines: 5,334 (net +34 from v1.99.15)
Changes: 2 code fixes, 3 NatSpec additions.
Source audit: Internal triple audit.
---
CODE FIX: startGame() now captures PREGAME yield before BreathCalibrated fires (L-01)
PREGAME deposits (OG intents at $1,040, weekly OG registrations, commitment payments) sit in Aave from registration through `startGame()`. This accrual window can be days or weeks. `\_captureYield()` was not called at `startGame()`, meaning the initial breath calibration (`BreathCalibrated` event) ran on a slightly understated `prizePot`. Yield was not lost -- it would be captured on the first `resolveWeek()` call -- but the initial breath target was set against the wrong number.
Fix: `\_captureYield()` is now the first call in `startGame()` after `\_checkSequencer()`, before the feed validation loop and `BreathCalibrated` emission.
---
CODE FIX: Constructor sequencer zero-address check moved before assignment (I-01)
The pattern throughout the constructor is: check then assign. The `SEQUENCER\_FEED` assignment was the only exception -- it assigned then checked. Functionally identical (the constructor reverts atomically), but inconsistent with the established guard-then-assign pattern. Check moved before the assignment.
---
NATSPEC ADDITIONS (3)
I-02 (_matchAndCategorize): Full `@notice` and `@dev` added to the prize mechanic heart of the contract. Documents the packed uint32 pick encoding, `exactMatches` (same rank AND same asset), `anyMatches` (right asset, any rank), and all four tier conditions (JP, P2, P3, P4) with the P4 double-counting guard.
I-03 (claimCommitmentRefund): `@notice` and `@dev` added documenting: triggered by draw-1 emergency reset, refund = `min(TICKET\_PRICE, commitmentRefundPool)`, 30-day deadline, clears `p.commitmentPaid`, decrements `committedPlayerCount`. Distinguished from `claimSignupRefund()` (failed PREGAME) and `claimResetRefund()` (draws 2+).
startGame() L-01 context note: Added to existing NatSpec explaining that `\_captureYield()` fires first so PREGAME yield lands in `prizePot` before `BreathCalibrated` fires.
---

---
[v1.99.17]: Dead Branch Removal + Fragment Fix + Info NatSpec
Date: March 2026
Lines: 5,346 (net +12 from v1.99.16)
Changes: 2 code fixes, 2 NatSpec additions.
Source audit: Internal triple audit. All v1.99.16 fixes confirmed. One carry-forward and three new informational findings addressed.
---
CODE FIX: getCurrentPrizeRate() corrupted NatSpec fragment repaired (carry-forward)
The I-04/I-02 NatSpec edit chain across v1.99.14/v1.99.15 left a garbled line: `use getPr    ///      use getProjectedEndgamePerOG()`. Cleaned to a single correct line.
---
CODE FIX: _checkSequencer() dead branch removed (I-03)
`if (SEQUENCER\_FEED == address(0)) return` was permanently unreachable: `SEQUENCER\_FEED` is immutable and the constructor enforces non-zero since v1.1. Internal audit static analysis would flag this. Branch removed. Replacement comment documents the removal rationale and the Pick432Whale (ETH Mainnet) context where `address(0)` is the valid no-sequencer path.
---
NATSPEC ADDITIONS (2)
I-01 (payCommitment -- PENDING+commitment double-increment): A player who calls `registerAsOG()` (increments `committedPlayerCount`, sets `ogIntentStatus = PENDING`) then calls `payCommitment()` double-increments `committedPlayerCount` and leaves a `pendingIntentCount` entry blocking `startGame()`. Attack cost ~$1,050 with zero benefit. Resolution: `forceDeclineIntent()`. Documented for audit submission.
I-02 (_calibrateBreathTarget -- 1-BPS discontinuity): At `actualRatioBps = 9000`, Seg C yields `targetReturnBps = 5000`; at 9001, Seg D yields 4999. Known integer division artefact in the piecewise-linear approximation. Immaterial at any realistic OG concentration. Documented inline at the boundary.
---

---
[v1.99.18]: Duplicate @notice Removed + startGame Discontinuity Cross-Reference
Date: March 2026
Lines: 5,347 (net +1 from v1.99.17)
Changes: 0 code changes, 2 NatSpec fixes.
Source audit: Internal triple audit. All v1.99.17 fixes confirmed. Two informational NatSpec gaps closed.
---
NATSPEC: claimCommitmentRefund() duplicate @notice removed (I-01)
The v1.99.16 addition of the accurate `@notice` ("Refunds the caller's commitment deposit if it was not consumed as a draw-1 ticket.") left the prior stale notice ("Refunds up to TICKET_PRICE from the commitment pool if the game was emergency-reset on draw 1.") in place above it. Stale notice removed. One `@notice` remains.
---
NATSPEC: startGame() piecewise formula cross-reference added (I-02)
`startGame()` contains the identical piecewise-linear OG ratio formula as `\_calibrateBreathTarget()`. The 1-BPS discontinuity at the 9000/9001 boundary was documented in `\_calibrateBreathTarget()` in v1.99.17 but not in `startGame()`. A cross-reference comment now points auditors reading `startGame()` in isolation to the `\_calibrateBreathTarget()` discontinuity note.
---

---
[v1.99.19]: Dormancy Snapshot Fix + Post-Sweep Player Info + yieldBonus Header
Date: March 2026
Lines: 5,374 (net +27 from v1.99.18)
Changes: 3 code fixes, 1 NatSpec addition.
Source audit: Internal triple audit.
---
CODE FIX: totalOGPrincipalSnapshot -- frozen denominator for dormancy proportional formula (AUDIT-M-01 / ECON-M-01)
Root cause: `claimResetRefund()` has no phase guard and can be called during DORMANT. It decrements `totalOGPrincipal`. PATH 1 and PATH 2 of `claimDormancyRefund()` used `totalOGPrincipal` as the live denominator in the underfunded proportional formula. Any OG who called `claimResetRefund()` after dormancy activation would silently shrink that denominator, over-paying subsequent claimants at the expense of earlier ones.
Fix:
New state variable: `uint256 public totalOGPrincipalSnapshot`
Set in `activateDormancy()` STEP 1: `totalOGPrincipalSnapshot = totalOGPrincipal`
PATH 1 and PATH 2 of `claimDormancyRefund()` now use `totalOGPrincipalSnapshot` as the frozen denominator
`totalOGPrincipal` continues to track accounting mutations normally. The snapshot is the fair, immutable denominator for dormancy distribution.
Self-audit knock-ons (all pass):
Zero default harmless before dormancy (paths gated by `gamePhase == DORMANT`)
`sweepDormancyRemainder()` does not touch the snapshot
`getDormancyInfo()` does not return `totalOGPrincipal` (unaffected)
`processMatches()` and `\_continueUnwind()` use live `totalOGPrincipal` during ACTIVE (correct)
No old `dormancyOGPoolSnapshot / totalOGPrincipal` denominators remain anywhere
---
CODE FIX: getPlayerInfo() returns 0 for unclaimedPrizes post-sweep (AUDIT-M-01)
After `sweepUnclaimedPrizes()` zeroes `totalUnclaimedPrizes`, individual `p.unclaimedPrizes` values remain non-zero in storage. `claimPrize()` correctly blocks claims via the `totalUnclaimedPrizes == 0` sentinel. But `getPlayerInfo()` was returning the stale `p.unclaimedPrizes` value, misleading front-end integrators.
Fix: One derived variable:
```solidity
uint256 displayUnclaimed = totalUnclaimedPrizes == 0 ? 0 : p.unclaimedPrizes;
```
No false-zero risk during normal play -- `totalUnclaimedPrizes` is only 0 after all claims or post-settlement sweep.
---
CODE FIX: yieldBonus header comment corrected (AUDIT-M-02)
The contract header changelog contained: "Yield accrued during the 90-day claim window flows entirely to qualified weekly OGs via yieldBonus." There is no `yieldBonus` mechanic. The 90-day DORMANT claim window yield flows to CHARITY via `sweepDormancyRemainder()`. Header corrected.
---
NATSPEC: getProjectedEndgamePerOG() obligation vs distribution denominator (AUDIT-M-02)
`ogEndgameObligation` is set from upfront OG counts only. `\_countQualifiedOGs()` includes both upfront and qualified weekly OGs in the distribution denominator. `obligation` is the protocol's capital commitment anchor, not the total payout promise to all qualified OGs. Front-ends must use `currentPerOG`, not `obligation`, for player-facing endgame estimates.
---

---
[v1.99.20]: Three Pre-Submission Fixes
Date: March 2026
Lines: 5,385 (net +11 from v1.99.19)
Changes: 2 code fixes, 1 NatSpec correction.
Final pre-submission fixes identified post-v1.99.19.
---
CODE FIX: sweepDormancyRemainder() zeros totalOGPrincipalSnapshot
`totalOGPrincipalSnapshot` was being left stale (non-zero) in storage after settlement while the eleven other dormancy variables were zeroed. One line added alongside `totalOGPrincipal = 0`:
```solidity
totalOGPrincipalSnapshot = 0;
```
Symmetric zeroing. Prevents auditors flagging the asymmetry.
---
CODE FIX: payCommitment() PENDING/OFFERED guard added
The NatSpec in v1.99.17 documented the double-increment attack path but the guard was never applied. A player with `ogIntentStatus == PENDING` or `OFFERED` calling `payCommitment()` would double-increment `committedPlayerCount` and block `startGame()`. One guard added after the `commitmentPaid` check:
```solidity
if (ogIntentStatus\[msg.sender] == OGIntentStatus.PENDING ||
    ogIntentStatus\[msg.sender] == OGIntentStatus.OFFERED)
    revert AlreadyInIntentQueue();
```
`AlreadyInIntentQueue` already existed. `DECLINED` and `SWEPT` players are not blocked -- a player who declined an OG intent may legitimately commit as a regular player.
---
NATSPEC: claimDormancyRefund() frozen denominator comment corrected
The v1.99.5 comment "Snapshot formula requires totalOGPrincipal frozen at activation value" was inaccurate -- `totalOGPrincipal` is the variable that was NOT frozen (that was the AUDIT-M-01 bug). Updated to: "`totalOGPrincipalSnapshot` provides the frozen denominator guarantee. `totalOGPrincipal` itself is NOT frozen."
---

---
[v1.99.21]: ogList Guard + Draw-1 Weekly OG Docs + Pool Oversize Note
Date: March 2026
Lines: 5,402 (net +17 from v1.99.20)
Changes: 1 code fix, 3 NatSpec additions.
Source audit: ogList integrity pass, streak tracking pass, fee arithmetic pass.
---
CODE FIX: _cleanupOGOnRefund() defensive swap-and-pop guard (LOW)
The swap-and-pop assumed the player is at `ogList\[ogListIndex\[addr]]`. This holds under current flow but would silently corrupt the array if any future code path set `isUpfrontOG = true` without a corresponding push. Guard added:
```solidity
if (ogLen > 0 \&\& ogListIndex\[addr] < ogLen \&\& ogList\[ogListIndex\[addr]] == addr)
```
The bounds check (`ogListIndex\[addr] < ogLen`) prevents out-of-bounds array access. The identity check (`ogList\[...] == addr`) ensures the removal only fires if addr is genuinely present at the recorded index. Inner swap-and-pop body unchanged.
---
NATSPEC: getOGListIndex() index-0 membership trap (INFO)
`ogListIndex` returns 0 as the default mapping value for non-members AND as the legitimate index for the OG at slot 0. Any indexer checking `getOGListIndex(addr) != 0` will misidentify every non-member as valid and miss the slot-0 OG. Correct membership check documented: `ogList.length > 0 \&\& ogList\[ogListIndex\[addr]] == addr`.
---
NATSPEC: buyTickets() weekly OG draw-1 AlreadyBoughtThisWeek (INFO)
Weekly OGs registered in PREGAME have `lastBoughtDraw` pre-set to 1 at registration. In draw 1 they hit `AlreadyBoughtThisWeek` from `buyTickets()` even though they have never called that function manually. This is correct -- they are already credited. Comment added directing them to `submitPicks()` for pick updates.
---
NATSPEC: emergencyResetDraw() commitmentRefundPool oversized at draw 1 (INFO)
When a draw-1 emergency reset fires, `commitmentRefundPool = committedPlayerCount \* TICKET\_PRICE`. `committedPlayerCount` includes credit-path weekly OGs whose commitment was applied at PREGAME registration (`commitmentPaid = false`). Those players cannot call `claimCommitmentRefund()`. The pool is oversized by `TICKET\_PRICE` per credit-path weekly OG. Excess sweeps to CHARITY after `RESET\_REFUND\_WINDOW` (30 days). No player is shorted.
---

---
[v1.99.22]: State Machine Gap + Invariant Docs + Permissionless Design Notes
Date: March 2026
Lines: 5,429 (net +27 from v1.99.21)
Changes: 3 code fixes, 4 NatSpec additions.
Source audit: prize distribution, endgame settlement math, draw state machine.
---
CODE FIX: distributePrizes() gamePhase guard added (F-M-01)
Every other draw phase function carries both `gamePhase == ACTIVE` and its own `drawPhase` guard. `distributePrizes()` only checked `drawPhase == DISTRIBUTING`. Currently unreachable from a non-ACTIVE phase (DISTRIBUTING requires MATCHING which required ACTIVE), but the state machine inconsistency is a gap. One line added as the first guard:
```solidity
if (gamePhase != GamePhase.ACTIVE) revert GameNotActive();
```
---
CODE FIX: TierSkippedDust event -- perWinner == 0 silent absorb now visible (LOW)
When `tierPools\[tier] / winners.length == 0` due to integer division, the tier pool returned silently to `prizePot`. Correct behaviour, but invisible to off-chain monitors. New event:
```solidity
event TierSkippedDust(uint256 indexed tier, uint256 amount);
```
Emitted in the `perWinner == 0` branch before the tier advance. Pool still returns to `prizePot` unchanged.
---
NATSPEC: closeGame() endgameOwed == prizePot formal invariant
Formally verified algebraically across all three settlement paths:
PATH A (normal): `endgameOwed = endgamePerOG \* qualifiedOGs + charityShare = prizePot` ✓
PATH B (cap overflow): cap excess added to charityShare, total still equals `prizePot` ✓
PATH C (qualifiedOGs == 0): `endgameOwed = 0 + prizePot = prizePot` ✓
audit submission reference: this invariant holds in all cases.
---
NATSPEC: distributePrizes() and resolveWeek() permissionless design intent
Both functions are callable by anyone. This is intentional: owner absence or inaction cannot block the game from progressing. Player funds should never be held hostage to operator liveness. Pre-emptive answer for submission "why is this permissionless?" question.
---
NATSPEC: sweepDormancyRemainder() dormancyTimestamp permanently non-zero
`dormancyTimestamp` is never zeroed after `activateDormancy()` fires -- including in CLOSED phase post-settlement. This is intentional: the non-zero flag signals that CLOSED was reached via dormancy (no endgame-per-OG pool). `claimEndgame()` uses this flag to block upfront OG endgame claims post-dormancy.
---

---
[v1.99.23]: Final Pre-Submission NatSpec Pass
Date: March 2026
Lines: 5,449 (net +20 from v1.99.22)
Changes: 0 code changes, 5 NatSpec additions.
Source audit: Chainlink feed reading (Audit G), breath/EMA formula (Audit H), player capacity (Audit I). All code verified numerically and algebraically correct. Five pre-submission documentation actions.
---
NATSPEC: breathOverrideLockUntilDraw suppresses 4 draws not 3 (H-L-01)
State variable comment corrected from "3 draws" to "4 draws." When `executeBreathOverride()` fires during draw N's IDLE phase, `lockUntilDraw = N + BREATH\_COOLDOWN\_DRAWS = N + 3`. The `currentDraw <= lockUntilDraw` check in `\_checkAutoAdjust()` suppresses draws N, N+1, N+2, N+3 -- four draws. The extra draw of protection is harmless and intentionally conservative. No code change -- correct behaviour, corrected documentation.
---
NATSPEC: setReserveFeeds() greedy consumption ordering (G-INFO-01)
Reserve feeds are consumed in array order at `startGame()` across all failing primary feeds. The first failing primary takes `reserveFeeds\[0]`, the second takes `reserveFeeds\[1]`, etc. No guaranteed pairing between specific primaries and specific reserves. Operators should place the most reliable fallback feeds at lower array indices.
---
NATSPEC: buyTickets() status-lost OG capacity gap (I-L-01)
Status-lost weekly OGs have `lastBoughtDraw` pre-set from PREGAME registration (not 0), so `isFirstBuy = false` when they re-engage as casual buyers. This capacity check does not fire for them and they are absent from every term of the capacity formula. Theoretical overshoot is bounded by the number of status-lost OGs who re-buy. No financial risk.
---
NATSPEC: claimEndgame() dormancyTimestamp cross-reference (E-L-01 carry-forward)
One-line cross-reference added at the `dormancyTimestamp > 0` guard: permanent non-zero is intentional, signals no per-OG endgame pool, see `sweepDormancyRemainder()` for authoritative explanation.
---
NATSPEC: finalizeWeek() scheduleAnchor subtraction safety (F-L-01 carry-forward)
`scheduleAnchor = block.timestamp - currentDraw \* DRAW\_COOLDOWN`. Subtraction is safe because `isResetFinalize` only fires after at least one draw has resolved, meaning `block.timestamp >= DEPLOY\_TIMESTAMP + currentDraw \* DRAW\_COOLDOWN`. No underflow possible.
---
Verified correct in this audit cycle (no changes needed)
Circuit-breaker int192→int256 cast: safe widening conversion, no overflow possible
Stale fallback price aging: dead feed contributes 0% performance until recovery
`answeredInRound` staleness check: correct for Arbitrum phased aggregators
Predictive formula: algebraically verified correct
No integer overflow in any formula term (worst-case analysis documented in report)
EMA seeding and draw-10 lock transition: correctly ordered
`activeRegistrationCount` to `totalLifetimeBuyers` conversion: no double-counting
Lapsed player unlapsing: correctly frees/occupies capacity
`register()` and `buyTickets()` capacity formulas: symmetric and consistent
---

---
[v1.99.24]: NatSpec Gap Fill -- Four Undocumented Functions
Date: March 2026
Lines: 5,493 (net +44 from v1.99.23)
Changes: 0 code changes, 4 NatSpec additions.
Source: full NatSpec audit of v1.99.23 identified 7 functions with no formal `@notice` or `@dev`. Four highest-priority gaps filled.
---
claimOGIntentRefund() -- @notice + @dev added
External function with the 85%/15% refund split mechanic -- highest priority gap. Documents: PREGAME-only, two eligible statuses (PENDING / OFFERED), 72-hour window for OFFERED, the 15% treasury slice is permanently kept, the 85% netRefund comes from prizePot, the deficit guard pulling from treasury if prizePot is insufficient, and CEI compliance.
---
_continueUnwind() -- @notice + @dev added
The OG status restoration engine called by emergencyResetDraw(). Documents: gas guard (gasleft < 150,000 returns early for retry), what is restored (weeklyOGStatusLost, mulliganUsed), what is NOT restored (consecutiveWeeks -- OG genuinely missed the reset draw), the lastActiveWeek fix (v1.99.8), and the asymmetry between statusLost and mulliganUsed paths.
---
_updateStreakTracking() -- @notice + @dev added
The streak mechanic heart. Documents all four execution paths: FIRST BUY (initialise), SAME DRAW (no-op), CONSECUTIVE (streak++, qualifiedWeeklyOGCount increment if threshold reached), GAP (streak reset, qualifiedWeeklyOGCount decrement if was qualified, StreakBroken event).
---
_cleanupOGOnRefund() -- @notice + @dev added
Internal helper for failed-pregame OG exits. Documents: upfront vs weekly OG handling, which counters are adjusted (totalOGPrincipal, ogList, pregame revenue totals), and the defensive swap-and-pop guard added in v1.99.21.
---

---
[v1.99.25]: Ownership Fix + Two NatSpec Gaps
Date: March 2026
Lines: 5,508 (net +15 from v1.99.24)
Changes: 1 code fix, 3 NatSpec additions.
Source audit: Ownership and access control (Audit J), prepaidCredit lifecycle (Audit K), JP miss redistribution and tier pool arithmetic (Audit L).
---
CODE FIX: transferOwnership() zero-address guard (J-L-01)
Every address guard in the contract emits `InvalidAddress()`. `transferOwnership()` was the one exception -- without an explicit guard, passing `address(0)` would revert via OZ's `OwnableInvalidOwner(address(0))` instead.
One line added before the super call:
```solidity
if (newOwner == address(0)) revert InvalidAddress();
```
Consistent error signature. Zero risk -- still reverts; now reverts with the correct contract-native error.
---
NATSPEC: transferOwnership() OWNERSHIP_TRANSFER_EXPIRY == TIMELOCK_DELAY parity (J-INFO-01)
Both `OWNERSHIP\_TRANSFER\_EXPIRY` and `TIMELOCK\_DELAY` are 7 days. This parity is intentional: ownership transfers carry the same deliberation window as all governance proposals. Documented in `transferOwnership()` @dev.
---
NATSPEC: topUpCredit() maxCredit cap calculation (K-L-01)
`maxCredit = TOTAL\_DRAWS \* EXHALE\_TICKET\_PRICE \* MAX\_TICKETS\_PER\_WEEK = $1,560`. Sized to cover all 52 draws at maximum exhale-phase ticket cost (2 tickets × $15 × 52 draws). A player who loads the cap during inhale draws can afford every draw through game end at peak pricing.
---
NATSPEC: currentTierPerWinner stale-after-TierSkippedDust warning (L-L-01)
`currentTierPerWinner` is valid only for the tier currently being distributed (`distTierIndex`). The `TierSkippedDust` path (`perWinner == 0`) does not update this variable -- after it fires, the value reflects the prior tier's per-winner amount. Off-chain tools reading this between batches should cross-check `distTierIndex`.
---
Verified correct in this audit cycle (no changes needed)
transferOwnership override chain: OZ identity gate + contract deadline gate. Belt-and-suspenders. ✓
prepaidCredit accounting identity: 6 mutation sites all symmetric. ✓
claimDormancyRefund PATH 5 + universal cleanup: correct for all player types. ✓
JP miss redistribution: zero dust at every layer (arithmetic proof). ✓
Tier pool sequencing: JP miss increments [1-3] before [0] is zeroed. Safe. ✓
TierSkippedDust stale currentTierPerWinner: 0 × stale = 0 in alreadyPaid formula. No risk. ✓
---

---
[v1.99.26]: Duplicate @notice Removed + Weekly OG Cap Clarification
Date: March 2026
Lines: 5,482 (net -26 from v1.99.25 -- stale NatSpec block removed)
Changes: 0 code changes, 2 NatSpec fixes.
---
NATSPEC: claimOGIntentRefund() duplicate @notice removed (I-01)
The original `@notice` ("Allows a player to exit the OG intent queue and reclaim their principal minus the commitment deposit...") plus its 2,319-character `@dev` block were still present above the accurate v1.99.24 `@notice` ("Voluntarily exits the OG intent queue and claims a partial refund."). Same pattern as claimCommitmentRefund() v1.99.17 I-01. Stale block removed. The v1.99.24 `@notice` and its `@dev` are the authoritative description.
---
NATSPEC: topUpCredit() weekly OG cap ceiling clarification (I-02)
The K-L-01 comment described the cap as $1,560 (52 × $15 × 2). Weekly OGs always pay `TICKET\_PRICE` ($10) regardless of phase -- their true maximum spend is 52 × $10 × 2 = $1,040. The $520 gap above their ceiling is recoverable via `claimUnusedCredit()` at game close. Note added.
---

---
[v1.99.27]: Four Code Fixes + Three NatSpec Additions
Date: March 2026
Lines: 5,524 (net +42 from v1.99.26)
Changes: 4 code fixes, 3 NatSpec additions.
Source audit: Triple-pass Internal audit. No new criticals or highs.
---
CODE FIX: claimDormancyRefund() PATH 4 -- p.totalPaid zeroed (M-01)
PATH 4 (commitment-only player) zeroed `p.commitmentPaid` and decremented `committedPlayerCount` but left `p.totalPaid = TICKET\_PRICE ($10)` stale after the refund. No current financial risk (`dormancyRefunded = true` blocks re-entry), but `getPlayerInfo()` returned $10 paid for a fully made-whole player, misleading dashboards. One line added after `p.commitmentPaid = false`:
```solidity
p.totalPaid = 0;
```
---
CODE FIX: emergencyResetDraw() -- cancel pendingMultiplier timelock (L-02)
Three timelocks were already cancelled on emergency reset (breath override, breath rails, dormancy proposal). The prize-rate multiplier (`pendingMultiplier`) was not, leaving a live rate-change proposal to execute silently in the next IDLE window if the owner forgot `cancelPrizeRateReduction()`. Added cancellation block after the dormancy cancel:
```solidity
if (pendingMultiplier != 0) {
    bool isReduction = pendingMultiplier < prizeRateMultiplier;
    pendingMultiplier       = 0;
    pendingMultiplierReason = bytes32(0);
    multiplierEffectiveTime = 0;
    if (isReduction) emit PrizeRateReductionCancelled();
    else             emit PrizeRateIncreaseCancelled();
}
```
---
CODE FIX: sweepResetRefundRemainder() -- removed !aaveExited from CLOSED revert (L-03)
`if (gamePhase == GamePhase.CLOSED \&\& !aaveExited) revert TooEarly()` forced an unnecessary `executeAaveExit()` call before expired reset-refund pools could clear. `\_withdrawAndTransfer()` handles `!aaveExited` correctly internally. The `!aaveExited` condition served no functional purpose and degraded UX with a misleading `TooEarly()` revert. Removed. CLOSED phase still reverts; the !aaveExited restriction is gone.
---
CODE FIX: processMatches() -- clear p.picks on status loss (L-04)
When a weekly OG loses status, `weeklyOGStatusLost = true` was set but `p.picks` was left non-zero until the owner called `pruneStaleOGs()`. The gap produced contradictory state (`statusLost = true` + non-zero picks) visible to `getPlayerInfo()`. Added `p.picks = 0` immediately after `p.statusLostAtDraw = currentDraw`. `pruneStaleOGs()` redundantly clears it again -- harmless.
---
NATSPEC: ResetRefundSkipped event -- three-reset runbook (M-03)
Both reset pools can be simultaneously occupied if two resets fire within 30 days. A third reset emits `ResetRefundSkipped` with no on-chain recourse for affected ticket holders. Prevention documented: call `sweepResetRefundRemainder()` between resets to free expired slots. Skipped funds remain in `prizePot` (indirect benefit to all players).
---
NATSPEC: _checkAutoAdjust() -- BREATH_COOLDOWN_DRAWS asymmetry (L-01)
The `<` comparison produces `BREATH\_COOLDOWN\_DRAWS - 1` (2) effective draws of suppression, not 3. This is deliberate: the auto-adjust cooldown is intentionally 2 draws. Contrast with `breathOverrideLockUntilDraw` which uses `<=` and suppresses 4 draws. The asymmetry is by design.
---
NATSPEC: DormancyClaimDeadline event -- sweep-window semantics (I-03)
Despite the name, `DormancyClaimDeadline` emits the sweep window opening timestamp, not a claim deadline. Players may claim at any point while `gamePhase == DORMANT`. The emitted timestamp is the earliest the owner can call `sweepDormancyRemainder()`. Front-ends must display this as "sweep opens" not "claim by".
---
Accepted design -- no action (confirmed in this audit)
M-02: Predictive breath + prizeRateMultiplier bias -- accepted conservative overshoot, NatSpec complete.
M-04: PATH 3 silent skip -- accepted, per-head still runs.
L-05: ACTIVE register() inhale-price credit -- deferred, topUpCredit() mitigation.
---

---
[v1.99.27]: Dormancy PATH 4 Fix + Multiplier Cancel + Sweep Routing Fix + Picks Clear
Date: March 2026
Lines: 5,530 (net +48 from v1.99.26)
Changes: 5 code fixes, 4 NatSpec additions.
Source audits: Internal audit full pass. New findings M-01, M-03, L-01 through L-04, I-01 through I-04. Plus regression M-01 new (L-03 fix inversion caught before build).
---
CODE FIX: claimDormancyRefund() PATH 4 p.totalPaid zeroed (M-01)
PATH 4 (commitment-only player) was zeroing `p.commitmentPaid` and decrementing `committedPlayerCount` but leaving `p.totalPaid = $10` in storage. Player is made whole by the refund but `getPlayerInfo()` reported $10 paid post-refund. Any future code checking `p.totalPaid > 0` would receive a false positive. `p.totalPaid = 0` added immediately after `p.commitmentPaid = false`.
---
CODE FIX: emergencyResetDraw() cancels pendingMultiplier (L-02)
Three timelocks were proactively cancelled by `emergencyResetDraw()` (breath override, breath rails, dormancy proposal). The pending prize-rate multiplier was not. A stale rate-change proposal could silently execute in the next IDLE window if the owner forgot to cancel manually. Cancellation block added after the dormancy cancellation, with directional event emission (`PrizeRateReductionCancelled` or `PrizeRateIncreaseCancelled` based on whether `pendingMultiplier < prizeRateMultiplier`).
---
CODE FIX: sweepResetRefundRemainder() CLOSED revert removed (L-03 + M-01 new)
Original L-03 finding: the `CLOSED \&\& !aaveExited` guard blocked the sweep unnecessarily. The intended fix was to remove `!aaveExited`. The correct fix is to remove the entire CLOSED guard -- the inner routing already handles CLOSED by directing remainder to CHARITY. Removing only `!aaveExited` would have made the revert unconditional on CLOSED, permanently stranding any reset-refund pools that expire post-game-close (no other function sweeps these pools). Full guard removed. Three inner `DORMANT || CLOSED → CHARITY` branches preserved.
---
CODE FIX: processMatches() clears p.picks = 0 on status loss (L-04)
Weekly OGs losing status in `processMatches()` now have `p.picks = 0` immediately alongside `weeklyOGStatusLost = true`. Previously `picks` was non-zero until `pruneStaleOGs()` ran, creating contradictory state in `getPlayerInfo()`. Side effect documented in NatSpec: status-loss-restored OGs (via `\_continueUnwind()`) come back with `picks = 0` and must call `submitPicks()` before the next draw. Mulligan-restored OGs retain picks (unaffected by L-04).
---
CODE FIX: getDormancyInfo() return variable renamed claimDeadline → sweepWindowOpens (I-01 new)
The I-03 NatSpec fix in v1.99.27 clarified that `DormancyClaimDeadline` event represents the sweep-window opening, not a player claim deadline. `getDormancyInfo()` returned the same timestamp as `claimDeadline` -- same semantic mismatch. Renamed to `sweepWindowOpens`. No logic change.
---
NATSPEC: DormancyClaimDeadline event semantic clarification (I-03)
Event represents the earliest time `sweepDormancyRemainder()` can be called, not a deadline after which player claims are blocked. Players may claim any time during `DORMANT` phase.
---
NATSPEC: _checkAutoAdjust() BREATH_COOLDOWN_DRAWS < vs <= asymmetry (L-01)
The `<` comparison in auto-adjust produces `BREATH\_COOLDOWN\_DRAWS - 1 = 2` effective draws of suppression, not 3. The override lock uses `<=` and produces 4 draws. The 2-draw auto-cooldown is deliberate -- faster auto-adjust recovery.
---
NATSPEC: emergencyResetDraw() three-reset pool exhaustion runbook (M-03)
When both reset pools are occupied and a third emergency reset fires, `ResetRefundSkipped` is emitted and affected players have no targeted refund path (funds remain in `prizePot`). Prevention: call `sweepResetRefundRemainder()` after each expired pool before the next reset.
---
NATSPEC: _continueUnwind() status-loss vs mulligan picks asymmetry (L-01 new + I-02)
Status-loss-restored OGs have `picks = 0` (cleared by L-04 during the reset draw). They must call `submitPicks()` before the next draw to receive prize matching. Mulligan-restored OGs retain their prior picks and auto-match without action required. Front-ends should check `picks == 0 \&\& isWeeklyOG \&\& !weeklyOGStatusLost` and prompt accordingly.
---

---
[v1.99.28]: Double-Recovery Fix + proposeDormancy Multiplier Cancel + Breath Guard
Date: March 2026
Lines: 5,551 (net +21 from v1.99.27)
Changes: 3 code fixes, 0 NatSpec additions (all prior NatSpec confirmed correct).
Source audit: triple pass v1.99.27. Three new code findings confirmed genuine. Three carry-forward "UNFIXED" claims from the audit report were incorrect -- v1.99.27 file verified correct on all three.
---
CODE FIX: claimResetRefund() status-lost weekly OG double-recovery (M-02)
Root cause: `claimResetRefund()` guarded the `p.totalPaid` and `totalOGPrincipal` decrements with `if (p.isWeeklyOG \&\& !p.weeklyOGStatusLost)`. A weekly OG who lost status in the reset draw had `weeklyOGStatusLost = true`, so the decrement was skipped. When `\_continueUnwind()` later restored the OG, it incremented `totalOGPrincipal += p.totalPaid` at full value -- but the player had already recovered part of that via reset refund. Net result: player recovers `p.totalPaid + claim` from a combination of reset refund and dormancy PATH 2.
Fix: `!p.weeklyOGStatusLost` removed from the guard in both pool 1 and pool 2 blocks. Now reads `if (p.isWeeklyOG)`. Status-lost OGs are decremented symmetrically, so `\_continueUnwind()` restores only what remains. Both pool blocks updated identically.
---
CODE FIX: proposeDormancy() cancels pendingMultiplier (L-01)
`proposeDormancy()` cancelled `pendingBreathOverride` and `breathRailsEffectiveTime` but not `pendingMultiplier`. Between `proposeDormancy()` and `activateDormancy()` (24-hour window), a pending prize-rate proposal could still execute if its timelock elapsed. Cancellation block added before `dormancyEffectiveTime` is set, mirroring the pattern added to `emergencyResetDraw()` in v1.99.27. Directional event emission (`PrizeRateReductionCancelled` or `PrizeRateIncreaseCancelled`) based on proposal direction.
---
CODE FIX: executeBreathOverride() gamePhase guard added (L-02)
`executeBreathOverride()` had no `gamePhase == ACTIVE` guard. In DORMANT phase, `drawPhase == IDLE` so the function could execute. Modifying `breathMultiplier` in DORMANT/CLOSED is semantically incorrect -- breath has no effect outside ACTIVE. `executeBreathRails()` already had this guard; the asymmetry is now closed. Guard added before `\_captureYield()`, consistent with `proposeBreathOverride()` which already required ACTIVE.
---
Audit report carry-forward findings -- verified INCORRECT
The audit report marked three findings as "UNFIXED" in v1.99.27. All three were verified correct in the saved file:
sweepResetRefundRemainder CLOSED revert: correctly absent. Inner DORMANT||CLOSED routing present x3.
getDormancyInfo return variable: correctly renamed to `sweepWindowOpens`.
_continueUnwind NatSpec picks asymmetry: correctly documented with L-01+I-02 tag, submitPicks() guidance present.
---

---
[v1.99.29]: claimCharity Guard + ABI Note + Disclosure Pass
Date: March 2026
Lines: 5,573 (net +22 from v1.99.28)
Changes: 1 code fix, 5 NatSpec additions.
Source audit: endgame settlement, sweep mechanics, streak/lapse tracking, caps/qualification, cross-function accounting invariants. No critical or high findings. Two low, four informational.
---
CODE FIX: claimCharity() explicit gamePhase guard (L-02)
`claimCharity()` relied on an implicit guard (`endgameCharityAmount` is only non-zero after `closeGame()`). Functionally equivalent, but the implicit guard depends on a cross-function invariant that a future code path could silently break. `if (!gameSettled) revert GameNotClosed()` added as the first check, consistent with `claimEndgame()` and all other settlement functions.
---
NATSPEC: getDormancyInfo() ABI breaking change note (L-01)
The v1.99.27 rename of the ninth return value from `claimDeadline` to `sweepWindowOpens` is a breaking change for named-return callers. Positional index 8 (zero-indexed) is unchanged; positional decoders are unaffected. Named-return callers -- Solidity destructuring, TypeScript/Python ABI decoders, subgraph ABIs -- must update `claimDeadline` → `sweepWindowOpens` before deployment. Documented in `getDormancyInfo()` @dev.
DormancyClaimDeadline event retained for ABI stability. The event name is semantically imprecise (it represents sweep-window opening, not a player claim deadline) but renaming it would break all event subscribers. The existing v1.99.27 NatSpec comment on the event declaration fully documents the semantic, including the rename consideration. No rename applied.
---
NATSPEC: emergencyResetDraw() amountReturned formula clarification (I-01)
The full-disruption formula `amountReturned + (distWinnerIndex \* currentTierPerWinner)` only captures the current partial tier. Prizes already credited to `p.unclaimedPrizes` in fully-completed tiers 0 through `distTierIndex-1` are excluded from `amountReturned` -- they legitimately belong to those winners. Clarification added inline.
---
NATSPEC: sweepUnclaimedEndgame() redundant zero note (I-02)
`endgameCharityAmount = 0` in `sweepUnclaimedEndgame()` may be a no-op if `claimCharity()` was already called. `endgameOwed` is always correct regardless. Safe cosmetic double-zero. Noted in @dev.
---
NATSPEC: prepaid credit Aave yield goes to prizePot (I-03)
Aave yield earned on prepaid credit balances flows into `prizePot` rather than back to the depositor. A player who loads credit and cancels via `claimUnusedCredit()` recovers exactly the deposited amount -- the yield benefits all players via the prize pool. Disclosed in `topUpCredit()` and `register()`.
---
Invariant re-verification (all hold at v1.99.29)
`totalOGPrincipal == sum(p.totalPaid for active OGs)`: holds. M-02 fix symmetric.
`\_solvencyCheck()` formula: holds. No new pool changes.
`endgameOwed == unclaimed individual shares + endgameCharityAmount`: holds algebraically across `claimEndgame()`, `claimCharity()`, `sweepUnclaimedEndgame()`.
`totalOGPrincipalSnapshot` frozen at dormancy: holds. Only written once, zeroed in sweep.
---

---
[v1.99.30]: proposeStartGame() -- Trustless 72-Hour Launch Notice
Date: March 2026
Lines: 5,640 (net +67 from v1.99.29)
Changes: 2 new functions, 5 modified functions, 2 constants, 2 state vars, 1 error, 2 events.
Design: PREGAME OGs who have been offered a slot (OFFERED status) must have a guaranteed 72-hour exit window before the game locks. Previously, `startGame()` could fire immediately with no notice. This change makes launch trustless and auditable.
---
NEW FUNCTION: proposeStartGame()
Owner calls this to open the 72-hour notice window before launch. Guards:
`gamePhase == PREGAME`
`committedPlayerCount >= MIN\_PLAYERS\_TO\_START`
`pendingIntentCount == 0` (all intents must be processed first)
No active proposal
`latestOfferTimestamp` is at least 66 hours old (OG_INTENT_WINDOW - START_GAME_OFFER_BUFFER)
The 66-hour buffer ensures any OG in the most recent confirmation batch has at most 6 hours of decline window remaining -- which expires within the 72-hour notice period. No OG can be trapped.
If `latestOfferTimestamp == 0` (no OG offers ever made -- weekly-OG-only game), buffer check is skipped. Emits `StartGameProposed(launchNotBefore)`.
During the notice window: `confirmOGSlots()` and `registerAsOG()` are both blocked. The notice period is frozen.
---
NEW FUNCTION: cancelStartGameProposal()
Owner cancels a pending proposal. `latestOfferTimestamp` is NOT reset -- independent of proposal state. Owner may re-propose immediately if the buffer condition is still satisfied.
---
MODIFIED: startGame()
Three changes:
Guard reorder: `MAX\_PREGAME\_DURATION` expiry check moved to position 2 (before `committedPlayerCount`). If the PREGAME window expires during the notice period, `startGame()` reverts `PregameWindowExpired` rather than `NoTimelockPending` -- clearer signal.
Two new guards: `startGameProposedAt == 0 → NoTimelockPending` and `block.timestamp < startGameProposedAt + START\_GAME\_NOTICE\_PERIOD → TooEarly`.
`startGameProposedAt = 0` on successful launch.
---
MODIFIED: confirmOGSlots()
Two changes:
Blocked during active proposal (`startGameProposedAt != 0 → TimelockPending`).
`latestOfferTimestamp = block.timestamp` recorded on each OFFERED confirmation.
---
MODIFIED: registerAsOG()
PREGAME path blocked during active proposal (`startGameProposedAt != 0 → TimelockPending`). New PENDINGs during the notice window would block `startGame()` and cannot be processed (confirmOGSlots also blocked). Clear error for players attempting late registration.
---
MODIFIED: getPreGameStats()
New return field `proposalTimestamp` (index 6, zero-indexed). `0` = no proposal active. ABI NOTE: Named-return callers must update. Positional index is additive -- no existing fields moved.
---
MODIFIED: getOGCapInfo() NatSpec
`readyToStart` note updated: does not check `pendingIntentCount == 0` or `startGameProposedAt`. Front-ends must check both separately.
---
New constants, state vars, error, events
```
START\_GAME\_NOTICE\_PERIOD = 72 hours
START\_GAME\_OFFER\_BUFFER  = 6 hours
startGameProposedAt      -- 0 = no proposal
latestOfferTimestamp     -- updated by confirmOGSlots()
error ActiveDeclineWindowOpen()
event StartGameProposed(uint256 launchNotBefore)
event StartGameProposalCancelled()
```
---
Operation sequence
```
1. confirmOGSlots()           → latestOfferTimestamp updated
2. Wait 66+ hours             → all offer windows nearly expired
3. proposeStartGame()         → notice opens, StartGameProposed emitted
4. \[confirmOGSlots + registerAsOG BLOCKED during notice]
5. startGame() after 72hrs   → launches, proposal cleared
```
Minimum total wait (with prior OG offers): 138 hours (~5.75 days).
Minimum (no OG offers): 72 hours.
---
Nine scenarios verified
A-I all pass including: correct flow, early-propose block, no-OG game, confirmOGSlots-during-notice block, registerAsOG-during-notice block, player-exit self-correction, expiry-during-notice guard ordering, repeated propose/cancel cycles.
---

---
[v1.99.31]: NatSpec Reposition + Notice Guard Polish
Date: March 2026
Lines: 5,653 (net +13 from v1.99.30)
Changes: 4 code/structural fixes, 2 NatSpec additions.
Source audit of v1.99.30. All five findings legit.
---
FIX: startGame() NatSpec repositioned to immediately precede its function (M-01)
The insertion of `proposeStartGame()` and `cancelStartGameProposal()` in v1.99.30 left the existing `startGame()` NatSpec block detached -- it preceded `proposeStartGame()` rather than `startGame()`. NatSpec parsers (Forge, Hardhat, Solidity compiler) attach doc blocks to the immediately following function, so Internal audit's auto-generated docs would have attributed "Starts the game, transitioning from PREGAME to ACTIVE" to `proposeStartGame()` and left `startGame()` undocumented. Block moved. Order is now: `proposeStartGame()` NatSpec+function → `cancelStartGameProposal()` NatSpec+function → `startGame()` NatSpec+function.
---
FIX: registerAsWeeklyOG() notice-period guard added (L-01)
`registerAsWeeklyOG()` had no guard for the launch notice window, asymmetric with `registerAsOG()`. New weekly OGs registered during the 72-hour countdown would shift `ogRatioBps` at `startGame()` without being included in any pre-launch OG ratio communication. Guard added: `if (startGameProposedAt != 0) revert ActiveDeclineWindowOpen()`.
---
FIX: registerAsOG() notice guard error changed to ActiveDeclineWindowOpen (L-02)
The v1.99.30 guard used `TimelockPending()`, which is used throughout the contract for 7-day governance timelocks. A player hitting this error would look for a governance proposal, not understand the launch countdown. `ActiveDeclineWindowOpen()` is semantically correct -- the notice period is an active window concern. Error changed.
---
FIX: START_GAME_OFFER_BUFFER renamed to OG_DECLINE_WINDOW_TAIL (I-03)
The original name described the effect from the wrong perspective. `OG\_DECLINE\_WINDOW\_TAIL = 6 hours` precisely names what it is: the maximum remaining tail of an OG's decline window at proposal time. All three occurrences (constant declaration, NatSpec reference, guard arithmetic) updated.
---
NATSPEC: proposeStartGame() -- payCommitment/registerAsWeeklyOG open during notice (I-02)
Both functions remain callable during the 72-hour notice period. New commitments will be included in `ogCapDenominator` at `startGame()`. Documented explicitly: the notice period is designed to honour OG exit windows, not that the committed cohort is frozen.
---
NATSPEC: Contract header -- getPreGameStats() ABI change noted (I-01)
`getPreGameStats()` now returns 7 values (was 6). The v1.99.30 NatSpec note was in the correct function but absent from the top-level contract header changelog. Added: positional callers unaffected, named-return callers must update ABI.
---

---
[v1.99.32]: Header Changelog Delta Entry for v1.99.31
Date: March 2026
Lines: 5,660 (net +7 from v1.99.31)
Changes: 0 code changes, 1 NatSpec addition.
Source: fresh triple audit of v1.99.31. No new critical/high/medium/low findings. One informational gap -- the contract header changelog lacked a specific delta entry for v1.99.31 changes. Added.
---
NATSPEC: Contract header changelog -- v1.99.31 key deltas documented
Added `Key deltas from v1.99.31` block documenting:
`registerAsWeeklyOG()` notice-period guard addition
`registerAsOG()` error change from `TimelockPending` to `ActiveDeclineWindowOpen`
`START\_GAME\_OFFER\_BUFFER` renamed to `OG\_DECLINE\_WINDOW\_TAIL`
`startGame()` NatSpec block repositioned to immediately precede its function
---

---
[v1.99.33]: Critical Compilation Fix + PATH 3 Flag + Draw-1 NatSpec
Date: March 2026
Lines: 5,674 (net +14 from v1.99.32)
Changes: 2 code fixes, 1 NatSpec addition.
---
CRITICAL CODE FIX: startGame() function declaration restored
The v1.99.31 NatSpec reposition accidentally merged the final `///` NatSpec line with the `function startGame()` declaration onto a single line. The declaration was therefore inside a `///` line comment and was compiled away. The contract was undeployable. Single line break restored between the NatSpec end and the function declaration.
---
CODE FIX: claimDormancyRefund() universal cleanup clears stale commitmentPaid (MEDIUM)
PATH 3 (casual last-draw buyer) handles refund correctly but left `p.commitmentPaid = true` if the player had committed via `payCommitment()` and never claimed `claimCommitmentRefund()` after a draw-1 emergency reset. With `dormancyRefunded = true` blocking re-entry, their $10 commitment became permanently unrecoverable -- not flowing to any pool, not returned to the player. `p.commitmentPaid = false` added to the universal cleanup block, which runs for all paths. PATH 4 already cleared it explicitly; universal cleanup now ensures no path leaves a stale flag.
---
NATSPEC: emergencyResetDraw() draw-1 reset + pregameWeeklyOGNetTotal interaction (LOW)
At `startGame()`, `currentDrawNetTicketTotal += pregameWeeklyOGNetTotal`. On a draw-1 emergency reset, this entire pregame weekly OG net revenue feeds `resetDrawRefundPool`. Weekly OGs are eligible claimants (`lastBoughtDraw = 1` set at PREGAME registration passes the eligibility check). Their PREGAME registration fee refunds via the reset pool. `totalPaid` and `totalOGPrincipal` are correctly decremented. Accounting consistent -- interaction non-obvious. Documented at `emergencyResetDraw()` draw-1 pool block.
---

---
[v1.99.34]: Dormancy Deadlock Fix + AaveExit Cancel + Counter Drift
Date: March 2026
Lines: 5,690 (net +16 from v1.99.33)
Changes: 3 code fixes.
---
CODE FIX: claimDormancyRefund() universal cleanup -- three corrections (F1 + F3)
F1 -- committedPlayerCount drift: The v1.99.33 fix cleared `p.commitmentPaid` in universal cleanup but forgot the matching `committedPlayerCount--`. PATH 4 does both explicitly. Any PATH 3 player with a stale `commitmentPaid` flag left `committedPlayerCount` permanently inflated. Fixed: `committedPlayerCount--` now fires inside the `if (p.commitmentPaid)` block alongside the flag clear.
F3 -- PATH 3 permanent deadlock resolved: The `if (refund == 0 \&\& p.prepaidCredit == 0) revert NothingToClaim()` guard in universal cleanup permanently wedged PATH 3 players whose `dormancyCasualRefundPool` and `dormancyPerHeadPool` were both drained. They could never reach `dormancyRefunded = true` because the revert fired first. Every re-call produced the same revert. Their stale `commitmentPaid` flag (v1.99.33 fix) also never cleared because it sits after the revert guard.
Fix: revert guard removed entirely. Strangers (players who don't belong in any PATH) are already blocked by the `else { revert NothingToClaim() }` at the end of the PATH chain -- the universal cleanup guard was redundant and harmful. `dormancyRefunded = true` now always sets. Transfer wrapped in `if (refund > 0)` to skip zero-value transfers. `emit DormancyRefund(msg.sender, refund)` still fires for all players including zero-refund, documenting the state resolution.
---
CODE FIX: emergencyResetDraw() cancels aaveExitEffectiveTime (F2)
Five timelocks were cancelled on emergency reset; `aaveExitEffectiveTime` was not. A proposed Aave exit from before the reset would silently become executable 7 days from its original proposal with no event or signal that the game state had changed. Pattern mirrors `dormancyEffectiveTime` cancellation added in prior versions. Uses existing `AaveExitCancelled` event.
emergencyResetDraw() now cancels all six pending timelocks: breath override, breath rails, dormancy, pendingMultiplier, startGameProposal (v1.99.30), and Aave exit.
---

---
[v1.99.35]: ogList Defensive Guards + Draw-51 + Catch-Up NatSpec
Date: March 2026
Lines: 5,714 (net +24 from v1.99.34)
Changes: 2 code fixes, 2 NatSpec additions.
---
CODE FIX: claimOGIntentRefund() and forceDeclineIntent() defensive ogList guard (LOW)
The v1.99.21 defensive swap-and-pop guard existed in `\_cleanupOGOnRefund()` but not in `claimOGIntentRefund()` or `forceDeclineIntent()`. All three perform the same swap-and-pop. Without the guard, `ogList.length - 1` on an empty list would underflow in Solidity 0.8.x, permanently reverting and locking the player's funds. The invariant should hold (confirmOGSlots only marks OFFERED after pushing to ogList) but explicit defensive treatment is consistent and safe.
Both functions now wrap their swap-and-pop in:
```solidity
if (ogLen > 0 \&\& ogListIndex\[addr] < ogLen \&\& ogList\[ogListIndex\[addr]] == addr)
```
Mirrors `\_cleanupOGOnRefund()` exactly.
---
NATSPEC: _checkAutoAdjust() draw-51 underfunded breath clamp (Area 1)
At draw 51 with an underfunded pot (`prizePot + avgRevenue <= requiredEndPot`), `optimalBreathBps` would be zero but clamps to `breathRailMin` (100 bps). 1% is extracted as prizes rather than preserving capital for endgame. OG endgame comes from `closeGame()`, not the draw-52 prize pool, so OGs are unaffected. Only casual draw-52 prize availability is reduced. Accepted design -- `breathRailMin > 0` is intentional.
---
NATSPEC: finalizeWeek() schedule anchor catch-up behaviour (Area 2)
`lastDrawTimestamp` is anchored to `scheduleAnchor + draw \* DRAW\_COOLDOWN`, not to actual resolution time. If `resolveWeek()` is called late, the next draw becomes resolvable immediately after `finalizeWeek()` completes. Prevents a single late draw from compounding delays across all 52 draws. The RESET_FINALIZING path resets `scheduleAnchor` (already documented); the normal path catch-up was undocumented until now.
---

---
[v1.99.35]: ogList Defensive Guards + Breath + Anchor NatSpec
Date: March 2026
Lines: 5,712 (net +22 from v1.99.34)
Changes: 2 code fixes, 2 NatSpec additions.
---
CODE FIX: claimOGIntentRefund() OFFERED swap-and-pop defensive guard (LOW)
`\_cleanupOGOnRefund()` received a defensive three-condition guard in v1.99.21:
```
if (ogLen > 0 \&\& ogListIndex\[addr] < ogLen \&\& ogList\[ogListIndex\[addr]] == addr)
```
`claimOGIntentRefund()` OFFERED path and `forceDeclineIntent()` OFFERED path both perform the same swap-and-pop without this guard. If `ogList.length` were ever 0 (invariant break), `ogList.length - 1` would underflow in Solidity 0.8.x, reverting permanently and locking the player's funds. Invariant should hold since `confirmOGSlots()` only transitions to OFFERED after pushing to `ogList`, but explicit guard added for consistency and safety.
---
CODE FIX: forceDeclineIntent() OFFERED swap-and-pop defensive guard (LOW)
Same pattern as above. Uses `ogLen\_` local variable to avoid shadowing.
---
NATSPEC: _checkAutoAdjust() draw-51 underfunded clamp behaviour
At draw 51 with `remainingDraws = 1`, an underfunded pot produces `optimalBreathBps = 0` which clamps to `breathRailMin` (100 bps = 1%). The formula still extracts 1% as prizes rather than preserving capital. OG endgame comes from `closeGame()` not draw-52 prizes, so OGs are not harmed. Casual draw-52 buyers in an underfunded game receive less. Accepted design -- documented for submission.
---
NATSPEC: finalizeWeek() schedule anchor catch-up behaviour
`lastDrawTimestamp` is anchored to `scheduleAnchor + draw \* DRAW\_COOLDOWN`, not to actual resolution time. If a draw resolves late (e.g. 10 days after eligible), the next draw is immediately resolvable since the scheduled window is already past. Multiple draws can resolve back-to-back after a stall. This prevents one late draw from compounding delays across all 52 draws. Intentional design -- now documented on the normal path.
---

---
[v1.99.36]: Compilation Fix + Pool1 Fallthrough + Brace Fix
Date: March 2026
Lines: 5,715 (net +3 from v1.99.35)
Changes: 2 code fixes.
---
CRITICAL CODE FIX: forceDeclineIntent() missing closing brace (F4)
The v1.99.35 defensive guard block in `forceDeclineIntent()` OFFERED path was missing its closing `}`. The `ogList.pop()` and `delete ogListIndex\[player]` were inside the guard block, but `ogIntentWindowExpiry\[player] = 0` and the following `} else {` were not -- the else was intended to close the `OFFERED` check but instead closed the defensive guard, leaving `OFFERED` permanently unclosed. Solidity compilation failure. Single closing brace inserted at the correct position.
---
CODE FIX: claimResetRefund() pool1-drained blocks pool2 access (LOW-MEDIUM)
The prior `if (eligiblePool1) { ... } else { pool2 }` structure permanently blocked a player eligible for both pools from reaching pool2 once pool1 drained. Every call routed to pool1 (eligiblePool1=true), computed `claim=0` (pool drained), and reverted `NothingToClaim()`. State was unchanged so `resetRefundClaimedAtDraw` still showed pool1 unclaimed, routing every subsequent call back to pool1. Player could never reach pool2 even if funded.
Fix: Restructured to sequential `if/if` pattern. Pool1 block uses `if (claim > 0)` with an early `return` on success. When `claim==0` and `eligiblePool2=true`, the pool1 block exits cleanly and the separate `if (eligiblePool2)` block executes. When `claim==0` and `!eligiblePool2`, reverts `NothingToClaim()` as before.
Five scenarios verified:
A: eligiblePool1=T, claim>0 → pool1 processes, returns.
B: eligiblePool1=T, claim==0, eligiblePool2=T → falls through to pool2.
C: eligiblePool1=T, claim==0, eligiblePool2=F → reverts NothingToClaim.
D: eligiblePool1=F, eligiblePool2=T → pool2 processes.
E: both false → blocked before pool blocks by existing guard.
---

---
[v1.99.37]: Counter-Up-Only + Post-Settlement NatSpec
Date: March 2026
Lines: 5,728 (net +13 from v1.99.36)
Changes: 0 code changes, 2 NatSpec additions.
Source: fresh triple audit of v1.99.36. No new critical/high/medium/low findings.
---
NATSPEC: buyTickets() totalLifetimeBuyers counter-up-only design (A2)
`totalLifetimeBuyers` increments on first buy and is never decremented. Players exiting via dormancy refund or sweep are not subtracted. The capacity formula `activeBuyers = totalLifetimeBuyers - lapsedPlayerCount` approximates active buyers within a single 52-draw lifecycle. `batchMarkLapsed()` covers players who stop buying. Dormancy is a late-game mechanism; no re-use scenario is possible per contract design. Accepted approximation with no financial risk -- documented for submission.
---
NATSPEC: sweepResetRefundRemainder() post-settlement _captureYield() invariant drift (A3)
After zeroing `resetDrawRefundPool` via a CLOSED/DORMANT sweep, the next `\_captureYield()` call sees smaller `nonPotAllocated`, creating a gap that routes to `prizePot` as apparent yield. `prizePot` is already 0 post-settlement, so this lands in a dead variable. USDC physically moved to CHARITY correctly. Accounting drift is consequence-free in CLOSED/DORMANT. Accepted design -- documented for submission.
---

---
[v1.99.38]: Upgrader Parity Drift + Intent Expiry + Credit Sweep NatSpec
Date: March 2026
Lines: 5,753 (net +25 from v1.99.37)
Changes: 3 code fixes (2 pools + cleanup), 1 NatSpec addition.
---
CODE FIX: claimResetRefund() qualifiedUpgraderOGCount double-increment (MEDIUM, A1)
Scenario: Upgrader reaches `p.totalPaid >= OG\_UPFRONT\_COST` via `payUpgradeBlock()` → `qualifiedUpgraderOGCount++`. Emergency reset fires. `claimResetRefund()` decrements `p.totalPaid` below parity. No decrement to `qualifiedUpgraderOGCount`. Upgrader pays to parity again via `payUpgradeBlock()` → `qualifiedUpgraderOGCount++` again. Phantom extra count in `closeGame()` divides `ogShare` by inflated denominator -- all real OGs receive slightly less, phantom share sweeps to charity. `endgameOwed = prizePot` invariant holds throughout.
Fix: Both pool1 and pool2 `isWeeklyOG` decrement blocks now check: if the player is `upgradedFromWeekly` AND their `totalPaid` dropped below `OG\_UPFRONT\_COST` after the claim AND `qualifiedUpgraderOGCount > 0`, decrement `qualifiedUpgraderOGCount`. Guard prevents underflow on the counter.
---
CODE FIX: _cleanupOGOnRefund() OFFERED branch stale ogIntentWindowExpiry (LOW, A2)
Every other OFFERED→DECLINED transition clears `ogIntentWindowExpiry`: `forceDeclineIntent()` (v1.99.21 L-03), `sweepExpiredDeclines()`. `\_cleanupOGOnRefund()` OFFERED branch (called from `claimSignupRefund()` on failed PREGAME) did not. Functional impact zero -- DECLINED status causes `claimOGIntentRefund()` to revert before the expiry check. Off-chain tooling reading the timestamp for a DECLINED address would misclassify them as holding an open window. `ogIntentWindowExpiry\[addr] = 0` added.
---
NATSPEC: claimUnusedCredit() intentional absence of sweep (INFO, A3)
Unlike endgame shares and weekly prizes (swept after `ENDGAME\_SWEEP\_WINDOW`), `totalPrepaidCredit` has no `sweepUnclaimedCredit()` function. USDC backing unclaimed credit is reserved indefinitely for the rightful owner. Abandoned wallets create permanent dust. Intentional player-protection design -- accepted and disclosed for audit submission.
---

---
[v1.99.39]: Post-v1.99.38 Triple Audit -- Four Findings Closed
Date: March 2026
Lines: 5,793 (net +40 from v1.99.38)
Changes: 2 code fixes, 2 NatSpec additions. All four findings closed.
---
NATSPEC: claimResetRefund() A1 guard confirmed unreachable (AUDIT-INFO-01)
The v1.99.38 A1 fix adds `if (p.upgradedFromWeekly \&\& p.totalPaid < OG\_UPFRONT\_COST \&\& qualifiedUpgraderOGCount > 0)` inside `if (p.isWeeklyOG)`. However `upgradeToUpfrontOG()` atomically sets `isWeeklyOG = false`, `isUpfrontOG = true`, `upgradedFromWeekly = true`. An upgraded player is blocked at the `if (p.isUpfrontOG) revert ResetRefundNotEligible()` entry guard before reaching the `isWeeklyOG` branch. `isWeeklyOG \&\& upgradedFromWeekly` cannot coexist. Guard is inert but retained for defence-in-depth. NatSpec added at both pool1 and pool2 sites.
---
CODE FIX: claimDormancyRefund() PATH 2 stale ogList entry removed (AUDIT-LOW-01)
PATH 2 correctly decrements `weeklyOGCount`, `earnedOGCount`, `qualifiedWeeklyOGCount` and clears `p.isWeeklyOG`. It did not remove the player's address from `ogList`. After PATH 2: `isWeeklyOG = false`, `isUpfrontOG = false`, address still in `ogList`. No financial risk (no draws in DORMANT), but off-chain tooling reads a ghost entry for a fully-refunded player. Swap-and-pop block added using local variable `ogLenD2` to avoid shadowing. Defensive three-condition guard matches `\_cleanupOGOnRefund()` v1.99.21 pattern exactly.
---
CODE FIX: claimDormancyRefund() universal cleanup zeroes p.totalPaid (AUDIT-INFO-01)
PATH 4 zeroed `p.totalPaid` explicitly (v1.99.27 M-01). PATH 1, 2, 3 did not. After `dormancyRefunded = true` blocks re-entry, `getPlayerInfo()` returned stale non-zero `totalPaid` for fully-refunded players. Display artifact only -- no financial function reads `p.totalPaid` post-dormancy. `p.totalPaid = 0` added to universal cleanup before `dormancyRefunded = true`. Safe: all path refund calculations already read `totalPaid` above this point.
---
NATSPEC: proposeFeedChange() operator RUNBOOK added (AUDIT-NEW-LOW-01)
The function does not validate that a candidate feed returns live data -- address collision guards pass for a correctly-formatted but dead aggregator. An in-contract `latestRoundData()` call at proposal time was considered and rejected (adds external call complexity; a feed passing at proposal can die before execution). RUNBOOK added: operators must simulate `\_readPrice()` logic off-chain against the candidate address, confirm non-stale in-range prices, and include the address in monitoring alerts so any anomaly triggers `cancelFeedChange()` before execution. The 7-day window is the verification window, not a rubber stamp.
---

---
[v1.99.40]: Triple Audit Response -- Five Findings Closed
Date: March 2026
Lines: 5,825 (net +32 from v1.99.39)
Changes: 4 code fixes, 1 NatSpec addition.
---
CODE FIX: proposeDormancy() cancels aaveExitEffectiveTime (AUDIT-LOW-01)
`emergencyResetDraw()` cancels `aaveExitEffectiveTime`. `proposeDormancy()` cancelled breath override, breath rails, and pendingMultiplier but missed this. Between `proposeDormancy()` and `activateDormancy()` (24-hour window), a pending Aave exit could execute silently -- no `AaveExitCancelled` event fires (it executes, not cancels). `activateDormancy()` handles both `aaveExited` states safely but operator surprise risk is real. Four-line cancel block added matching `emergencyResetDraw()` pattern exactly.
---
CODE FIX: getPlayerInfo() qualifiedForEndgame corrected post-dormancy (AUDIT-INFO-01)
`\_isQualifiedForEndgame(p)` returns true for eligible OGs regardless of dormancy state. After dormancy settlement, `claimEndgame()` reverts `NothingToClaim()` on the `dormancyTimestamp > 0` guard. Front-ends reading `getPlayerInfo()` would show a claim button that always reverts. Return value changed to `\_isQualifiedForEndgame(p) \&\& dormancyTimestamp == 0`.
---
CODE FIX: getProjectedEndgamePerOG() returns (0,0,0) after dormancy (AUDIT-INFO-02)
After `sweepDormancyRemainder()` fires (`gameSettled = true`, dormancy path), `closeGame()` was never called and `endgamePerOG = 0`. The function was returning `(0, non-zero-obligation, 10000)` -- zero per-OG against a meaningful obligation target. Misleading and triggers false shortfall alerts in monitoring tooling. Early return `if (dormancyTimestamp > 0) return (0, 0, 0)` added before the `gameSettled` branch.
---
CODE FIX: claimDormancyRefund() PATH 4 restricted to true commitment-only players (AUDIT-INFO-01)
PATH 4 entry was `} else if (p.commitmentPaid)`. A player who committed, bought tickets in several draws, then went inactive with a stale `commitmentPaid` flag (from draw-1 reset + 30-day pool expiry without clearing the flag) would misroute to PATH 4 and draw ~$8.50 from `dormancyPerHeadPool`. They are not a commitment-only player -- their revenue is already in the pot. Guard `\&\& p.lastBoughtDraw == 0` added: PATH 4 now only fires for players who genuinely never bought a ticket.
---
NATSPEC: claimUnusedCredit() interim CLOSED/!gameSettled window (AUDIT-INFO-02)
`gamePhase` transitions to CLOSED at draw 52 in `finalizeWeek()`. `gameSettled` is set by `closeGame()`. This function is callable in the interim window before `closeGame()`. Mechanically safe -- prepaid credit is ring-fenced, withdrawal is for the exact amount. Documented: integrators must call `closeGame()` promptly after draw 52 finalisation.
---

---
[v1.99.41]: Fresh-Area Audit -- Three Info NatSpec Additions
Date: March 2026
Lines: 5,843 (net +18 from v1.99.40)
Changes: 0 code changes, 3 NatSpec additions.
---
NATSPEC: claimSignupRefund() interestedCount not decremented (AUDIT-INFO-01)
`interestedCount` is incremented in `registerInterest()` and never decremented anywhere, including `claimSignupRefund()`. Players who registered interest on a failed pregame leave a stale count. `getPreGameStats()` returns the elevated figure on the dead game. Display artifact only -- no financial consequence. Documented for submission.
---
NATSPEC: getOGCapInfo() OG_ABSOLUTE_FLOOR zeroes weekly slots on small games (AUDIT-INFO-01)
`OG\_ABSOLUTE\_FLOOR = 500` guarantees 500 upfront OG slots regardless of the BPS-derived cap. On small games where `denominator \* TOTAL\_OG\_CAP\_BPS / 10000 < 500`, `upfrontOGCount` can reach the floor (500) while exceeding the total BPS ceiling. `weeklyMax` saturates to zero (`wMax = tMax - upfrontOGCount`, clamped at 0). Weekly OG slots are unavailable once `upfrontOGCount >= tMax`. Intentional player-first design -- not a bug. Operators of small deployments should set `MIN\_PLAYERS\_TO\_START` high enough that the floor is not dominant.
---
NATSPEC: getGameState() prizePot is phase-dependent (AUDIT-INFO-01)
During `MATCHING` and `DISTRIBUTING` draw phases, `prizePot` has already had the weekly draw allocation deducted at `resolveWeek()` start. The `pot` field is temporarily deflated until `finalizeWeek()` seeds the Eternal Seed return back in. Front-ends should display `drawPhase` alongside `pot` to contextualise the live snapshot. `IDLE` and `CLOSED` phases always return a clean value.
---

---
[v1.99.42]: Fresh-Area Audit -- Two Info NatSpec Additions
Date: March 2026
Lines: 5,859 (net +16 from v1.99.41)
Changes: 0 code changes, 2 NatSpec additions.
---
NATSPEC: getCurrentPrizeRate() PREGAME returns default calibration (AUDIT-INFO-01)
During PREGAME, `currentDraw = 0` which is less than `TOTAL\_DRAWS = 52`. The draw-52 early return does not fire. The function returns `breathMultiplier \* prizeRateMultiplier / 10000` -- the default breath calibration (~700 bps, ~7%). This is a real contract value but represents nothing: no draw has resolved, no prize rate is active. Front-ends should suppress or contextualise this value during PREGAME.
---
NATSPEC: registerInterest() DECLINED players can re-inflate interestedCount (AUDIT-INFO-01)
DECLINED players are not blocked from calling `registerInterest()` again. The `AlreadyRegisteredInterest` guard fires only if `p.registeredInterest` is already true -- but `registerAsOG()` clears that flag (v2.75 I-01). A DECLINED player can call `registerInterest()` again, increment `interestedCount`, but can never re-enter the OG intent queue (NONE status required). Their new interest entry is permanently stale. Extends v1.99.41 AUDIT-INFO-01: `interestedCount` is a soft display metric, not a hard eligibility counter.
---

---
[v1.99.43]: Neglected-Area Triple Audit -- Five NatSpec Additions
Date: March 2026
Lines: 5,883 (net +24 from v1.99.42)
Changes: 0 code changes, 5 NatSpec additions.
Source: Triple audit of 30+ functions not previously given focused attention.
No critical, high, medium, or low code findings. All findings resolved as NatSpec.
---
NATSPEC: activateAaveEmergency() + executeAaveExit() intentional bare IPool.withdraw (A+1)
Both functions use a bare `IPool.withdraw()` call without try/catch, unlike all 8 `supply()` calls which were wrapped in v1.99.11. The pattern is intentional: a try/catch that silently continues after withdraw failure would dangerously set `aaveExited = true` with no USDC actually withdrawn. Supply failure is recoverable (funds stay in Aave); exit failure during a crisis must be atomic -- the function either fully succeeds or fully reverts. Owner sees the revert, can retry when Aave recovers. Note added to `activateAaveEmergency()`. Cross-reference added to `executeAaveExit()`.
---
NATSPEC: pruneStaleOGs() swap-and-pop while-loop safety (B)
The swap-and-pop uses bare `ogList.length - 1` without the defensive three-condition guard applied in v1.99.21, v1.99.35, and v1.99.39. The while loop condition `i < ogList.length` guarantees `ogList.length >= 1` whenever the bare subtraction is reached, making underflow impossible. The pattern difference is intentional -- the while guard is sufficient here. Documented for submission consistency audit.
---
NATSPEC: claimCommitmentRefund() no gamePhase guard -- intentional (C)
The function has no gamePhase guard and is callable in any phase. Intentional: `commitmentRefundPool` is only set by `emergencyResetDraw()` during ACTIVE draw 1. After 30 days the pool expires or is swept. The pool's own existence provides the implicit phase safety. Identical reasoning to `withdrawTreasury()` (v1.79 / I-03).
---
NATSPEC: _isQualifiedForEndgame() live p.totalPaid dormancy interaction (2)
The upgrader parity check reads live `p.totalPaid`. After `claimDormancyRefund()` universal cleanup (v1.99.39), `p.totalPaid = 0` post-refund, causing a claimed upgrader to return false here. Harmless: the v1.99.40 `dormancyTimestamp == 0` guard in `getPlayerInfo()` already returns `qualifiedForEndgame = false` for all post-dormancy players regardless. Accepted design interaction.
---

---
[v1.99.44]: Comprehensive Audit Response -- Code Fix + Six NatSpec
Date: March 2026
Lines: 5,929 (net +46 from v1.99.43)
Changes: 1 code fix, 6 NatSpec additions.
Source: Full 8-finding audit response. Two findings rated MEDIUM, handled as disclosure + code fix where applicable.
---
CODE FIX: claimDormancyRefund() PATH 1 stale ogList entry + isUpfrontOG cleared (F1, LOW)
PATH 2 (weekly OG) received a swap-and-pop + flag clear in v1.99.39. PATH 1 (upfront OG) was asymmetric: `p.isUpfrontOG` remained true and the player's address stayed in `ogList` after claiming. No financial risk in current version (draw-phase functions cannot fire in DORMANT/CLOSED), but a future fork that re-enters ACTIVE after dormancy settlement would cause stale OGs to be matched again. `p.isUpfrontOG = false` added. Defensive three-condition swap-and-pop block added using `ogLenP1` local variable, matching v1.99.39 pattern exactly.
---
NATSPEC: _readPrice() minAnswer=0 disables floor circuit breaker (F8, MEDIUM-level deployment risk)
If a deployed feed has `minAnswer = 0`, the `price <= int256(minAns)` check degenerates to `price <= 0`, which is already handled by the existing `price <= 0` guard. A feed clamped at Chainlink's floor price (e.g. 1 during a depeg) passes through as a real price, producing wrong rankings without the contract detecting it. Deployment checklist note added: verify `minAnswer > 0` on all 32 production feeds before deployment.
---
NATSPEC: emergencyResetDraw() three-reset scenario strengthened (F4, MEDIUM)
Third-reset buyers lose refund access if both pools are occupied without `sweepResetRefundRemainder()` being called between resets. Their ticket revenue stays in `prizePot` permanently. Existing M-03 runbook entry strengthened: operator MUST call `sweepResetRefundRemainder()` after each reset. Front-ends MUST monitor `ResetRefundSkipped` and alert affected users.
---
NATSPEC: currentTierPerWinner stale after TierSkippedDust (F2, INFO)
`currentTierPerWinner` is not updated when a tier is skipped via the `TierSkippedDust` path. Off-chain tools reading it between distribution batches see the value from the previous tier. Declaration annotated: tools must cross-check `distTierIndex` and `tierPools\[]` rather than reading `currentTierPerWinner` alone.
---
NATSPEC: encodePicks() / isValidPicks() asymmetry front-end trap (F5, INFO)
After silent truncation by `encodePicks()` (e.g. input 32 becomes 0), the masked value passes `isValidPicks()` without error since 0 < 32. A front-end calling `encodePicks(32,...)` then `isValidPicks()` sees no error but produces wrong picks. Front-ends must sanitise inputs to [0,31] before calling `encodePicks()`.
---
NATSPEC: proposeStartGame() two-tier behaviour when latestOfferTimestamp=0 (F7, INFO)
When `latestOfferTimestamp == 0` (no upfront OG offers ever made -- weekly-OG or casual-only game), the 66-hour buffer check is skipped entirely. `proposeStartGame()` can fire immediately after `MIN\_PLAYERS\_TO\_START` is met. This is correct: no OFFERED OGs exist to protect. Front-ends should display different messaging for zero-OG games: no 66-hour wait, 72-hour notice period only.
---
NATSPEC: _checkAutoAdjust() upgrader proxy obligation inflation Internal audit disclosure (F3, LOW/Accepted)
Existing `\[v1.92 / #6] ACCEPTED BIAS` note strengthened with v1.99.44 Internal audit disclosure tag. Breath may be suppressed high by ~$960 per upgrader for 2 draws maximum. Compounds if many upgrades happen in draws 7-9. Accepted and self-correcting at draw-10 obligation lock.
---

---
[v1.99.45]: PATH 1 Counter Decrements (v1.99.44 F1 Follow-up)
Date: March 2026
Lines: 5,935 (net +6 from v1.99.44)
Changes: 1 code fix.
---
CODE FIX: claimDormancyRefund() PATH 1 -- upfrontOGCount and qualifiedUpgraderOGCount decremented (LOW + INFO)
The v1.99.44 F1 fix added `p.isUpfrontOG = false` and the ogList swap-and-pop to PATH 1, but missed the counter decrements that PATH 2 performs for the equivalent weekly OG path.
Finding 1 (LOW): `upfrontOGCount` not decremented. PATH 2 decrements `weeklyOGCount` and `earnedOGCount`. PATH 1 now decrements `upfrontOGCount` with the standard underflow guard. Zero financial consequence (counter is irrelevant in DORMANT/CLOSED) but Internal audit would flag the asymmetry.
Finding 2 (INFO): `qualifiedUpgraderOGCount` not decremented for parity-qualified upgraders. Upgraders who reached `OG\_UPFRONT\_COST` parity via `payUpgradeBlock()` incremented `qualifiedUpgraderOGCount`. PATH 1 now decrements it when `p.upgradedFromWeekly \&\& p.totalPaid >= OG\_UPFRONT\_COST`. `p.totalPaid` is read live here -- universal cleanup (which zeros it) fires after this block. Parity check is correct and safe.
---

---
[v1.99.46]: NatSpec Accuracy Pass -- Six Inaccuracies + One Disclosure
Date: March 2026
Lines: 5,951 (net +16 from v1.99.45)
Changes: 0 code changes, 7 NatSpec corrections.
All changes are documentation-only. No function logic changed.
---
FIX 1: _checkAutoAdjust() draws range corrected (draws 1-9 → draws 1-10)
`\_calculatePrizePools()` calls `\_checkAutoAdjust()` before `\_lockOGObligation()` sets the flag. Draw 10 therefore runs the pre-lock formula. NatSpec now reads "PRE-LOCK (draws 1-10)" with an explanatory note.
---
FIX 2: claimOGIntentRefund() PENDING path summary corrected
Path summary said "Full net return" implying 100%. Player receives 85% (15% commitment deposit kept). Now reads "85% net return (15% commitment deposit kept)."
---
FIX 3: resolveWeek() permissionless claim caveated
Added: "Subject to Arbitrum sequencer liveness: `\_checkSequencer()` reverts on sequencer downtime, blocking resolution until recovery."
---
FIX 4: claimCommitmentRefund() no-phase-guard rationale corrected
Prior wording: "By the time any other phase is active, the pool is either claimed or gone." This is inaccurate -- dormancy can activate within 30 days of a draw-1 reset while the pool is live. Corrected: callable in any phase including DORMANT; pool expires at 30-day deadline, not at phase boundary.
---
FIX 5: registerAsWeeklyOG() upgrade window bullet clarified
Bullet "Upgrade window: draws 1-7. snapshot fires at draw 7 close" was ambiguous -- reads as if the window applies to registration. Clarified: registered weekly OGs may upgrade via `upgradeToUpfrontOG()` during draws 1-7. The upgrade applies to the OG after registration, not to the registration process.
---
FIX 6: getPlayerInfo() dormancy guard framing corrected
AUDIT-INFO-01 note said "Post-dormancy settlement (dormancyTimestamp > 0, gameSettled = true)". The `dormancyTimestamp == 0` guard fires when dormancy activates, not only post-settlement. `gameSettled` plays no role. Corrected to: "Guard fires when dormancy ACTIVATES (dormancyTimestamp > 0), regardless of whether settlement has completed."
---
DISCLOSURE: proposeDormancy() pending feed changes not cancelled
Five timelocks are explicitly cancelled by `proposeDormancy()`. `pendingFeedChanges` are not. `executeFeedChange()` remains callable during the 24-hour proposal window. After `activateDormancy()` transitions to DORMANT, the ACTIVE-only guard in `executeFeedChange()` blocks it. Note added for operator awareness.
---

---
[v1.99.47]: Two NatSpec Inaccuracies Corrected
Date: March 2026
Lines: 5,953 (net +2 from v1.99.46)
Changes: 0 code changes, 2 NatSpec corrections.
---
FIX: _matchAndCategorize() "four 8-bit slots" corrected to "four 5-bit slots"
`PICKS\_BITS = 5`, `PICKS\_MASK = 0x1F`, `FULL\_PICKS\_MASK = 0xFFFFF` (20 bits = 4 × 5). The "8-bit" description has been wrong since v1.99.16. A front-end developer reading this NatSpec to implement their own pick decoder would write broken code using `>> 8` instead of `>> 5`.
---
FIX: sweepDormancyRemainder() "five additional vars zeroed" corrected to "six"
`totalOGPrincipalSnapshot = 0` (added v1.99.20) was already in the code with its own comment but absent from the NatSpec list. List now reads six vars and includes `totalOGPrincipalSnapshot`.
---
[v1.99.48]: Two Remaining Audit Findings Fixed
Date: March 2026
Lines: 5,954 (net +1 from v1.99.47)
Changes: 1 code fix (cosmetic), 1 NatSpec correction.
---
FIX: startGame() @dev "three-segment piecewise scale" corrected to "four-segment"
The inline comments immediately below the @dev intro correctly label four segments (A, B, C, D). The @dev line said "three-segment." Auditors reads NatSpec before code -- the contradiction was on first read. Corrected to "four-segment."
---
CODE FIX (cosmetic): _cleanupOGOnRefund() ogGross duplicate variable removed
`ogGross = TICKET\_PRICE \* MIN\_TICKETS\_WEEKLY\_OG` was declared in the weekly OG branch, identical to `weeklyOGCost` declared earlier in the same function. Not a bug, no funds at risk, but a static analyser flags duplicate local variables and Auditors will note it. Declaration removed; all three uses replaced with `weeklyOGCost`.
---
[v1.99.49]: Full Internal audit/AUDIT-Style Audit Response
Date: March 2026
Lines: 6,011 (net +57 from v1.99.48)
Changes: 3 code fixes, 14 NatSpec additions. M-01 accepted as design.
---
CODE FIX: claimDormancyRefund() PATH 2 dead write removed (L-02)
`p.weeklyOGStatusLost = false` inside PATH 2 was always false at that point -- PATH 2 entry requires `!p.weeklyOGStatusLost`. Dead write removed. Saves one SSTORE per PATH 2 claim.
---
CODE FIX: _cleanupOGOnRefund() ogIntentUsedCredit cleared on exit (L-03)
`ogIntentUsedCredit\[addr] = false` added alongside the existing `ogIntentStatus = DECLINED` transition. DECLINED status is the authoritative gate; no downstream code reads this flag post-refund. Stale `true` was misleading off-chain forensics.
---
CODE FIX: claimDormancyRefund() PATH 1 upgradedFromWeekly cleared (L-05)
`p.upgradedFromWeekly = false` added to PATH 1 cleanup block. `dormancyRefunded = true` blocks re-entry so no financial function reads this post-dormancy, but stale storage was inconsistent with PATH 2's cleanup approach.
---
NATSPEC: M-02 -- activeRegistrationCount drift accepted (M-02)
Players who register in ACTIVE and never buy leave `activeRegistrationCount` permanently elevated, shrinking `buyerCap` by 1 per zombie registrant. Negligible at `MAX\_PLAYERS = 55,000`. Accepted design. Documented in `register()`.
---
NATSPEC: M-03 -- resolveWeek() stale fallback baseline drift is a false positive (M-03)
The concern (14-day return measured as 7-day after a stale draw) does not occur. The stale branch sets `currentPrices\[i] = lastValidPrices\[i]`, and the final loop `if (currentPrices\[i] > 0) weekStartPrices\[i] = currentPrices\[i]` correctly anchors the baseline for the next draw. Clarification added inline.
---
NATSPEC: L-01 -- _continueUnwind() warm-slot dependency documented
50K gas guard assumes warm SSTOREs from preceding `processMatches()`. Cold-slot worst case (~132K per iteration) is unreachable on Arbitrum in production. Any fork calling this without preceding `processMatches()` should raise guard to 250K.
---
NATSPEC: L-04 -- executeFeedChange() no liveness check accepted
Adding `\_readPriceFeed()` revert at execution time would block valid feeds that are momentarily stale. The 7-day window and the `proposeFeedChange()` RUNBOOK (v1.99.39) are the correct mitigations. Accepted and documented.
---
NATSPEC: L-06 -- proposeStartGame() revert window operational risk
`committedPlayerCount` is validated at proposal time but OFFERED OGs may decline during the 72-hour notice window, dropping below `MIN\_PLAYERS\_TO\_START`. `startGame()` would revert `NotEnoughPlayers()`. Operator must cancel and re-propose. Documented as operational risk.
---
NATSPEC: I-01 -- getDormancyInfo() upgrader totalPaid corrected (priority fix)
Prior wording "upgrader's p.totalPaid may exceed OG_UPFRONT_COST" was factually wrong. `payUpgradeBlock()` caps at `OG\_UPFRONT\_COST - p.totalPaid` making $1,040 the exact maximum. Corrected to "p.totalPaid is bounded by OG_UPFRONT_COST."
---
NATSPEC: I-02 -- startGame() 11-BPS truncation zone documented
`targetReturnBps` in [4001, 4011] produces `initialBreath = 165` via `(1..11)\*535/6000 = 0` (integer truncation). Zone is 11 BPS wide, not the 1-BPS previously noted. Harmless at any realistic OG ratio.
---
NATSPEC: I-03 -- BreathCalibrated/BreathRecalibrated naming caveat
`BreathCalibrated` is the preview (emitted at `startGame`). `BreathRecalibrated` is authoritative (draw 7). Contrary to typical naming convention. Warning added to event declaration.
---
NATSPEC: I-04 -- processMatches() picks==0 silent no-match documented
Active OGs with `p.picks == 0` receive no match, no event, no revert. Front-ends must poll `p.picks` for all active OGs each IDLE window and surface a warning before the pick deadline.
---
NATSPEC: I-05 -- proposeDormancy() side effects fully enumerated
Cancels breath override, breath rails, prize rate multiplier, AND Aave exit timelock (emits `AaveExitCancelled`). Pending feed changes are NOT cancelled. All five side effects now listed.
---
NATSPEC: I-06 -- _matchAndCategorize() P4 reachability condition explicit
P4 (`anyMatches >= 3 \&\& exactMatches < 3`) is only reachable when `exactMatches <= 2`. P3 (`exactMatches == 3`) fires first in the if-else chain. Documented to save auditors from tracing the evaluation order.
---
NATSPEC: I-07 -- getOGCapInfo() weeklyMax=0 conflation distinguished
`wMax = 0` has two distinct causes: weekly cap reached, or upfront floor exceeded total cap. Comment added distinguishing them; integrators should compare `upfrontOGCount` vs `tMax` to identify which applies.
---

---
[v1.99.50]: SWEPT Branch ogIntentUsedCredit Clear
Date: March 2026
Lines: 6,015 (net +4 from v1.99.49)
Changes: 1 code fix.
---
CODE FIX: _cleanupOGOnRefund() SWEPT branch ogIntentUsedCredit cleared (INFO-01)
The L-03 fix in v1.99.49 cleared `ogIntentUsedCredit\[addr] = false` in the OFFERED branch. The SWEPT branch was missed. `ogIntentUsedCredit\[addr] = false` added to the SWEPT branch to match. Zero functional impact -- DECLINED status is the authoritative gate and no downstream code reads this flag post-refund. Forensic cleanliness only.
---
[v1.99.51]: Contract Header Trimmed for Submission
Date: March 2026
Lines: 5,681 (net -334 from v1.99.50)
Changes: Header only. Zero code or NatSpec changes to functions.
The 384-line embedded changelog was removed from the contract header. Version history belongs in the changelog file, not the contract. The header now contains only what an auditor needs inline:
Title, notice, author
Pointer to Pick432_1Y_Changelog.md with inline tag cross-reference note
USDC blacklist systemic risk (v1.99.11 / I-01) -- must be in-contract, deployment-critical
ABI breaking change notice for getPreGameStats() (v1.99.31 / I-01) -- integrator-critical
All inline `\[vX.X.X / FINDING]` tags and NatSpec throughout functions are preserved in full. These are the audit trail audit reviewors read function-by-function and they demonstrate systematic review discipline.
---
[v1.99.52]: Final Pre-Submission Comment Fix
Date: March 2026
Lines: 5,681 (unchanged)
Changes: 1 inline comment correction.
Inline block comment inside `startGame()` read "Three-segment piecewise linear scale" while listing four segments (A, B, C, D). The `@dev` NatSpec was corrected in v1.99.48; this companion inline comment was missed. Corrected to "Four-segment."
---
[v1.99.53]: _lockOGObligation() Upgrader Obligation Formula Corrected (HIGH)
Date: March 2026
Lines: 5,686 (net +5 from v1.99.52)
Changes: 1 code fix, 1 NatSpec correction.
---
CODE FIX: _lockOGObligation() upgrader branch uses OG_UPFRONT_COST not OG_PREPAY_AMOUNT (H-01)
Root cause: The v2.80 "honest obligation formula" reasoned that upgraders only committed OG_PREPAY_AMOUNT ($80) at registration, so using OG_UPFRONT_COST ($1,040) for them "overstated the target." This reasoning was wrong because it ignored two downstream facts:
`payUpgradeBlock()` brings every parity-qualified upgrader's `p.totalPaid` to exactly OG_UPFRONT_COST ($1,040).
`closeGame()` entitles qualified upgraders to receive up to OG_UPFRONT_COST ($1,040) at endgame.
The obligation anchor must match the endgame entitlement. Using OG_PREPAY_AMOUNT ($80) understated `requiredEndPot` by $960 per upgrader -- a 13x error (vs 26x in Lettery 1Y where OG_PREPAY_AMOUNT = $40). This caused `breathMultiplier` to target a pot that was too small, allowing breath to run hotter than needed. A game with significant upgrader uptake could arrive at draw 52 genuinely short of honouring qualified upgraders.
Fix: `upgraderOGCount \* OG\_PREPAY\_AMOUNT` changed to `upgraderOGCount \* OG\_UPFRONT\_COST`. Both branches of the formula now use OG_UPFRONT_COST. The formula simplifies to `(upfrontOGCount) \* OG\_UPFRONT\_COST` -- all registered OGs anchored at their full entitlement. The v2.80 NatSpec comment corrected to document the original error.
Note: This was discovered via the Lettery 1Y fork audit where the equivalent error was flagged as H-01 at 26x severity. The Pick432 1Y version is 13x.
---
[v1.99.54]: _lockOGObligation() Weekly OGs Counted in requiredEndPot (HIGH)
Date: March 2026
Lines: 5,691 (net +5 from v1.99.53)
Changes: 1 code fix.
---
CODE FIX: _lockOGObligation() requiredEndPot now anchored on ALL active OGs at draw 10 (H-02)
The design intent: Breath should target a pot large enough to return OG_UPFRONT_COST to every OG active at draw 10 -- upfront AND weekly. Weekly OGs who drop off over draws 10-52 create surplus above requiredEndPot. That surplus flows to the draw 52 prize pool. Dropout converts directly into prizes. This is deliberate over-provisioning, not hope.
The prior bug: The formula used `upfrontOGCount \* OG\_UPFRONT\_COST` only. Weekly OGs (earnedOGCount) were entirely excluded from the obligation anchor. Breath targeted a pot sized for upfront OGs alone, leaving weekly OG endgame funding to whatever surplus happened to exist -- which was not guaranteed.
The fix: `ogEndgameObligation = maxOGs \* OG\_UPFRONT\_COST` where `maxOGs = upfrontOGCount + earnedOGCount`. `maxOGs` was already computed at the top of the function for `OGObligationLocked` event emission. The formula now counts every OG active at draw 10 at their full entitlement. `requiredEndPot = ogEndgameObligation \* targetReturnBps / 9000` is unchanged.
Economics: A game with 500 upfront OGs and 300 weekly OGs at draw 10 now targets a pot sized for 800 OGs. If 250 weekly OGs drop off by draw 52, the pot arrives with ~$260,000 surplus above what 550 qualified OGs need. That entire surplus -- minus the already-reserved OG shares -- flows to draw 52 prizes.
Note: `regularOGCount` / `upgraderOGCount` split removed. After v1.99.53 both branches used OG_UPFRONT_COST anyway, making them equivalent to `upfrontOGCount \* OG\_UPFRONT\_COST`. The new single line is simpler and correct.
---
[v1.99.55]: _checkAutoAdjust() Live Target Tracks Weekly OG Dropout
Date: March 2026
Lines: 5,704 (net +13 from v1.99.54)
Changes: 1 code fix in _checkAutoAdjust() post-lock branch.
---
CODE FIX: Breath recalibrates live as weekly OGs drop off (Option B)
The problem with v1.99.54 alone: `requiredEndPot` was anchored correctly at draw 10 on all active OGs (upfront + weekly). But it was frozen. Breath targeted that fixed number for all 41 post-lock draws. As weekly OGs dropped off, the pot remained calibrated for a larger cohort than would actually qualify at draw 52. All the surplus from dropout banked up and exploded as a draw 52 jackpot rather than distributing naturally as prizes throughout the game.
The fix -- Option B: Each post-lock draw in `\_checkAutoAdjust()`, a `liveTarget` is computed inline:
```solidity
uint256 liveTarget = (upfrontOGCount + earnedOGCount)
                     \* OG\_UPFRONT\_COST \* targetReturnBps / 9000;
uint256 breathTarget = liveTarget < requiredEndPot ? liveTarget : requiredEndPot;
```
`breathTarget` -- the smaller of `liveTarget` and the frozen `requiredEndPot` -- replaces `requiredEndPot` in the optimalBreath formula. As each weekly OG loses status, `earnedOGCount` falls, `liveTarget` shrinks, `breathTarget` shrinks, and breath opens wider that same draw. Surplus distributes naturally throughout the game.
The frozen cap (`liveTarget < requiredEndPot ? liveTarget : requiredEndPot`) protects against edge cases where emergency reset restores OGs between draws, temporarily raising `earnedOGCount` above the draw-10 anchor.
`requiredEndPot` is unchanged. It remains the true draw-10 maximum obligation, used correctly in `getProjectedEndgamePerOG()`, `getSolvencyStatus()`, `OGObligationLocked` event, and the `EndgameShortfall` check in `closeGame()`.
Economics (example: 500 upfront + 300 weekly OGs at draw 10, targetReturnBps = 8000):
Draw	Dropoffs	breathTarget	vs frozen 739K	Effect
10	0	739,555	same	no change
20	50	693,333	-46,222	breath opens, ~$46K more prizes
40	150	600,888	-138,667	more prize velocity
52	250	508,444	-231,111	$231K distributed as prizes during game, not banked
All 550 qualified OGs at draw 52 still receive up to OG_UPFRONT_COST ($1,040). The pot was always over-provisioned relative to whoever actually qualified. The difference is whether dropout surplus pays players during the game or on the final day.
---
[v1.99.56]: Revert v1.99.55 + Remove Absolute Financial Language
Date: March 2026
Lines: 5,701 (net -3 from v1.99.55)
Changes: 1 code revert, 8 NatSpec corrections, 4 changelog corrections.
---
REVERT: v1.99.55 live target removed -- frozen requiredEndPot restored
Simulations confirmed the v1.99.55 live recalculation was unnecessary. With the frozen `requiredEndPot` (v1.99.54 design), exhale revenue collapse to 0% still produces full OG endgame return in all normal scenarios. The formula self-corrects: when exhale revenue disappears, `projectedRevenue` drops, `optimalBreathBps` drops, pot is preserved. The live target added complexity without improving outcomes. Weekly OG dropout surplus banks naturally and flows to draw 52 prizes -- which is the intended design.
---
LANGUAGE FIX: Absolute financial promises removed throughout
The contract and changelog used "guaranteed/guarantee" in financial contexts. Nothing in DeFi is guaranteed -- these are design aims and targets.
Contract fixes:
`proposeStartGame()` NatSpec: "Guarantees all OFFERED OGs a full exit opportunity" → "Provides all OFFERED OGs a 72-hour exit window"
`proposeStartGame()` NatSpec: "The notice period guarantees OG exit windows are honoured" → "is designed to honour"
`proposeStartGame()` inline comment: same correction
`claimSignupRefund()` NatSpec: "FULL REFUND GUARANTEE" → "FULL REFUND AIM"
Dormancy STEP 3 NatSpec: "Players always first" → "Players take priority over charity"
`getProjectedEndgamePerOG()` NatSpec: "OG obligations fully covered" → "on track"
`\_checkAutoAdjust()` NatSpec: "OG endgame payouts remain fully covered" → "remain on track"
`\_lockOGObligation()`: Added "AIM: breath targets this pot level -- not a guarantee"
Changelog fixes: Same corrections applied to v1.99.54 and v1.99.55 changelog entries.
Preserved (correct technical invariants):
"full upfront OGs always qualify" -- code invariant, `isUpfrontOG` flag check
"Safety guaranteed by the while condition" -- mathematical invariant
"OG_ABSOLUTE_FLOOR guarantees 500 upfront OG slots" -- contract behaviour, not financial promise
---
[v1.99.57]: Breath Calibration Fixes + Weekly OG Commitment Disclosure
Date: March 2026
Lines: 5,726 (net +25 from v1.99.56)
Changes: 2 code fixes, 2 NatSpec additions. Triple audit conducted -- 1 INFO finding fixed inline.
---
CODE FIX: startGame() ogRatioBps includes weekly OGs in numerator (FIX 1)
Prior formula: `upfrontOGCount \* 10000 / committedPlayerCount`
Weekly OGs were in the denominator (`committedPlayerCount`) but not the numerator. A game with 200 upfront OGs and 200 weekly OGs showed 50% OG ratio at launch when the true ratio was 100%. Opening breath was set too high for the actual OG concentration.
Fixed: `(upfrontOGCount + earnedOGCount) \* 10000 / committedPlayerCount`
This is the PREGAME orientation estimate only. Draw-7 recalibration (FIX 2) is the authoritative snapshot. Economic effect: PREGAME breath opens more conservatively when weekly OGs are present -- the game has more committed OG obligations than the old formula recognised.
Invariant verified: `totalOGs\_sg <= committedPlayerCount` always holds. Every OG registration increments `committedPlayerCount` exactly once (credit-path or direct). `ogRatioBps` cannot exceed 10000.
---
CODE FIX: _calibrateBreathTarget() uses totalRegisteredPlayers as denominator (FIX 2)
Prior denominator: `ogCapDenominator` = `committedPlayerCount` at `startGame()` = PREGAME committed players only. Casual players who registered and bought tickets in draws 1-7 were invisible to the draw-7 calibration, overstating the OG ratio on casual-heavy games.
Fixed: `totalRegisteredPlayers` = everyone who called `register()` by draw 7 -- all OGs + all casual buyers. (Casual buyers must call `register()` before `buyTickets()`.) This is the authoritative draw-7 population snapshot.
`ogCapDenominator` is unchanged -- still used for OG cap enforcement in `\_upfrontOGCapReached()`, `\_weeklyOGCapReached()`, and `getOGCapInfo()`.
Economic effect: in a 400-OG / 600-casual game, draw 7 now reads 40% OG ratio (not 100%), giving `targetReturnBps = 7500` (75% return target) instead of 4000 (40%). Breath calibrates to the actual game composition, not just the PREGAME committed cohort.
Three-phase design now matches intent:
PREGAME -- rough orientation from committed players, all OG types included in numerator
Draw 7 -- authoritative calibration from full player population, OG ceiling locked
Draw 10 -- obligation locked, post-lock predictive breath takes over
---
NATSPEC: registerAsWeeklyOG() $20 is non-refundable once game launches (FIX 3)
The $20 PREGAME registration payment cannot be recovered after `startGame()` fires. There is no voluntary exit path for weekly OGs in ACTIVE phase. On game failure (failed pregame), `claimSignupRefund()` returns the full $20. The 15% commitment deposit penalty does NOT apply to weekly OGs -- it applies only to upfront OG intent exits via `claimOGIntentRefund()`.
---
NATSPEC: startGame() "Immutable from here" comment corrected (AUDIT-INFO)
Triple audit found the inline comment "Immutable from here" on the breath calibration block was stale -- it predates v1.92 when draw-7 recalibration was added. Both `targetReturnBps` and `breathMultiplier` are recalibrated by `\_calibrateBreathTarget()` at draw 7 close. Comment updated to "Initial orientation only -- recalibrated at draw 7 close."
---

---
[v1.99.57]: Declining Breath Buffer -- Rising Exhale Prize Pools
Date: March 2026
Lines: 5,717 (net +16 from v1.99.56)
Changes: 2 constants added, 1 formula change in `\_checkAutoAdjust()`.
---
CODE CHANGE: 5% declining buffer added to post-lock breath target
The problem: The current formula targets a flat landing at `requiredEndPot`. As the pot grows toward target, the distributable surplus shrinks, breath tightens, and prize pools plateau then fall across the exhale phase. This creates a poor player experience -- the final weeks of the game feel less exciting than the middle weeks.
The fix: A declining buffer is added to `breathTarget` each post-lock draw:
```solidity
uint256 buffer       = requiredEndPot \* BREATH\_BUFFER\_BPS
                       \* remainingDraws / (10000 \* POST\_LOCK\_DRAWS);
uint256 breathTarget = requiredEndPot + buffer;
```
At draw 11: buffer = ~4.9% of requiredEndPot. Declines linearly. At draw 51: ~0.1%. At draw 52: remainingDraws = 0, exact-landing branch fires before this block runs -- buffer never fires at draw 52.
Effect: Breath is held modestly higher early, forcing prizes to build toward draw 52 rather than plateau. Verified across all scenarios:
	No buffer	5% buffer
Draw 50 prizes (normal game)	$7,830	$8,299
Draw 52 prizes (normal game)	$7,865	$8,736
Exhale avg (normal game)	$7,516	$7,764
Inhale avg (normal game)	$5,819	$5,655 (-2.8%)
OG endgame	$1,040	$1,040
Trade-off: Inhale prizes are ~2.8% lower on average. This is deliberate -- holding back slightly more early to fund a stronger late game.
Draw 37 note: A one-draw dip still occurs at the inhale-to-exhale transition regardless of buffer. This is EMA lag -- ticket revenue jumped from $10 to $15 but the EMA needs one draw to absorb the new signal. This is not a buffer issue and is documented in NatSpec.
New constants:
`BREATH\_BUFFER\_BPS = 500` (5.00%)
`POST\_LOCK\_DRAWS = 42` (TOTAL_DRAWS - OG_OBLIGATION_LOCK_DRAW, used as decay denominator)
Overflow safe: max intermediate = requiredEndPot * 500 * 41 < 2.4e20, well within uint256.
Revenue collapse: Buffer has zero effect when `available <= breathTarget` -- `breathRailMin` governs that path unchanged.
---
Cumulative: 5C 3H 27M 55L 112I -- all resolved or NatSpec'd. Cyfrin submission-ready.

---
[v1.99.58]: batchRefundPlayers() -- Owner Push Refund on Failed Pregame
Date: March 2026
Lines: 5,820 (net +103 from v1.99.57)
Changes: 1 constant added, 1 new function.
---
FEATURE: batchRefundPlayers(address[] calldata playerList)
The problem: On a failed pregame, players must call `claimSignupRefund()` individually to recover their funds. If the owner calls `sweepFailedPregame()` before all players have claimed, unclaimed funds go to charity -- players who haven't claimed yet lose their money. There was no owner tool to push refunds and eliminate this risk.
The fix: `batchRefundPlayers()` lets the owner push refunds to a supplied list of addresses. The RUNBOOK pattern is: drain `committedPlayerCount` to 0 via one or more batch calls, then call `sweepFailedPregame()`. At that point `toCharity ≈ 0` -- only Aave yield earned during pregame goes to charity, which is correct.
Accounting: Exact mirror of `claimSignupRefund()` per player. CEI compliant. `\_captureYield()` called once before the loop.
Skip conditions (silent continue, not revert):
`dormancyRefunded = true` -- already processed by self-claim or prior batch
`totalPaid == 0 \&\& prepaidCredit == 0` -- nothing owed, includes voluntary exiters
Player types handled: Upfront OGs (`\_cleanupOGOnRefund`), weekly OGs (`\_cleanupOGOnRefund`), commitment-only players, PENDING intent players. All counter decrements and state cleanup identical to the pull path.
Voluntary exiters: Players who called `claimOGIntentRefund()` have `totalPaid = 0`. They are skipped. Their 15% commitment deposit is NOT returned -- the deposit penalty survives game failure for voluntary exits. This is intentional design.
Duplicate addresses: Safe. First occurrence refunds and sets `dormancyRefunded = true`. Subsequent occurrences are skipped.
New constant:
`BATCH\_REFUND\_MAX = 100` -- kept separate from `MAX\_LAPSE\_BATCH = 500` because each batch refund player requires an Aave withdrawal (~100K gas). 100 players = ~10M gas, within Arbitrum's 32M block limit. If `aaveExited = true`, cost drops to ~30K per player via `safeTransfer`.
Two-pass audit result: 0C 0H 0M 0L 2I. Both infos are accepted design (yield drift negligible, voluntary exit skip by design).
---
Cumulative: 5C 3H 27M 55L 112I -- all resolved or NatSpec'd. Cyfrin submission-ready.

---
[v1.99.59]: Apply Three Missing v1.99.57 Fixes + INFO Correction
Date: March 2026
Lines: 5,839 (net +19 from v1.99.58)
Changes: 2 code fixes (HIGH), 2 NatSpec corrections (LOW), 1 comment correction (INFO).
These fixes were documented in the v1.99.57 changelog as applied but did not land in the code.
---
CODE FIX: startGame() ogRatioBps includes weekly OGs in numerator (H-01)
`ogRatioBps` was computed as `upfrontOGCount \* 10000 / committedPlayerCount`. Weekly OGs (`earnedOGCount`) were in the denominator via `committedPlayerCount` but absent from the numerator, understating the true OG ratio at game launch.
Fixed: `(upfrontOGCount + earnedOGCount) \* 10000 / committedPlayerCount`.
This is the PREGAME orientation snapshot only -- it sets `targetReturnBps` and the opening `breathMultiplier`. The authoritative calibration fires at draw 7 close via `\_calibrateBreathTarget()`.
---
CODE FIX: _calibrateBreathTarget() uses totalRegisteredPlayers as denominator (H-02)
`actualRatioBps` was computed as `maxOGs \* 10000 / ogCapDenominator`. `ogCapDenominator` is set to `committedPlayerCount` at `startGame()` -- it only captures players committed at PREGAME. Casual weekly buyers who joined draws 1-7 are invisible to it, causing `actualRatioBps` to be overstated and `targetReturnBps` to be understated.
Fixed: `maxOGs \* 10000 / totalRegisteredPlayers`. `totalRegisteredPlayers` tracks all registered players across all types and is updated continuously.
---
NatSpec FIX: startGame() "Immutable from here" corrected (LOW-1)
The inline comment read "initial breathMultiplier proportionally. Immutable from here." The breath calibration is NOT immutable from startGame() -- it is recalibrated at draw 7 close via `\_calibrateBreathTarget()`. Corrected to: "Initial orientation only -- recalibrated at draw 7 close."
---
NatSpec FIX: _checkAutoAdjust() predictive formula description updated (LOW-2)
The NatSpec said the formula "projects the pot to requiredEndPot." Since v1.99.57 the formula targets `breathTarget` (= `requiredEndPot + declining buffer`), not `requiredEndPot` directly. NatSpec updated to reflect this. The draw-52 exact-landing branch still targets `requiredEndPot` directly -- buffer is 0 at draw 52 so `breathTarget == requiredEndPot` at that point.
---
COMMENT FIX: buffer percentage corrected to 4.88% (INFO)
The constant-block comment and inline buffer NatSpec said "adds 5% of requiredEndPot at draw 11." The actual computation at draw 11 (remainingDraws = 41): `500 \* 41 / (10000 \* 42) = 4.88%`. Both instances corrected. Not a security issue.
---
Cumulative: 5C 3H 27M 55L 112I -- all resolved or NatSpec'd. Cyfrin submission-ready.

---
[v1.99.60]: NatSpec Corrections from Triple Audit Pass
Date: March 2026
Lines: 5,857 (net +18 from v1.99.59)
Changes: 5 NatSpec corrections (3 LOW, 2 INFO). Zero code changes.
---
L-1: sweepFailedPregame() NatSpec added
The function had no `@notice` or `@dev` block. The NatSpec for it was displaced and appearing to belong to `batchRefundPlayers()`. A full NatSpec block is now positioned immediately before `sweepFailedPregame()` documenting both activation paths (time gate and allRefunded), the fund routing, the treasuryBalance retention, and the RUNBOOK note pointing operators to `batchRefundPlayers()` first.
---
L-2: _lockOGObligation() @dev bullet 1 corrected
Bullet 1 read: "honest formula using upgrader OG_PREPAY_AMOUNT not OG_UPFRONT_COST." This was the pre-v1.99.53 description and contradicted the actual code. Updated to: "all active OGs at draw 10 (upfrontOGCount + earnedOGCount = maxOGs) multiplied by OG_UPFRONT_COST." References v1.99.53 H-01 and v1.99.54 H-02.
---
L-3: getProjectedEndgamePerOG() AUDIT-M-02 block corrected
The block read: "ogEndgameObligation is set in _lockOGObligation() from upfront OG counts only." Since v1.99.54 H-02, `ogEndgameObligation = maxOGs \* OG\_UPFRONT\_COST` where `maxOGs = upfrontOGCount + earnedOGCount`. Weekly OGs are included. Updated to reflect this with a v1.99.54 H-02 reference.
---
I-1: _checkAutoAdjust() formula pseudocode updated
The formula comment block showed `requiredEndPot` as the target. Since v1.99.57 the formula targets `breathTarget = requiredEndPot + buffer`. Updated: `avgRevenue\*remaining - breathTarget` and added note `where breathTarget = requiredEndPot + buffer \[v1.99.57]`.
---
I-2: File header finding count updated
Header read "198 findings documented across 50 versions." Corrected to "202 findings documented across v1.0 to v1.99.60."
---
Cumulative: 5C 3H 27M 55L 112I -- all resolved or NatSpec'd. Cyfrin submission-ready.

---
[v1.99.61]: Audit Remediation -- 2 Medium Fixes + 5 NatSpec
Date: March 2026
Lines: 5,887 (net +30 from v1.99.60)
Changes: 2 code fixes (MEDIUM), 1 code fix (INFO/SSTORE), 4 NatSpec additions.
---
M-01: committedPlayerCount ghost count fixed in claimOGIntentRefund() and forceDeclineIntent()
Root cause: The v1.84/AUDIT-I-01 fix removed the `!ogIntentUsedCredit` gate from `claimSignupRefund()` PENDING path but was not propagated to the two symmetric functions. Credit-path players (who called `payCommitment()` then `registerAsOG()`) had their `committedPlayerCount` incremented by `payCommitment()`. On voluntary exit or forced decline, the decrement was gated behind `!ogIntentUsedCredit` which was `true` for these players -- so the decrement never fired. Ghost count persisted permanently, blocking the `sweepFailedPregame()` allRefunded fast-track.
Fix: Removed the `!ogIntentUsedCredit` gate from both sites. Decrement is now unconditional, mirroring the v1.84 fix exactly. Both credit and non-credit paths had exactly one `committedPlayerCount++` at registration; both now have exactly one `--` on exit.
---
M-02: totalOGPrincipal double-decrement fixed in claimResetRefund()
Root cause: `processMatches()` decrements `totalOGPrincipal` by `p.totalPaid` at weekly OG status-loss. `claimResetRefund()` subsequently decremented `totalOGPrincipal` again by the claim amount for the same player, understating the dormancy proportional denominator.
Fix: The `totalOGPrincipal` decrement inside the `isWeeklyOG` branch is now wrapped in `if (!p.weeklyOGStatusLost)`. The `p.totalPaid` decrement remains unconditional (correct -- it tracks the running balance used by dormancy PATH 2 cap). Active weekly OGs (status not yet lost) are unaffected.
---
I-04: currentTierPerWinner = 0 on TierSkippedDust path in distributePrizes()
One SSTORE added. Eliminates stale-read risk for off-chain tooling after a dust-skip.
---
L-05: proposeDormancy() NatSpec -- Aave exit cancellation documented
Notes that a pending `proposeAaveExit()` timelock is silently cancelled. Re-propose after dormancy if needed. Symmetric behaviour in `emergencyResetDraw()` was already documented at v1.99.34/F2.
---
L-06: sweepResetRefundRemainder() NatSpec -- post-settlement yield drift documented
Notes the consequence-free yield attribution gap and flags it as a required fix in any fork that re-opens ACTIVE after dormancy settlement.
---
I-05: claimDormancyRefund() PATH 3 NatSpec -- draw-N scope clarified
PATH 3 covers only tickets purchased for the in-progress IDLE draw (currentDraw), not the most recently resolved draw. A player whose last buy was draw N (resolved normally) has no PATH 3 entitlement.
---
Cumulative: 5C 5H 27M 55L 112I -- all resolved or NatSpec'd. Cyfrin submission-ready.

---
[v1.99.62]: Pool2 Medium Fix + 5 NatSpec + intentQueueClear field
Date: March 2026
Lines: 5,900 (net +13 from v1.99.61)
Changes: 1 code fix (MEDIUM), 1 code addition (L-03 new return field), 4 NatSpec corrections.
---
M-01-pool2: claimResetRefund() pool 2 totalOGPrincipal double-decrement fixed
Pool 1 was fixed in v1.99.61. Pool 2 was missed. Identical `!weeklyOGStatusLost` guard applied to the pool 2 `isWeeklyOG` block. Both pools now correctly skip `totalOGPrincipal` decrement for status-lost weekly OGs whose principal was already removed at status-loss in `processMatches()`.
---
L-03: getPreGameStats() new return field intentQueueClear (bool)
New 8th return value: `intentQueueClear = (pendingIntentCount == 0)`. Positional index 7. Positions 0-6 unaffected. `readyToStart` (position 5) can be `true` while `intentQueueClear` is `false` -- `startGame()` would revert `IntentQueueNotEmpty` in that case. Front-ends must check both fields before enabling the launch button. ABI change noted in file header and function NatSpec.
---
L-01: File header audit trail count updated
Updated from "202 findings...v1.99.60" to "209 findings...v1.99.62."
---
L-02: Orphaned sweepFailedPregame() NatSpec removed from above batchRefundPlayers()
The `sweepFailedPregame()` NatSpec block was sitting above `batchRefundPlayers()` as well as above `sweepFailedPregame()` itself, creating two consecutive `@notice` blocks before `batchRefundPlayers()`. The orphaned block removed. `sweepFailedPregame()` retains its own correctly-positioned NatSpec.
---
L-04: pruneStaleOGs() NatSpec -- multi-phase accessibility documented
Notes that only `drawPhase == IDLE` is enforced, no `gamePhase` guard. Callable in DORMANT and CLOSED. Documents why this is safe: status-lost weekly OGs cannot reach dormancy PATH 2 regardless, so pruning them in DORMANT produces the same end state via a different execution path.
---
I-02: _matchAndCategorize() @notice added before @dev
Function had `@dev` only. `@notice` added before `@dev` per NatSpec standard convention. Tagged `\[v1.99.62 / I-02]`.
---
Cumulative: 5C 6H 27M 55L 112I -- all resolved or NatSpec'd. Cyfrin submission-ready.

---
[v1.99.63]: NatSpec Corrections from Triple Audit Pass
Date: March 2026
Lines: 5,916 (net +16 from v1.99.62)
Changes: 0 code changes. 9 NatSpec corrections (3L, 4I split across 7 functions).
---
L-01: getPreGameStats() intentQueueClear position corrected to 6
`intentQueueClear` is at position 6 (zero-indexed), not 7. `proposalTimestamp` moved from 6 to 7. Three fixes: signature comment, `proposalTimestamp` inline note, file header. Integrators building positional ABI decoders now have correct indices in all three locations.
---
L-02: topUpCredit() dormancy recovery path documented
Added note that during dormancy, excess prepaid credit is recovered via `claimDormancyRefund()` PATH 5, not `claimUnusedCredit()`. The prior note only mentioned the CLOSED-game path.
---
L-03: buyTickets() lastBoughtDraw assignment linked to AlreadyBoughtThisWeek gate
Added maintenance note at `p.lastBoughtDraw = currentDraw` explicitly linking it to the `weeklyNonOGPlayers.push()` dedup guarantee. Moving this assignment would silently break the array dedup invariant.
---
I-01: claimCharity() endgameOwed decrement documented
One-line note explaining that `claimCharity()` decrements `endgameOwed` by `charityShare`, `sweepUnclaimedEndgame()` decrements by remaining OG claims, and combined decrements equal the initial `endgameOwed` per the `closeGame()` invariant proof.
---
I-02: emergencyResetDraw() delete weekPerformance gas semantics documented
Notes that `delete` on a fixed-size `int256\[32]` array writes zero to all 32 elements individually (32 SSTOREs, ~640K gas worst case). Distinguishes this from the assembly length-zero pattern used for dynamic arrays.
---
I-03: withdrawTreasury() totalTreasuryWithdrawn documented as pure audit counter
Confirms it is never used in any formula or guard. Overflow unreachable at max game scale (~$8.58M << uint256 max).
---
I-04: _matchAndCategorize() NatSpec consolidated to @notice + single @dev
Two separate `@dev` blocks separated by `@notice` merged into one clean `@notice` + one `@dev`. Matches standard NatSpec convention used throughout the contract.
---
Cumulative: 5C 6H 27M 55L 112I -- all resolved or NatSpec'd. Cyfrin submission-ready.

---
[v1.99.64]: Critical Compilation Fix + 4 NatSpec Corrections
Date: March 2026
Lines: 5,925 (net +9 from v1.99.63)
Changes: 1 code fix (CRITICAL), 1 code fix (LOW), 3 NatSpec corrections.
---
C-01: getPreGameStats() return statement swapped -- COMPILATION ERROR FIXED
The v1.99.62/v1.99.63 changes correctly updated the NatSpec to declare `bool intentQueueClear` at position 6 and `uint256 proposalTimestamp` at position 7, but the return statement values were left in the old order: `startGameProposedAt` (uint256) at position 6 and `pendingIntentCount == 0` (bool) at position 7. Solidity 0.8 does not permit implicit conversion between uint256 and bool. The contract would not compile.
Fixed: return statement now correctly places `pendingIntentCount == 0` (bool) at position 6 and `startGameProposedAt` (uint256) at position 7. The declared signature and return values now match.
---
L-01 (carry-forward): closeGame() PATH C emits EndgameShortfall when qualifiedOGs == 0
When `\_countQualifiedOGs()` returns 0 and an obligation existed, `closeGame()` now emits `EndgameShortfall(0, OG\_UPFRONT\_COST, ogEndgameObligation)` before routing all funds to charity. Provides on-chain transparency for OG-class players when all qualified OGs dropped out or never reached parity.
---
L-02: getPreGameStats() intentQueueClear comment wording clarified
"not 7" wording was confusing without full changelog context. Updated to: "intentQueueClear is at position 6. proposalTimestamp is at position 7. First introduced in v1.99.62."
---
L-03: buyTickets() CEI gate tag renumbered to I-05
The `\[v1.99.63 / L-03]` tag in `buyTickets()` clashed with the `\[v1.99.63 / L-03]` ABI change note in the file header. Renumbered to `\[v1.99.64 / I-05]` to restore one-to-one tag-to-finding mapping.
---
I-01: delete weekPerformance gas note corrected
Warm vs cold SSTORE figures both stated: warm ~640K gas, cold ~707K gas (32 × 22,100). Both within Arbitrum 32M limit.
---
Cumulative: 5C 7H 27M 55L 112I -- all resolved or NatSpec'd. Cyfrin submission-ready.

---
[v1.99.65]: Final Pre-Submission Fixes
Date: March 2026
Lines: 5,947 (net +22 from v1.99.64)
Changes: 1 new event, 1 new constant, 1 code addition (L-05), 5 NatSpec/comment fixes.
---
L-05: batchRefundPlayers() pre-check protects batch from PregameOGNetNotSet revert
A weekly OG with `pregameOGNetContributed == 0` (invariant violation) would cause `\_cleanupOGOnRefund()` to revert `PregameOGNetNotSet()`, bricking the entire batch. Added a pre-check that emits `SignupRefundSkipped(addr)` and `continue`s past that player. Their funds remain in `prizePot`. `claimSignupRefund()` remains open for them. Operator must investigate the invariant violation before attempting individual recovery. New event: `event SignupRefundSkipped(address indexed player)`.
---
L-03: JP_MISS_TO_LOWER_TIERS_BPS = 3000 named constant added
Replaces the inline `3000` in `distributePrizes()` JP miss path. Every governance-relevant ratio in the prize flow now has a named constant.
---
L-01: PATH C EndgameShortfall shortfallTotal semantics documented
`shortfallTotal` in PATH C equals `ogEndgameObligation` (total initial obligation), not `(perOGPromised - perOGPaid) \* qualifiedOGs` which would be zero. Off-chain monitors must handle PATH C (perOGPaid == 0 AND shortfallTotal > 0) distinctly from PATH A/B shortfalls.
---
L-02: File header count updated to rolling format
"209 findings...v1.99.62" -> "215+ findings across v1.0 to v1.99.65 -- full count in changelog." Rolling format prevents the header from going stale after each version.
---
L-04: winningResult reset sentinel documented
`winningResult = 0` after `emergencyResetDraw()` is indistinguishable from a valid result where asset 0 won all four ranks. Front-ends must check `DrawPhase` (RESET_FINALIZING or IDLE) to determine whether `winningResult` is stale.
---
I-01: closeGame() PATH C invariant table updated
Invariant comment now notes that PATH C also emits `EndgameShortfall(0, OG\_UPFRONT\_COST, ogEndgameObligation)` when obligation > 0.
---
Cumulative: 5C 7H 27M 55L 113I -- all resolved or NatSpec'd. Cyfrin submission-ready.

---
[v1.99.66]: M-01 Fix + 2 NatSpec Additions
Date: March 2026
Lines: 5,959 (net +12 from v1.99.65)
Changes: 1 code fix (MEDIUM), 2 NatSpec additions.
---
M-01: batchRefundPlayers() L-05 pre-check moved before state mutations
The v1.99.65 L-05 pre-check was inserted after `p.dormancyRefunded = true` and `p.totalPaid = 0` were already written. A skipped player would have their state permanently corrupted -- `dormancyRefunded=true` blocking `claimSignupRefund()` and `totalPaid=0` erasing their payment record -- with no USDC transfer and no recovery path.
Fixed: the pre-check now fires before any state mutations. A skipped player's full state is preserved (`dormancyRefunded=false`, `totalPaid` intact, `prepaidCredit` intact). Operator can investigate the invariant violation and arrange recovery before calling `sweepFailedPregame()`.
---
L-01: claimCharity() PATH C flow documented
Added NatSpec note: in PATH C (`qualifiedOGs == 0`), `endgameCharityAmount` equals the full `prizePot` at settlement. A single `claimCharity()` call settles the entire game. `sweepUnclaimedEndgame()` correctly reverts `NothingToClaim()` after.
---
I-01: batchRefundPlayers() SignupRefundSkipped RUNBOOK added
Documents that a `SignupRefundSkipped` emission indicates a `pregameOGNetContributed == 0` invariant violation. Player state is fully preserved. Operator must investigate and make the player whole via direct treasury action before calling `sweepFailedPregame()`.
---
Cumulative: 5C 8H 27M 55L 113I -- all resolved or NatSpec'd. Cyfrin submission-ready.

---
[v1.99.66]: lastResolvedDraw Added + 2 Comment Fixes
Lines: 5,978
L-02 (CLOSED): lastResolvedDraw field added
New `uint256 public lastResolvedDraw` declaration. Set to `currentDraw` in `resolveWeek()` immediately after `winningResult` is written. Added as position 12 in `getGameState()` return tuple -- ABI change noted in file header. Positions 0-11 unaffected.
Front-end stale check: `lastResolvedDraw != currentDraw - 1`. Single unambiguous signal for reset scenarios.
Edge case documented in NatSpec: before draw 1 resolves, `lastResolvedDraw=0` and `currentDraw=1`, so `0 == 1-1` -- the check does NOT fire as stale. Front-ends must additionally check `DrawPhase` for the pre-first-draw case.
`emergencyResetDraw()` does NOT reset `lastResolvedDraw` -- by design. After a reset `currentDraw` decrements, making `lastResolvedDraw != currentDraw-1` fire correctly without any additional logic.
L-01: Header version updated v1.99.65 -> v1.99.66
I-01: Overflow comment corrected 2.4e20 -> 1.3e18
Cumulative: 5C 8H 27M 55L 113I -- all resolved or NatSpec'd. Cyfrin submission-ready.

---
[v1.99.67]: White-Hat Red Team Audit Remediation
Date: March 2026
Lines: 6,037 (net +54 from v1.99.66)
Changes: 1 new view function, 1 code fix, 6 NatSpec additions, 4 housekeeping fixes.
---
I-03: isResultStale() view function added
On-chain convenience for integrators. Implements the full two-condition stale check: `(lastResolvedDraw != currentDraw - 1) || (winningResult == 0)`. The OR clause covers the post-reset-then-finalizeWeek gap where `lastResolvedDraw == currentDraw-1` but `winningResult` was zeroed by the reset. PREGAME guard: `currentDraw == 0` returns true. Zero gas view function, no state changes.
---
I-05: claimCharity() defensive underflow guard added
`if (endgameOwed < amount) revert InsufficientBalance();` added before `endgameOwed -= amount`. The algebraic invariant in `closeGame()` NatSpec guarantees this can never fire in normal operation, but a belt-and-suspenders guard costs nothing and prevents silent underflow if any future code path sets `endgameCharityAmount` independently of `endgameOwed`. Uses contract's custom error pattern (not `require()`).
---
I-01: Fix tags corrected v1.99.66 → v1.99.67
Three stale-check NatSpec blocks carried `\[v1.99.66 / I-01]` for a finding that didn't exist until the v1.99.67 audit. Corrected to `\[v1.99.67 / I-01]`. The two legitimate v1.99.66 tags (batchRefundPlayers RUNBOOK and overflow comment) unchanged.
---
L-02: Header "New 8th field" → "New 7th field (position 6, zero-indexed)"
`intentQueueClear` is at position 6 (zero-indexed) which is the 7th field in 1-indexed counting. The header said "New 8th field" which was wrong. Corrected to avoid off-by-one confusion for integrators counting from 1.
---
M-01: resolveWeek() tie-break determinism documented
The `>` (strictly-greater-than) tie-break means equal-performing assets always resolve by lower feed array index. This is deterministic, permanent, and publicly known. Players picking lower-index assets gain positive EV in correlation events (stablecoin pairs, wrapped asset variants, simultaneous feed failures). Accepted design, acknowledged in NatSpec for Cyfrin submission.
---
M-02: register() active-phase zombie attack cost boundary documented
Attack cost: N wallets × $40 prepaid credit locked for up to 1 year. To block 100 slots at game margin: ~$4,000 time-locked, fully recovered at close via `claimUnusedCredit()`. No permanent capital loss, but `buyerCap` is drained for the attack window. Accepted design with explicit cost boundary now in NatSpec.
---
I-04: finalizeWeek() dormancy activation window documented
The assembly length-zero clear of `weeklyNonOGPlayers` means dormancy activated immediately after `finalizeWeek()` (before draw N+1 buyers arrive) would exclude draw-N casual buyers from `dormancyParticipantCount`. PICK_DEADLINE guard largely mitigates this. Residual edge case accepted -- activation window is negligibly narrow.
---
@title: version bumped to v1.99.67
---
Cumulative: 5C 8H 27M 55L 113I -- all resolved or NatSpec'd. Cyfrin submission-ready.

---
[v1.99.68]: M-01 resetRefundClaimedAtDraw Double-Refund Fix + executeBreathRails NatSpec
Date: March 2026
Lines: 6,050 (net +13 from v1.99.67)
Changes: 1 new PlayerData field (MEDIUM fix), 3 code sites updated, 1 NatSpec addition.
---
M-01: claimResetRefund() pool2 claim overwrote pool1 record, enabling double-refund
Root cause: A single `resetRefundClaimedAtDraw` field tracked both pool1 and pool2 claims. When a player claimed pool1 (field = `resetDrawRefundDraw`), then claimed pool2 (field overwritten to `resetDrawRefundDraw2`), the pool1 block record was erased. A third call with `lastBoughtDraw` still matching pool1's draw would pass pool1 eligibility again and over-refund -- provided the pool was not yet depleted.
Attack trace:
CALL 1: pool1 fires. `resetRefundClaimedAtDraw = 10`.
CALL 2: pool2 fires. `resetRefundClaimedAtDraw = 20` (OVERWRITES 10).
CALL 3: pool1 check: `claimedAtDraw(20) != 10` = TRUE. Pool1 re-opens. Double refund.
The pool-depletion guard `claim = min(netCost, pool)` only protects a fully-drained pool. In a live game with many players sharing one pool, any individual player's share is a small fraction -- the pool is not drained by their first claim.
Fix: Added `uint256 resetRefundClaimedAtDraw2` to `PlayerData`. Pool1 eligibility checks and writes only touch `resetRefundClaimedAtDraw`. Pool2 eligibility checks and writes only touch `resetRefundClaimedAtDraw2`. Neither overwrites the other. `buyTickets()` snapshot gate for pool2 also updated to use the new field.
Three sites updated: `PlayerData` struct, `claimResetRefund()` (eligibility + write), `buyTickets()` (pool2 snapshot gate).
---
L-01: executeBreathRails() stuck-draw edge case documented
`proposeBreathRails()` requires `drawPhase == IDLE`. `executeBreathRails()` checks only `gamePhase == ACTIVE`. If a draw is stuck for > 7 days (TIMELOCK_DELAY) and `drawPhase` is not IDLE when the timelock expires, the function can fire mid-draw. `DRAW\_STUCK\_TIMEOUT` (48h) makes this scenario highly unlikely. Accepted design, documented in NatSpec with operator guidance.
---
Cumulative: 5C 9H 27M 55L 113I -- all resolved or NatSpec'd. Cyfrin submission-ready.

---
[v1.99.69]: NatSpec Corrections (2 Informational)
Date: March 2026
Lines: 6,063 (net +13 from v1.99.68)
Changes: 2 NatSpec corrections. Zero code changes.
---
I-01: resetRefundClaimedAtDraw struct comment updated for dual-field design
The old comment "Single field serves both pools... Pool2 double-claim is prevented via snapshot erasure" is no longer accurate after the v1.99.68 M-01 fix. Updated to document the new dual-field design: `resetRefundClaimedAtDraw` tracks pool1 claims only, `resetRefundClaimedAtDraw2` tracks pool2 claims only. Explains why the single-field design was retired (pool2 claim overwrote pool1 record) and why snapshot erasure alone was insufficient (pool1 eligibility also matches via `lastBoughtDraw`).
---
I-02: isResultStale() NatSpec -- resolution-phase false-positive documented
During MATCHING, DISTRIBUTING and FINALIZING phases of draw N, `lastResolvedDraw = N` and `currentDraw = N`, so `(N != N-1) = true` -- `isResultStale()` returns true even though `winningResult` is the valid just-resolved result. Front-ends must additionally check `drawPhase != IDLE` to distinguish "result valid, draw still settling" from "result genuinely stale." Do not blank results solely on `isResultStale()` during active resolution.
---
Cumulative: 5C 9H 27M 55L 113I -- all resolved or NatSpec'd. Cyfrin submission-ready.

---
[v1.99.70]: NatSpec Corrections (1 Low, 4 Informational)
Date: March 2026
Lines: 6,063 (unchanged -- NatSpec edits only)
Changes: 5 NatSpec corrections. Zero code changes.
Note: I-01 (struct comment) and I-02 (isResultStale resolution phase) from this audit round were already fixed in v1.99.69.
---
L-01: executeBreathRails() NatSpec corrected -- guard IS present
The v1.99.68 note incorrectly stated "this function only checks gamePhase == ACTIVE." The actual code enforces both `gamePhase == ACTIVE` and `drawPhase == IDLE` -- the function reverts `DrawInProgress()` if the draw is not idle. The stuck-draw scenario described was not possible. Note corrected to accurately describe both enforced guards.
---
I-03: resolveWeek() tie-break comment -- "stablecoin pairs" replaced
The tie-break NatSpec listed "stablecoin pairs" as a tie-source. This deployment uses 32 volatile crypto assets with no stablecoins. Updated to "correlated assets (similar-sector pairs)" with an explicit note that this deployment is volatile-only.
---
I-04: Two version tags corrected v1.99.67 → v1.99.68
The griefing cost boundary note in `register()` and the dormancy window note in `finalizeWeek()` were added in v1.99.68 but carried `\[v1.99.67 / ...]` tags. Corrected to `\[v1.99.68 / M-02]` and `\[v1.99.68 / I-04]`.
---
I-05: File header version updated to v1.99.70
Header count line updated from "v1.0 to v1.99.66" to "v1.0 to v1.99.70".
---
Cumulative: 5C 9H 27M 55L 113I -- all resolved or NatSpec'd. Cyfrin submission-ready.

---
[v1.99.71]: Three Cyfrin Pre-Submission Fixes
Date: March 2026
Lines: 6,079 (net +16 from v1.99.70)
Changes: 1 code fix (encodePicks guard), 2 NatSpec additions.
---
P2-NEW-INFO-01: encodePicks() input validation added -- revert on rank >= 32
Prior behaviour: `encodePicks(32, 0, 1, 2)` silently masked to `encodePicks(0, 0, 1, 2)`, passed `isValidPicks()` without error, and submitted wrong picks with no diagnostic anywhere in the chain. Documented since v1.80/I-04 as "sanitise inputs before calling" but no on-chain guard existed.
Fix: `if (rank1 >= NUM\_ASSETS || rank2 >= NUM\_ASSETS || rank3 >= NUM\_ASSETS || rank4 >= NUM\_ASSETS) revert InvalidPicks();` added before encoding. Out-of-range inputs now produce a clean revert. The silent truncation path is closed. Front-ends should still call `isValidPicks()` after `encodePicks()` to verify unique indices (duplicates are not caught by the new guard).
---
P1-NEW-LOW-01: isResultStale() NatSpec -- severity label + canonical code example
The resolution-phase false-positive note (v1.99.69/I-02) had no severity label and no reference implementation, which Cyfrin would flag. Added: severity LOW label, canonical front-end pattern:
```
bool resultReady = !isResultStale() || drawPhase != DrawPhase.IDLE;
```
Logic verified for all four cases: post-resolution IDLE (TRUE), active MATCHING/DISTRIBUTING/FINALIZING (TRUE), post-reset-then-finalize stale (FALSE), PREGAME (FALSE). `isResultStale()` alone is insufficient during resolution phases.
---
P3-NEW-LOW-04: getDormancyInfo() monitoring note added
When `dormancyParticipantCount == 0`, `perHeadShare` returns 0 but `dormancyPerHeadPool` may still be > 0. PATH 4 claims are still live -- commitment-only players can drain the pool at their net ticket cost. Operators must check `perHeadPool > 0` directly and not treat `perHeadShare == 0` as a signal that PATH 4 is exhausted.
---
Cumulative: 5C 9H 27M 55L 113I -- all resolved or NatSpec'd. Cyfrin submission-ready.

---
[v1.99.72]: PicksMissing Event + 5 NatSpec Additions
Date: March 2026
Lines: 6,121 (net +42 from v1.99.71)
Changes: 1 new event, 1 new emit site, 5 NatSpec additions.
---
P4-NEW-LOW-01: PicksMissing event added to processMatches()
An active OG (upfront or weekly) with `picks == 0` at match time is silently skipped with zero prizes and no on-chain signal. The most common cause: `upgradeToUpfrontOG()` clears the player's weekly picks to 0. If the upgrader forgets `submitPicks()` before the next draw, they participate as an OG (auto-entry) but earn nothing.
New event: `event PicksMissing(address indexed player, uint256 indexed draw)`. Emitted in `processMatches()` when `isActive \&\& p.picks == 0`. No state change. No impact on OG status, endgame eligibility, or future draws. Player can call `submitPicks()` before any subsequent draw and participate normally.
Logic: `if (isActive \&\& picks != 0) { match } else if (isActive) { emit PicksMissing }`. The else-if fires only when `isActive=true` AND `picks==0`. Inactive players (status-lost weekly OGs etc.) are silently skipped as before.
---
P5-NEW-LOW-01: getPlayerInfo() upgrader parity gap documented
`qualifiedForEndgame = false` for an upgrader does NOT mean they are not an OG. It means `totalPaid < OG\_UPFRONT\_COST` -- they have not yet reached parity via `payUpgradeBlock()`. `isUpfrontOG = true` remains, auto-matching continues every draw. NatSpec now explicitly distinguishes `isUpfrontOG` (participation, always true for any OG) from `qualifiedForEndgame` (endgame payout eligibility, requires parity for upgraders).
---
P4-NEW-LOW-02: emergencyResetDraw() amountReturned scope documented
`amountReturned` in the `EmergencyReset` event covers only undistributed funds. Prizes already credited to `p.unclaimedPrizes` in completed tiers remain with those players. Full disruption = `amountReturned + (distWinnerIndex \* currentTierPerWinner)`.
---
P6-NEW-INFO-02: proposeDormancy() feed change runbook note added
Pending feed changes are not cancelled by `proposeDormancy()`. After `activateDormancy()` they become permanently stuck (unexecutable, `gamePhase` guard). Operator runbook: call `cancelFeedChange()` for all pending feed changes before proposing dormancy.
---
P6-NEW-LOW-01: confirmOGSlots() centralization disclosure added
`confirmOGSlots()` is owner-only. Players cannot force processing of their PENDING intent. Economic incentive to abuse is low. Documented as permissioned-by-design centralization disclosure.
---
P4-NEW-INFO-01: processMatches() status-lost weekly OG double-count confirmation
Status-lost weekly OG can appear in both `ogList` (until pruned) and `weeklyNonOGPlayers`. The `!weeklyOGStatusLost` guard in the OG loop ensures they are skipped there and matched exactly once in the non-OG loop. Correctness note added for audit reviewers.
---
Cumulative: 5C 9H 27M 55L 113I -- all resolved or NatSpec'd. Cyfrin submission-ready.

---
[v1.99.73]: SWEPT Player Intent Cleanup Fix
Date: March 2026
Lines: 6,142 (net +21 from v1.99.72)
Changes: 2 code additions. Zero state machine changes.
---
H-01 (reclassified MEDIUM): SWEPT player state not fully cleaned on refund
Root cause: `sweepExpiredDeclines()` marks OFFERED players as SWEPT when their 72-hour response window expires. It does NOT zero `ogIntentAmount` or clean up `ogIntentStatus` or `committedPlayerCount`. `confirmOGSlots()` had previously set `isUpfrontOG = true` for these players, which means they DO have a refund path in failed pregame via the `isUpfrontOG` branch of `claimSignupRefund()`. So no permanent fund loss -- but three state items were left dirty:
`ogIntentAmount` stayed non-zero (blocked re-registration via `AlreadyInIntentQueue`)
`ogIntentStatus` stayed as SWEPT (not DECLINED -- same re-registration block)
`committedPlayerCount` was not decremented -- preventing the `allRefunded` fast-track in `sweepFailedPregame()` from ever reaching zero
Fix: Added a post-chain SWEPT cleanup block in both `claimSignupRefund()` and `batchRefundPlayers()`. The block fires only when `ogIntentStatus == SWEPT` -- a no-op for all other player types. It zeroes `ogIntentAmount`, sets `ogIntentStatus = DECLINED`, and decrements `committedPlayerCount` with the same underflow guard used at every other decrement site.
Note on severity: The auditor rated this HIGH (permanent fund loss). Actual severity is MEDIUM. SWEPT players have `isUpfrontOG = true` (set by `confirmOGSlots`) which gives them a valid refund path through the existing `isUpfrontOG` branch. The original finding was run against stripped code with no NatSpec, so the auditor could not see the state flow documentation.
Two sites updated: `claimSignupRefund()` and `batchRefundPlayers()`.
---
Cumulative: 5C 9H 27M 56L 113I -- all resolved or NatSpec'd. Cyfrin submission-ready.

---
[v1.99.74]: v1.99.73 Double-Decrement Regression Fix
Date: March 2026
Lines: 6,149 (net +7 from v1.99.73)
Changes: 1 line added to `\_cleanupOGOnRefund` SWEPT branch.
---
H-01 regression (MEDIUM): committedPlayerCount double-decrement for SWEPT upfront OGs
Root cause of regression: v1.99.73 added outer SWEPT cleanup blocks to `claimSignupRefund()` and `batchRefundPlayers()` that decrement `committedPlayerCount` when `ogIntentStatus == SWEPT`. However `\_cleanupOGOnRefund` -- called earlier in the same flow via the `isUpfrontOG` branch -- already decrements `committedPlayerCount` unconditionally at its end. Its SWEPT branch clears `ogIntentAmount` and `ogIntentUsedCredit` but does NOT set `ogIntentStatus = DECLINED`. Control returns with `ogIntentStatus` still SWEPT, the outer block fires, and `committedPlayerCount` is decremented a second time.
Fix: One line added to `\_cleanupOGOnRefund`'s SWEPT branch: `ogIntentStatus\[addr] = OGIntentStatus.DECLINED`. This mirrors the OFFERED branch which already sets DECLINED. The outer v1.99.73 blocks now see DECLINED and skip their `committedPlayerCount--`.
Flow after fix:
`claimSignupRefund` -- `isUpfrontOG` branch calls `\_cleanupOGOnRefund`
`\_cleanupOGOnRefund` SWEPT branch -- zeros `ogIntentAmount`, `ogIntentUsedCredit`, sets `ogIntentStatus = DECLINED`
`\_cleanupOGOnRefund` end -- `committedPlayerCount--` (exactly once)
Back in `claimSignupRefund` -- outer SWEPT check sees DECLINED, skips
The outer SWEPT blocks in `claimSignupRefund` and `batchRefundPlayers` are retained as belt-and-suspenders for any hypothetical SWEPT path that does not route through `\_cleanupOGOnRefund`.
---
Cumulative: 5C 9H 27M 56L 113I -- all resolved or NatSpec'd. Cyfrin submission-ready.

---
[v1.99.75]: M-02 CEI Fix + I-05 Deadline Guard + M-01 Runbook Note
Date: March 2026
Lines: 6,169 (net +20 from v1.99.74)
Changes: 2 code fixes, 1 NatSpec addition.
---
M-02: register() CEI violation fixed -- registered=true moved before external calls
In the ACTIVE registration path, `players\[msg.sender].registered = true` and `totalRegisteredPlayers++` and `emit PlayerRegistered` were set AFTER `safeTransferFrom` and the Aave supply `try/catch`. This violated CEI (Checks-Effects-Interactions). `nonReentrant` prevents exploitation today, but the pattern is a latent maintenance trap in any fork that loosens the guard.
Fix: the three state-write lines are moved unconditionally above the `if (gamePhase == GamePhase.ACTIVE)` block. They now fire for both PREGAME and ACTIVE paths before any external call. The `AlreadyRegistered` guard at function entry correctly fires before the flag is set. `RegistrationPrepaid` emit remains conditional on ACTIVE (correct -- it references `prepaidCredit` which is only set in the ACTIVE path).
---
I-05: registerAsOG() signupDeadline guard added
`payCommitment()`, `registerAsWeeklyOG()`, and other PREGAME entry functions all gate on `block.timestamp >= signupDeadline`. `registerAsOG()` PREGAME path had no such guard, leaving a window where new OG intent registrations could be accepted after the signup deadline closed. One-line fix: `if (block.timestamp >= signupDeadline) revert PregameWindowExpired()` added at the top of the PREGAME block, consistent with all other PREGAME entry functions.
---
M-01: forceDeclineIntent() failed-transfer runbook note added
When `\_externalTransfer` throws inside the `try/catch` wrapper, `OGIntentForceDeclineFailed` is emitted. State is already cleaned (DECLINED, counts decremented) so the funds self-heal to `prizePot` on the next `\_captureYield()` call as apparent yield. NatSpec now explicitly warns operators: do NOT use `withdrawTreasury()` to pay the player off-chain after seeing `OGIntentForceDeclineFailed`. The funds have already returned to `prizePot` -- manual payment would double-pay. Correct recovery: wait for next `\_captureYield()`, confirm yield capture, then pay from treasury.
---
Cumulative: 5C 9H 27M 56L 113I -- all resolved or NatSpec'd. Cyfrin submission-ready.

---
[v1.99.76]: registerAsWeeklyOG() signupDeadline Guard
Date: March 2026
Lines: 6,175 (net +6 from v1.99.75)
Changes: 1 line added.
---
P9-NEW-LOW-01: registerAsWeeklyOG() signupDeadline guard added
After v1.99.75/I-05, `registerAsOG()` correctly blocked new OG registrations after `signupDeadline`. `registerAsWeeklyOG()` had no equivalent guard, allowing weekly OGs to register between `signupDeadline` and `signupDeadline + MAX\_PREGAME\_DURATION` (provided no proposal was active). This silently expanded the OG cohort after the nominal signup window, shifting the `ogRatioBps` that breath calibration uses at draw 7 without being included in any pre-launch OG ratio communication.
Fix: `if (block.timestamp >= signupDeadline) revert PregameWindowExpired()` added after the `startGameProposedAt` guard. All three PREGAME entry functions (`payCommitment`, `registerAsOG`, `registerAsWeeklyOG`) now enforce the signup deadline consistently.
---
Cumulative: 5C 9H 27M 56L 113I -- all resolved or NatSpec'd. Cyfrin submission-ready.

---
[v1.99.77]: batchRefundPlayers() Treasury Drainage Runbook
Date: March 2026
Lines: 6,188 (net +13 from v1.99.76)
Changes: 1 NatSpec addition.
---
P1-NEW-LOW-02: batchRefundPlayers() operator monitoring runbook added
When `prizePot` is exhausted mid-batch, remaining refunds draw from `treasuryBalance`. The `SignupRefund(addr, refund, fullAmount)` event does not indicate whether `prizePot` or `treasuryBalance` funded the refund. On a large failed-pregame batch run across multiple calls, treasury could drain significantly with no per-player signal.
NatSpec now documents the operator monitoring pattern: read `treasuryBalance` before each batch call, compare after, track the delta. Repeat until `committedPlayerCount == 0`. No player funds are at risk -- this is an operator tooling gap only.
---
Cumulative: 5C 9H 27M 56L 113I -- all resolved or NatSpec'd. Cyfrin submission-ready.

---
[v1.99.78]: proposeStartGame Guard + Two NatSpec Additions
Date: March 2026
Lines: 6,208 (net +20 from v1.99.77)
Changes: 1 code fix, 2 NatSpec additions.
---
L-01: proposeStartGame() MAX_PREGAME_DURATION expiry guard added
`startGame()` already rejects calls after `signupDeadline + MAX\_PREGAME\_DURATION` via its own `PregameExpired()` check. `proposeStartGame()` had no equivalent guard, allowing an operator to emit `StartGameProposed` after the pregame had technically expired. This creates a 72-hour notice window overlapping an already-invalid pregame, which confuses operators and front-ends that watch for `StartGameProposed` as the launch signal.
Fix: `if (block.timestamp >= signupDeadline + MAX\_PREGAME\_DURATION) revert PregameWindowExpired()` added before `startGameProposedAt = block.timestamp`. One line, zero financial risk, mirrors the guard already in `startGame()`.
---
H-01 (INFO): _calibrateBreathTarget() registerInterest inflation documented
`registerInterest()` increments `totalRegisteredPlayers` for zero-capital PREGAME players who may never commit. These inflate the draw-7 breath calibration denominator, reducing apparent `ogRatioBps` and pushing `targetReturnBps` slightly higher. The bias is conservative -- better for casual players, marginally smaller per-OG endgame pot sizing. Bounded by `interestedCount` at game start. Documented in NatSpec and flagged for Cyfrin submission as accepted design with known conservative bias direction.
---
M-02 (LOW): payUpgradeBlock() reset loss quantification added
Maximum exposure per emergency reset: active upgraders * $80. At theoretical maximum (9,900 OGs all upgrading simultaneously): $792,000. Practical exposure is far lower -- upgrader counts are typically small and emergency resets are rare. Requires two events to coincide in the same draw window. Classification: LOW (unchanged from v1.6/L-01).
---
Cumulative: 5C 9H 27M 56L 113I -- all resolved or NatSpec'd. Cyfrin submission-ready.

---
[v1.99.79]: M-02 Figure Correction + NEW-I-01 Drift Note
Date: March 2026
Lines: 6,218 (net +10 from v1.99.78)
Changes: 2 NatSpec corrections. Zero code changes.
---
INFO: payUpgradeBlock() M-02 quantification corrected
The v1.99.78 note stated maximum exposure = 9,900 * $80 = $792,000, using TOTAL_OG_CAP_BPS. This was wrong. Upgraders are upfront OGs, capped by UPFRONT_OG_CAP_BPS (10% of MAX_PLAYERS = 5,500 max upfront OGs). Correct maximum = 5,500 * $80 = $440,000. Figure corrected.
---
NEW-I-01: _countQualifiedOGs() upgrader drift during DORMANT documented
When an upgrader with parity claims via PATH 1 of `claimDormancyRefund()`, `upfrontOGCount` and `qualifiedUpgraderOGCount` decrement but `upgraderOGCount` does not, creating drift in `fullUpfrontOGs = upfrontOGCount - upgraderOGCount`. Zero financial impact: `\_countQualifiedOGs()` is only called by `closeGame()` (blocked during DORMANT) and `getProjectedEndgamePerOG()` (returns (0,0,0) when `dormancyTimestamp > 0`). Accepted informational, documented in NatSpec.
---
Cumulative: 5C 9H 27M 56L 113I -- all resolved or NatSpec'd. Cyfrin submission-ready.

---
[v1.99.80]: getGameState() NatSpec @notice Repositioned
Date: March 2026
Lines: 6,223 (net +5 from v1.99.79)
Changes: 1 NatSpec cosmetic fix.
---
INFO: getGameState() @notice was structurally orphaned
The `/// @notice Returns a high-level snapshot of overall game state` comment sat in a contiguous `///` block above `isResultStale()`. Solidity NatSpec parsers attach a contiguous `///` block to the immediately following function declaration. Since `isResultStale()` was inserted between that block and `getGameState()`, the `@notice` was parsed as belonging to `isResultStale()`, leaving `getGameState()` appearing undocumented in auto-generated docs. Zero financial risk. Fixed by adding a standalone `/// @notice` directly above `function getGameState()`.
---
Cumulative: 5C 9H 27M 56L 113I -- all resolved or NatSpec'd. Cyfrin submission-ready.

---
[v1.99.81]: Stage 1 -- Prepaid Credit System Removed
Date: March 2026
Lines: 6,022 (net -201 from v1.99.80)
Changes: Major architectural removal. Zero new features in this version.
---
Design decision
The prepaid credit system (casual players registering in ACTIVE and pre-loading $40 for 4 draws) was removed entirely. Problems it created: zombie slot-holding griefing, exhale price arbitrage ($530/player structural discount), orphaned credit at game end, and a complex accounting float sitting in the solvency formula. Replacement: per-draw payment with auto-pick fallback (Stages 2-3).
---
Removed entirely
Constants: `PREPAY\_WEEKS`
State variables: `totalPrepaidCredit`, `activeRegistrationCount`
PlayerData fields: `prepaidCredit`, `usedStandardRegistrationActive`
Events: `CreditToppedUp`, `CreditConsumed`, `RegistrationPrepaid`, `UnusedCreditReturned`
Functions: `claimUnusedCredit()`, `topUpCredit()`, `getCreditBalance()`
---
Modified
`register()` ACTIVE path: No longer loads prepaid credit or transfers USDC. Registration is now free -- players buy tickets each draw independently. Capacity check simplified: `upfrontOGCount + weeklyOGCount >= MAX\_PLAYERS` (no slot reservation).
`buyTickets()`: Credit deduction block removed. Commitment draw-1 credit ($10 for pre-registered weekly OGs in draw 1) retained -- this is a separate mechanism unrelated to the casual prepay system. `buyerCap` formula simplified: `MAX\_PLAYERS - ogSlotsTaken` with no reserved-slot subtraction.
`claimSignupRefund()`: Guards simplified from `totalPaid == 0 \&\& prepaidCredit == 0` to `totalPaid == 0`.
`batchRefundPlayers()`: PATH 5 (prepaid-credit-only refund) removed. Guards simplified.
`claimDormancyRefund()`: Credit top-up block at end of function removed.
`payUpgradeBlock()`: prepaidCredit drain block removed (was defensive dead code -- PREGAME weekly OGs never had prepaidCredit).
`\_solvencyCheck()` and `\_captureYield()`: `totalPrepaidCredit` removed from `nonPotAllocated` formula. Both sides of the solvency equation reduced equally -- invariant holds. Players now pay at `buyTickets()` time, so no float accumulates between registration and ticket purchase.
`OG\_PREPAY\_AMOUNT`: Retained (used by `upgradeToUpfrontOG()` and `payUpgradeBlock()`). Dependency on `PREPAY\_WEEKS` inlined: `4 \* TICKET\_PRICE \* MIN\_TICKETS\_WEEKLY\_OG = $80`.
---
Solvency invariant after Stage 1
Before: `nonPotAllocated` included `totalPrepaidCredit` as a ring-fenced player float. The corresponding asset (USDC/aUSDC) sat in the contract between registration and ticket purchase.
After: No float. Payments flow directly to `treasuryBalance` and `prizePot` at `buyTickets()` call time. `nonPotAllocated` smaller by the amount previously held as prepaid float -- actual contract balance smaller by the same amount. Net effect on solvency invariant: zero.
---
Stage 2 (buyTickets ABI change + submitPicks eligibility) and Stage 3 (auto-pick system) to follow.

---
[v1.99.82]: Stage 1 NatSpec Cleanup (Post-Removal Hygiene)
Date: March 2026
Lines: 6,016 (net -6 from v1.99.81)
Changes: 1 dead error removed, 6 NatSpec corrections, 1 header update.
---
Dead error removed
`CreditTopUpGameNotActive` -- reverted only by `topUpCredit()` which was removed in v1.99.81. Dead declaration removed.
---
NatSpec corrections (6 functions)
`register()` -- @dev rewritten. Removed references to `prepaidCredit`, `totalPrepaidCredit`, `topUpCredit()`. Now states registration is free and stateless, capacity enforced at `buyTickets()`.
`buyTickets()` -- Removed stale sentence about prepaidCredit being consumed first. Removed "active registrations" from capacity description.
`upgradeToUpfrontOG()` -- @dev line updated from "All weekly OGs registered in PREGAME have prepaidCredit = 0" to "All upgraders transfer OG_PREPAY_AMOUNT ($80) fresh." Body comments replaced: removed prepaidCredit drain path references.
`claimDormancyRefund()` -- PATH 5 (prepaid credit) removed from path list. Note added: four paths remain.
`withdrawTreasury()` -- `totalPrepaidCredit` removed from ring-fenced pools enumeration.
`batchRefundPlayers()` -- SKIP condition updated from `totalPaid == 0 \&\& prepaidCredit == 0` to `totalPaid == 0`.
---
Header updated
Finding count range updated from "v1.0 to v1.99.70" to "v1.0 to v1.99.82".
---
BREAKING (Stage 1): `register()` in ACTIVE phase no longer transfers USDC. Integrators must not expect a balance change on this call.
---
Stage 2 (buyTickets ABI + submitPicks eligibility) and Stage 3 (auto-pick system) pending.

---
[v1.99.82]: Stage 1 NatSpec Fixes + Stage 2 Auto-Pick System
Date: March 2026
Lines: 6,128 (net +106 from v1.99.81)
Changes: Stage 1 NatSpec cleanup (8 fixes) + Stage 2 auto-pick system (new functions, events, constants).
---
Stage 1 NatSpec fixes
`CreditTopUpGameNotActive` dead error removed
`register()` @dev NatSpec updated: prepaidCredit/topUpCredit references removed, BREAKING note added
`buyTickets()` @dev: prepaidCredit sentence removed, capacity description updated
`upgradeToUpfrontOG()` body comments: stale prepaidCredit drain references replaced
`claimDormancyRefund()` @dev: PATH 5 (prepaid credit) removed from list
`withdrawTreasury()` @dev: totalPrepaidCredit removed from enumeration
`batchRefundPlayers()` @dev: SKIP condition updated from `totalPaid == 0 \&\& prepaidCredit == 0` to `totalPaid == 0`
Header version tag updated to v1.99.82
---
Stage 2: buyTickets() ABI change
BREAKING: `buyTickets(uint32 picks, uint256 ticketCount)` → `buyTickets(uint256 ticketCount)`. Picks are now submitted separately via `submitPicks()` any time before `PICK\_DEADLINE`. `TicketsBought` event updated (picks field removed). Pre-mainnet -- no live integrations affected.
---
Stage 2: submitPicks() opened to all registered players
Previously OG-only (`isUpfrontOG || isWeeklyOG`). Now: OGs can always submit picks (auto-entered every draw). Casual players can submit picks if they have bought a ticket this draw (`lastBoughtDraw == currentDraw`). Neither path → `NotEligible()` revert.
---
Stage 2: Auto-pick system
New constant: `GENESIS\_PICKS = \[0,1,2,3]` (packed uint32). Default picks for new players with no pick history. Published pre-launch with the 32-asset feed ordering.
New constant: `AUTO\_PICK\_BUFFER = 300` (5 minutes before `PICK\_DEADLINE`).
New state: `address public automationForwarder` -- settable by owner via `setAutomationForwarder()`.
New events: `AutoPickApplied(player, draw, picks)`, `AutomationForwarderSet(forwarder)`.
New error: `NotEligible()`.
New functions:
`applyAutoPicksForDraw(address\[] calldata)` -- called by Chainlink Automation 5 min before deadline. For each address: if ticket bought this draw and picks == 0, assigns GENESIS_PICKS. Access: owner or automationForwarder only. Batch limit: 500.
`checkUpkeep(bytes)` -- Chainlink Automation interface. Returns true when game ACTIVE, draw IDLE, within AUTO_PICK_BUFFER window before deadline.
`performUpkeep(bytes)` -- Chainlink Automation execution. Decodes address list from performData and applies auto-picks.
`setAutomationForwarder(address)` -- owner-only. Sets the CL Automation forwarder address.
processMatches() updated: Both OG loop and casual loop now apply GENESIS_PICKS fallback for any player with picks == 0. No more silent skips. Every player with a ticket participates. This is the authoritative on-chain fallback; `applyAutoPicksForDraw()` is best-effort.
---
Design notes
`p.picks` persists between draws for all player types. Returning players automatically carry forward their last submitted picks with no action required.
New players (picks == 0) receive GENESIS_PICKS [0,1,2,3] on their first draw, then carry forward.
Prize dilution risk when many players share GENESIS_PICKS in a winning draw is acknowledged and accepted.
`applyAutoPicksForDraw()` + `processMatches()` work in sequence: keeper fires 5 min before deadline (best-effort), contract applies fallback at match time (authoritative).
---
Cumulative: 5C 9H 27M 56L 113I -- all resolved or NatSpec'd.

---
[v1.99.83]: Swarm Audit Fixes on v1.99.82
Date: March 2026
Lines: 6,153 (net +25 from v1.99.82)
Changes: 2 code fixes (CRITICAL + HIGH), 5 NatSpec additions.
---
C-01: buyTickets() residual _validatePicks(picks) removed (compile fix)
`\_validatePicks(picks)` was left in `buyTickets()` after the Stage 2 picks parameter removal. `picks` is no longer in scope -- compile error. Removed. Picks validation belongs exclusively to `submitPicks()`.
---
H-01: performUpkeep() access guard added
`performUpkeep()` had no access control. Any EOA could call it with a crafted address list and write `GENESIS\_PICKS` to any player's storage before they submitted. `applyAutoPicksForDraw()` had the correct guard (`owner || automationForwarder`) but `performUpkeep()` did not. Guard added: `if (msg.sender != owner() \&\& msg.sender != automationForwarder) revert OwnableUnauthorizedAccount(msg.sender)`.
---
M-01: submitPicks() error change documented (ABI break)
`submitPicks()` now reverts `NotEligible()` instead of `NotOG()` when a player is ineligible. This is an ABI-breaking change for any error-catching callers. Documented in NatSpec with call-order requirement: casual players must call `buyTickets()` before `submitPicks()` each draw.
---
NatSpec additions
`checkUpkeep()`: `AUTO\_PICK\_BUFFER` window is advisory only. `performUpkeep()` callable any time by permissioned callers as manual override. `\[v1.99.83 / I-01]`
`processMatches()` casual loop: stale picks note -- p.picks persists between draws, front-ends must display current stored picks and prompt re-submission. `\[v1.99.83 / I-02]`
`\_calibrateBreathTarget()`: free ACTIVE registration (v1.99.81) extends the existing registerInterest() denominator inflation note. `\[v1.99.83 / L-01]`
---
Cumulative: 5C 9H 27M 56L 113I -- all resolved or NatSpec'd.

---
[v1.99.84]: PicksMissing Removed + Automation Refactor
Date: March 2026
Lines: 6,157 (net +4 from v1.99.83)
Changes: 1 dead event removed, 1 internal function extracted, 1 function relocated.
---
L-02: PicksMissing event removed -- superseded by AutoPickApplied
Stage 2 replaced the `else if (isActive) { emit PicksMissing }` path in `processMatches()` with the auto-pick fallback. `PicksMissing` can never fire in v1.99.82+. The event declaration and all NatSpec references removed. `AutoPickApplied` is the correct signal for zero-picks players at match time.
---
I-04: Duplicate auto-pick loop extracted to _applyAutoPicks() internal
`applyAutoPicksForDraw()` and `performUpkeep()` contained identical loop bodies. Extracted to `\_applyAutoPicks(address\[] memory)` internal function. Both callers now delegate to the internal. Single source of truth for the auto-pick assignment logic. Access control and phase guards remain in each caller as the outer layer.
---
I-03: setAutomationForwarder() relocated to automation section
`setAutomationForwarder()` was adjacent to `acceptOwnership()` causing NatSpec bleed from the ownership section. Relocated to sit with `\_applyAutoPicks()`, `applyAutoPicksForDraw()`, `checkUpkeep()`, and `performUpkeep()` for logical grouping. No functional change.
---
Cumulative: 5C 9H 27M 56L 113I -- all resolved or NatSpec'd.

---
[v1.99.85]: NatSpec Fixes (NS-05, NS-06, NS-07 + INFO-01)
Date: March 2026
Lines: 6,166 (net +9 from v1.99.84)
Changes: 3 NatSpec fixes. Zero code changes.
---
NS-06: processMatches() NatSpec block repositioned
Moving `setAutomationForwarder()` in v1.99.84 caused the `processMatches` NatSpec block to sit above `setAutomationForwarder` rather than above `function processMatches()`. Solidity NatSpec parsers attach each `///` block to the immediately following function declaration, so the full `processMatches` description was being attributed to `setAutomationForwarder`. The orphan fragment `///      OGs each IDLE window...` was all that preceded `function processMatches()`. Both issues fixed: full NatSpec block moved to directly above `function processMatches()`, orphan fragment removed.
---
NS-05: Contract header version tag updated
Header now reads `215+ findings across v1.0 to v1.99.85`. Was stale at v1.99.82 across three versions.
---
NS-07 + INFO-01: _applyAutoPicks() NatSpec extended
Two notes added: (1) phase guard dependency -- internal function has no `gamePhase`/`drawPhase` guards of its own; callers must enforce them; future call sites must replicate ACTIVE+IDLE checks. (2) Gas note -- `applyAutoPicksForDraw()` passes `calldata players\_` as `memory`, forcing a copy (~3 gas/element, max ~1,500 gas at 500 elements on Arbitrum, under $0.01). `performUpkeep()` unaffected -- `abi.decode` already produces memory.
---
Cumulative: 5C 9H 27M 56L 113I -- all resolved or NatSpec'd.

---
[v1.99.86]: Missing @notice Restored on Two Functions
Date: March 2026
Lines: 6,172 (net +6 from v1.99.85)
Changes: 2 NatSpec additions. Zero code changes.
---
NEW-I-02: registerInterest() and closeGame() @notice restored
Both functions were missing `@notice` NatSpec. Present in prior versions, dropped during the Stage 1/2 refactor. Single `/// @notice` line added above each, with a tag noting the restoration. No NatSpec bleed risk -- both functions stand alone with no adjacent function NatSpec to contaminate.
---
Zero open findings at C, H, M, or L. Cyfrin-ready at v1.99.86.

---
[v1.99.87]: Draw Automation -- completeDrawStep + unified keeper
Date: March 2026
Lines: 6,172 (net +0 from v1.99.86 -- extraction balanced by new functions)
Changes: Architectural refactor. Logic unchanged. New public function, 3 internal extractions, checkUpkeep/performUpkeep replaced.
---
New: completeDrawStep()
Permissionless public function that advances the draw state machine by one step. Routes based on drawPhase:
`MATCHING` → `\_processMatchesCore()` (call repeatedly until DISTRIBUTING)
`DISTRIBUTING` → `\_distributePrizesCore()` (call repeatedly until FINALIZING)
`FINALIZING` / `RESET\_FINALIZING` → `\_finalizeWeekCore()` (single call)
`UNWINDING` → `\_continueUnwind()` (call until RESET_FINALIZING)
`IDLE` → reverts `DrawNotProgressing()`
Any address may call `completeDrawStep()` during a live draw. Chainlink Automation calls it via `performUpkeep()` action 1.
---
New: DrawNotProgressing error
Reverted by `completeDrawStep()` and `performUpkeep()` action 1 when `drawPhase == IDLE`.
---
Extracted internals
`\_processMatchesCore()`, `\_distributePrizesCore()`, `\_finalizeWeekCore()` -- core logic moved from public functions into internal helpers. Public wrappers (`processMatches`, `distributePrizes`, `finalizeWeek`) retain their `nonReentrant` guards and phase checks, then delegate to the cores. `completeDrawStep()` and `performUpkeep()` action 1 also call the cores directly.
---
checkUpkeep rewritten (unified keeper)
Now handles both draw progression and auto-picks via action byte:
Priority 1 (draw in progress): returns `(true, abi.encode(uint8(1)))`
Priority 2 (auto-pick window): returns `(true, abi.encode(uint8(2)))`
For action 2, `checkUpkeep` returns only the action byte. The keeper must build the player list from `TicketsBought` events and re-encode as `abi.encode(uint8(2), address\[] players\_)` before calling `performUpkeep`. Passing `checkUpkeep` output directly for action 2 will revert.
---
performUpkeep: nonReentrant restored + action routing
`nonReentrant` was absent in v1.99.82-86. Restored: `\_distributePrizesCore()` and `\_finalizeWeekCore()` write prize state and phase variables; reentrancy guard is required.
Action routing:
action 1: draws state machine forward (same paths as `completeDrawStep()`)
action 2: applies auto-picks via `\_applyAutoPicks(players\_)`
---
Cumulative: 5C 9H 27M 56L 113I -- all resolved or NatSpec'd.

---
[v1.99.88]: NatSpec Restoration Post-v1.99.87 Extraction
Date: March 2026
Lines: 6,192 (net +20 from v1.99.87)
Changes: 3 NatSpec fixes. Zero code changes.
---
NS-01: processMatches() NatSpec block restored
The full NatSpec block for `processMatches()` was dropped entirely during the v1.99.87 core extraction. The function had no `@notice` or `@dev` block above it. Restored with one correction: the stale line "Upfront OGs with p.picks == 0 are skipped silently" is replaced with the correct v1.99.82 behaviour -- auto-pick fallback applies `GENESIS\_PICKS` and emits `AutoPickApplied`. No player is skipped.
---
NS-02: distributePrizes() @notice added
The public wrapper had no `@notice` of its own -- only the `\_distributePrizesCore()` internal had NatSpec. Added a brief `@notice` directly above the wrapper pointing readers to the core for full detail.
---
NS-03: finalizeWeek() @notice added
Same issue as NS-02. The public wrapper had no `@notice`. Added a brief `@notice` directly above the wrapper.
---
Cumulative: 5C 9H 27M 56L 113I -- all resolved or NatSpec'd.

---
[v1.99.88]: NatSpec fixes on v1.99.87 extractions + GENESIS_PICKS hex
Date: March 2026
Lines: 6,180 (net +8 from v1.99.87)
Changes: 4 NatSpec fixes. Zero code changes. Zero logic changes.
---
NS-01: processMatches() @notice restored
The `@notice` block for `processMatches()` was eaten by the v1.99.87 step-6 replacement of the checkUpkeep/performUpkeep block. The `pu\_fn\_end` marker included the processMatches NatSpec in the replaced range because it sat between the end of performUpkeep and the start of `function processMatches()`. Restored directly above the wrapper.
---
NS-02: finalizeWeek() @notice added
The `finalizeWeek()` public wrapper was left bare during v1.99.87 extraction. The original NatSpec was attached to the pre-extraction function and the wrapper replaced it without carrying the block forward. `@notice` and `@dev` added.
---
NS-03: _finalizeWeekCore/@notice bleed fixed
In v1.99.87, the `\_finalizeWeekCore @dev` lines ran directly into the `completeDrawStep @notice` lines forming one merged `///` block. Solidity NatSpec parsers attach a contiguous block to the immediately following function declaration -- both blocks were attaching to `completeDrawStep()`, leaving `\_finalizeWeekCore()` undocumented. Fixed: `\_finalizeWeekCore @dev` is now a standalone block directly above its function.
---
GENESIS_PICKS hex annotation
Added `// = 0x18820` inline comment on the constant declaration, matching the ETH fork. The correct packed value for indices [0,1,2,3] is 100384 = 0x18820. The fork had noted 0x18820 correctly; the reference was missing the annotation.
---
Cumulative: 5C 9H 27M 56L 113I -- all resolved or NatSpec'd.

---
[v1.99.89]: L-01 gamePhase guard unified + M-01 documented
Date: March 2026
Lines: 6,194 (net +14 from v1.99.88)
Changes: 1 code fix (L-01), 2 NatSpec additions (M-01).
---
L-01 FIXED: completeDrawStep() gamePhase guard unified
The DISTRIBUTING branch had a per-branch `if (gamePhase != ACTIVE)` guard while all other branches had none. While safe in practice (all non-IDLE phases are only reachable during ACTIVE), the inconsistency was a maintenance trap for forks. Fixed: single `if (gamePhase != GamePhase.ACTIVE) revert GameNotActive()` at the top of `completeDrawStep()` covering all branches. The per-branch guard on DISTRIBUTING removed.
---
M-01 DOCUMENTED: UNWINDING timeout bypass is intentional
`completeDrawStep()` calls `\_continueUnwind()` directly without the `UNWIND\_CONTINUATION\_TIMEOUT` check that exists in `emergencyResetDraw()`. This makes the timeout dead code for the automation path -- intentionally. The timeout was designed for manual non-owner callers in a world without automation. With Chainlink Automation driving the unwind via `completeDrawStep()`, immediate continuation is correct. The timeout path in `emergencyResetDraw()` is retained as a manual fallback. Documented in both `completeDrawStep()` NatSpec and the UNWINDING branch of `emergencyResetDraw()`.
---
Finding register after v1.99.89
All prior open findings resolved or documented:
M-01 (UNWINDING timeout bypass): Documented as intentional design. Closed as accepted.
L-01 (asymmetric gamePhase guards): Fixed.
L-02 (checkUpkeep action-2 operator note): Documented in NatSpec. Accepted.
I-01 (calldata-to-memory copy): Acknowledged.
I-02 (automation gas vs _continueUnwind guard): Operator note.
---
Zero open findings at C, H, M, or L. Cyfrin-ready.

---
[v1.99.90]: M-NEW-01 -- pull refund for failed forceDeclineIntent() transfers
Date: March 2026
Lines: 6,224 (net +30 from v1.99.89)
Changes: 1 new function, 2 new state variables, 1 new event, 4 accounting updates, 1 NatSpec correction.
---
M-NEW-01: forceDeclineRefundOwed pull model
Previously, when `forceDeclineIntent()` caught a failed `\_externalTransfer()`, the funds remained in the contract and would self-heal to `prizePot` on the next `\_captureYield()` call. This was incorrect: `prizePot` had already been decremented at force-decline time. The self-healing created apparent yield from player funds that properly belonged to the player, and the associated NatSpec runbook was misleading.
Fix: failed transfers now store the owed amount in `forceDeclineRefundOwed\[player]` (pull mapping) and increment `totalForceDeclineRefundOwed`. Players call `claimForceDeclineRefund()` to recover. `\_captureYield()`, `\_solvencyCheck()`, and `getSolvencyStatus()` include `totalForceDeclineRefundOwed` in the non-pot-allocated accounting so the aggregate is never re-inflated as yield. `sweepFailedPregame()` excludes it from the charity sweep.
---
New: claimForceDeclineRefund()
Callable in any phase. The mapping entry is the sole eligibility check. CEI: mapping zeroed before transfer. On a failed game, players should call this before `sweepFailedPregame()` sweeps the USDC balance.
---
New: ForceDeclineRefundClaimed event
Emitted by `claimForceDeclineRefund()` on successful pull claim.
---
NatSpec: forceDeclineIntent runbook corrected
The `\[v1.99.75 / M-01]` block described the old self-healing approach and said "DO NOT use withdrawTreasury() -- the funds have self-healed to prizePot." Replaced with the correct pull-model runbook referencing `claimForceDeclineRefund()`.
---
Combines v1.99.89 draw automation (completeDrawStep, unified keeper) with M-NEW-01 pull refund model. Cumulative: 5C 9H 27M 56L 113I -- all resolved or NatSpec'd. Zero open C/H/M/L.

---
[v2.0]: Upgrade path removal -- upgradeToUpfrontOG and payUpgradeBlock deleted
Date: March 2026
Lines: 5,933 (net -291 from v1.99.90)
Changes: 2 functions deleted, 2 errors deleted, 2 events deleted, 2 constants deleted/renamed, 2 state variables deleted, 1 PlayerData field deleted, 2 internal functions simplified, 7 NatSpec/comment sites cleaned.
---
Design decision: upgrade path removed entirely
The weekly-to-upfront OG upgrade path (`upgradeToUpfrontOG()` in draws 1-7, `payUpgradeBlock()` for subsequent $80 blocks) was removed on the basis that:
It was architecturally messy. Two classes of upfront OG with different qualification thresholds created complexity in `\_isQualifiedForEndgame()`, `\_countQualifiedOGs()`, dormancy PATH 1, and both `claimResetRefund()` pools.
It created a zombie risk. A player who upgraded for $80 and never paid the remaining $960 in blocks played as an upfront OG for the full game but qualified for no endgame share. Their capital was stuck in the pot with no refund path.
The Arb game had a design flaw: `payUpgradeBlock()` had no draw deadline, allowing late qualification after the draw-10 obligation lock. The ETH game fixed this but the inconsistency across forks was a liability.
The replacement model ($20/week for 52 draws) is simpler, self-policing, and already mostly implemented via the existing weekly OG streak and status-loss machinery.
---
Removed: upgradeToUpfrontOG()
Function deleted in full. Allowed a PREGAME weekly OG to pay $80 in draws 1-7 to become an upfront OG. No replacement.
---
Removed: payUpgradeBlock()
Function deleted in full. Allowed an upgrader to pay $80 blocks toward the $1,040 OG_UPFRONT_COST total. No replacement.
---
Removed: errors
`NotWeeklyOG()` -- only used by the two removed functions
`UpgradeWindowClosed()` -- only used by the two removed functions
---
Removed: events
`UpfrontOGUpgraded` -- emitted only by `upgradeToUpfrontOG()`
`UpgradeBlockPaid` -- emitted only by `payUpgradeBlock()`
---
Removed: constants
`OG\_PREPAY\_AMOUNT` -- used only by the two removed functions. Value was `4 \* TICKET\_PRICE \* MIN\_TICKETS\_WEEKLY\_OG` ($80).
`OG\_UPGRADE\_LAST\_DRAW = 7` -- renamed `BREATH\_CALIBRATION\_DRAW = 7`. The draw-7 breath calibration trigger is retained and valid without the upgrade path. The constant was serving two purposes; only one survives.
---
Removed: state variables
`upgraderOGCount` -- count of players who called `upgradeToUpfrontOG()`
`qualifiedUpgraderOGCount` -- count of upgraders who reached `OG\_UPFRONT\_COST` parity via blocks
---
Removed: PlayerData field
`upgradedFromWeekly` (bool) -- set by `upgradeToUpfrontOG()`, read by dormancy PATH 1, both `claimResetRefund()` pools, and `\_isQualifiedForEndgame()`. All readers updated or removed.
---
Simplified: _isQualifiedForEndgame()
Previously two upfront OG paths: plain upfront OGs always qualified; upgraders only qualified if `totalPaid >= OG\_UPFRONT\_COST`. Now one path: `if (p.isUpfrontOG) return true`. Weekly OG path unchanged.
---
Simplified: _countQualifiedOGs()
Previously: `(upfrontOGCount - upgraderOGCount) + qualifiedUpgraderOGCount + qualifiedWeeklyOGCount`.
Now: `upfrontOGCount + qualifiedWeeklyOGCount`.
---
Updated: totalOGPrincipal comment
Increment sites updated from (6) to (4): removed `upgradeToUpfrontOG` and `payUpgradeBlock`. Confirmed active sites: `confirmOGSlots`, `registerAsWeeklyOG`, `buyTickets` (weekly OG path), `\_continueUnwind`.
Decrement sites note retained -- pre-existing inaccuracy corrected in v2.01 (see I-V2-04 below).
---
NatSpec cleaned (7 sites)
`AutoPickApplied` event comment: upgrade cause removed, auto-pick fallback language retained.
`registerAsOG()` NatSpec: ACTIVE clause updated to remove upgrade reference.
`registerAsOG()` ACTIVE path inline comment: simplified to WrongPhase explanation only.
`confirmOGSlots()` emit comment: "ACTIVE upgrade path" reference removed.
`registerAsWeeklyOG()` NatSpec: upgrade window paragraph removed. "No upgrade path exists" added.
`resolveWeek()` NatSpec: `OG\_UPGRADE\_LAST\_DRAW` replaced with `BREATH\_CALIBRATION\_DRAW`.
`\_calibrateBreathTarget()` NatSpec: "upgrade window end" replaced with "BREATH_CALIBRATION_DRAW".
`\_lockOGObligation()` NatSpec and inline: all upgrader bias notes and `OG\_PREPAY\_AMOUNT` references removed.
`\_checkAutoAdjust()` inline: upgrader bias comment replaced with v2.0 note.
`getDormancyInfo()` NatSpec: upgrader totalPaid cap note removed.
---
Inherited from v1.99.90
All v1.99.89 draw automation (completeDrawStep, unified keeper, DrawNotProgressing) and v1.99.90 M-NEW-01 pull-refund model fully carried into v2.0. Verified by triple audit pass.
---
Cumulative finding register: 5C 9H 27M 56L 113I -- all resolved or accepted. Zero open C/H/M/L.
---
[v2.01]: Seven NatSpec findings from triple audit resolved
Date: March 2026
Lines: 5,938 (net +5 from v2.0)
Changes: NatSpec and comment corrections only. Zero logic changes.
---
L-V2-01: NatSpec bleed -- registerAsWeeklyOG NatSpec was attached to claimForceDeclineRefund
The NatSpec parser attaches a comment block to the next function declaration. In v2.0, the `registerAsWeeklyOG` @notice/@dev block was placed before `claimForceDeclineRefund`'s NatSpec and function body, so parsers attached the weekly OG docs to `claimForceDeclineRefund` and `registerAsWeeklyOG` received no NatSpec.
Fix: reordered so `claimForceDeclineRefund` @notice/@dev sits immediately above its own function, and `registerAsWeeklyOG` @notice/@dev sits immediately above its own function.
---
L-V2-02: Stale getProjectedEndgamePerOG @dev referencing removed upgrader distinction
The inline comment read: "Prior: upfrontOGCount + qualifiedWeeklyOGCount included all upgraders regardless of parity." In v2.01, `\_countQualifiedOGs()` returns exactly `upfrontOGCount + qualifiedWeeklyOGCount`. The comment falsely implied a more sophisticated formula was previously in use and that the current formula was the old flawed one.
Fix: replaced with `// \[v2.01] \_countQualifiedOGs() returns upfrontOGCount + qualifiedWeeklyOGCount. No upgrader distinction exists in v2.0+. All upfront OGs qualify unconditionally.`
---
I-V2-01 (RESOLVED in v2.0): Dead events UpfrontOGUpgraded + UpgradeBlockPaid
Both events removed in v2.0 as part of the upgrade path deletion. Confirmed absent.
---
I-V2-02 (RESOLVED in v2.0): Dead errors NotWeeklyOG + UpgradeWindowClosed
Both errors removed in v2.0 as part of the upgrade path deletion. Confirmed absent.
---
I-V2-03 (RESOLVED in v2.0): Dead constant OG_PREPAY_AMOUNT
Removed in v2.0. Confirmed absent from live code. Appears only in the v2.0 changelog header as historical documentation.
---
I-V2-04: totalOGPrincipal decrement comment missed claimResetRefund sites
The comment listed "(5)" decrement sites but `claimResetRefund()` pool1 and pool2 both decrement `totalOGPrincipal` when `isWeeklyOG \&\& !weeklyOGStatusLost`. Pre-existing inaccuracy carried forward from v1.99.90.
Fix: updated to "(7)" with pool1 and pool2 listed explicitly.
---
I-V2-05: Header audit trail said "v1.0 to v1.99.85"
Fix: updated to "v1.0 to v2.01". Changelog header block updated with v2.0 change summary.
---
All seven findings resolved. Zero open findings at any severity. Cyfrin-ready.

---
[v2.02]: NEW-I-02 -- getPlayerInfo qualifiedForEndgame stale after claim
Date: March 2026
Lines: 5,941 (net +2 from v2.01)
Changes: One expression updated in getPlayerInfo(). Zero logic changes elsewhere.
---
NEW-I-02: qualifiedForEndgame returned true after claimEndgame() called
`getPlayerInfo()` returned `qualifiedForEndgame = true` for a player who had already successfully called `claimEndgame()`. The field was computed as `\_isQualifiedForEndgame(p) \&\& dormancyTimestamp == 0` which has no knowledge of claim state. Front-ends rendering a "Claim Endgame" button from this field would re-display it post-claim. The on-chain guard in `claimEndgame()` correctly reverts `AlreadyClaimed()` so no funds were at risk.
Fix: added `\&\& !p.endgameClaimed` to the return expression. The field now returns false once the player has claimed, giving front-ends an accurate signal.
---
Zero open findings at any severity. Cyfrin-ready.

---
[v2.03]: Triple audit findings resolved -- 3M, 1CL, 1L, 7NS/I
Date: March 2026
Lines: 6,028 (net +87 from v2.02)
Changes: 1 new function, 1 new state variable, 1 new error, 1 new event, 2 constant changes, 4 accounting updates, 8 NatSpec additions. Zero logic regressions.
---
M-v2.02-01: PicksResetOnUnwind event emitted on weekly OG status restoration
`processMatches()` clears `p.picks = 0` when a weekly OG loses status. `\_continueUnwind()` restores `weeklyOGStatusLost = false` but previously did not signal that picks remained zero. A restored OG who missed the resubmit window before the next `resolveWeek()` would be auto-matched with `GENESIS\_PICKS \[0,1,2,3]` instead of their chosen picks, potentially losing one draw's prize opportunity through no fault.
Fix: `PicksResetOnUnwind(address indexed player, uint256 atDraw)` event emitted immediately after each status restoration in `\_continueUnwind()`. Front-ends consume this event and surface a targeted prompt to call `submitPicks()` before the next draw. picks are intentionally NOT restored -- the OG genuinely missed the reset draw and has no prior picks to restore to.
---
M-v2.02-02: performUpkeep() action-2 MalformedPerformData guard
If a Chainlink keeper passed `checkUpkeep()` output directly to `performUpkeep()` for action 2 (auto-picks), the ABI decode produced a low-level Solidity panic with no named error. Keeper monitoring saw an opaque revert; auto-picks failed silently and players entered with `GENESIS\_PICKS`.
Fix: `MalformedPerformData()` custom error added. A `performData.length < 64` pre-check (32 bytes for `uint8` action + 32 bytes minimum for array offset) fires before the ABI decode. Named error surfaces explicitly in keeper job history. Correctly-formed action-2 calls are unaffected.
---
M-v2.02-03: activateDormancy() STEP 3 charity extracted to claimDormancyCharity()
The STEP 3 charity transfer (`\_withdrawAndTransfer(CHARITY, charityActual)`) was inside `activateDormancy()`. Under Aave liquidity stress, `IPool.withdraw()` could revert, blocking dormancy activation entirely while leaving the game ACTIVE with players continuing to transact.
Fix: STEP 3 now sets `dormancyCharityPending = charityActual` and deducts from `prizePot` at activation time (accounting identical to before). The live transfer is extracted to `claimDormancyCharity()`, callable by anyone after `dormancyTimestamp > 0`. `dormancyCharityPending` is included in all three `nonPotAllocated` accounting sites (`\_captureYield`, `\_solvencyCheck`, `getSolvencyStatus`) to prevent re-inflation as yield. `sweepDormancyRemainder()` zeroes `dormancyCharityPending` and includes it in the remaining calculation.
No player refund is affected: STEP 3 only fires when both full-cover flags are true, meaning all player obligations were already allocated in STEPs 1 and 2.
---
CL-v2.02-01: AUTO_PICK_BUFFER increased from 300 to 1800 seconds
5 minutes was too tight an automation window on Arbitrum given sequencer outage recovery times. The ETH fork uses 1 hour. Arbitrum, with L2 sequencer dependency, warrants at minimum a 30-minute buffer. Increased to `1800` (30 minutes). `processMatches()` GENESIS_PICKS fallback remains the authoritative safety net.
---
L-v2.02-04: MAX_UNWIND_PER_TX reduced from 3000 to 500
3000 implied ~360M gas per transaction -- 11x the Arbitrum 32M block limit. The NatSpec comment even stated this explicitly. Reduced to 500, achievable within the Arbitrum block limit (~25M gas at 50K per iteration). The `gasleft() < 50\_000` per-iteration guard in `\_continueUnwind()` is the authoritative runtime safety net regardless.
---
I-v2.02-01: registerAsOG() _validatePicks reordered
`\_validatePicks(picks)` was called before the `if (gamePhase == GamePhase.PREGAME)` branch, meaning an ACTIVE caller with invalid picks received `InvalidPicks()` not `WrongPhase()`. NatSpec stated "ACTIVE reverts WrongPhase()" which was factually incorrect for that input.
Fix: `\_validatePicks()` moved inside the PREGAME block. ACTIVE callers now always receive `WrongPhase()` at the trailing revert regardless of picks validity. NatSpec updated to document the correct ordering.
---
I-v2.02-03: BREATH_CALIBRATION_DRAW comment clarified
The constant comment said "Upgrade path removed" without specifying which upgrade path. Auditors could misread this as `\_calibrateBreathTarget()` itself being dead code.
Fix: Comment now reads "The weekly-to-upfront OG upgrade path (upgradeToUpfrontOG, payUpgradeBlock) was removed in v2.0. This constant retains the draw-7 snapshot timing for `\_calibrateBreathTarget()` which is independent of the upgrade path."
---
NS-v2.02-01: checkUpkeep action-2 augmentation cross-reference
Added to `checkUpkeep()` NatSpec: action-2 return is a signal only. Keeper must re-encode as `abi.encode(uint8(2), address\[] players)` before calling `performUpkeep()`. Passing output directly reverts `MalformedPerformData()`.
---
NS-v2.02-02 / L-v2.02-01: claimResetRefund two-call requirement formally documented
The pool-1 early-return (`return;` after success) preventing same-transaction pool-2 claim is now explicitly tagged in NatSpec: "A second call is required for pool-2."
---
NS-v2.02-03 / I-v2.02-07: emergencyResetDraw casual rebuy lockout documented
Casual players who already bought the reset draw cannot rebuy (AlreadyBoughtThisWeek guard). Their net ticket cost is refundable via claimResetRefund(). Now documented in function NatSpec.
---
NS-v2.02-04 / I-v2.02-04: sweepFailedPregame direct safeTransfer explained
Comment added explaining why `IERC20.safeTransfer()` is used directly rather than `\_withdrawAndTransfer()`: `aaveExited` is guaranteed true at that point. The Aave withdrawal path is unreachable. Divergence from other charity transfer sites is intentional.
---
NS-v2.02-05 / I-v2.02-01: registerAsOG NatSpec corrected for error ordering
NatSpec now correctly states that ACTIVE callers receive WrongPhase() for all inputs, and explains that the prior InvalidPicks-first behaviour was a diagnostic inaccuracy now fixed by the _validatePicks reorder.
---
Cumulative: 5C 9H 27M 56L 113I resolved or accepted. Three new mediums resolved (M-v2.02-01/02/03). Zero open C/H/M/L. Cyfrin-ready.

---
[v2.04]: Two lows and three NatSpec/info fixes -- doc-only pass
Date: March 2026
Lines: 6,038 (net +10 from v2.03)
Changes: Comment and NatSpec corrections only. Zero logic changes. Zero ABI changes.
---
L-v2.03-01: Stale gas comment in _continueUnwind() corrected
The per-iteration gas guard comment block read "At MAX_UNWIND_PER_TX = 3000 that is ~360M gas -- 11x Arbitrum block limit." `MAX\_UNWIND\_PER\_TX` was reduced to 500 in v2.03. The comment misstated both the value and the implication.
Fix: Updated to "At MAX_UNWIND_PER_TX = 500 that is ~25M gas -- within Arbitrum's 32M block limit. The per-iteration gasleft() < 50_000 guard is the authoritative safety net regardless of the batch ceiling."
---
L-v2.03-02 / NS-v2.03-01: applyAutoPicksForDraw() NatSpec "5 minutes" updated to "30 minutes"
`AUTO\_PICK\_BUFFER` was increased from 300 (5 min) to 1800 (30 min) in v2.03. The NatSpec for `applyAutoPicksForDraw()` still said "Called by Chainlink Automation 5 minutes before PICK_DEADLINE."
Fix: Updated to "30 minutes" with a `\[v2.04 / L-v2.03-02]` tag noting the v2.03 constant change.
---
NS-v2.03-02: claimDormancyCharity() ordering note added
Added to NatSpec: "If sweepDormancyRemainder() executes before this function, dormancyCharityPending is zeroed by the sweep and this call reverts NothingToClaim(). The charity amount is absorbed into the swept remainder in that case -- no funds are lost."
---
NS-v2.03-03 / I-v2.03-03: DormancyCharitySent event comment corrected
The event declaration comment read "Emitted when charity is sent immediately at dormancy activation." Since v2.03 / M-v2.02-03, charity is sent via `claimDormancyCharity()`, not at activation.
Fix: Updated to "Emitted when the STEP 3 dormancy charity amount is claimed via claimDormancyCharity(). Charity is no longer sent at activation (changed in v2.03/M-v2.02-03)."
---
I-v2.03-02: sweepDormancyRemainder() var-zeroing count updated
The comment "Five additional vars zeroed" had not been updated to account for `dormancyCharityPending` added in v2.03. Count is now seven, with all seven vars listed explicitly.
---
I-v2.03-01 (deferred): getDormancyInfo() missing dormancyCharityPending field
`dormancyCharityPending` is a live claimable pool post-activation. Adding it as a tenth return value to `getDormancyInfo()` would give front-ends a clean "pending charity: $X" signal. Deferred: ABI-breaking change, schedule alongside any future view function updates.
---
I-v2.03-04 (accepted): PicksResetOnUnwind scope confirmed correct
Confirmed that `PicksResetOnUnwind` cannot double-emit for a pruned OG. After `pruneStaleOGs()`, the OG has `isWeeklyOG = false` and is no longer in `ogList`. `\_continueUnwind()` iterates `ogList` only. The event scope is correct. No action required.
---
Cumulative: 5C 9H 27M 56L 113I resolved or accepted. Zero open C/H/M/L. Cyfrin-ready.

---
[v2.05]: Two lows -- stale "5 min" and "Six vars" comment cleanup
Date: March 2026
Lines: 6,035 (net -3 from v2.04)
Changes: Three inline comment/NatSpec corrections. Zero logic changes. Zero ABI changes.
---
L-v2.04-01 / NS-v2.04-02: _processMatchesCore() "5 min" inline comment updated
The auto-pick fallback block in `\_processMatchesCore()` read "applyAutoPicksForDraw() should have fired 5 min before deadline." `AUTO\_PICK\_BUFFER` was increased to 1800 seconds (30 min) in v2.03 and the `applyAutoPicksForDraw()` NatSpec was corrected in v2.04, but this inline comment in the OG matching loop was missed. A matching stale reference in the `buyTickets()` function header was also updated.
Fix: Both occurrences updated to "30 minutes before deadline."
---
L-v2.04-02 / NS-v2.04-01: sweepDormancyRemainder() @dev header "Six" updated to "Seven"
The function-level `@dev` NatSpec header listed six additional state vars zeroed and carried `\[v1.99.47] Corrected from "five" to "six"`. The inline body comment was correctly updated to seven in v2.04 (I-v2.03-02 fix) when `dormancyCharityPending` was added, but the `@dev` header was not updated to match.
Fix: Updated to "Seven additional state vars zeroed" with `dormancyCharityPending` added to the explicit list. The contradicted `\[v1.99.47]` parenthetical removed and replaced with `\[v2.05] Updated from "six"`.
---
Carried / accepted
I-v2.04-01 (`getDormancyInfo()` missing `dormancyCharityPending`): Deferred. ABI-breaking, schedule with future view function changes.
---
Cumulative: 5C 9H 27M 56L 113I resolved or accepted. Zero open C/H/M/L. Cyfrin-ready.
