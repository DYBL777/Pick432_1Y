# Crypto42 Master Changelog
## Development History: 3Y Lineage to 1Y v2.68

**Protocol:** Crypto42 (3Y format) and Crypto42 1Y (One-Year Format)
**Contracts:** Crypto42_v1.sol (3Y) / Crypto42_1Y (1Y fork)
**Audit methodology:** Severity labels C/H/M/L/I throughout
**Development period:** Late 2025 to March 2026
**Author:** DYBL Foundation

> This document records the development and audit history of the Crypto42
> protocol lineage, from the original 3Y contract through to 1Y v2.66.
> The 3Y and 1Y contracts live in separate repositories.
> This changelog exists to provide development provenance for auditors
> and grant reviewers.
>
> **3Y repo:** DYBL777/DYBL-Crypto42 (Crypto42_v1.sol)
> **1Y repo:** separate repository (Crypto42_1Y)
>
> v1.1.15 (1Y) source was not available at time of writing. See the consolidated
> bridge entry at that version. All other entries are evidenced from source
> code or documented audit sessions.

---

---

# PART 1, 3Y CONTRACT LINEAGE

## 3Y Version Index

| Version | Headline |
|---------|----------|
| v1.0 | Initial 3Y contract. 1,094 lines. |
| v1.1 | S2-FIX-01-17 + S2-DOC-01-04: oracle resilience, timelocks, gas fixes (50 items) |
| v1.2 | S2-FIX-18-24 + S2-DOC-05: endgame split, treasury taper, exhale accuracy |
| v1.3 | S2-FIX-25-50 + S2-DOC-06-16: dormancy perimeter, per-feed staleness, pick lock, JP overflow |
| v1.4 | Final 3Y audit pass. 50 code fixes + 16 docs complete. 1,663 lines. Published to GitHub. |
| v1.5 | Internal: OG cap restructure, Config D BPS, JP miss redesign prep |
| v1.6 | V16-01-11: major economics and auto-breathe redesign |
| v1.7 | Internal hardening pass |
| v1.8 | 10 further fixes: yield timing, auto-breathe accuracy, obligation lock, free draw removed |
| v1.8 audit | Full second-pass audit: 3C 4M 7L 3I. All critical fixed. |
| v16(40) | Final 3Y state. Forked to produce 1Y v1.0.0. |

---

## [3Y v1.0]: Initial Contract

### Summary

Original Crypto42 3Y contract. 150-draw prediction game: pick 6 of 42 cryptos,
Chainlink price feeds determine weekly winners, Aave V3 compounds the prize pot.
Two-tier OG membership with endgame share. 1,094 lines.

**Core parameters:**
- TOTAL_DRAWS = 150, TICKET_PRICE = $7.50, OG_UPFRONT_COST = $2,250
- MAX_PLAYERS = 111,111
- INHALE_DRAWS = 104, EXHALE_DRAWS = 46
- Chainlink price feeds: 42 assets
- Aave V3 yield on prize pot

---

## [3Y v1.1 - v1.4]: Security Hardening Sprint (S2 Series)

### Summary

50 code fixes and 16 documentation notes across v1.1 through v1.4.
The complete S2 series. Contract grows from 1,094 to 1,663 lines.
Published to GitHub at v1.4 as Crypto42_v1.sol.

### S2-FIX-01 (MEDIUM): Oracle resilience: try/catch on _resolveWeek()

One dead or stale feed disqualifies that crypto. Game never stalls.
Previously a reverting aggregator propagated a full revert through resolveWeek(),
permanently sticking the draw at IDLE with no emergency exit path.

### S2-FIX-02 (MEDIUM): Oracle resilience: try/catch on _snapshotStartPrices()

Dead feed at snapshot stores 0. resolveWeek() disqualifies assets with
startPrice <= 0. Chain of resilience across both oracle touchpoints.

### S2-FIX-03 (LOW): Precision upgrade: PERFORMANCE_MULTIPLIER 10000 to 10^10

Matches Chainlink 8-decimal precision. Eliminates performance ties.
Two cryptos must move identically to 0.00000001% to tie.

### S2-FIX-04 (MEDIUM): Stale start price check in _snapshotStartPrices()

Feed alive but stale at snapshot stores 0 and is disqualified.
Prevents performance calculation built on bad baseline data.

### S2-FIX-05 (LOW): getCurrentPerformance() try/catch

One dead feed no longer reverts entire view function.
Frontend leaderboard stays live during feed failures.

### S2-FIX-06 (CRITICAL: trust surface): Feed update timelock

proposeFeedUpdate / executeFeedUpdate / cancelFeedUpdate. 7-day delay.
Anyone can execute after timelock expires. Owner cannot silently swap
feeds to rig outcomes. Replaces instant updatePriceFeed.

### S2-FIX-07 (LOW): Feed proposal overwrite prevention

AlreadyProposed error. Must cancel existing proposal before proposing
new one for same index. Prevents silent clock resets.

### S2-FIX-08 (MEDIUM: decentralisation): Permissionless emergency functions

emergencyResetDraw() and forceCompleteDistribution() no longer onlyOwner.
14-day timeout IS the protection. If owner vanishes, anyone can unstick.

### S2-FIX-09 (INFO): NatSpec on emergency functions

Documents deliberate nonReentrant omission. No token transfers = no
reentrancy surface. Documentation only.

### S2-FIX-10 (HIGH: fund loss): extendSubscription game phase check

GameClosed revert. Prevents money being taken after closeGame() when
no more draws will ever happen.

### S2-FIX-11 (CRITICAL: direct fund theft): changePicks front-running prevention

changePicks / changePicksBoth: drawPhase must be IDLE. Attacker cannot
read WeekResolved event and swap to winning combo before matching runs.

### S2-FIX-12 (LOW): Dormancy race condition closed

performUpkeep, triggerDraw, and checkUpkeep all check dormancyActive.
No draw can start during dormancy batch processing.

### S2-FIX-13 (MEDIUM): JP distribution double-bonus prevention

!jpHitThisWeek guard on JP block entry. Uncapped JP loop (all JP winners
paid in one call). Bonus deducted once.

### S2-FIX-14 (MEDIUM: superseded by S2-FIX-20): Exhale pot routing

Originally routed 100% to pot during exhale. Later replaced with linear
treasury taper. Annotated as superseded in changelog.

### S2-FIX-15 (HIGH: design correction): Independent ticket matching

Two tickets = two entries = two payouts. Same address can appear twice
in winner arrays. distributePrizes handles naturally. Replaces best-of-two
logic which was artificially suppressing multi-ticket prize value.

### S2-FIX-16 (LOW): rescueAbandonedPot()

Permissionless, callable after week 312 with zero OGs and zero subs.
Pot + JP reserve to treasury. Prevents permanent fund lock in dead game.

### S2-FIX-17 (LOW): Fixed exhale treasury cap

periodStartTreasuryBalance snapshots at period start. 20% cap consistent
regardless of withdrawal pattern within 30-day period.

### S2-DOC-01-04

- Gas asymmetry on final distributePrizes batch (~300-400k extra gas)
- Degenerate combo documentation (all feeds dead = [0,1,2,3,4,5])
- Treasury naming clarification (boolean gate, not percentage)
- Yield attribution: all Aave yield to prizePot only

---

### v1.2 additions (S2-FIX-18-24)

### S2-FIX-18 (HIGH: design): Endgame split

closeGame distributes 80% OGs, 20% treasury. Charity commitment
operational from treasury, not enforced on-chain.

### S2-FIX-19: Charity wallet timelock [REMOVED in v1.3]

Charity handled off-chain from treasury allocation.

### S2-FIX-20 (MEDIUM: design): Treasury taper during exhale

Treasury take declines linearly from 25% to 0% over 52 exhale weeks.
Replaces 100%-to-pot. Smooth decline mirrors breathing mechanic.
Supersedes S2-FIX-14.

### S2-FIX-21 (HIGH: fund lock prevention): rescueAbandonedPot time-based fallback

Fires when real wall-clock time exceeds (TOTAL_WEEKS + CLOSE_GRACE_WEEKS),
not just when currentWeek advances. Fixes fund lock when game dies
mid-run and week counter stalls. 100% to treasury.

### S2-FIX-22 (LOW): getPotHealth exhale accuracy

Inflow calculation reflects actual treasury taper during exhale.
Dashboard numbers match reality.

### S2-FIX-24 (LOW): getEstimatedOGShare reflects 80% endgame split

Shows actual expected payout, not 100% of pot.

---

### v1.3 additions (S2-FIX-25-50)

### S2-FIX-25 (HIGH): expireSubscription blocked during dormancy

Swap-and-pop during dormancy batch skips users behind the cursor.
Direct fund loss for innocent subscribers. Blocked.

### S2-FIX-26 (MEDIUM): triggerDormancy requires drawPhase == IDLE

Prevents dormancy firing mid-draw, which would corrupt tierPayoutAmounts
and prizePot.

### S2-FIX-27 (MEDIUM): Charity code removed entirely

charityWallet, charityBalance, proposeCharityWallet, executeCharityWallet,
cancelCharityWallet, withdrawCharity, CHARITY_WALLET_DELAY, 3 errors,
4 events removed. Charity handled operationally from treasury.

### S2-FIX-28 (HIGH): Dormancy guard on subscribe / subscribeDouble / extendSubscription

New subscriber during dormancy batch increases activeSubscribers, causing
underflow on completion. Complete dormancy perimeter enforced.

### S2-FIX-29 (LOW): Dormancy guard on closeGame

Dormancy distributing from prizePot while closeGame splits it = double-spend.

### S2-FIX-30 (INFO): Removed unused errors: StaleFeed, InvalidFeedPrice

Dead code since try/catch handles stale feeds.

### S2-FIX-31 (MEDIUM): expireSubscription blocked during MATCHING/DISTRIBUTING

Swap-and-pop during matching moves last subscriber behind cursor,
skipping them for prizes.

### S2-FIX-32 (INFO): getContractState returns dormancyActive

Frontend display of game winding down state.

### S2-FIX-33 (LOW): Pin compiler: ^0.8.24 to 0.8.24

Standard production practice.

### S2-FIX-34 (MEDIUM: operational): Per-feed staleness thresholds

Replaces single constant with uint256[42] array. Each feed matches its
actual Chainlink heartbeat (e.g. BTC 2hr, low-cap 24hr). Updated via
feed timelock atomically. getAllStalenessThresholds() view added.

### S2-FIX-35 (LOW): _removeSubscriber OG grant time check

All three OG grant paths now require currentWeek >= startWeek + 208 - 1
for consistency.

### S2-FIX-36 (MEDIUM): Pick lock: PICK_LOCK_BEFORE_RESOLVE = 3 days

Picks frozen 3 days before resolve window. 4 days to analyse, 3 days
of commitment. Applied to: subscribe, subscribeDouble, changePicks,
changePicksBoth. Enforces prediction over copying the leaderboard.

### S2-FIX-37 (LOW): FeedDisqualified event

Emitted in _snapshotStartPrices when storing 0. uint8 reason code
(1 = stale/invalid, 2 = dead/reverted).

### S2-FIX-38 (MEDIUM: trustlessness): closeGame decentralisation

Owner grace period removed. Anyone calls once currentWeek > 312
or time expires.

### S2-FIX-39 (MEDIUM): Subscribe during pick lock: deferred start week

startWeek = currentWeek + 1. matchAndPopulate skips deferred subs.
Prevents first-week front-running while keeping door open for new players.

### S2-FIX-40 (MEDIUM: safety): Ownable2Step

Two-step ownership transfer prevents loss to typo. renounceOwnership()
overridden to revert. A 6-year game cannot become headless.

### S2-FIX-41 (LOW): Aave negative rebase

_captureYield deducts loss from prizePot instead of silently ignoring.
Floors at zero. Keeps books honest if aUSDC balance drops.

### S2-FIX-42 (MEDIUM: fund recovery): Dead game rescue shortcut

rescueAbandonedPot third path: zero subs + zero OGs + 90 days since
last draw. Prevents funds locked for years in a game that died at week 50.

### S2-FIX-43 (INFO): arePicksLocked() view function

Frontend convenience.

### S2-FIX-44 (INFO): Removed unused JP_SEED_BPS constant

### S2-FIX-45 (MEDIUM): Non-OG deferred sub into exhale guard

If deferred startWeek > INHALE_WEEKS and user is not OG, revert NotOG.
Prevents paying for weeks that would be skipped.

### S2-FIX-46 (MEDIUM): Aave negative rebase waterfall

prizePot absorbs loss first. If insufficient, remainder deducted from
treasury. Prevents phantom solvency gap when prizePot is zero.

### S2-FIX-47 (MEDIUM): rescueAbandonedPot returns orphaned tier payouts

Returns tierPayoutAmounts to pot before rescue. Same pattern as
emergencyResetDraw.

### S2-FIX-48 (LOW): renounceOwnership dedicated error

RenounceDisabled custom error. InvalidAddress was misleading for
monitoring tools.

### S2-FIX-49 (INFO): Removed unused TIER_SEED_BPS constant

Seed calculated as remainder. Constant was dead code.

### S2-FIX-50 (MEDIUM: game economics): JP overflow

When jackpot not hit, 20% of that week's JP allocation overflows back
to prizePot. Remaining 80% accumulates in jpReserve. Keeps tier prizes
growing during long JP dry spells. JP_OVERFLOW_BPS = 2000.
New event JackpotOverflow.

**Total: 50 code fixes + 16 documentation notes. Lines: 1,094 to 1,663.**

---

## [3Y v1.5]: 16-Fix Hardening Sprint

### Summary

Internal hardening version. 16 fixes covering gas safety, OG qualification
enforcement, yield capture, accounting correctness, and exploit prevention.
Not published separately to GitHub. Source recovered from local archive.

Contract header title: `Crypto42 v1.5`
BUSL-1.1 Change Date: 24 February 2030

Constants unchanged from prior version (OG caps still 26%/33%, restructured
in V16). Prize BPS in this version: JP=3600, M5=2200, M4=1500, M3=1000,
M2=700, SEED=1000.

### FIX-04: Gas bomb: weekly OG status check moved into processMatches()

Pre-fix: a loop over all OGs ran in resolveWeek(), risk of gas limit hit
at scale. Fixed: lazy check folded into batched processMatches() alongside
player matching. Each OG checked at match time, not upfront.

### FIX-05: 117-week qualification enforced for weekly OG endgame eligibility

WEEKLY_OG_QUALIFICATION_WEEKS = 117 constant added. _isQualifiedForEndgame()
and _countQualifiedOGs() now gate endgame claims on consecutive weeks.
qualifiedWeeklyOGCount running counter maintained. O(1) qualification check
at closeGame(). Upfront OGs unconditionally qualified.

### FIX-06: Aave yield captured in closeGame() and closeDormantGame()

_captureYield() called before endgame split in both close paths. Reads
actual aUSDC balance, subtracts non-pot allocations, sets prizePot to real
surplus. All untracked accumulated yield flows into the endgame pot.
YieldCaptured event emitted.

### FIX-08: Signup refund accounting properly capped

claimSignupRefund() bounded by maxDeductible = prizePot + treasuryBalance.
Refund drawn from prizePot first, treasury second. Prevents underflow if
refund exceeds either bucket individually.

### FIX-09: Require picks at OG registration (both types)

_validatePicks(picks) called in both registerAsOG() and
registerAsWeeklyOG(). OG cannot register without valid 6-pick bitmask.
Prevents zero-pick phantom OG registrations.

### FIX-10: Phase start timestamp for emergency reset timing

phaseStartTimestamp state variable added. Set at start of each draw phase
(MATCHING, DISTRIBUTING, FINALIZING). emergencyResetDraw() timeout now
measured from phase start, not last draw. More accurate stuck detection.

### FIX-11: Signup refund revokes OG status (phantom OG exploit)

claimSignupRefund() now sets isUpfrontOG = false, clears picks, decrements
upfrontOGCount. Prevents a refunded player from retaining OG status and
claiming endgame on a zero-cost basis.

### FIX-12: Dormancy refund simplified: current-draw refund only

Non-OG dormancy refund logic simplified. Only the current unresolved draw
payment is returned. Prior draws: paid and played, nothing owed. Uses
lastTicketCount (FIX-15) for accurate refund amount.

### FIX-13: registerAsWeeklyOG sets lastBoughtDraw to prevent instant revocation

p.lastBoughtDraw = currentDraw set during weekly OG registration. Prevents
the registration draw from immediately triggering status-lost logic in
processMatches() on the same draw.

### FIX-14: registerAsWeeklyOG requires payment (no free first draw)

2-ticket payment taken at registration time. No free draw on sign-up.
cost = price * MIN_TICKETS_WEEKLY_OG. Funds split to treasury + prizePot
same as regular buyTickets(). Supersedes earlier design where first draw
was unpaid.

### FIX-15: lastTicketCount stored for accurate dormancy refund

p.lastTicketCount field added to PlayerData. Set in buyTickets() and
registerAsWeeklyOG(). Used by claimDormancyRefund() to return the exact
amount paid for the unresolved draw rather than assuming 1 ticket.

### FIX-16: Stale feeds guard: revert if fewer than 6 valid price feeds

After calculating performance for all 42 assets, count valid feeds
(performance[i] > type(int256).min). If fewer than NUM_PICKS (6) valid,
revert NotEnoughValidPrices(). Prevents draw resolving on degraded oracle
data that would produce a meaningless winning mask.

### FIX-17: _applyTreasuryCap: remove internal prizePot double-count (CRITICAL)

Pre-fix: _applyTreasuryCap() was adding excess directly to prizePot internally,
then the caller also added the full cost to prizePot. Result: excess double-counted.
Fixed: _applyTreasuryCap() returns the capped amount only. Caller does
prizePot += cost - cappedAmount. No internal modification of prizePot.
TreasuryCapped event emitted for excess.

### FIX-18: totalPaid uses += not = in registerAsOG and registerAsWeeklyOG

Pre-fix: p.totalPaid = OG_UPFRONT_COST overwrote any prior payments.
Player who registered first then upgraded to OG lost prior payment tracking.
Fixed: p.totalPaid += cost in both registration functions. Preserves
full payment history for dormancy refund calculation.

### FIX-19: gameSettled flag prevents double-close with zero qualified OGs

gameSettled bool added. Set true in closeGame() and closeDormantGame().
Both functions revert GameAlreadyClosed() if already settled. Prevents
a second closeGame() call when qualifiedOGs = 0 (charityShare = prizePot path)
from resetting endgame accounting on an already-distributed pot.

### State after v1.5

Lines: ~1,663 (unchanged structure from v1.4).
Fixes applied: FIX-04 through FIX-19 (16 fixes).
OG caps: UPFRONT=26%, TOTAL=33% (restructured in V16-01).
Prize BPS: JP=3600, M5=2200, M4=1500, M3=1000, M2=700, SEED=1000.
Treasury: INHALE_1=1100, INHALE_2=1500, EXHALE=2000.
INHALE_PRIZE_RATE_BPS=100, EXHALE_START=100, EXHALE_END=200.

---

## [3Y v1.6]: Major Economics Redesign (V16 Series)

### Summary

Eleven changes restructuring OG caps, prize tier BPS, JP miss behaviour,
auto-breathe v1, and the OG obligation lock. This is the version that
introduced the core mechanics the 1Y inherits.

### V16-01: OG caps reduced

UPFRONT_OG_CAP_BPS: 26% to 10%. TOTAL_OG_CAP_BPS: 33% to 18%.
First-come-first-served. Hard cap enforced.

### V16-02: Inhale prize rate reduced

INHALE_PRIZE_RATE_BPS: 1.00% to 0.77%. EXHALE ramp: 0.77% to 2.00%.

### V16-03: Config D BPS

| Tier | Old | New |
|------|-----|-----|
| JP   | 3600 | 2500 |
| M5   | 2200 | 2400 |
| M4   | 1500 | 1700 |
| M3   | 1000 | 1300 |
| M2   | 700  | 1100 |
| Seed | 1000 | 1000 |

### V16-04: JP miss: accumulator removed

No cross-draw JP accumulation. 50% of missed JP redistributed to M2-5
proportionally, 50% to seed.

### V16-05: OG obligation locked at draw 26

ogEndgameObligation locked at start of draw 26. Strategy C offset trajectory.
requiredEndPot = obligation * 10000 / 9000 (90% endgame split).

### V16-06: Auto-breathe v1

Closed-loop controller adjusting breathMultiplier every draw from draw 27.
Range: 50% floor to 250% ceiling. BREATH_STEP_UP = 500, BREATH_STEP_DOWN = 1000.
BREATH_COOLDOWN_DRAWS = 3.

### V16-07 through V16-11

Treasury no on-chain reserve. getProjectedEndgamePerOG() view. Payment required
at registerAsWeeklyOG(). prizeRateMultiplier bytes32 reason on-chain. Three
NatSpec audit notes.

---

## [3Y v1.8]: Auto-Breathe Accuracy + Obligation Lock Timing

### Summary

Ten targeted fixes. Full second-pass security audit post-v1.8: 3C 4M 7L 3I.
All critical findings fixed before 1Y fork.

Key fixes: yield captured each draw in resolveWeek(); descending trajectory for
auto-breathe; getProjectedEndgamePerOG underflow and denominator fixes; atomic
feed validation + snapshot (single loop); obligation lock moved AFTER prize pool
deduction (EC3 fix); free draw mechanism removed.

### [3Y v1.8: Second-Pass Audit]

Five architectural elements cited as having no DeFi equivalent:
- Auto-breathe closed-loop controller (PID-adjacent, 60 lines of Solidity)
- Obligation lock timing after prize deduction (non-obvious, self-corrected)
- Assembly O(1) array resets
- Signed int performance sentinel (type(int256).min for dead feeds)
- Future timestamp guard on Chainlink data

All three critical findings (C-01 try/catch, C-02 immutable CHARITY, C-03 pregame
yield orphan) resolved before 1Y fork.

---

## [3Y v16(9) - v16(40)]: Final 3Y Hardening Series

Approximately 31 further versions. 13 audit passes completed on 3Y lineage
before 1Y fork. Contract size: 111KB. All S2-FIX, V16, and v1.8 findings
resolved. Forked to produce 1Y v1.0.0.

---

---

# PART 2, 1Y CONTRACT LINEAGE

## 1Y Version Index

| Version | Headline |
|---------|----------|
| v1.0.0 | Fork from 3Y v16(40). 1Y constants applied. |
| v1.0.1 | Compile fix + treasury branch fix |
| v1.0.2 | Stale comment sweep |
| v1.0.3 | Reset refund mechanism introduced |
| v1.0.4-v1.0.9 | Reset refund hardening (11 findings) |
| v1.1.0 | Final audit pass. 0 C/H/M |
| v1.1.1 | CEI fix on sweepResetRefundRemainder |
| v1.1.2 | Slot-squatting mitigation. ACTIVE prepay system |
| v1.1.3 | Prepay system security audit. 2C 2H 2M 3L 2I |
| v1.1.4 | 2 Critical 1 High in OG prepay differentiation |
| v1.1.5 | Cap integrity. register to registerAsWeeklyOG orphan |
| v1.1.6 | Treasury integrity. credit draws zero-treasury bug |
| v1.1.7 | False-decrement hardening. usedStandardRegistrationActive |
| v1.1.8 | External audit. M-1 M-2 L-1 |
| v1.1.9 | External audit. M-NEW-01 L-NEW-01/02 INFO-01/02/03 |
| v1.1.10 | LOW-1 register() missing nonReentrant |
| v1.1.11 | INFO-1 NatSpec reentrancy list updated |
| v1.1.12 | INFO-1 renounceOwnership string to custom error |
| v1.1.13 | INFO-1 dead error removed, INFO-2 NatSpec fix |
| v1.1.14 | Prize tier redesign. M2 removed, BPS redistributed |
| v1.1.15-v1.1.16 | BPS surgery, breath rails, 111% target, endgame cap |
| v2.0 | First deployment candidate. economics locked |
| v2.01 | Patch. 4 code fixes, 4 doc fixes |
| v2.1 | Feature. one-in-one-out non-OG slot management |
| v2.2 | Triple audit remediation pass 1. 13 fixes (3C 4H 5M 1L) |
| v2.3 | RESET_REFUND_WINDOW 90 to 30 days |
| v2.31 | Self-audit: commitmentRefundPool deadline + solvency gap (3 fixes) |
| v2.32 | DrawPhase.RESET_FINALIZING (OZ-H-01) |
| v2.33 | lastDrawHadJPMiss early-return bug fix (BUG-A) |
| v2.34 | activateDormancy() 24-hour timelock (OZ-M-06) |
| v2.35 | NEW-C-01: commitment flag gate in buyTickets() |
| v2.36 | NEW-H-02: JP miss flag consumption redesign |
| v2.37 | NEW-H-03 + NEW-H-01: Full CEI compliance (3 functions) |
| v2.38 | NEW-M-03 + M-01 + M-02: dormancy breath cancel, totalPaid, sweep event |
| v2.39 | V2.38-M-01 + L-01: breath cooldown restart + draw-52 flag clear |
| v2.40 | CYFRIN-C-01: dead exhale premium branch removed |
| v2.41 | OZ-H-03: ownership transfer 7-day expiry window |
| v2.42 | CYFRIN-H-04 + OZ-M-07: weekly OG dormancy state cleanup |
| v2.43 | KO-H-01: mulligan streak rollback |
| v2.44 | KO-M-01: lastDrawHadJPMiss pre-lock gate |
| v2.45 | KO-M-03 + KO-L-02: commitment dormancy path + emit fix |
| v2.46 | OZ-H-04 + KO-M-04 anchor + N2.45-L-01 |
| v2.47 | OZ-M-02 + NEW-M-05: dormancy endgame settlement + commitment carve order |
| v2.48 | v2.47-L-01 retracted, no material change |
| v2.49 | CYFRIN-H-02: two-slot reset refund pool + 4 knock-on solvency fixes |
| v2.50 | Pre-lock breathing (draws 1-9) + call site fix + aaveEmergency pool-2 |
| v2.51 | ogListIndex O(1) surgery + pruneStaleOGs (CYFRIN-M-01 + M-02) |
| v2.52 | Full Cyfrin-style audit: 17 findings (1C 1H 2M 4L 5I), no fixes applied |
| v2.53 | Cyfrin audit remediation: 8 findings fixed |
| v2.54 | Treasury lock fix + commitment counter fix |
| v2.55 | batchMarkLapsed cap + pruneStaleOGs full clear + dormancy redundant set removed |
| v2.56 | Full NatSpec pass. 225 tags across 61 functions. No logic changes. |
| v2.57-v2.65 | Session gap. Source in archive. See note below. |
| v2.66 | Phase 1: two-track OG concentration system + v2.66-I-02 + v2.66-L-01 NatSpec |

---

## [v1.0.0]: Fork from 3Y v16(40)

Crypto42 1Y forked from 3Y v16(40). Duration constants changed: GAME_DURATION 156 to 52,
TICKET_PRICE $5 to $10, OG_UPFRONT_COST $780 to $1,040. All 13 3Y audit passes inherited
clean. BREATH-OVERRIDE mechanism, auto-breathe, eager-unwind, AAVE-EMERGENCY-OBLIGATION fix
all present from fork.

---

## [v1.0.1]: Compile Fix + Treasury Branch Fix

Residual 3Y game duration constant causing compile failure corrected. Treasury branch
conditional referencing wrong game duration sentinel corrected to GAME_DURATION = 52.

---

## [v1.0.2]: Stale Comment Sweep

All 3Y-specific figures (156 draws, $780 OG cost, 3-year references) in inline comments
and NatSpec updated or removed. No logic changes.

---

## [v1.0.3]: Reset Refund Mechanism

New player protection if emergencyResetDraw() fires: per-draw claimable refund pool.
Added: resetRefundPool[draw], claimResetRefund(), sweepResetRefundRemainder(),
RESET_REFUND_WINDOW = 90 days, ResetRefundClaimed, ResetRefundExpiredSwept events.

---

## [v1.0.4 - v1.0.9]: Reset Refund Hardening (11 findings)

Six-version sprint. 11 findings resolved including: duplicate transfer CEI fix,
CLOSED phase drain blocked, ownership check on sweep, race condition timelock fix,
plus 7 pool accounting, NatSpec, and event fixes.

---

## [v1.1.0]: Final Audit Pass: 0 C/H/M

All v1.0.3-v1.0.9 findings confirmed resolved. Contract declared audit-ready.

---

## [v1.1.1]: CEI Fix on sweepResetRefundRemainder

Pool storage zeroed before _withdrawAndTransfer() call. Pattern correction.

---

## [v1.1.2]: Slot-Squatting Mitigation: ACTIVE Prepay System

ACTIVE phase registrants must prepay 4 weeks upfront. Added: PREPAY_WEEKS = 4,
OG_PREPAY_AMOUNT, topUpCredit(), prepaidCredit in PlayerData, credit consumption in
buyTickets(), CreditToppedUp, CreditConsumed events, claimUnusedCredit(),
getCreditBalance() view.

---

## [v1.1.3]: Prepay System Security Audit: 2C 2H 2M 3L 2I

Nine findings. C-01: credit treasury routing zero. C-02: register-to-OG credit not
rerouted. H-01: activeRegistrationCount slot reservation. H-02: register-to-weeklyOG
orphan. M-01: totalPrepaidCredit not tracked. M-02: getSolvencyStatus credit blind.
All resolved. totalPrepaidCredit global tracking introduced.

---

## [v1.1.4]: OG Prepay Differentiation: 2C 1H

C-01: duplicate transfer in registerAsOG(). C-02: claimSignupRefund credit gate.
H-01: claimDormancyRefund missing ACTIVE branch. OG_PREPAY_AMOUNT formula corrected
to use MIN_TICKETS_WEEKLY_OG.

---

## [v1.1.5]: Cap Integrity

H-01: register-to-weeklyOG activeRegistrationCount orphan. M-01: refund paths
also orphan counter. Fixed in claimSignupRefund() and sweepFailedPregame().

---

## [v1.1.6]: Treasury Integrity: Credit Draws Zero-Treasury Bug

C-01: OG upgrade path zero-treasury on credit draws. H-02: register-to-OG
activeRegistrationCount orphan. L-03: stranded credit treasury rate fix.

---

## [v1.1.7]: False-Decrement Hardening: usedStandardRegistrationActive Flag

C-02: usedStandardRegistrationActive boolean introduced. Only register() in ACTIVE
sets it true. All decrement sites guarded. False decrements structurally impossible.
M-02: buyTickets() OG path false decrement fixed. L-04: topUpCredit OG flag guard added.

---

## [v1.1.8]: External Audit: M-1 M-2 L-1

M-1: priorTicketCost not captured before modification. M-2: isFirstBuy guard missing
in credit draw path. L-1: activateAaveEmergency totalPrepaidCredit missing.

---

## [v1.1.9]: External Audit: M-NEW-01 L-NEW-01/02 INFO-01/02/03

M-NEW-01: register() ACTIVE cap missing totalLifetimeBuyers. L-NEW-01: sweepFailedPregame
credit not cleared. L-NEW-02: topUpCredit cap uses wrong base. INFO-01/02/03: NatSpec gaps.

---

## [v1.1.10 - v1.1.13]: Minor Hardening

v1.1.10: register() missing nonReentrant added. v1.1.11: NatSpec reentrancy list updated.
v1.1.12: renounceOwnership string literal to custom error RenounceOwnershipDisabled.
v1.1.13: PrepayRequired dead error removed. registerInterest() NatSpec position restored.

---

## [v1.1.14]: Prize Tier Redesign: M2 Removal

M2 prize tier removed entirely (~3,187 winners/draw at sub-$1 per winner, below gas cost).
BPS redistributed: JP 2500 to 3300, M5 2400 to 2600, M4 1700 to 1900, M3 1300 to 1200.
M25_TOTAL_BPS updated to 5700. JP miss redistribution changed 50/50 to 30/70 tiers/seed.
getWinnerCounts() ABI change: 5-tuple to 4-tuple.

---

## [v1.1.15 - v1.1.16]: BPS Surgery, Breath Rails, 111% Target, Endgame Cap

Four changes: JP_BPS +40 to 3340, M5_BPS -40 to 2560 (JP per-winner always beats M5).
JP miss split constants (JP_MISS_M5_BPS=3000, JP_MISS_M4_BPS=3300, M3 remainder ~37%).
INHALE_PRIZE_RATE_BPS and EXHALE_START_RATE_BPS: 77 to 150 BPS.
Breathing target: 100% to 111% OG return. Breath rails architecture introduced
(ABSOLUTE_BREATH_FLOOR=2000, ABSOLUTE_BREATH_CEILING=100000, mutable breathRailMin/Max,
setBreathRails()). closeGame() 111% cap + proportional fallback.

Three knock-on findings (C-01 ogDust double-count, M-01 silent clamp, M-02 stale
pending override) fixed in v2.0.

---

## [v2.0]: First Deployment Candidate: Economics Locked

All knock-on findings from v1.1.16 fixed (C-01, M-01, M-02, L-01).
Economics locked. Tier BPS: JP=3340, M5=2560, M4=1900, M3=1200.
JP miss: 30% tiers, 70% seed. Prize rates 150 BPS inhale/exhale-start.
111% OG target. Breath rails ABSOLUTE_FLOOR=2000, ABSOLUTE_CEILING=100000.
closeGame() cap: OG_UPFRONT_COST * 111 / 100 = $1,154.40.

---

## [v2.01]: Patch Release

M-1: cap checks used stale earnedOGCount, replaced with weeklyOGCount (active count).
L-5: totalPrepaidCredit missing from dormancy branch of activateAaveEmergency().
L-1: require() strings in setBreathRails replaced with custom errors.
Four documentation fixes (partial distribution RUNBOOK, double-reset limitation RUNBOOK,
setBreathRails multi-phase NatSpec, clamp cooldown NatSpec).

---

## [v2.1]: Feature Release: One-In-One-Out Non-OG Slot Management

Non-OG lapsed players free their cap slot. New state: isLapsed bool in PlayerData,
lapsedPlayerCount contract-level. New functions: markLapsed() onlyOwner, batchMarkLapsed().
Cap check updated: (totalLifetimeBuyers - lapsedPlayerCount) + activeRegistrationCount
+ OG counts. Auto-unlapse on buyTickets() return. Emergency reset interaction handled
in _continueUnwind(). PlayerLapsed, PlayerUnlapsed events.

---

## [v2.2]: Triple Audit Remediation Pass 1 (13 fixes)

| Fix | ID | Severity |
|-----|-----|---------|
| 1 | CROSS-EC-02 | HIGH: auto-cancel stranded override on rail tighten |
| 2 | CYFRIN-H-01 | HIGH: cancel pending override on emergency reset |
| 3 | CROSS-EC-04 | MEDIUM: JP miss breath overcorrection guard (lastDrawHadJPMiss) |
| 4 | CYFRIN-H-03 | HIGH: block withdrawTreasury() post-settlement |
| 5 | CYFRIN-M-03 | MEDIUM: clear weeklyNonOGPlayers in emergency reset assembly |
| 6 | CYFRIN-M-06 | MEDIUM: payCommitment() rejects calls after signupDeadline |
| 7 | CYFRIN-M-07 | MEDIUM: remove duplicate obligation lock from finalizeWeek() |
| 8 | OZ-H-02/M-01 | HIGH: revoke unlimited USDC approval on both Aave exit paths |
| 9 | CYFRIN-L-06 | LOW: getProjectedEndgamePerOG() returns 10000 not max uint256 |
| 10 | CROSS-EC-05 | CRITICAL: draw-1 reset commitment credit protection (up to $25K) |
| 11 | CYFRIN-M-05 | MEDIUM: scheduleAnchor rebased after emergency reset |
| 12 | CYFRIN-C-02 | CRITICAL: buyTickets() cap includes activeRegistrationCount |
| 13 | OZ-C-01 | CRITICAL: full CEI refactor on register(), registerAsOG(), registerAsWeeklyOG() |

New: commitmentRefundPool, commitmentRefundDraw state. claimCommitmentRefund() function.
CommitmentRefundActivated, CommitmentRefundClaimed events.

---

## [v2.3]: RESET_REFUND_WINDOW 90 to 30 Days

CYFRIN-H-02 partial mitigation. Window reduced from 90 to 30 days: shrinks double-reset
collision window 3x, returns unclaimed funds to protocol 60 days earlier.

---

## [v2.31]: Self-Audit: commitmentRefundPool Deadline + Solvency Gap (3 fixes)

SELF-01-A: commitmentRefundPool had no expiry. commitmentRefundDeadline state var added.
Deadline set at pool creation. Deadline check in claimCommitmentRefund().
SELF-01-B: sweepResetRefundRemainder() did not sweep commitmentRefundPool. Rebuilt with
dual-pool logic. Both pools swept independently.
SELF-01-C: commitmentRefundPool missing from all 6 solvency accounting locations.
Added to: dormancy sweep, Aave emergency (both branches), getSolvencyStatus,
_captureYield, _solvencyCheck.

---

## [v2.32]: DrawPhase.RESET_FINALIZING (OZ-H-01)

New enum value RESET_FINALIZING distinguishes post-reset finalization from normal
post-distribution finalization. emergencyResetDraw() and _continueUnwind() route to
RESET_FINALIZING. finalizeWeek() accepts both phases. scheduleAnchor rebase uses
isResetFinalize flag. Stuck-game guard updated to include RESET_FINALIZING.
DrawPhase enum values: IDLE=0, MATCHING=1, DISTRIBUTING=2, FINALIZING=3,
RESET_FINALIZING=4, UNWINDING=5.

---

## [v2.33]: BUG-A: lastDrawHadJPMiss Early-Return Bug

Flag only cleared inside (prizePot > targetNow) branch. Three paths left flag
permanently set: cooldown early return, pre-lock early return, pot == target exactly.
Fix: clear moved to very first line of _checkAutoAdjust(), before any early returns.

---

## [v2.34]: OZ-M-06: proposeDormancy / cancelDormancy 24-Hour Timelock

activateDormancy() was a single irreversible owner call with no warning.
New: DORMANCY_TIMELOCK = 24 hours, dormancyEffectiveTime state var,
proposeDormancy() and cancelDormancy() functions, DormancyProposed and
DormancyCancelled events. activateDormancy() gated on timelock elapsed.

---

## [v2.35]: NEW-C-01: Commitment Flag Gate in buyTickets()

commitmentPaid nullification (currentDraw > 1) made conditional on
commitmentRefundPool == 0. When an active draw-1 reset commitment pool exists,
the flag is preserved until the player claims or the pool is swept.

---

## [v2.36]: NEW-H-02: JP Miss Flag Consumption Redesign

v2.33 approach wrong: clearing at top consumed flag before suppression could run.
Fix: flag consumed only inside the UP-eligible branch. Cooldown returns and DOWN
paths leave flag intact. Oscillation eliminated correctly.

---

## [v2.37]: NEW-H-03 + NEW-H-01: Full CEI Compliance

Three functions restructured to strict Checks-Effects-Interactions:
registerAsWeeklyOG(): lastBoughtDraw, ogList, weeklyOGCount, earnedOGCount all
written before external calls. payCommitment() and buyTickets(): full compute-then-
state-then-external restructure. All accounting before transfer.

---

## [v2.38]: NEW-M-03 + M-01 + M-02

NEW-M-03: proposeDormancy() auto-cancels pending breath override.
NEW-M-01: claimCommitmentRefund() zeros p.totalPaid after refund.
NEW-M-02: dedicated CommitmentRefundExpiredSwept event for commitment pool sweep.

---

## [v2.39]: V2.38-M-01 + L-01

V2.38-M-01: lastBreathAdjustDraw = currentDraw written on JP miss suppression
(fresh cooldown from suppression draw prevents next-draw oscillation).
V2.38-L-01: lastDrawHadJPMiss cleared in finalizeWeek() on draw 52 close.

---

## [v2.40]: CYFRIN-C-01: Dead Exhale Premium Branch Removed

MAX_TICKETS_PER_WEEK == MIN_TICKETS_WEEKLY_OG == 2. Branch
isExhale && isActiveWeeklyOG && ticketCount > MIN_TICKETS_WEEKLY_OG permanently
unreachable. Removed. Cost calculation simplified to two branches.

---

## [v2.41]: OZ-H-03: Ownership Transfer 7-Day Expiry

OWNERSHIP_TRANSFER_EXPIRY = 7 days. ownershipTransferExpiry state var.
transferOwnership() override sets expiry. acceptOwnership() override reverts with
dedicated OwnershipTransferExpired error if window elapsed.

---

## [v2.42]: CYFRIN-H-04 + OZ-M-07: Weekly OG Dormancy State Cleanup

claimDormancyRefund() calls _cleanupOGOnRefund() for weekly OGs: clears isWeeklyOG,
removes from ogList, decrements weeklyOGCount. Prevents double-payment via
claimEndgame() post-dormancy. Prevents inflated _countQualifiedOGs() denominator.

---

## [v2.43]: KO-H-01: Mulligan Streak Rollback

_continueUnwind() mulligan reversal was not rolling back consecutiveWeeks or
lastActiveWeek. On re-run of _updateStreakTracking(), early return prevented streak
rebuild. Fix: p.consecutiveWeeks-- and p.lastActiveWeek recalculated in mulligan
rollback block.

---

## [v2.44]: KO-M-01: lastDrawHadJPMiss Pre-Lock Gate

Flag set unconditionally on JP miss including draws 1-9. Flag sat stale until draw 11,
then wrongly suppressed first post-lock UP adjustment. Fix: flag only set when
obligationLocked is true.

---

## [v2.45]: KO-M-03 + KO-L-02

KO-M-03: claimDormancyRefund() commitmentPaid branch guard changed from
currentDraw == 1 to commitmentRefundPool == 0. Draw-1 reset increments currentDraw
to 2, permanently blocking the original guard. Fix allows dormancy refund path for
committed players whenever commitment pool is not active.
KO-L-02: commitmentRefundDraw saved before zeroing in sweepResetRefundRemainder().
Event now emits actual draw number not hardcoded 1.

---

## [v2.46]: OZ-H-04 + KO-M-04 Anchor + N2.45-L-01

OZ-H-04: earnedOGCount never decremented on weekly OG status loss. At draw 10
obligation lock read inflated earnedOGCount, biasing auto-breathe DOWN for entire
post-lock game. Fix: earnedOGCount-- in status-loss block. _continueUnwind() gets
complementary earnedOGCount++ for mulligan restore.
KO-M-04: anchor comment confirming intentional absence of double-count bug line.
N2.45-L-01: OwnershipTransferExpired dedicated error replaces semantically inverted TooEarly.

---

## [v2.47]: OZ-M-02 + NEW-M-05

OZ-M-02 part 1: sweepDormancyRemainder() sets gameSettled = true and
settlementTimestamp after distribution. Prevents double-sweep.
OZ-M-02 part 2: claimEndgame() guard added blocking upfront OGs post-dormancy
(their entitlement is in dormancyOGPool, not endgamePerOG).
NEW-M-05: commitment pool carve in emergencyResetDraw() moved to standalone
if block, independent of ticket-refund else-if. Draw-1 resets with no ticket
buyers now correctly create the commitment pool.

---

## [v2.48]: v2.47-L-01 Retracted

Finding alleged double-fire risk on commitment carve. On review: currentDraw == 1
guard and WrongPhase guard on emergencyResetDraw() already prevent this.
Finding retracted. No material change.

---

## [v2.49]: CYFRIN-H-02: Two-Slot Reset Refund Pool + 4 Knock-On Fixes

Core: second pool slot (resetDrawRefundPool2, resetDrawRefundDraw2,
resetDrawRefundDeadline2) for sequential resets within 30-day window.
emergencyResetDraw() fills pool-1 first, pool-2 on overflow (emits ResetRefundOverflow).
claimResetRefund() routes to matching pool. sweepResetRefundRemainder() sweeps both.
Knock-ons: buyTickets() pool-2 lastResetBoughtDraw check. getSolvencyStatus(),
executeAaveExit()/activateAaveEmergency(), _solvencyCheck() all updated with pool-2.

---

## [v2.50]: Pre-Lock Breathing (Draws 1-9) + Call Site Fix + aaveEmergency Pool-2

FIX-V50-01: Pre-lock breathing draws 1-9 DOWN only. Proxy obligation
(enrolledOGs x OG_UPFRONT_COST) used as conservative ceiling. DOWN fires if pot <
90% of proxy. Never breathes UP pre-lock. Critical bug fixed: _calculatePrizePools()
outer guard was if (obligationLocked), blocking all pre-lock calls. Changed to
if (currentDraw < TOTAL_DRAWS). Validated: Monte Carlo 6 scenarios, floor 0.75
never triggered, solvent in all cases.
FIX-V50-02: activateAaveEmergency() missing resetDrawRefundPool2 in both obligation
branches. Added.

---

---

---

## v2.51: ogListIndex surgery + pruneStaleOGs + v2.50-H-01
**March 2026 | ~3,470 lines | 3 fixes**

**Rule: never change code beyond what is agreed. If anything looks wrong, ask first.**

---

### v2.51 Fix Index

| Fix | Audit ID | Severity | Description |
|-----|----------|----------|-------------|
| 1 | M-02 | MEDIUM | O(n) OG cleanup: ogListIndex mapping + O(1) swap-and-pop |
| 2 | M-01 | MEDIUM (mitigated) | ogList unbounded growth: pruneStaleOGs(uint256 maxPrune) added |
| 3 | v2.50-H-01 | HIGH | _captureYield() missing resetDrawRefundPool2 in totalAllocated |

---

### FIX-V51-01: M-02: O(1) OG List Cleanup via ogListIndex Mapping

**Location:** `_cleanupOGOnRefund()`, all OG removal sites, state variables
**Audit Finding:** M-02 (MEDIUM)

**Problem:**
Every OG removal site (dormancy cleanup, status loss) required a linear scan of
`ogList` to find the player's index. At max OG cap (~5,500 OGs), each removal was
O(n) = up to 5,500 iterations. `_cleanupOGOnRefund()` called during dormancy could
iterate the full list for every claiming OG in sequence. Gas cost grew unbounded with
player count, with no gas limit defence.

**Fix:** Introduced `ogListIndex` mapping:
```solidity
mapping(address => uint256) private ogListIndex;
```

Set on OG registration (both upfront and weekly):
```solidity
ogListIndex[msg.sender] = ogList.length; // index before push
ogList.push(msg.sender);
```

O(1) swap-and-pop in all removal sites:
```solidity
uint256 idx = ogListIndex[addr];
uint256 last = ogList.length - 1;
if (idx != last) {
    address lastAddr = ogList[last];
    ogList[idx] = lastAddr;
    ogListIndex[lastAddr] = idx;
}
ogList.pop();
delete ogListIndex[addr];
```

**Affected removal sites:** `_cleanupOGOnRefund()`, `processMatches()` status-loss block,
any `emergencyResetDraw()` path that modifies `ogList`.

**Result:** All OG removals are now O(1) regardless of `ogList` length.
Gas cost per removal is constant at ~3 SSTORE operations.

**Invariant maintained:** `ogList` always contains the same set of addresses as before.
Order within the array is not guaranteed (intentional, order is irrelevant to protocol logic).

---

### FIX-V51-02: M-01: pruneStaleOGs(uint256 maxPrune) Bounded Batch Function

**Location:** New function `pruneStaleOGs()`
**Audit Finding:** M-01 (MEDIUM, mitigated)

**Problem:**
`ogList` is append-only for active OGs. Weekly OGs who lose status remain in the list
with `isWeeklyOG = false`. Over a 52-draw game, the list can accumulate stale entries.
Although individual removal is now O(1) via FIX-V51-01, the list itself was unbounded
with no mechanism for the owner to trim dead entries and reclaim storage.

**Fix:** New owner-callable function:
```solidity
function pruneStaleOGs(uint256 maxPrune) external onlyOwner {
    if (gamePhase != GamePhase.ACTIVE) revert WrongPhase();
    if (drawPhase != DrawPhase.IDLE) revert WrongPhase();
    uint256 pruned = 0;
    uint256 i = 0;
    while (i < ogList.length && pruned < maxPrune) {
        address addr = ogList[i];
        PlayerData storage p = players[addr];
        if (!p.isUpfrontOG && (!p.isWeeklyOG || p.weeklyOGStatusLost)) {
            uint256 last = ogList.length - 1;
            if (i != last) {
                address lastAddr = ogList[last];
                ogList[i] = lastAddr;
                ogListIndex[lastAddr] = i;
            }
            ogList.pop();
            delete ogListIndex[addr];
            p.isWeeklyOG = false;
            p.picks = 0;
            pruned++;
        } else {
            i++;
        }
    }
    emit OGsPruned(pruned);
}
```

`maxPrune` is a caller-supplied gas cap. Keeper can call in batches of e.g. 100 per
IDLE window. Each pass is safe to call multiple times until `ogList` is clean.

**Guard: ACTIVE + IDLE only.** Cannot prune mid-draw, cannot prune post-game.

**Design note:** M-01 is mitigated, not fully resolved. `ogList` can still grow
to the OG cap before the first prune opportunity. The prune mechanism provides ongoing
maintenance, not a structural cap on the list. Full resolution would require refactoring
`ogList` to a doubly-linked structure, which was out of scope for this audit cycle.

**New event:**
```solidity
event OGsPruned(uint256 count);
```

---

### FIX-V51-03: v2.50-H-01: _captureYield() Missing resetDrawRefundPool2 in totalAllocated

**Location:** `_captureYield()`
**Found by:** Fresh-scope audit of v2.50 output
**Severity:** HIGH (same class as v2.49/v2.50 knock-on pool-2 findings)

**Problem:**
`_captureYield()` computes `totalAllocated` to determine how much of the aUSDC balance
belongs to `prizePot` versus other obligations. The v2.49 fixes correctly added
`resetDrawRefundPool2` to `getSolvencyStatus()`, `_solvencyCheck()`, and
`activateAaveEmergency()`. But `_captureYield()` was missed in that pass.

If pool-2 held funds, `_captureYield()` would overstate `prizePot` by exactly
`resetDrawRefundPool2`. Every subsequent solvency check and auto-breathe calculation
would run on an inflated `prizePot`, potentially triggering premature UP adjustments
and masking a true solvency deficit.

**Fix:**
```solidity
// Before:
uint256 totalAllocated = treasuryBalance
    + totalUnclaimedPrizes
    + resetDrawRefundPool
    + commitmentRefundPool
    + totalPrepaidCredit;

// After:
uint256 totalAllocated = treasuryBalance
    + totalUnclaimedPrizes
    + resetDrawRefundPool
    + resetDrawRefundPool2      // [v2.51 v2.50-H-01]
    + commitmentRefundPool
    + totalPrepaidCredit;
```

---

---

## v2.52: v2.51-L-01 + v2.51-M-01: pruneStaleOGs IDLE guard + dual-reset documented limit
**March 2026 | ~3,490 lines | 1 code fix + 1 documented limit**

**Rule: never change code beyond what is agreed. If anything looks wrong, ask first.**

---

### FIX-V52-01: v2.51-L-01: pruneStaleOGs() Missing IDLE DrawPhase Guard

**Location:** `pruneStaleOGs()`
**Found by:** Self-audit of v2.51 pruneStaleOGs() introduction
**Severity:** LOW

**Problem:**
`pruneStaleOGs()` checked `gamePhase != GamePhase.ACTIVE` but did NOT check
`drawPhase != DrawPhase.IDLE`. If called during MATCHING or DISTRIBUTING, the
function would modify `ogList` and `ogListIndex` while `processMatches()` or
`distributePrizes()` was mid-execution, potentially corrupting the iteration order
of the OG list or causing a double-removal if a status-loss was in flight.

**Fix:**
Added explicit `drawPhase` guard at the top of `pruneStaleOGs()`:
```solidity
if (drawPhase != DrawPhase.IDLE) revert WrongPhase();
```

This guard was documented as design intent in v2.51 but was not present in the
implemented code. Now enforced in code, not only in NatSpec.

---

### DOC-V52-01: v2.51-M-01: Dual-Reset Pool-1 Loss Documented as Known Protocol Limit

**Location:** `emergencyResetDraw()`, RUNBOOK comment block
**Found by:** Knock-on audit of v2.49 dual-pool design
**Severity:** MEDIUM (documented and accepted, no code change)

**Problem identified:**
If two emergency resets occur within 30 days AND the first draw had both OG and
non-OG buyers, the following sequence produces a pool-1 accounting discrepancy:

1. Reset draw N. Pool-1 carved. Deadline = now + 30 days.
2. Player from draw N buys in draw N+1.
3. Second reset fires within 30 days. Pool-2 carved for draw N+1.
4. claimResetRefund() routes draw-N player to pool-1. Correct.
5. OG/non-OG pricing differential can leave pool-1 slightly short for last claimant.

**Resolution:** Documented as a known protocol limit. Exposure bounded at ~hundreds of
dollars. Owner compensates from treasury. On-chain events provide complete audit trail.

RUNBOOK comment added to `emergencyResetDraw()`.

---

---

## v2.53: NEW Series. 4 Code Fixes + 3 NatSpec. Zero C/H/M Audit Pass.
**March 2026 | 3,326 lines | 7 changes applied**

**Rule: never change code beyond what is agreed. If anything looks wrong, ask first.**

---

### v2.53 Fix Index

| Fix | Audit ID | Severity | Type | Description |
|-----|----------|----------|------|-------------|
| 1 | NEW-M-01 | MEDIUM | Code | sweepFailedPregame() CEI-compliant auto-sweep treasury |
| 2 | NEW-L-01 | LOW | Code | pruneStaleOGs() clear isWeeklyOG and picks on prune |
| 3 | NEW-L-02 | LOW | Code | batchMarkLapsed() MAX_LAPSE_BATCH = 500 gas cap |
| 4 | NEW-I-04 | INFO | Code | claimDormancyRefund() remove redundant inner dormancyRefunded set (commitment branch) |
| 5 | NEW-I-01 | INFO | NatSpec | sweepFailedPregame() treasury-sweep ordering note |
| 6 | NEW-I-02 | INFO | NatSpec | getPreGameStats() comment placement inside return tuple |
| 7 | NEW-I-03 | INFO | NatSpec | batchMarkLapsed() batch size recommendation |

---

### FIX-V53-01: NEW-M-01: sweepFailedPregame() CEI-Compliant Treasury Auto-Sweep

**Location:** `sweepFailedPregame()`
**Audit Finding:** NEW-M-01 (MEDIUM)

**Problem:** `sweepFailedPregame()` did not sweep `treasuryBalance` before settling.
Trapped treasury balance after `gameSettled = true` with no recovery path.
Also: `gameSettled = true` was set AFTER a `_withdrawAndTransfer()` call, violating CEI.

**Fix:** CEI order corrected. Treasury auto-swept to owner() before charity transfer.
Balance math: `toCharity = usdcBalance - treasurySweep`. No double-count.

---

### FIX-V53-02: NEW-L-01: pruneStaleOGs() Clear isWeeklyOG and Picks on Prune

**Location:** `pruneStaleOGs()`
**Audit Finding:** NEW-L-01 (LOW)

**Problem:** Prune removed from ogList and ogListIndex but left `p.isWeeklyOG` and
`p.picks` set on the PlayerData. Stale flags mislead off-chain tools.

**Fix:** Two lines added in prune block: `p.isWeeklyOG = false; p.picks = 0;`

---

### FIX-V53-03: NEW-L-02: batchMarkLapsed() MAX_LAPSE_BATCH = 500 Gas Cap

**Location:** `batchMarkLapsed()`
**Audit Finding:** NEW-L-02 (LOW)

**Problem:** No cap on input array length. Misconfigured keeper could pass arbitrary
length array, exceeding block gas limit.

**Fix:** `uint256 public constant MAX_LAPSE_BATCH = 500;` with guard in function.
Gas math: 500 x ~25,000 gas = 12.5M gas. Well within Base's 125M block limit.

---

### FIX-V53-04: NEW-I-04: Remove Redundant Inner dormancyRefunded Set (Commitment Branch)

**Location:** `claimDormancyRefund()`, commitment branch

Inner `p.dormancyRefunded = true` removed from commitment branch. Unconditional set at
function end covers both paths. Identical pattern in prepaidCredit branch missed in
this pass (tracked as v2.53-I-01, resolved in v2.55).

---

### v2.53 Fresh Triple-Pass Audit: Results

**Result:** Zero critical, high, or medium findings.

| Severity | Count | Status |
|---------|-------|--------|
| CRITICAL | 0 | — |
| HIGH | 0 | — |
| MEDIUM | 0 | — |
| LOW | 1 | OPEN (v2.53-L-01, resolved v2.55) |
| INFO | 2 | OPEN (v2.53-I-01 resolved v2.55, v2.53-I-02 resolved v2.56) |

---

---

## v2.54: Treasury Lock Fix + Commitment Counter Fix
**March 2026 | 2,915 lines | 2 code fixes**

**Rule: never change code beyond what is agreed. If anything looks wrong, ask first.**

---

### FIX-V54-01: sweepFailedPregame() Treasury Auto-Sweep (CEI)

**Location:** `sweepFailedPregame()`

Treasury auto-sweep applied. CEI order confirmed. `gameSettled = true` and all state
mutations fire before any `_withdrawAndTransfer()` call. Trapped treasury balance
path closed.

---

### FIX-V54-02: claimCommitmentRefund() Missing committedPlayerCount--

**Location:** `claimCommitmentRefund()`

`committedPlayerCount` not decremented on claim. Counter drifted upward. Fix:
`if (committedPlayerCount > 0) committedPlayerCount--;` after `p.commitmentPaid = false`.

---

---

## v2.55: batchMarkLapsed cap + pruneStaleOGs full clear + dormancy redundant set removed
**March 2026 | 2,920 lines | 4 code fixes**

**Rule: never change code beyond what is agreed. If anything looks wrong, ask first.**

---

### v2.55 Fix Index

| Fix | Audit ID | Severity | Description |
|-----|----------|----------|-------------|
| 1 | NEW-L-02 | LOW | MAX_LAPSE_BATCH = 500 constant + batchMarkLapsed() length guard (slipped through in v2.53) |
| 2 | v2.53-L-01 | LOW | pruneStaleOGs() clears weeklyOGStatusLost and statusLostAtDraw on prune |
| 3 | v2.53-I-01 | INFO | claimDormancyRefund() redundant inner dormancyRefunded set removed from prepaidCredit branch |
| 4 | Header | — | Version label updated from v2.54 to v2.55 |

---

### FIX-V55-01: NEW-L-02 (recovered): batchMarkLapsed() MAX_LAPSE_BATCH = 500

Constant and guard documented in v2.53 but not inserted into contract. Recovered and
applied. Gas math: 500 x ~25,000 gas = 12.5M gas. Well within Base's 125M block limit.

---

### FIX-V55-02: v2.53-L-01: pruneStaleOGs() Full State Clear on Prune

v2.53 cleared isWeeklyOG and picks. weeklyOGStatusLost and statusLostAtDraw left stale.
Latent ghost-OG path through re-registration (blocked by streak math in all realistic
scenarios but a lingering invariant violation). Fix: all four fields cleared on prune.

```solidity
p.isWeeklyOG          = false; // [v2.55 v2.53-L-01]
p.picks               = 0;     // [v2.55 v2.53-L-01]
p.weeklyOGStatusLost  = false; // [v2.55 v2.53-L-01]
p.statusLostAtDraw    = 0;     // [v2.55 v2.53-L-01]
```

---

### FIX-V55-03: v2.53-I-01: Remove Redundant dormancyRefunded Set in prepaidCredit Branch

Commitment branch fix applied in v2.53 (FIX-V53-04). Identical pattern in prepaidCredit
branch missed in that pass. Inner set removed here. Idempotent, no security impact.

---

### v2.55 Audit: Zero findings on v2.55 changes.

---

---

## v2.56: Full NatSpec Pass
**March 2026 | 3,315 lines | Documentation only. No logic changes.**

**Rule: never change code beyond what is agreed. If anything looks wrong, ask first.**

---

### v2.56 Summary

Full NatSpec pass across all 61 external and public functions.
Zero logic changes. No new findings introduced.

| Metric | v2.55 | v2.56 |
|--------|-------|-------|
| Lines | 2,920 | 3,315 |
| NatSpec tags | 3 | 225 |
| Functions with NatSpec | 2 | 61 |

Every external and public function now carries @notice, @dev, @param (where applicable),
and @return (where applicable).

**N-5 (markLapsed NatSpec):** markLapsed() documents that lapsing a status-lost weekly OG
does NOT remove them from ogList. Caller should use pruneStaleOGs() separately.

**N-6 (emergencyResetDraw RUNBOOK):** emergencyResetDraw() carries the RUNBOOK note: if a
non-OG player lapses between a reset and the next draw opening, their commitment credit is
not automatically restored and must be handled manually by the owner.

---

---

## v2.57 - v2.65: Session Gap
**March 2026**

> **Note for auditors and grant reviewers:**
> Versions v2.57 through v2.65 were produced across development sessions between
> the v2.56 NatSpec pass and the v2.66 OG concentration system. Full source for
> each version exists in the DYBL Foundation development archive and session
> transcripts. These versions are not individually logged in this changelog due to
> session continuity. The v2.66 entry below documents the contract state as received
> at the start of that session and all changes applied within it. All open findings
> from v2.56 remained open entering v2.65 unless noted otherwise below.

---

---

## v2.68: Audit Remediation — v2.67 Findings (H-01, M-01, L-01, L-02, I-01 through I-04)
**March 2026 | 3,316 lines | 1 error + 1 guard + 1 accounting fix + 6 NatSpec/comment additions**

**Rule: never change code beyond what is agreed. If anything looks wrong, ask first.**

### Summary

Combined remediation pass against findings from two audits: the internal self-audit (MEDIUM/LOW/INFO) and an external Cyfrin-style review that upgraded the PENDING-trap finding to HIGH and added three additional INFOs. All seven material findings closed. Zero open code findings after this version.

### Findings Closed

**H-01 / v2.67-M-01 (regraded HIGH): PENDING intent players fund-locked after startGame()**
`startGame()` had no check that the intent queue was fully processed before phase transition. A player in PENDING status (paid ~$1,040, no OG status) had no refund path once ACTIVE began: `claimOGIntentRefund()` and `claimSignupRefund()` both gate on PREGAME. Fix: one guard added to `startGame()`.

**M-01: ogRatioBps deflated by unresolved PENDING players**
Closed as a consequence of H-01 fix. `pendingIntentCount == 0` at startGame() guarantees every player either has confirmed OG status (OFFERED/SWEPT) or has been declined and exited. No PENDING entries in the denominator at track selection.

**L-01: prizePot floor silently under-deducted in claimOGIntentRefund()**
When `prizePot < netAmount` (edge case: concurrent yield anomaly in PREGAME), the old code set `prizePot = 0` but paid the full refund amount without accounting for the gap. The deficit was unaccounted. Fix: pull the deficit from `treasuryBalance` first, mirroring the `claimSignupRefund()` pattern.

**L-02: committedPlayerCount decrement path comment-fragile in _cleanupOGOnRefund()**
No code bug. The implicit dependency between `ogIntentUsedCredit` and the unconditional `committedPlayerCount--` was opaque. Fix: explicit explanatory comment added.

**I-01 (external): "timestamp order" should be "FIFO queue order"**
NatSpec in `confirmOGSlots()` and `registerAsOG()` said "timestamp order." The actual mechanism is queue insertion order (FIFO via `ogIntentQueue.push()`), which is approximately but not exactly timestamp order. Fixed in both locations.

**I-02 (external): sweepExpiredDeclines() left ogIntentWindowExpiry non-zero**
After sweeping, `ogIntentWindowExpiry[player]` retained its non-zero value, misleading off-chain tooling that might read it as "window still open." Fix: `ogIntentWindowExpiry[player] = 0` added on sweep. `ogIntentAmount` intentionally retained as historical record.

**I-03 (external / my I-01 combined): DECLINED re-entry block undocumented + "CONVERTED" ghost**
`registerAsOG()` NatSpec did not document that DECLINED players cannot re-enter the queue. Added. `confirmOGSlots()` NatSpec referenced "CONVERTED" status which never existed in the enum (leftover from an earlier design). Replaced with correct "OFFERED" in the skipped-states list.

**I-04 (external): MIN_PLAYERS_TO_START = 500 low-pop obligation math note**
Not a code bug. At 500 players with 50 OGs (10% cap), the draw-10 obligation lock creates a `requiredEndPot` that is unreachable at low population. Breathing suppresses prizes correctly but the note is useful for operators. Comment added to the constant declaration.

**My I-03 (sweepExpiredDeclines PREGAME-only limitation)**
Players who have OFFERED status when `startGame()` fires will never be marked SWEPT. Their OG status is permanent regardless. Limitation documented in `sweepExpiredDeclines()` NatSpec. No code change warranted.

### v2.68 Change Index

**1. New error**
`IntentQueueNotEmpty()`: reverted by `startGame()` when `pendingIntentCount > 0`.

**2. startGame() guard (H-01)**
```solidity
if (pendingIntentCount > 0) revert IntentQueueNotEmpty();
```
Inserted after existing phase/player-count checks, before `_checkSequencer()`.

**3. claimOGIntentRefund() prizePot deficit accounting (L-01)**
Old: `else { prizePot = 0; // safety floor }` with full payment still going out.
New: pulls deficit from `treasuryBalance` if `prizePot < netAmount`, with absolute safety floor. Mirrors `claimSignupRefund()` pattern.

**4. _cleanupOGOnRefund() comment (L-02)**
Six-line comment above `committedPlayerCount--` explaining the credit/non-credit invariant.

**5. registerAsOG() NatSpec (I-01, I-03)**
"timestamp order" replaced with "FIFO queue order (approximately registration-timestamp order)." DECLINED re-entry block documented.

**6. confirmOGSlots() NatSpec (I-01, my I-01, my I-03)**
"timestamp order" replaced with "FIFO order." "CONVERTED" replaced with "OFFERED" in skipped-states list. PREGAME-only limitation of sweepExpiredDeclines documented.

**7. sweepExpiredDeclines() (I-02, my I-03)**
`ogIntentWindowExpiry[player] = 0` added on sweep. NatSpec updated: ogIntentAmount retention explained, PREGAME-only limitation documented.

**8. MIN_PLAYERS_TO_START comment (I-04)**
Four-line inline comment noting low-population obligation math implications.

### v2.68 Audit Results

Triple pass complete. Zero C/H/M/L open findings. Zero open INFO findings.

| ID | Source | Severity | Status |
|----|--------|----------|--------|
| H-01 | External + internal | HIGH | Closed: startGame() guard |
| M-01 | External | MEDIUM | Closed: consequence of H-01 fix |
| L-01 | External | LOW | Closed: deficit accounting fix |
| L-02 | External | LOW | Closed: comment added |
| I-01 | External | INFO | Closed: NatSpec |
| I-02 | External | INFO | Closed: expiry cleared + NatSpec |
| I-03 | External | INFO | Closed: NatSpec |
| I-04 | External | INFO | Closed: constant comment |
| My I-01 | Internal | INFO | Closed: CONVERTED removed from NatSpec |
| My I-03 | Internal | INFO | Closed: PREGAME-only limitation documented |

---

## v2.67: Phase 2: OG Intent Queue and MIN_PLAYERS Reduction
**March 2026 | 3,284 lines | 1 enum + 2 constants + 5 errors + 5 events + 7 state variables + 1 rewritten function + 3 new functions + 2 patched functions**

**Rule: never change code beyond what is agreed. If anything looks wrong, ask first.**

### Summary

Phase 2 addresses the pregame OG slot monopolisation problem. Previously, `registerAsOG()` granted full OG status immediately in PREGAME, meaning the BPS cap could be exhausted in seconds by coordinated buyers. v2.67 replaces this with a two-step queue: pay now, get status when the owner confirms your slot in timestamp order, then accept or decline within 72 hours.

`MIN_PLAYERS_TO_START` drops from 2,500 to 500. The 2,500 figure predated the intent queue concept. Now that slot confirmation is gated by the owner working the queue in order, the floor requirement can be lower without concentration risk.

No changes to any ACTIVE-phase logic. The ACTIVE path inside `registerAsOG()` is structurally identical to v2.66.

### v2.67 Change Index

**1. New enum: `OGIntentStatus`**
Added to the enums block. Five states: `NONE`, `PENDING`, `OFFERED`, `DECLINED`, `SWEPT`.

**2. New constants (2)**
- `OG_INTENT_HARD_CAP = 5_000`: maximum depth of the intent queue. Anti-bot ceiling.
- `OG_INTENT_WINDOW = 72 hours`: decline window duration after a slot is offered.

**3. `MIN_PLAYERS_TO_START` changed: 2,500 -> 500**
Rationale: intent queue removes slot-rush incentive. A lower floor allows earlier launches and reduces the risk of failed pregames.

**4. New errors (5)**
- `IntentQueueFull()`: `ogIntentQueue.length >= OG_INTENT_HARD_CAP`.
- `AlreadyInIntentQueue()`: caller already has a non-NONE intent status.
- `NoIntentPending()`: `claimOGIntentRefund()` called with no PENDING or OFFERED entry.
- `IntentWindowExpired()`: `claimOGIntentRefund()` called after 72-hour window closed.

**5. New events (5)**
- `OGIntentRegistered(address, queueIndex, amount)`: emitted in PREGAME path of `registerAsOG()`.
- `OGIntentOffered(address, windowExpiry)`: emitted per slot confirmed in `confirmOGSlots()`.
- `OGIntentDeclined(address, refund)`: emitted in `claimOGIntentRefund()`.
- `OGIntentSwept(address)`: emitted per address swept in `sweepExpiredDeclines()`.
- `OGSlotsConfirmed(confirmed, pendingRemaining)`: emitted at end of `confirmOGSlots()` batch.

**6. New state variables (7)**
- `ogIntentQueue` (address[]): addresses in timestamp order.
- `ogIntentQueueHead` (uint256): next index for `confirmOGSlots` to process. Advances monotonically.
- `pendingIntentCount` (uint256): PENDING entries not yet offered a slot. Decrements on offer or refund.
- `ogIntentStatus` (mapping address -> OGIntentStatus): per-player lifecycle state.
- `ogIntentAmount` (mapping address -> uint256): what the player transferred on intent registration.
- `ogIntentWindowExpiry` (mapping address -> uint256): 0 until slot offered; then block.timestamp + OG_INTENT_WINDOW.
- `ogIntentUsedCredit` (mapping address -> bool, private): true if commitment credit was applied at registration. Governs `committedPlayerCount` logic on refund.

**7. `registerAsOG()` rewritten**
PREGAME path entirely replaced with intent queue logic. ACTIVE path unchanged.

PREGAME path:
- Rejects if `ogIntentStatus[msg.sender] != NONE` (cannot queue twice).
- Rejects if `ogIntentQueue.length >= OG_INTENT_HARD_CAP`.
- Applies commitment credit (`TICKET_PRICE` deduction) if `p.commitmentPaid`, same as before.
- Takes full payment, splits treasury/prizePot, records `ogIntentAmount`, `ogIntentUsedCredit`, stores `picks` on `PlayerData`.
- Pushes address onto `ogIntentQueue`. Increments `pendingIntentCount`.
- Increments `committedPlayerCount` only if not already counted via commitment credit.
- Does NOT grant `p.isUpfrontOG`. Does NOT push to `ogList`. Does NOT increment `upfrontOGCount`.
- Emits `OGIntentRegistered`. Returns early via `return`.

ACTIVE path (structurally identical to v2.66):
- No commitment credit path (ACTIVE registrations are direct, not queue-routed).
- `_upfrontOGCapReached()` check, OG status granted immediately, `ogList` push, `upfrontOGCount++`.
- Emits `UpfrontOGRegistered`.

**8. New function: `confirmOGSlots(uint256 batchSize)` (onlyOwner)**
- PREGAME only.
- Iterates from `ogIntentQueueHead` up to `batchSize` entries.
- For each PENDING entry: checks `_upfrontOGCapReached()`. If cap full, breaks and stops advancing head (can retry later when committedPlayerCount grows).
- If slot available: grants `p.isUpfrontOG = true`, pushes to `ogList`, increments `upfrontOGCount`, sets status to OFFERED, sets `ogIntentWindowExpiry`, decrements `pendingIntentCount`, increments `confirmed`. Emits `OGIntentOffered`.
- Non-PENDING entries (DECLINED/SWEPT) are skipped by advancing `ogIntentQueueHead` past them.
- Emits `OGSlotsConfirmed(confirmed, pendingIntentCount)` at end.

**9. New function: `claimOGIntentRefund()` (external, nonReentrant)**
- PREGAME only.
- Accepts PENDING or OFFERED status. OFFERED only within `ogIntentWindowExpiry`.
- CEI compliant: all state mutations before `_withdrawAndTransfer`.
- OFFERED path: reverses OG status (swap-and-pop from ogList, decrements upfrontOGCount). Note: pendingIntentCount was already decremented in `confirmOGSlots`.
- PENDING path: decrements `pendingIntentCount`.
- Both paths: `committedPlayerCount--` only if `!ogIntentUsedCredit[msg.sender]`.
- Reverses treasury/prizePot accounting using `ogIntentAmount` (safety floors for both).
- **[v2.67 original]** Transfers `ogIntentAmount` back to player. Yield earned while queued stays in prizePot.
  **[v2.81 updated]** Transfers `ogIntentAmount × 85%` (netRefund). The 15% treasury slice (depositKept) is permanently retained. See v2.81 for commitment deposit mechanic.
- Emits `OGIntentDeclined`.

**10. New function: `sweepExpiredDeclines(address[] calldata)` (onlyOwner)**
- PREGAME only. No fund movement. Housekeeping only.
- Iterates provided addresses. For each OFFERED entry past its window: marks SWEPT. Emits `OGIntentSwept`.
- SWEPT is a permanent marker. No claim path from SWEPT.

**11. `claimSignupRefund()` patched**
New branch for PENDING intent players claiming a failed-pregame refund. Decrements `pendingIntentCount`, marks DECLINED, clears `ogIntentAmount`, conditional `committedPlayerCount--`.

**12. `_cleanupOGOnRefund()` patched**
New branch at end of function: if player is OFFERED (granted OG by `confirmOGSlots` but refunding via a failed-pregame sweep), marks DECLINED and clears `ogIntentAmount`. `pendingIntentCount` note retained.

### Design Notes

**No OG_INTENT_WINDOW on ACTIVE path:** ACTIVE registrations go direct (no queue, no window). The intent queue is a PREGAME-only mechanism.

**Yield retention on refund:** `claimOGIntentRefund()` refunds exactly `ogIntentAmount`, not the Aave rebase value of the deposit. Any yield earned while queued stays in prizePot. This is intentional: it rewards the protocol for the trust the queued player extended, and avoids a yield-extraction attack where players join the queue just to accumulate Aave yield on a refundable deposit.

**[v2.81 update]** `claimOGIntentRefund()` was subsequently changed to retain 15% (`OG_TREASURY_BPS`) of `ogIntentAmount` as a permanent commitment deposit. Players receive 85% on voluntary exit. The game-failed path (`claimSignupRefund()`) continues to return 100%. See v2.81 for full commitment deposit design rationale. The yield retention principle above is unchanged — yield stays in pot regardless.

**`ogIntentQueueHead` stops at cap:** `confirmOGSlots()` leaves `ogIntentQueueHead` pointing at the first PENDING entry that could not be confirmed. When `committedPlayerCount` grows (more weekly players commit) the BPS cap widens and the owner can call again without re-scanning the queue from the start.

**No picks re-validation at confirmation:** picks are validated at `registerAsOG()` time (PREGAME path) and stored on `PlayerData`. They are live picks from the moment of confirmation. No second validation required in `confirmOGSlots()`.

### v2.67 Open Findings

| ID | Severity | Status | Description |
|----|----------|--------|-------------|
| v2.67-I-01 | INFO | **Superseded by v2.81** | `claimOGIntentRefund()` originally refunded `ogIntentAmount` (principal only). Yield retained in pot was by design. **v2.81 changed this:** voluntary exit now returns 85% only — 15% commitment deposit kept permanently. The yield-retention principle is unchanged. |

### v2.67 Audit Results

Triple pass complete. Zero C/H/M open findings.

All edge cases verified:
- Double-queue attempt reverts with `AlreadyInIntentQueue()`.
- PENDING refund while cap is full: no ogList touched, clean decrement.
- OFFERED refund: ogList swap-and-pop correct, upfrontOGCount consistent.
- `claimSignupRefund()` on failed pregame: PENDING branch decrements correctly, OFFERED branch handled in `_cleanupOGOnRefund()`.
- `committedPlayerCount` invariant preserved across all paths.
- CEI order correct in `claimOGIntentRefund()`.
- ACTIVE path structurally unchanged from v2.66.

---

## v2.66: Phase 1: Two-Track OG Concentration System
**March 2026 | 3,078 lines | 4 constants + 1 event + 3 state variables + 2 logic blocks + 2 NatSpec additions**

**Rule: never change code beyond what is agreed. If anything looks wrong, ask first.**

---

### Context: The Pregame OG Concentration Problem

The existing OG cap enforces a ratio against a growing `committedPlayerCount`
denominator. Motivated early adopters can exhaust their allocation before enough
weekly players have committed, leaving the contract at `startGame()` with a high OG
ratio. If OGs represent too large a share of the player base at launch, early prize
pools draw down OG principal faster than Aave yield replaces it, making the 111%
endgame target unreachable.

This version introduces an automated two-track system. At `startGame()` the contract
reads the actual OG ratio and permanently selects a protective configuration. No human
decision. No override. The track selection is a pure on-chain read.

---

### v2.66 Change Index

| # | Type | Description |
|---|------|-------------|
| 1 | Constants (4) | BREATH_PRE_LOCK_CAP_BUFFER, BREATH_PRE_LOCK_CAP_NUCLEAR, TRACK_JUNCTION_BUFFER_BPS, TRACK_JUNCTION_NUCLEAR_BPS |
| 2 | Event (1) | TrackSelected(track, ogRatioBps, preLockBreathCap) |
| 3 | State variables (3) | ogConcentrationTrack, preLockBreathCap, ogPrincipalFloor |
| 4 | startGame() | Track junction logic block |
| 5 | _calculatePrizePools() | Pre-lock cap block + Track 2 guardrail block |
| 6 | proposeBreathOverride() | v2.66-I-02 NatSpec: silent cap behaviour during pre-lock draws |
| 7 | _calculatePrizePools() | v2.66-L-01 NatSpec: guardrail zero-draw Aave-rebase trigger and false-positive JP miss flag |

---

### Zone Definitions

**Zone 1 (ogRatioBps <= 3000, i.e. <= 30%):**
Track 1. No pre-lock cap. Normal game. `preLockBreathCap = BREATH_START` (700 = 7%).
Auto-breathe functions as designed from draw 1. Cap condition `700 < 700` is false:
zero performance overhead for zone 1 games.

**Zone 2 (ogRatioBps > 3000 and <= 5000, i.e. 30-50%):**
Track 1 with buffer. Pre-lock breath capped at 3% for draws 1-9.
`preLockBreathCap = BREATH_PRE_LOCK_CAP_BUFFER` (300). Draws 10+ uncapped. No guardrail.

**Zone 3 (ogRatioBps > 5000, i.e. > 50%):**
Track 2. Pre-lock breath capped at 2% for draws 1-9.
`preLockBreathCap = BREATH_PRE_LOCK_CAP_NUCLEAR` (200).
Declining linear principal guardrail active for draws 1-51.

---

### New Constants

```solidity
uint256 public constant BREATH_PRE_LOCK_CAP_BUFFER  = 300;  // 3% zone 2 pre-lock cap
uint256 public constant BREATH_PRE_LOCK_CAP_NUCLEAR = 200;  // 2% zone 3 pre-lock cap
uint256 public constant TRACK_JUNCTION_BUFFER_BPS   = 3000; // 30%: zone 1/2 boundary
uint256 public constant TRACK_JUNCTION_NUCLEAR_BPS  = 5000; // 50%: zone 2/3 boundary
```

---

### New Event

```solidity
event TrackSelected(uint256 track, uint256 ogRatioBps, uint256 preLockBreathCap);
```

Emitted once at `startGame()`. Permanent on-chain record of zone detected and
configuration applied. Canonical source of truth for dashboards and auditors.

---

### New State Variables

```solidity
/// @dev Written once in startGame(). Immutable after game start. 1 = normal, 2 = nuclear.
uint256 public ogConcentrationTrack;

/// @dev Written once in startGame(). BPS cap applied to weeklyPool for draws 1-9
///      in zones 2 and 3. Equal to BREATH_START in zone 1 (cap condition never fires).
uint256 public preLockBreathCap;

/// @dev Written once in startGame() for Track 2 only. Zero for zones 1 and 2.
///      Total net OG principal at game start. Used by declining linear guardrail.
uint256 public ogPrincipalFloor;
```

All three are written exactly once. No function modifies them after `startGame()`.

---

### startGame() Addition: Track Junction Logic

```solidity
uint256 ogRatioBps = committedPlayerCount > 0
    ? upfrontOGCount * 10000 / committedPlayerCount : 0;

if (ogRatioBps <= TRACK_JUNCTION_BUFFER_BPS) {
    ogConcentrationTrack = 1;
    preLockBreathCap     = BREATH_START;
} else if (ogRatioBps <= TRACK_JUNCTION_NUCLEAR_BPS) {
    ogConcentrationTrack = 1;
    preLockBreathCap     = BREATH_PRE_LOCK_CAP_BUFFER;
} else {
    ogConcentrationTrack = 2;
    preLockBreathCap     = BREATH_PRE_LOCK_CAP_NUCLEAR;
    ogPrincipalFloor     = upfrontOGCount * OG_UPFRONT_COST
                           * (10000 - OG_TREASURY_BPS) / 10000;
}
emit TrackSelected(ogConcentrationTrack, ogRatioBps, preLockBreathCap);
```

**Overflow analysis:** At 5,000 OGs max, OG_UPFRONT_COST in 6-decimal USDC, OG_TREASURY_BPS
= 1550, the maximum intermediate value is approximately 5.2e16. Well within uint256.

---

### _calculatePrizePools() Additions

Two blocks inside the draws 1-51 `else` branch. Operation order: pre-lock cap first,
guardrail second, then `potSnapshot`, then deduction, then `_checkAutoAdjust()`. The
v2.65 `potSnapshot` ordering is fully preserved.

**Block 1: Pre-lock cap**

```solidity
if (currentDraw <= WEEKLY_OG_REGISTRATION_DEADLINE && preLockBreathCap < BREATH_START) {
    uint256 cappedPool = prizePot * preLockBreathCap / 10000;
    if (weeklyPool > cappedPool) weeklyPool = cappedPool;
}
```

**Block 2: Track 2 declining linear principal guardrail**

```solidity
if (ogConcentrationTrack == 2 && ogPrincipalFloor > 0) {
    uint256 remainingDraws = TOTAL_DRAWS - currentDraw + 1;
    uint256 currentFloor   = ogPrincipalFloor * remainingDraws / TOTAL_DRAWS;
    if (prizePot <= currentFloor) {
        weeklyPool = 0;
    } else if (prizePot - weeklyPool < currentFloor) {
        weeklyPool = prizePot - currentFloor;
    }
}
```

**Guardrail schedule:** Draw 1 protects 100% of net OG principal. Declines linearly.
Draw 51 protects ~3.8%. Draw 52 uses the exact-landing branch: guardrail does not run.
Minimum raw return on Track 2: ~76% of $1,040. With Aave yield and prizes won:
effective floor approximately 85-92% depending on season yield rate.

---

### v2.66-I-02: proposeBreathOverride() NatSpec

**Finding:** INFO. An owner could propose a breath override above `preLockBreathCap`
during draws 1-9. The override is stored on-chain at the proposed value but
`_calculatePrizePools()` silently caps the effective `weeklyPool`. No funds at risk.
Misleading without documentation.

**Fix:** NatSpec `@dev` block added to `proposeBreathOverride()` explaining the silent
cap behaviour and confirming it lifts after draw 9. A revert guard was considered and
rejected: adding draw-number awareness inside a governance function valid across all 52
draws would add surface area disproportionate to the risk. NatSpec only. Correct.

---

### v2.66-L-01: Guardrail Zero-Draw Trigger and JP Miss False Positive (NatSpec only)

**Finding:** LOW. If Track 2 guardrail zeros `weeklyPool` while `obligationLocked` is
true, `distributePrizes()` will set `lastDrawHadJPMiss = true` (false positive). Worst
case: one breath step-up suppressed next draw. No fund risk.

**Trigger analysis:** Under normal prize deduction this branch is unreachable. The
guardrail on draw N maintains `prizePot >= floor(N)`. The floor decreases each draw
(fewer remaining draws), so `prizePot` at draw N+1 start is always above `floor(N+1)`.
The sole realistic trigger is an **Aave negative rebase** event between draws (captured
by `_captureYield()`) severe enough to push `prizePot` at or below `currentFloor`.
This requires Track 2 (already a >50% OG ratio game) AND a significant Aave loss event.

**Fix:** NatSpec comment added to the guardrail block in `_calculatePrizePools()`
documenting the Aave-rebase-only trigger path and the false-positive JP miss consequence.
No code change warranted. Documented and accepted.

---

### v2.66 Audit Results (Triple Pass)

| Check | Result |
|-------|--------|
| Zone 1 bypass (700 < 700 = false) | Correct |
| Draw 52 bypass (separate branch) | Correct |
| potSnapshot ordering preserved | Correct |
| ogPrincipalFloor overflow | Clear at maximum OG count |
| getSolvencyStatus() / _captureYield() | No changes needed. ogPrincipalFloor is a guardrail on funds already inside prizePot |
| emergencyResetDraw() | Unaffected. Guardrail state variables are read-only post-start |

**Findings:**

| ID | Severity | Status | Description |
|----|----------|--------|-------------|
| v2.66-I-01 | INFO | Deferred to Phase 2 | MIN_PLAYERS_TO_START still 2,500. Target 500. Change requires dynamic 7:1 gate from Phase 2 intent queue. |
| v2.66-I-02 | INFO | Closed (NatSpec) | proposeBreathOverride() silent cap during pre-lock draws. NatSpec added. |
| v2.66-I-03 | INFO | N/A | getCurrentPrizeRate() NatSpec correctly documents non-reflection of pre-lock cap. Already correct. |
| v2.66-L-01 | LOW | Closed (NatSpec) | Guardrail zero-draw false-positive JP miss. Aave-rebase-only trigger. NatSpec added to guardrail block. |

**Audit verdict: Zero critical, high, or medium findings. v2.66 is clean.**

---

### v2.66 Deployment Notes

- Three new public state variables (ogConcentrationTrack, preLockBreathCap, ogPrincipalFloor) are ABI additions.
- Frontend and monitoring dashboards should read `ogConcentrationTrack` and `preLockBreathCap` at game start.
- The `TrackSelected` event is the canonical source of truth for zone and track assignment.
- No keeper bot changes required.

---

---

## 1Y Version Index (Complete to v2.66)

| Version | Headline |
|---------|----------|
| v1.0.0 | Fork from 3Y v16(40). 1Y constants applied. |
| v1.0.1 | Compile fix + treasury branch fix |
| v1.0.2 | Stale comment sweep |
| v1.0.3 | Reset refund mechanism introduced |
| v1.0.4-v1.0.9 | Reset refund hardening (11 findings) |
| v1.1.0 | Final audit pass. 0 C/H/M |
| v1.1.1 | CEI fix on sweepResetRefundRemainder |
| v1.1.2 | Slot-squatting mitigation. ACTIVE prepay system |
| v1.1.3 | Prepay system security audit. 2C 2H 2M 3L 2I |
| v1.1.4 | 2 Critical 1 High in OG prepay differentiation |
| v1.1.5 | Cap integrity. register to registerAsWeeklyOG orphan |
| v1.1.6 | Treasury integrity. credit draws zero-treasury bug |
| v1.1.7 | False-decrement hardening. usedStandardRegistrationActive |
| v1.1.8 | External audit. M-1 M-2 L-1 |
| v1.1.9 | External audit. M-NEW-01 L-NEW-01/02 INFO-01/02/03 |
| v1.1.10 | LOW-1 register() missing nonReentrant |
| v1.1.11 | INFO-1 NatSpec reentrancy list updated |
| v1.1.12 | INFO-1 renounceOwnership string to custom error |
| v1.1.13 | INFO-1 dead error removed, INFO-2 NatSpec fix |
| v1.1.14 | Prize tier redesign. M2 removed, BPS redistributed |
| v1.1.15-v1.1.16 | BPS surgery, breath rails, 111% target, endgame cap |
| v2.0 | First deployment candidate. Economics locked. |
| v2.01 | Patch. 4 code fixes, 4 doc fixes |
| v2.1 | Feature. one-in-one-out non-OG slot management |
| v2.2 | Triple audit remediation pass 1. 13 fixes (3C 4H 5M 1L) |
| v2.3 | RESET_REFUND_WINDOW 90 to 30 days |
| v2.31 | Self-audit. commitmentRefundPool deadline + solvency gap. 3 fixes |
| v2.32 | DrawPhase.RESET_FINALIZING. OZ-H-01 |
| v2.33 | BUG-A: lastDrawHadJPMiss early-return flag leak |
| v2.34 | proposeDormancy / cancelDormancy 24-hour timelock. OZ-M-06 |
| v2.35 | NEW-C-01: commitmentPaid nullification gate in buyTickets() |
| v2.36 | NEW-H-02: JP miss flag consumption redesigned |
| v2.37 | NEW-H-03 + NEW-H-01: full CEI compliance 3 functions |
| v2.38 | NEW-M-03 + M-01 + M-02: dormancy breath cancel, totalPaid zero, sweep event |
| v2.39 | V2.38-M-01 + L-01: breath cooldown restart + draw-52 flag clear |
| v2.40 | C-01 (dead exhale premium branch removed) |
| v2.41 | OZ-H-03: ownership transfer 7-day expiry window |
| v2.42 | H-04 + OZ-M-07: weekly OG dormancy state cleanup |
| v2.43 | KO-H-01: mulligan streak rollback |
| v2.44 | KO-M-01: lastDrawHadJPMiss gated on obligationLocked |
| v2.45 | KO-M-03 + KO-L-02: commitment dormancy path + emit fix |
| v2.46 | OZ-H-04 + KO-M-04 + N2.45-L-01: earnedOGCount decrement + ownership error |
| v2.47 | OZ-M-02 + NEW-M-05: dormancy endgame settlement + commitment carve order |
| v2.48 | v2.47-L-01 retracted. No material change. |
| v2.49 | H-02: two-slot reset refund pool + 4 knock-on solvency fixes |
| v2.50 | Pre-lock breathing draws 1-9 + call site fix + aaveEmergency pool-2 |
| v2.51 | M-02 + M-01: ogListIndex O(1) + pruneStaleOGs + v2.50-H-01 captureYield pool-2 |
| v2.52 | v2.51-L-01: pruneStaleOGs IDLE guard + v2.51-M-01 dual-reset documented limit |
| v2.53 | NEW series: 4 code fixes + 3 NatSpec. Zero C/H/M audit pass. 3,326 lines. |
| v2.54 | NEW-M-01: sweepFailedPregame treasury lock + NEW-L-01: commitment counter fix |
| v2.55 | batchMarkLapsed cap + pruneStaleOGs full clear + dormancy redundant set removed |
| v2.56 | Full NatSpec pass. 225 tags across 61 functions. No logic changes. |
| v2.57-v2.65 | Session gap. Source in archive. All v2.56 open findings carried forward. |
| v2.66 | Phase 1: two-track OG concentration system. v2.66-I-02 + v2.66-L-01 NatSpec. |

---

## Version Line Count Index: v2.35 to v2.66

| Version | Headline | Lines |
|---------|----------|-------|
| v2.35 | NEW-C-01: commitment flag gate in buyTickets() | 3,014 |
| v2.36 | NEW-H-02: JP miss flag consumption redesign | 3,030 |
| v2.37 | NEW-H-03 + NEW-H-01: Full CEI compliance (3 functions) | 3,048 |
| v2.38 | NEW-M-03 + M-01 + M-02: dormancy breath cancel, totalPaid, sweep event | 3,060 |
| v2.39 | V2.38-M-01 + L-01: breath cooldown restart + draw-52 flag clear | 3,072 |
| v2.40 | Dead exhale premium branch removed | 3,080 |
| v2.41 | OZ-H-03: ownership transfer 7-day expiry window | 3,098 |
| v2.42 | H-04 + OZ-M-07: weekly OG dormancy state cleanup | 3,120 |
| v2.43 | KO-H-01: mulligan streak rollback (consecutiveWeeks + lastActiveWeek) | 3,132 |
| v2.44 | KO-M-01: lastDrawHadJPMiss gated on obligationLocked | 3,140 |
| v2.45 | KO-M-03 + KO-L-02: commitment dormancy path + emit fix | 3,155 |
| v2.46 | OZ-H-04 + KO-M-04 anchor + N2.45-L-01 (earnedOGCount + ownership error) | 3,178 |
| v2.47 | OZ-M-02 + NEW-M-05: dormancy endgame settlement + commitment carve order | 3,210 |
| v2.48 | v2.47-L-01 retracted, no material change | 3,218 |
| v2.49 | H-02: two-slot reset refund pool + 4 knock-on solvency fixes | 3,368 |
| v2.50 | Pre-lock breathing (draws 1-9) + call site fix + aaveEmergency pool-2 | 3,420 |
| v2.51 | ogListIndex O(1) + pruneStaleOGs + _captureYield pool-2 gap | ~3,470 |
| v2.52 | pruneStaleOGs IDLE guard + dual-reset limit documented | ~3,490 |
| v2.53 | NEW series 4+3. Zero C/H/M. | 3,326 |
| v2.54 | NEW-M-01 treasury lock + NEW-L-01 commitment counter | 2,915 |
| v2.55 | batchMarkLapsed cap + pruneStaleOGs full clear + dormancy fix | 2,920 |
| v2.56 | Full NatSpec pass. No logic changes. | 3,315 |
| v2.57-v2.65 | Session gap. Archive only. | — |
| v2.66 | Two-track OG concentration system. Phase 1. NatSpec additions. | 3,078 |

> Note: v2.53 line count reduction from ~3,490 to 3,326 reflects NatSpec consolidation
> and removal of redundant comment blocks during the NEW-series application pass.
> v2.54 line count 2,915 reflects inline changelog comments stripped to external changelog,
> GAME_SETTLED_SENTINEL removal, and pragma pin.
> v2.56 line count increase to 3,315 reflects the full NatSpec pass (225 tags added).
> v2.66 line count 3,078 reflects Phase 1 six insertions plus two NatSpec additions
> (v2.66-I-02 and v2.66-L-01).

---

## Open Findings (as of v2.66)

### Pending Code

None. All prior code findings resolved. v2.66-L-01 closed via NatSpec.

### Design Pending

| # | ID | Severity | Status | Description |
|---|---|---|---|---|
| 1 | Phase 2 | HIGH | PENDING BUILD | Intent queue system (v2.67). registerAsOG() pregame branch rewrite to queue. confirmOGSlots(batchSize). claimOGIntentRefund() 72-hour window. convertIntentToWeekly() Option B. sweepExpiredDeclines(). OG_INTENT_HARD_CAP = 5,000. MIN_PLAYERS_TO_START = 500 with dynamic 7:1 gate. |
| 2 | SPEC-1 | MEDIUM | PENDING DESIGN | Staggered OG upgrade path. upgradeToUpfrontOG() currently requires $2,235 in one payment. Monthly pre-pay (4 weeks at once) is the first stepping stone. Seed-health-gated mechanism is the target design. Full design session needed before implementation. |
| 3 | M-01 | LOW-MED | MITIGATED | ogList unbounded. pruneStaleOGs() is the mitigation. Full structural fix deferred to v3.0. |

### Documented and Accepted

| # | ID | Severity | Status | Description |
|---|---|---|---|---|
| 4 | v2.66-L-01 | LOW | DOCUMENTED (NatSpec) | Guardrail zero-draw false-positive JP miss. Aave-rebase-only trigger. One suppressed breath step-up at worst. NatSpec added to guardrail block. No code fix warranted. |
| 5 | KO-L-01 | LOW | DOCUMENTED | cancelDormancy() does not restore a pending breath override cancelled by proposeDormancy(). Intentional. NatSpec documents this. |
| 6 | v2.51-M-01 | MED (reduced) | DOCUMENTED | Dual-reset dual-buyer pool-1 minor shortfall. Bounded exposure. Owner compensates from treasury. RUNBOOK comment in code. |
| 7 | OZ-C-02 | MED | ACCEPTED | Seed truncation dust. Mathematical property of integer division. No financial impact. |
| 8 | OZ-M-03 | MED | ACCEPTED | JP miss dust routing. By design. Documented. |
| 9 | v2.47-I-02 | INFO | DOCUMENTED | Dual-claim window ordering: qualified weekly OGs must claim dormancy refund before sweepDormancyRemainder() closes it. Operator guidance in NatSpec. |

### Resolved (tracked for provenance)

| ID | Fixed in | Description |
|---|---|---|
| C-01 (dead exhale branch) | v2.40 | Dead exhale premium branch removed |
| H-01 (breath override not cancelled) | v2.2 | Breath override not cancelled on emergency reset |
| H-02 (sequential reset second pool) | v2.49 | Sequential reset second pool |
| H-03 (withdrawTreasury post-settlement) | v2.2 | withdrawTreasury() allowed post-settlement |
| H-04 (weekly OG dormancy double-payment) | v2.42 | Weekly OG dormancy double-payment |
| M-02 (O(n) OG cleanup scan) | v2.51 | O(n) OG cleanup scan |
| M-05 (scheduleAnchor rebase) | v2.2 | scheduleAnchor rebase after reset |
| M-06 (payCommitment no deadline) | v2.2 | payCommitment() no deadline guard |
| M-07 (duplicate obligation lock) | v2.2 | Duplicate obligation lock in finalizeWeek() |
| OZ-C-01 (CEI violation) | v2.2 | CEI violation in three registration functions |
| OZ-H-01 (FINALIZING dual-path) | v2.32 | FINALIZING dual-path (DrawPhase.RESET_FINALIZING) |
| OZ-H-02 (unlimited USDC approval) | v2.2 | Unlimited USDC approval not revoked on Aave exit |
| OZ-H-03 (pendingOwner no expiry) | v2.41 | pendingOwner no expiry |
| OZ-H-04 (earnedOGCount not decremented) | v2.46 | earnedOGCount never decremented on status loss |
| OZ-M-02 (sweepDormancyRemainder no settled flag) | v2.47 | sweepDormancyRemainder() no gameSettled flag |
| OZ-M-06 (activateDormancy no timelock) | v2.34 | activateDormancy() no timelock |
| OZ-M-07 (weekly OG in ogList post-dormancy) | v2.42 | Weekly OG retained in ogList after dormancy refund |
| CROSS-EC-02 (stranded breath override) | v2.2 | Stranded breath override after rail tighten |
| CROSS-EC-04 (JP miss breath overcorrection) | v2.2 | JP miss breath overcorrection (lastDrawHadJPMiss) |
| CROSS-EC-05 (draw-1 reset commitment credit) | v2.2 | Draw-1 reset commitment credit protection |
| KO-H-01 (mulligan streak rollback) | v2.43 | Mulligan streak rollback |
| v2.50-H-01 (_captureYield missing pool-2) | v2.51 | _captureYield() missing resetDrawRefundPool2 |
| v2.51-L-01 (pruneStaleOGs IDLE guard missing) | v2.52 | pruneStaleOGs IDLE guard missing |
| NEW-M-01 (sweepFailedPregame treasury lock) | v2.53/54 | sweepFailedPregame treasury lock |
| NEW-L-01 (pruneStaleOGs stale flags) | v2.53 | pruneStaleOGs isWeeklyOG/picks not cleared |
| NEW-L-02 (batchMarkLapsed no cap) | v2.55 | batchMarkLapsed() no input size cap |
| NEW-I-04 (dormancyRefunded double-set) | v2.53/55 | Redundant inner dormancyRefunded set removed from both branches |
| v2.53-L-01 (pruneStaleOGs full clear) | v2.55 | weeklyOGStatusLost and statusLostAtDraw not cleared on prune |
| v2.66-I-02 (proposeBreathOverride silent cap) | v2.66 | NatSpec documenting silent cap behaviour during pre-lock draws |

---

## Audit Submission Readiness (as of v2.66)

**Critical:** 0 open. All resolved.
**High:** 0 open. All resolved.
**Medium:** 0 open code findings. SPEC-1 and Phase 2 intent queue are design items, not code defects.
**Low:** 0 open code findings. v2.66-L-01 closed via NatSpec (Aave-rebase-only edge case, documented and accepted).
**Info:** 0 open.

**Assessment:** Phase 1 complete and clean. Zero open code findings across all severity levels.
Phase 2 (v2.67 intent queue system) is the next major workstream.
Foundry testing, stress simulations, and submission pack preparation remain pending.

---

## Pending (as of v2.66)

**Phase 2 build (v2.67):**
- Intent queue system: registerAsOG() pregame rewrite, confirmOGSlots(), claimOGIntentRefund(),
  convertIntentToWeekly(), sweepExpiredDeclines(), OG_INTENT_HARD_CAP = 5,000.
- MIN_PLAYERS_TO_START = 500 with dynamic 7:1 gate, folded into Phase 2 build.

**Design sessions still needed:**
- SPEC-1: Adaptive OG Upgrade Path. Monthly pre-pay (4 weeks at once) is the
  recommended first step. Staggered seed-health-gated mechanism is the target design.
  Full design session needed before any code is written.

**Ongoing:**
- Chainlink Automation: checkUpkeep() / performUpkeep() full draw lifecycle
- Price Feed asset list: confirm all 42 feeds live on target chain
- Stress sims: whale OG surge mid-inhale, early bear market from draw 15, fast onboarding
- Audit submission pack with simulation results and deployment checklist
- Whale variant parameter spec ($50/week, Aave V4, 5-20K cap)
- Layer 2 (Foundry fuzz) and Layer 3 (adversarial Anvil agents) not started
- Constants to constructor args before multi-game launch (Crypto16, monthly format)
- 3-of-5 multisig: set as owner before any testnet or mainnet startGame() call


---

---

## v2.69: Breath Calibration System — Replaces Track System. 500 OG Absolute Floor.
**March 2026 | 3,304 lines | 2 constants + 1 state variable + 1 event + 1 rewritten block + 5 NatSpec/comment fixes + 1 view function fix**

**Rule: never change code beyond what is agreed. If anything looks wrong, ask first.**

---

### Summary

v2.69 replaces the three-zone two-track OG concentration system (v2.66) with a single breath calibration mechanism. The track system used zone boundaries (30% and 50% OG ratio) that were unreachable under the 10% upfront OG cap — dead code carrying audit surface with no protective benefit.

The replacement is conceptually simpler and strategically richer: at `startGame()` the contract reads the actual OG ratio, consults a piecewise linear scale, sets `targetReturnBps` (the return the breathing mechanism strives for), and calibrates the initial `breathMultiplier` to match. Both values are public, immutable after game start, and readable on-chain by any participant from the moment the game launches.

The 500 OG absolute floor ensures early adopters are never blocked by a small pregame denominator. The first 500 upfront OG slots are available regardless of ratio.

---

### Design: The Sliding Scale (Craig's Table)

The calibration scale is a three-segment piecewise linear function matching the agreed design table exactly:

| OG % at launch | Breathing strives for |
|---|---|
| 0% – 20% | 100% raw return |
| 30% | 80% |
| 40% | 75% |
| 50% | 70% |
| 60% | 65% |
| 70% | 60% |
| 80% | 55% |
| 90% | 50% |
| 100% | 40% |

**Important:** "strives for" means the breathing mechanism is calibrated toward this target. It is not a guarantee. Real outcomes depend on Aave yield, weekly player revenue, and 52 draws of auto-breathe adjustment. `targetReturnBps` is a public on-chain variable. Anyone can read what the contract is calibrated to strive for.

**Safety floor:** `TARGET_RETURN_FLOOR_BPS = 3000` (30%). The natural 100% OG anchor is 40%. The floor only activates if concentration somehow exceeds the cap — structural protection, not a normal operating state.

**Marketing headline:** `targetReturnBps` is set on-chain at `startGame()`. The contract literally tells you what it is calibrated to strive for. Not a whitepaper promise. Immutable code.

---

### v2.69 Change Index

| # | Type | Description |
|---|------|-------------|
| 1 | Constants removed (4) | BREATH_PRE_LOCK_CAP_BUFFER, BREATH_PRE_LOCK_CAP_NUCLEAR, TRACK_JUNCTION_BUFFER_BPS, TRACK_JUNCTION_NUCLEAR_BPS |
| 2 | State variables removed (3) | ogConcentrationTrack, preLockBreathCap, ogPrincipalFloor |
| 3 | Event replaced (1) | TrackSelected → BreathCalibrated(ogRatioBps, targetReturnBps, initialBreathBps) |
| 4 | Constants added (2) | OG_ABSOLUTE_FLOOR = 500, TARGET_RETURN_FLOOR_BPS = 3000 |
| 5 | State variable added (1) | targetReturnBps (public uint256, set once at startGame()) |
| 6 | startGame() rewritten | Track junction block replaced with three-segment calibration block |
| 7 | _calculatePrizePools() | Pre-lock cap block and Track 2 guardrail block removed. NatSpec updated. |
| 8 | _lockOGObligation() | requiredEndPot formula: hardcoded 11100/9000 replaced with targetReturnBps / 9000 |
| 9 | Endgame settlement (normal) | maxPerOG cap: OG_UPFRONT_COST * 111/100 replaced with OG_UPFRONT_COST * targetReturnBps / 10000 |
| 10 | Endgame settlement (dormancy) | Same maxPerOG cap fix |
| 11 | getProjectedEndgamePerOG() | obligation display: hardcoded 111% replaced with targetReturnBps |
| 12 | _upfrontOGCapReached() | 500 absolute floor added: maxUpfront = max(ratio-derived, OG_ABSOLUTE_FLOOR) |
| 13 | getOGCapInfo() | uMax now reflects OG_ABSOLUTE_FLOOR, matching _upfrontOGCapReached() exactly |

---

### Removed: Track System (v2.66)

Everything introduced in v2.66 is gone. No zone logic. No pre-lock cap block. No declining principal guardrail. No `ogConcentrationTrack == 2` conditional. Confirmed zero stale references.

---

### Added: Three-Segment Calibration Formula

```solidity
if (ogRatioBps <= 2000) {
    targetReturnBps = 10000;                          // Seg A: 0-20% OG → 100%
} else if (ogRatioBps <= 3000) {
    targetReturnBps = 10000 - (ogRatioBps - 2000) * 2; // Seg B: 20-30% steep
} else if (ogRatioBps <= 9000) {
    targetReturnBps = 8000 - (ogRatioBps - 3000) / 2;  // Seg C: 30-90% shallow
} else if (ogRatioBps < 10000) {
    targetReturnBps = 5000 - (ogRatioBps - 9000);       // Seg D: 90-100% mid
} else {
    targetReturnBps = 4000;                           // 100% OG natural anchor: 40%
}
if (targetReturnBps < TARGET_RETURN_FLOOR_BPS) targetReturnBps = TARGET_RETURN_FLOOR_BPS;
```

Opening breath calibrated proportionally:

```solidity
initialBreath = 165 + (targetReturnBps - 4000) * (BREATH_START - 165) / (10000 - 4000);
// 165 bps (1.65%) at 40% target, 700 bps (7.00%) at 100% target.
```

Both clamped to `[BREATH_MIN, breathRailMax]` before assignment.

---

### 500 OG Absolute Floor

`_upfrontOGCapReached()` now uses:

```solidity
uint256 maxUpfront = denominator * UPFRONT_OG_CAP_BPS / 10000;
if (maxUpfront < OG_ABSOLUTE_FLOOR) maxUpfront = OG_ABSOLUTE_FLOOR;
```

`getOGCapInfo()` applies the same logic so reported `upfrontMax` matches enforcement exactly.

**Effect:** In early PREGAME with fewer than 5,000 committed players, the ratio-derived cap is below 500. The floor guarantees the first 500 upfront OG slots are always available. After 5,000 committed players the ratio cap exceeds 500 and the floor is inactive.

---

### All 111% Hardcodes Replaced

Four locations in the contract previously hardcoded 111% as the endgame target. All four now use `targetReturnBps`:

| Location | Before | After |
|---|---|---|
| `_lockOGObligation()` | `* 11100 / 9000` | `* targetReturnBps / 9000` |
| Normal endgame | `* 111 / 100` | `* targetReturnBps / 10000` |
| Dormancy endgame | `* 111 / 100` | `* targetReturnBps / 10000` |
| `getProjectedEndgamePerOG()` | `* 111 / 100` | `* targetReturnBps / 10000` |

The formula is algebraically self-consistent: `_lockOGObligation` uses `/9000` to account for the 90/10 endgame OG/charity split. `maxPerOG` in settlement uses `/10000` applied to the per-OG cost. Both flow from the same `targetReturnBps`.

---

### v2.69 Audit Findings and Dispositions

| ID | Severity | Status | Description |
|----|----------|--------|-------------|
| v2.69-M-01 | MEDIUM | CLOSED (this version) | Single-linear formula did not match Craig's design table. Off by up to 11pp at key concentrations. Fixed with three-segment piecewise formula. Exact match verified. |
| v2.69-L-01 | LOW | CLOSED (this version) | Stale `[v2.66]` event comment on `BreathCalibrated`. Updated to `[v2.69]`. |
| v2.69-L-02 | LOW | CLOSED (this version) | Stale `[v2.66]` constant block comment referencing "pre-lock breath caps and track junction thresholds." Replaced. |
| v2.69-L-03 | LOW | CLOSED (this version) | Stale `[v2.66]` state variable comment referencing "Track system." Replaced. |
| v2.69-L-04 | LOW | CLOSED (this version) | Mangled comment block at MIN_PLAYERS_TO_START. v2.68 I-04 tail merged with v2.69 insert. Rewritten as coherent block. |
| v2.69-L-05 | LOW | CLOSED (this version) | `getOGCapInfo()` reported `upfrontMax` without applying OG_ABSOLUTE_FLOOR. Front end would show misleading cap below 500 in early PREGAME. Fixed: floor applied, NatSpec updated. |
| v2.69-L-06 | LOW | CLOSED (this version) | `breathMultiplier` declaration comment said "opens at 700." Misleading post-calibration. Updated: "default 700 bps, overridden at startGame() by calibration." |
| v2.69-I-01 | INFO | CLOSED (this version) | `TARGET_RETURN_FLOOR_BPS` comment imprecise. Now: "30% safety floor. Natural 100% OG anchor is 40%. Floor fires only below that." |
| v2.69-I-02 | INFO | CLOSED (this version) | startGame() inline comment said "At 100% OG: target=30%." Should be 40%. Updated alongside formula fix. |
| v2.69-I-03 | INFO | CLOSED (this version) | startGame() NatSpec said "targetReturnBps (30%-100%)." Corrected to "40%-100%, with 30% safety floor." |

**Audit verdict: Zero C/H/M/L/I open findings after v2.69.**

---

### Net Diff

| Metric | v2.68 | v2.69 |
|--------|-------|-------|
| Lines | 3,316 | 3,304 |
| Track constants | 4 | 0 |
| Track state variables | 3 | 0 |
| Calibration constants | 0 | 2 |
| Calibration state variables | 0 | 1 |
| Hardcoded 111% targets | 4 | 0 |
| Open code findings | 0 | 0 |

---

### Updated: 1Y Version Index

| Version | Headline |
|---------|----------|
| v2.66 | Phase 1: two-track OG concentration system |
| v2.67 | Phase 2: OG intent queue + MIN_PLAYERS_TO_START 500 |
| v2.68 | Audit remediation: H-01 fund-lock + L/I fixes. Zero open findings. |
| v2.69 | Breath calibration system replaces track system. 500 OG absolute floor. |

---

### Open Findings (as of v2.69)

**Code:** Zero open findings across all severity levels.

**Design Pending:**

| # | ID | Status | Description |
|---|---|---|---|
| 1 | SPEC-1 | PENDING DESIGN | Staggered OG upgrade path. Monthly pre-pay (4 weeks at once) is first stepping stone. Seed-health-gated mechanism is target design. |

**Documented and Accepted (carried forward):**

| # | ID | Severity | Description |
|---|---|---|---|
| 1 | KO-L-01 | LOW | cancelDormancy() does not restore a cancelled breath override. Intentional. NatSpec documented. |
| 2 | v2.51-M-01 | MED (reduced) | Dual-reset pool-1 minor shortfall. Bounded. Owner compensates from treasury. RUNBOOK in code. |
| 3 | OZ-C-02 | MED | Seed truncation dust. Integer division. No financial impact. |
| 4 | OZ-M-03 | MED | JP miss dust routing. By design. Documented. |
| 5 | v2.47-I-02 | INFO | Dual-claim window ordering. Operator guidance in NatSpec. |
| 6 | MOCK-L-01 | LOW | Post-expansion OGs not covered by ogPrincipalFloor. Not applicable: ogPrincipalFloor removed in v2.69. Finding retired. |

**Pending:**
- Foundry fuzz testing
- Stress simulations (whale OG surge, early bear market, fast onboarding)
- Cyfrin submission pack
- Base Sepolia deployment + testnet run
- 3-of-5 multisig as owner before any mainnet startGame()



---

---

## v2.70: Draw-10 Recalibration + Predictive Optimal Breath + EMA Revenue Tracking
**March 2026 | 3,360 lines | 2 additions + 2 rewrites**

**Rule: never change code beyond what is agreed. If anything looks wrong, ask first.**

---

### Summary

v2.69 introduced breath calibration at startGame() but had two gaps. First: OG registrations during draws 1-9 (ACTIVE phase) could shift the real OG ratio significantly from the startGame() snapshot, making targetReturnBps stale by the time obligation locked at draw 10. Second: the post-lock auto-breathe was reactive and blind — it stepped up/down against a straight-line trajectory with no awareness of incoming ticket revenue. A high-OG-ratio start followed by a wave of weekly players was only reflected in the breath after the pot had already drifted above the line. These two issues are fixed in v2.70.

---

### Change 1: Draw-10 Recalibration (targetReturnBps + breathMultiplier)

`_lockOGObligation()` now re-runs the full three-segment formula using the actual OG ratio at draw 10. `ogCapDenominator` (locked at startGame) is the denominator. `upfrontOGCount + earnedOGCount` is the numerator. The result replaces `targetReturnBps` and recalculates `requiredEndPot`. `breathMultiplier` is reset to the interpolated opening rate for the new target using the same formula as startGame().

The `BreathCalibrated` event at startGame() is now a **preview** — it reflects the pregame ratio and is useful for early transparency, but it is not authoritative. The `BreathRecalibrated` event at draw 10 is the **definitive on-chain record** of what the game is actually calibrated to strive for.

```solidity
event BreathRecalibrated(
    uint256 oldTargetBps,
    uint256 newTargetBps,
    uint256 oldBreath,
    uint256 newBreath,
    uint256 actualRatioBps
);
```

Example: game starts 20% OG (targetReturnBps=10000, breath=700). Eight hundred OGs join in draws 1-9. At draw 10: 900 OGs / 5,000 committed = 18% OG. targetReturnBps stays 10000. Breath resets to 700. No change. All good.

Example 2: game starts with 500 players (500 OGs, pure OG). Breath starts at 165. 4,500 weekly players join draws 1-9. At draw 10: 500 OGs / 5,000 committed = 10% OG. Three-segment formula: 10% is below the 20% flat ceiling, targetReturnBps = 10000. Breath resets to 700. The contract now strives for 100% return with a full breath, reflecting the actual healthy game composition.

---

### Change 2: EMA Revenue Seeding at Draw 10

`_lockOGObligation()` seeds `avgNetRevenuePerDraw = currentDrawNetTicketTotal` (draw 10's net ticket revenue). This gives the predictive formula a meaningful first data point from the moment obligation locks.

---

### Change 3: Predictive Optimal Breath (post-lock)

The entire post-lock section of `_checkAutoAdjust()` is replaced. No more steps, no more trajectory line, no more cooldown, no more JP miss suppression of UP.

**Old approach:** Draw a straight line from potAtObligationLock to requiredEndPot. Each draw: check if pot is above or below the line by a buffer. If above: step up 50 bps (if no JP miss). If below: step down 100 bps. 3-draw cooldown between changes.

**Problems:** Purely reactive. Blind to revenue. A wave of new weekly players only registers after the pot floats above the line. JP miss suppression created asymmetric oscillation. Cooldown introduced 3-draw lag minimum.

**New approach:** Every draw, solve for the exact breath rate that projects the pot to `requiredEndPot` at draw 52:

```
optimalRate = (prizePot + avgRevenue*remaining - requiredEndPot) * 10000
              / (prizePot * remaining)
```

Clamp to `[breathRailMin, breathRailMax]`. Set directly. No cooldown. No steps. Recalculates every draw.

When 2,000 new weekly players join in draw 15: the EMA updates with their revenue, `avgNetRevenuePerDraw` increases, `projectedRevenue` grows, optimal rate rises, more prizes. Next draw. No lag.

When players leave: EMA fades their revenue contribution over subsequent draws, rate tightens automatically.

When pot is below target and projected revenue can't cover the gap: `available <= requiredEndPot`, optimal rate = 0, clamped to `breathRailMin`. The formula is honest — it won't pretend prizes can happen when the maths says they can't.

---

### Change 4: EMA Revenue Update Each Draw

```solidity
avgNetRevenuePerDraw = (avgNetRevenuePerDraw + currentDrawNetTicketTotal) / 2;
```

Simple EMA. Each draw's revenue counts equally with the running average. Old draws fade. New activity reflects immediately. `currentDrawNetTicketTotal` already captures all ticket revenue regardless of payment method (direct transfer, prepaid credit consumption, weekly OG registration).

`lastDrawHadJPMiss` is cleared unconditionally at the start of the post-lock section. The predictive formula already accounts for JP miss impact through its effect on `prizePot` — no separate suppression logic needed.

---

### What Did Not Change

- Pre-lock section of `_checkAutoAdjust()`: unchanged. DOWN-only, proxy obligation, 3-draw cooldown. Correct for draws 1-9.
- Draw 52 exact-landing branch: unchanged.
- All view functions using `drawsSinceLock`/`targetNow` (getPotHealth, getProjectedEndgamePerOG): unchanged. These display the historical trajectory for off-chain reference.
- `BREATH_STEP_UP`, `BREATH_STEP_DOWN`, `BREATH_COOLDOWN_DRAWS` constants: retained. Still used in pre-lock section.
- `lastBreathAdjustDraw`: still updated on every breath change for off-chain monitoring.

---

### New State Variables

| Variable | Type | Description |
|---|---|---|
| `avgNetRevenuePerDraw` | uint256 public | EMA of net ticket revenue per draw. Seeded at draw 10. |

### New Events

| Event | When |
|---|---|
| `BreathRecalibrated(oldTargetBps, newTargetBps, oldBreath, newBreath, actualRatioBps)` | draw 10 `_lockOGObligation()` |

---

### v2.70 Audit Notes

**No new security findings introduced.** Changes are confined to two internal functions and add no new external call sites, no new fund flows, and no new state mutations outside the breath/calibration accounting already established in v2.69.

**One edge case to note for Foundry testing:**
The linear approximation `optimalRate = distributable * 10000 / (prizePot * remaining)` becomes imprecise at very early post-lock draws with large `remaining` values. At draw 11 with 41 remaining draws and high pot, the formula can return a very low rate (the pot is large relative to the 41-draw drain). This is correct behaviour — the pot doesn't need to release much per draw when there are 41 draws left and it's already healthy. The clamp to `breathRailMin` provides the floor in extreme scenarios. This is the accepted Option A tradeoff and is suitable for Foundry validation.

---

### Open Findings (as of v2.70)

**Code:** Zero open findings across all severities.

**Design Pending:**

| ID | Status | Description |
|---|---|---|
| SPEC-1 | PENDING DESIGN | Staggered OG upgrade path |
| TREASURY-HAND | PENDING CONFIRM | Owner inject/withdraw mechanism. Design agreed verbally. Awaiting build confirm. |

---

## v2.71: Audit Remediation (v2.70 findings) + Discretionary Reserve

**Source file:** `Crypto42_1Y_v2.71.sol`
**Lines:** 3,449
**Status:** Zero open findings across all severities.

### Summary

Seven findings from the v2.70 audit pass resolved. Discretionary reserve mechanism added (2.5% of every weekly ticket, owner-deployable into prizePot only, auto-sweeps at draw 52). Treasury gross take moves from 15.5% to 17.5%, split 15% / 2.5%.

---

### Audit Findings Resolved

#### v2.70-M-01 (MEDIUM) — FIXED
**Breath override wiped by predictive formula on next draw**

`executeBreathOverride()` now sets `breathOverrideLockUntilDraw = currentDraw + BREATH_COOLDOWN_DRAWS` (3 draws). `_checkAutoAdjust()` post-lock path returns immediately if `currentDraw <= breathOverrideLockUntilDraw`. After the window, predictive formula resumes normally. New state variable: `uint256 public breathOverrideLockUntilDraw`.

#### v2.70-L-01 (LOW) — FIXED
**`_currentTrajectoryTarget()` gate inconsistent with predictive model**

Both `proposeBreathOverride()` and `executeBreathOverride()` now gate upward overrides on pot health: `prizePot * 10000 / requiredEndPot >= 8000` (pot must be at least 80% of target). Replaces the old straight-line trajectory gate which no longer governs auto-breathe since v2.70. `_currentTrajectoryTarget()` reclassified as view-only display helper via NatSpec — not used by any protocol logic.

#### v2.70-L-02 (LOW) — FIXED
**`getProjectedEndgamePerOG()` potHealth misleading post-v2.70**

`potHealth` now returns `prizePot * 10000 / requiredEndPot`, capped at 10000. Replaces old trajectory-line percentage which corresponded to nothing the protocol acts on. Meaning: 10000 = pot already meets or exceeds target. Below 10000 = still closing the gap. Clean and honest.

#### v2.70-L-03 (LOW) — FIXED
**NatSpec missing on `_lockOGObligation()` and `_checkAutoAdjust()`**

Full `@dev` NatSpec blocks added to both functions documenting their three responsibilities, phase behaviour, formula, and guards.

#### v2.70-I-01 (INFO) — FIXED
**Pure-OG EMA behaviour undocumented**

`avgNetRevenuePerDraw` state variable comment now documents the pure-OG edge case: if no weekly players ever buy, EMA halves toward zero each draw, formula returns 0, clamps to `breathRailMin`. Correct behaviour — prizes paid from existing pot surplus only.

#### v2.70-I-02 (INFO) — FIXED
**`getCurrentPrizeRate()` NatSpec stale**

`@dev` block updated to reference v2.70 draw-10 recalibration and the live predictive update each draw.

#### v2.70-I-03 (INFO) — CONFIRMED CLOSED
**startGame() immutability claim**

Verified: the stale "immutable after this call" language was already removed in a prior pass. No action required.

---

### Feature: Discretionary Reserve (2.5%)

**Design:** "Treasury can only put back — by order of the code."

Every weekly ticket now routes 17.5% gross treasury take instead of 15.5%:
- 15.0% → `treasuryBalance` (unchanged, withdrawable by owner)
- 2.5% → `discretionaryReserve` (locked, pot-only destination)

**Constants added:**
```solidity
uint256 public constant TREASURY_BPS       = 1500;  // 15.00% to treasuryBalance
uint256 public constant DISCRETIONARY_BPS  =  250;  // 2.50%  to discretionaryReserve
uint256 public constant TREASURY_GROSS_BPS = 1750;  // 17.50% total gross take
```

**State variable added:** `uint256 public discretionaryReserve`

**Events added:**
- `DiscretionaryAccrual(uint256 indexed draw, uint256 amount)` — fired at every routing site
- `DiscretionaryDeployed(uint256 amount, uint256 remainingReserve)` — fired on manual deploy
- `DiscretionaryAutoSwept(uint256 amount)` — fired at draw-52 auto-sweep

**Owner function added:** `deployDiscretionary(uint256 amount)`
- Callable during ACTIVE phase only
- Blocked on draw 52 (auto-sweep handles it)
- Moves `amount` from `discretionaryReserve` to `prizePot`
- No other destination possible in code

**Draw-52 auto-sweep:** Any remaining `discretionaryReserve` automatically folds into `prizePot` before the exact-landing surplus calculation. Zero undeployed reserve at game close. Guaranteed by code.

**Routing sites updated (5):**
1. `payCommitment()` — pregame commitment ticket
2. Stranded prepaid credit in `registerAsOG()` — credit routed when player upgrades to upfront OG
3. `registerAsWeeklyOG()` — weekly OG registration ticket
4. `buyTickets()` credit path — prepaid credit consumption
5. `buyTickets()` cash path — direct USDC transfer

**OG routes unchanged:** `registerAsOG()`, `confirmOGSlots()`, and upfront OG payment paths all use `OG_TREASURY_BPS` (1500) directly and do not route to `discretionaryReserve`.

**`_getCurrentTreasuryBps()` updated:** Returns `TREASURY_GROSS_BPS` (1750). All refund and net-cost calculations (dormancy refund, reset refund, pregame accounting) correctly reflect the full 17.5% gross as the player's non-pot contribution.

**Solvency accounting:** `discretionaryReserve` added to `nonPotAllocated` in `_captureYield()`, `totalAllocated` in `getSolvencyStatus()`, and `totalAllocated` in `_solvencyCheck()`. Never invisible.

**`getGameState()` updated:** Returns `discReserve` as a new named return value alongside `treasury`.

**`withdrawTreasury()` NatSpec updated:** Notes that it operates on `treasuryBalance` only. `discretionaryReserve` cannot be withdrawn — only deployed into pot.

---

### Other Changes

- `withdrawTreasury()` NatSpec clarified: operates on the 15% `treasuryBalance` only.
- Stale duplicate `TreasuryAccrual` emit removed from `registerAsWeeklyOG()` post-transfer block (routing block already emits it).
- Unused `tRate` local variable removed from `buyTickets()`.

---

### Pending Items (carried forward)

| ID | Status | Description |
|---|---|---|
| SPEC-1 | PENDING DESIGN | Staggered OG upgrade path |
| VRF-BONUS | PENDING SESSION | VRF Thursday bonus draw (fills Tue-Sat dead time). ~80-100 lines. |

---

## v2.72: Audit Remediation — v2.71 Findings

**Source file:** `Crypto42_1Y_v2.72.sol`
**Lines:** 3,480
**Status:** Zero open findings across all severities.

### Summary

Eight findings from the v2.71 Cyfrin-style audit pass resolved. One medium (discretionaryReserve stranded on dormancy close), three low (NatSpec and stale state), four info (NatSpec gaps, typo, dead function).

---

### Findings Resolved

#### v2.71-M-01 (MEDIUM) — FIXED
**`discretionaryReserve` stranded if game closes via dormancy path**

`closeGame()` now sweeps any remaining `discretionaryReserve` into `prizePot` before `_captureYield()` runs, using the same pattern as the draw-52 auto-sweep. Emits `DiscretionaryAutoSwept`. Covers all closure paths: normal draw-52 completion and dormancy-triggered close.

#### v2.71-L-01 (LOW) — FIXED
**`proposeBreathOverride()` NatSpec stale — trajectory language, missing gate/lock docs**

`@dev` block rewritten. Now describes: the 80% pot-health gate for upward overrides, the 3-draw predictive formula suppression window after execute, and the fact that downward overrides have no pot-health gate.

#### v2.71-L-02 (LOW) — FIXED
**`executeBreathOverride()` had no `@dev` NatSpec**

Full `@dev` block added covering all three material behaviours: 7-day timelock, pot-health gate for upward overrides, and `breathOverrideLockUntilDraw` assignment protecting the override for 3 draws.

#### v2.71-L-03 (LOW) — FIXED
**`sweepFailedPregame()` left `discretionaryReserve` stale after sweep**

`discretionaryReserve = 0` added after `prizePot = 0`. The raw balance sweep already included reserve funds in `toCharity`; this zeroing keeps the state variable consistent with the settled reality. Inline comment explains the implicit inclusion.

#### v2.71-I-01 (INFO) — FIXED
**`_calculatePrizePools()` NatSpec missing draw-52 auto-sweep mention**

One sentence added to `@dev` block: draw-52 sweeps any remaining `discretionaryReserve` into `prizePot` before exact-landing surplus calculation.

#### v2.71-I-02 (INFO) — FIXED
**Typo: `undeploped` in two places**

Corrected to `undeployed` in both the constant block comment (line 254) and the `deployDiscretionary()` NatSpec.

#### v2.71-I-03 (INFO) — FIXED
**`breathOverrideLockUntilDraw` state variable needed `@dev`-level detail**

Inline comment expanded: documents initial value of 0 (no lock active), the draw-count mechanics, which function sets it, and how `_checkAutoAdjust()` consumes it.

#### v2.71-I-04 (INFO) — FIXED
**`_currentTrajectoryTarget()` is a dead function with no callers**

NatSpec note added: function has no internal callers as of v2.72. Retained for potential off-chain tooling. Not callable externally.

---

### No logic changes in v2.72
All changes are: one sweep added to `closeGame()`, one state-zero added to `sweepFailedPregame()`, NatSpec rewrites, and typo correction.

---

### Pending Items

| ID | Status | Description |
|---|---|---|
| SPEC-1 | PENDING DESIGN | Staggered OG upgrade path |
| VRF-BONUS | PENDING SESSION | VRF Thursday bonus draw (~80-100 lines) |

---

## v2.73: Audit Remediation — External Cyfrin-Style Pass

**Source file:** `Crypto42_1Y_v2.73.sol`
**Lines:** 3,487
**Status:** Zero open findings across all severities.

### Summary

Four findings from an independent external audit pass resolved. One medium (dual ogList entry via intent queue bypass), two low (ghost discretionaryReserve state in dormancy sweep, stale EMA during override lock window), one info (dead function removed).

---

### Findings Resolved

#### External-M-01 (MEDIUM) — FIXED
**`registerAsWeeklyOG()` PREGAME path allowed dual `ogList` entry via intent queue bypass**

A player with PENDING or OFFERED intent queue status had `isUpfrontOG = false`, so the `AlreadyOG` guard in `registerAsWeeklyOG()` did not fire. They could register as weekly OG, enter `ogList` at index X, then receive upfront OG confirmation via `confirmOGSlots()`, entering `ogList` again at index Y. Both indices remained in `ogList`. `processMatches()` would call `_matchAndCategorize()` twice per draw for this player — double prizes for 52 draws.

**Two-part fix:**

Option A (primary guard) — `registerAsWeeklyOG()` now checks intent status before the cap check:
```solidity
if (ogIntentStatus[msg.sender] == OGIntentStatus.PENDING
    || ogIntentStatus[msg.sender] == OGIntentStatus.OFFERED)
    revert AlreadyInIntentQueue();
```

Option B (backstop) — `confirmOGSlots()` now checks `p.isWeeklyOG` before granting upfront OG status. If the flag is set, the queue entry is silently skipped (head advances, `continue`). Intent status remains PENDING so the player retains `claimOGIntentRefund()`. Setting DECLINED was considered and rejected — it would trap the player's ~$1,040 with no refund path.

Note: the `AlreadyInIntentQueue` custom error (line 85) already existed from v2.67. No new error needed.

#### External-L-01 (LOW) — FIXED
**`sweepDormancyRemainder()` left `discretionaryReserve` non-zero after sweep**

`discretionaryReserve` was absent from `accounted` in `sweepDormancyRemainder()`. The reserve funds physically present in `usdcBalance` were correctly absorbed into `yieldBonus` and distributed — no fund loss. But `discretionaryReserve` was never zeroed. Post-settlement, `getSolvencyStatus()` would report `isSolvent = false` because `totalAllocated` included the stale reserve value while the funds were already gone.

`discretionaryReserve = 0` added after `prizePot = 0` with inline comment explaining the implicit inclusion in the balance sweep. Consistent with the v2.72 L-03 fix to `sweepFailedPregame()` and the v2.72 M-01 fix to `closeGame()`. All three closure paths now correctly zero the reserve.

#### External-L-02 (LOW) — FIXED
**EMA not updated during breath override lock window — stale projection on resume**

The EMA update (`avgNetRevenuePerDraw`) and JP miss flag clear were positioned after the `breathOverrideLockUntilDraw` early return. During the 3-draw override protection window, `avgNetRevenuePerDraw` received no updates. On draw N+4 when the lock expired, the predictive formula resumed with up to 3 draws of stale revenue data, miscalibrating `optimalBreathBps` until the EMA caught up.

Both the JP miss clear and the EMA update now execute unconditionally before the override lock return:
```solidity
if (lastDrawHadJPMiss) lastDrawHadJPMiss = false;
avgNetRevenuePerDraw = (avgNetRevenuePerDraw + currentDrawNetTicketTotal) / 2;
// [v2.71 M-01] Honour breath override lock window...
if (breathOverrideLockUntilDraw > 0 && currentDraw <= breathOverrideLockUntilDraw) return;
```
Revenue tracking now stays current throughout the override window.

#### External-I-01 (INFO) — FIXED
**`_currentTrajectoryTarget()` dead code removed**

Flagged in v2.72-I-04 NatSpec as having no internal callers. Function body removed in v2.73. The straight-line trajectory model it implemented was superseded by predictive optimal breath in v2.70. Override gates use the 80% pot-health check (v2.71 L-01). A tombstone comment at the section header documents the removal for audit provenance.

---

### No other logic changes in v2.73

---

### Submission Readiness

| Item | Status |
|---|---|
| Code audit findings | Zero open across all severities |
| Foundry testing | PENDING |
| Base Sepolia testnet run | PENDING |
| Cyfrin submission pack | PENDING |
| 3-of-5 multisig as owner | PENDING before mainnet startGame() |
| VRF bonus draw feature | PENDING SESSION |
| Staggered OG upgrade path | PENDING DESIGN |

---

## v2.74: Audit Remediation — Third External Pass

**Source file:** `Crypto42_1Y_v2.74.sol`
**Lines:** 3,503
**Status:** Zero open findings across all severities.

### Summary

Three findings from a third independent audit pass resolved. One low (activateAaveEmergency missing discretionaryReserve), two info (dead state variable documented, RUNBOOK comments added for stuck intent queue path).

---

### Findings Resolved

#### External2-L-01 (LOW) — FIXED
**`activateAaveEmergency()` excluded `discretionaryReserve` from `effectiveObligation` in both branches**

The `prizePot == 0` branch and the `prizePot > 0` branch both omitted `discretionaryReserve` from the `effectiveObligation` calculation. Every other solvency touchpoint in the contract — `_captureYield()`, `_solvencyCheck()`, `getSolvencyStatus()` — includes it. The omission made the `aBalance < effectiveObligation / 2` liquidity gate marginally understated (up to ~2.5% at max scale).

`discretionaryReserve` added to both branches with inline comment referencing `_solvencyCheck()` consistency.

#### External2-I-01 (INFO) — DOCUMENTED
**`potAtObligationLock` had no internal readers after `_currentTrajectoryTarget()` removal (v2.73)**

`potAtObligationLock` is written once in `_lockOGObligation()` and was previously read only by `_currentTrajectoryTarget()`, which was removed in v2.73. The variable is `public` — accessible off-chain by front-ends and auditors as a snapshot of the pot value at the moment OG obligation locked. Removing it would lose a useful transparency data point.

Decision: retain the variable and assignment. Full NatSpec comment added explaining: no internal readers, intentionally retained as an off-chain transparency reference, safe to keep, not a control input. RUNBOOK note included.

#### External2-I-02 (INFO) — DOCUMENTED
**`confirmOGSlots()` backstop leaves `pendingIntentCount` non-zero if primary guard is bypassed**

If the v2.73 backstop branch fires (PENDING player also has `isWeeklyOG`), the queue head advances but `pendingIntentCount` is not decremented. `startGame()` hard-reverts on `IntentQueueNotEmpty` until the player self-exits via `claimOGIntentRefund()`. No owner force-exit exists.

The alternative fixes were considered and rejected:
- Setting DECLINED and decrementing traps the player's ~$1,040 with no refund path.
- Forcing a USDC transfer inside the owner loop adds unsafe complexity.

Resolution: RUNBOOK comments added to both sites:
- `confirmOGSlots()` backstop block: explains the non-decrement, the self-exit dependency, and the owner action (contact player off-chain).
- `startGame()` NatSpec: RUNBOOK note explaining the stuck-queue scenario and resolution path. Notes that the player's principal is safe and refundable at any time.

---

### No logic changes in v2.74
All changes are: two `+ discretionaryReserve` additions, one state variable comment block, two RUNBOOK comment additions.

---

### Submission Readiness

| Item | Status |
|---|---|
| Code audit findings | Zero open across all severities |
| Foundry testing | PENDING |
| Base Sepolia testnet run | PENDING |
| Cyfrin submission pack | PENDING |
| 3-of-5 multisig as owner | PENDING before mainnet startGame() |
| VRF bonus draw feature | PENDING SESSION |
| Staggered OG upgrade path | PENDING DESIGN |

---

## v2.75: Remove Discretionary Reserve + Two Bug Fixes

**Source file:** `Crypto42_1Y_v2.75.sol`
**Lines:** 3,436
**Status:** Zero open findings across all severities.

### Summary

Discretionary reserve mechanism (introduced v2.71) removed entirely. Treasury reverts to flat 15% on all weekly tickets, matching OG_TREASURY_BPS. Two bugs fixed: ACTIVE registerAsOG() silent $10 overcharge (L-02), registerInterest() interestedCount drift (I-01).

---

### Design Decision: Remove Discretionary Reserve

The 2.5% discretionary reserve was a good idea but created disproportionate audit surface. Across v2.71-v2.74 it generated: 3 medium/low findings (closeGame missing sweep, sweepDormancyRemainder missing zero, activateAaveEmergency missing inclusion), 2 low findings (claimSignupRefund cap gap, sweepFailedPregame stale state), and touched 12+ sites across the contract.

A flat 15% treasury with no separate bucket is simpler, cleaner, and auditor-friendly. The owner retains the ability to voluntarily put money back into the pot from their own wallet — that mechanism is reserved for a future session when the design (deposit + conditional withdrawal when pot is healthy) is fully specified.

**Removed:**
- Constants: `DISCRETIONARY_BPS`, `TREASURY_GROSS_BPS`
- State variable: `discretionaryReserve`
- Events: `DiscretionaryAccrual`, `DiscretionaryDeployed`, `DiscretionaryAutoSwept`
- Function: `deployDiscretionary()`
- Solvency accounting: removed from `_captureYield()`, `getSolvencyStatus()`, `_solvencyCheck()`, `activateAaveEmergency()` (both branches)
- Settlement zeroing: removed from `closeGame()`, `sweepDormancyRemainder()`, `sweepFailedPregame()`
- Draw-52 auto-sweep block: removed from `_calculatePrizePools()`
- `getGameState()` `discReserve` return value removed

**`TREASURY_BPS` is now 1500 (15.00%)**, unified with `OG_TREASURY_BPS`. All player types pay the same rate. `_getCurrentTreasuryBps()` returns `TREASURY_BPS` directly.

**Five routing sites reverted** to single `treasurySlice` split: `payCommitment()`, stranded credit in `registerAsOG()`, `registerAsWeeklyOG()`, `buyTickets()` credit path, `buyTickets()` cash path.

---

### Bug Fixes

#### External3-L-02 (LOW) — FIXED
**ACTIVE `registerAsOG()` silently overcharged players who paid `payCommitment()` in PREGAME**

A player with `commitmentPaid = true` entering the ACTIVE `registerAsOG()` path paid the full `OG_UPFRONT_COST` ($1,040) with no credit applied. The PREGAME path correctly applied a `TICKET_PRICE` credit. The ACTIVE path had no equivalent. The $10 was unrecoverable — no refund path existed for upfront OGs.

Fix: ACTIVE path now checks `p.commitmentPaid`. If true: `ogTransfer = OG_UPFRONT_COST - TICKET_PRICE`, clears flag, decrements `committedPlayerCount`. The $10 already in prizePot from `payCommitment()` counts as partial payment. No double-transfer occurs.

#### External3-I-01 (INFO) — FIXED
**`registerInterest()` allowed PENDING/OFFERED intent players to re-register, inflating `interestedCount`**

`registerAsOG()` clears `registeredInterest` and decrements `interestedCount` when entering the intent queue. But it does not set any guard on `registerInterest()`. A PENDING or OFFERED player (with `isUpfrontOG = false`) passed all `registerInterest()` guards and could increment `interestedCount` again. `claimOGIntentRefund()` never touches `interestedCount`, leaving it permanently overstated.

Fix: `registerInterest()` now checks `ogIntentStatus` and reverts `AlreadyInIntentQueue` for PENDING or OFFERED players. Reuses existing error from v2.67.

---

### Pending Items

| ID | Status | Description |
|---|---|---|
| INJECT-POT | PENDING SESSION | Owner injectToPot() + conditional withdrawal when pot healthy |
| SPEC-1 | PENDING DESIGN | Staggered OG upgrade path |
| VRF-BONUS | PENDING SESSION | VRF Thursday bonus draw |

---

## v2.76: Weekly OG → Upfront OG Upgrade Path

**Source file:** `Crypto42_1Y_v2.76.sol`
**Lines:** 3,487
**Status:** Zero open findings across all severities.

### Summary

Three payment tiers formalised. New `upgradeToUpfrontOG()` function added. ACTIVE direct registration path for non-weekly-OGs closed. Two v2.75 audit findings fixed.

---

### Three Payment Tiers

The protocol now has three distinct commitment levels, each with a natural player psychology:

**YEARLY** — Upfront OG via PREGAME intent queue. Pay $1,040 once before game starts. Whale / early believer path. Unchanged.

**MONTHLY** — Weekly OG upgrade via `upgradeToUpfrontOG()`. Must be an active weekly OG who joined by draw 5. Call in draws 5, 6, or 7. Pay $80 (OG_PREPAY_AMOUNT = 4 weeks × 2 tickets × $10) now and every 4 draws thereafter. Total paid over 52 draws ≈ $1,040 — same as yearly path, paid in blocks.

**WEEKLY** — Regular player or weekly OG. $10-$20 per draw. No commitment.

---

### New Feature: `upgradeToUpfrontOG(uint64 picks)`

**Eligibility:**
- `gamePhase == ACTIVE`
- `currentDraw` between `OG_UPGRADE_FIRST_DRAW` (5) and `OG_UPGRADE_LAST_DRAW` (7) inclusive
- `p.isWeeklyOG == true` and `!p.weeklyOGStatusLost`
- `p.firstPlayedDraw <= OG_UPGRADE_JOIN_BY_DRAW` (5) — must have joined by draw 5
- Upfront OG cap not full

**Payment:**
- Transfers `OG_PREPAY_AMOUNT` ($80) immediately
- *[As shipped in v2.76 — this was a bug]* Stored gross in `p.prepaidCredit` and `totalPrepaidCredit` — treasury slice taken at consumption in `buyTickets()`, consistent with existing prepay pattern. **Fixed in v2.77-M-01:** upfront OGs cannot call `buyTickets()`, making this credit permanently stranded. v2.77 routes directly to `prizePot` instead.
- Weekly payments already made (`p.totalPaid`) stand as-is. No topup required.
- *[As shipped in v2.76 — this was a bug]* Emits `CreditToppedUp` and `UpfrontOGUpgraded`. **Fixed in v2.77:** `CreditToppedUp` removed (no prepaidCredit), `UpfrontOGUpgraded` retained.

**State transition:**
- `p.isWeeklyOG = false` → `p.isUpfrontOG = true`
- `weeklyOGCount--`, `earnedOGCount--`, `upfrontOGCount++`
- If `p.consecutiveWeeks >= WEEKLY_OG_QUALIFICATION_WEEKS`: `qualifiedWeeklyOGCount--`
- Pushed to `ogList` — matched every draw from this point
- Fresh picks submitted at upgrade time stored as `p.picks` — auto-play from this draw onward
- `p.consecutiveWeeks = 0`, `p.lastActiveWeek = 0` — streak state cleared, no longer relevant

**Draw-10 protection:**
- Upgrade window closes after draw 7. Draw 8 and 9 are stable.
- `_lockOGObligation()` at draw 10 fires on a frozen, fully-funded OG count.
- Each upgrade deposits $80 immediately, funding the new obligation before lock.

**Endgame entitlement:**
- `_isQualifiedForEndgame()` returns true immediately on `isUpfrontOG = true`
- `maxPerOG = OG_UPFRONT_COST × targetReturnBps / 10000` — same cap as all other OGs
- Upgraders who play all 52 draws pay ≈ $1,040 total. Cap is fair and consistent.

**Auto-play:**
- OGs are always in `ogList` and matched every draw on `p.picks`
- Last submitted picks auto-play until player actively changes them via `buyTickets()` or `submitPicks()`
- No toggle needed — this is architectural, not configurable

**New constants:**
```solidity
uint256 public constant OG_UPGRADE_FIRST_DRAW   = 5;
uint256 public constant OG_UPGRADE_LAST_DRAW    = 7;
uint256 public constant OG_UPGRADE_JOIN_BY_DRAW = 5;
```

**New errors:** `NotWeeklyOG`, `UpgradeWindowClosed`, `MustJoinByDrawFive`

**New event:** `UpfrontOGUpgraded(address indexed player, uint256 prepayAmount, uint256 atDraw)`

---

### ACTIVE `registerAsOG()` Direct Path Closed

Regular players can no longer buy upfront OG status during ACTIVE draws 1-9. The ACTIVE branch now reverts `NotWeeklyOG()` unconditionally. The only ACTIVE path to upfront OG is `upgradeToUpfrontOG()` — earned by playing weekly OG since draw 5. PREGAME intent queue (whale path) is completely unchanged.

---

### Bug Fixes (carried from v2.75)

#### v2.75-L-01 — FIXED
**`registerAsWeeklyOG()` ACTIVE path didn't credit `commitmentPaid`**

`usingPreCommitment` was gated on `gamePhase == PREGAME`. A player with `commitmentPaid = true` registering as weekly OG in ACTIVE draws 1-9 was overcharged $10 with no recovery. Fixed: `usingPreCommitment = p.commitmentPaid` (no phase gate). ACTIVE path now also clears the flag and decrements `committedPlayerCount` when credit is applied.

#### v2.75-I-02 — FIXED
**`_checkAutoAdjust` NatSpec said "draws 11-51" — should be "draws 10-51"**

Predictive optimal breath first runs on draw 10 (same draw `_lockOGObligation()` fires). Corrected.

---

### Pending Items

| ID | Status | Description |
|---|---|---|
| INJECT-POT | PENDING SESSION | Owner injectToPot() + conditional withdrawal when pot healthy |
| SPEC-1 | PENDING DESIGN | Staggered OG upgrade path (superseded by v2.76 design) |
| VRF-BONUS | PENDING SESSION | VRF Thursday bonus draw |

---

## v2.77: Audit Remediation — v2.76 Self-Audit (7 findings)

**Source file:** `Crypto42_1Y_v2.77.sol`
**Lines:** 3,505
**Status:** Zero open findings across all severities.

### Summary

Seven findings from the v2.76 double self-audit resolved. One critical (dual ogList entry — double prizes), one medium (prepaidCredit stranded), one low (zero-grind upgrade possible), four info (NatSpec).

---

### Findings Resolved

#### v2.76-C-01 (CRITICAL) — FIXED
**Dual ogList entry — upgraded player matched twice per draw**

Weekly OGs are already in `ogList` from `registerAsWeeklyOG()`. `upgradeToUpfrontOG()` was pushing them to `ogList` a second time. `processMatches()` iterates `ogList` linearly — with `isUpfrontOG = true`, the player matched at both indices every draw. Double prizes for all remaining draws. Structurally identical to the v2.73 M-01 exploit.

Fix: removed the `ogList.push()` and `ogListIndex` assignment from `upgradeToUpfrontOG()`. The player's existing `ogList` entry and `ogListIndex` from `registerAsWeeklyOG()` are valid and sufficient — `isUpfrontOG = true` now causes them to be matched as an upfront OG through the same entry.

#### v2.76-M-01 (MEDIUM) — FIXED
**`prepaidCredit` loaded at upgrade permanently stranded**

`buyTickets()` and `topUpCredit()` both block `isUpfrontOG` players. Any amount loaded into `p.prepaidCredit` at upgrade time could never be consumed. The $80 would sit in Aave indefinitely, ring-fenced in `totalPrepaidCredit`, never flowing to `prizePot`.

Fix: the $80 (`OG_PREPAY_AMOUNT`) now routes **directly to `prizePot`** after the `OG_TREASURY_BPS` treasury slice. No `prepaidCredit` involved. Pattern:
```solidity
uint256 tSlice = prepay * OG_TREASURY_BPS / 10000;
treasuryBalance += tSlice;
prizePot        += prepay - tSlice;
p.totalPaid     += prepay;
```
`p.totalPaid` updated so the payment is visible to `getPlayerInfo()`. `CreditToppedUp` emit removed (not appropriate without prepaidCredit). Subsequent block payment mechanism remains a pending design item (INJECT-POT session).

#### v2.76-L-01 (LOW) — FIXED
**Player could join draw 5 and upgrade draw 5 — zero draws played as weekly OG**

No weekly grind required. $80 to become upfront OG on day one of eligibility.

Fix: added guard `if (currentDraw <= p.firstPlayedDraw) revert UpgradeWindowClosed()`. Player must have completed at least one draw as weekly OG before upgrading. A player joining draw 5 can upgrade from draw 6 onward. Players joining draws 1-4 can upgrade from draw 5 onward.

#### v2.76-I-01 (INFO) — FIXED
`registerAsOG()` NatSpec said "ACTIVE: direct registration (unchanged from v2.66)" — now correctly says ACTIVE path reverts `NotWeeklyOG()` and directs users to `upgradeToUpfrontOG()`.

#### v2.76-I-02 (INFO) — FIXED
`upgradeToUpfrontOG()` NatSpec said credit "auto-spends via `buyTickets()`" and picks updated "via `buyTickets()`" — both wrong. Updated: payment goes directly to pot, picks updated via `submitPicks()`.

#### v2.76-I-03 (INFO) — FIXED
NatSpec implied "repeat every 4 draws" payment mechanism exists. No such function exists yet. Updated to note subsequent block payments are PENDING DESIGN (INJECT-POT session).

#### v2.76-I-04 (INFO) — FIXED
`p.totalPaid` not updated after prepay. Now incremented by `OG_PREPAY_AMOUNT` so payment is visible via `getPlayerInfo()`.

---

### Pending Items

| ID | Status | Description |
|---|---|---|
| INJECT-POT | PENDING SESSION | Owner injectToPot() + conditional withdrawal + OG block payment mechanism |
| VRF-BONUS | PENDING SESSION | VRF Thursday bonus draw |

---

## v2.78: Audit Remediation — External Pass on v2.77

**Source file:** `Crypto42_1Y_v2.78.sol`
**Lines:** 3,535
**Status:** Zero open findings across all severities.

### Summary

Two findings from an external audit pass on v2.77 resolved. One low (double-charge on upgrade), one info (dead event).

---

### Findings Resolved

#### External4-L-01 (LOW) — FIXED
**`upgradeToUpfrontOG()` double-charged $80 for ACTIVE weekly OG upgraders**

`registerAsWeeklyOG()` ACTIVE loads `OG_PREPAY_AMOUNT` ($80) into `p.prepaidCredit` via a live `safeTransferFrom`. `upgradeToUpfrontOG()` then required a second $80 fresh transfer. ACTIVE weekly OG upgraders paid $160 for an $80 upgrade. The first $80 was inaccessible until `claimUnusedCredit()` at game close (~52 weeks).

Fix: drain-and-shortfall pattern.
1. Any existing `prepaidCredit` (up to $80) routes directly to `prizePot` at upgrade time — no fresh transfer needed for that portion. `totalPrepaidCredit` decremented. `p.totalPaid` updated (ogPrepayTopUp at registration did not update it).
2. Fresh `safeTransferFrom` covers only the shortfall (`OG_PREPAY_AMOUNT - drained`).
3. ACTIVE weekly OGs with full $80 in prepaidCredit: zero fresh transfer.
4. PREGAME weekly OGs (prepaidCredit = 0): full $80 fresh transfer as before.
5. Total pot contribution = `OG_PREPAY_AMOUNT` in all cases.

CEI pattern maintained: all state mutations (drain accounting + state transition) before the conditional `safeTransferFrom`.

#### External4-I-01 (INFO) — FIXED
**`UpfrontOGRegistered` event declared but never emitted**

In v2.77, no code path emitted `UpfrontOGRegistered`. Off-chain indexers building upfront OG rosters by listening to this event would receive nothing. The event was dead code.

Fix: `UpfrontOGRegistered` is now emitted in two places:
1. `confirmOGSlots()` — at the point OG status is granted to an intent queue player.
2. `upgradeToUpfrontOG()` — at upgrade confirmation.

`UpfrontOGRegistered` is the canonical signal that an address is a confirmed upfront OG.
`OGIntentOffered` (also emitted from `confirmOGSlots`) signals the 72-hour decline window — a separate concern.
`UpfrontOGUpgraded` carries upgrade-specific data (prepay amount, draw).

`confirmOGSlots()` NatSpec updated to document both events and their distinct purposes.
`upgradeToUpfrontOG()` NatSpec payment section updated to describe drain-and-shortfall mechanic.

---

### Pending Items

| ID | Status | Description |
|---|---|---|
| INJECT-POT | PENDING SESSION | Owner injectToPot() + conditional withdrawal + OG block payment mechanism |
| VRF-BONUS | PENDING SESSION | VRF Thursday bonus draw |

---

## v2.79: Audit Remediation — External Pass on v2.78

**Source file:** `Crypto42_1Y_v2.79.sol`
**Lines:** 3,552
**Status:** Zero open findings across all severities.

### Summary

Three findings from an external audit pass on v2.78 resolved. All documentation/storage hygiene — no logic changes.

---

### Findings Resolved

#### External5-L-01 (INFO, elevated to document) — DOCUMENTED
**Aave yield on prepaidCredit during load-to-drain window bypasses treasury split**

While $80 sat in `prepaidCredit` between `registerAsWeeklyOG()` and `upgradeToUpfrontOG()`, `_captureYield()` excluded it from `nonPotAllocated` via `totalPrepaidCredit`. Any Aave yield on that $80 flowed to `prizePot` without a treasury split. When drained at upgrade, 15% treasury slice applied to full $80 as if it just arrived.

Discrepancy = Aave yield on $80 × ≤7 draws × ~4% APY ≈ **$0.03 per upgrader**. Player-favorable. Bounded. Applying the split at load time would change `registerAsWeeklyOG()` accounting for all weekly OGs — disproportionate to a $0.03 rounding artefact.

Resolution: inline comment added to the drain block documenting the known behaviour, magnitude, direction, and rationale for not fixing at load time.

#### External5-I-01 (INFO) — FIXED
**Stale mulligan fields in storage post-upgrade**

After `upgradeToUpfrontOG()`, `isWeeklyOG = false`. The `processMatches()` mulligan block (line 1572) is permanently unreachable for the upgraded player. `p.mulliganUsed`, `p.mulliganUsedAtDraw`, `p.mulliganQualifiedOG` sat stale in storage.

Three zero assignments added to `upgradeToUpfrontOG()` streak-clear block:
```solidity
p.mulliganUsed        = false;
p.mulliganUsedAtDraw  = 0;
p.mulliganQualifiedOG = false;
```
NatSpec note explains: upfront OGs are always auto-matched on `p.picks` every draw and cannot miss a draw, so no mulligan equivalent applies.

**On the mulligan design question:** Weekly OGs joining draws 5-7 cannot accumulate the 17-week streak (`MULLIGAN_THRESHOLD = 17`) required to earn a mulligan before upgrading. After upgrade the concept is moot — upfront OGs auto-play and cannot miss draws. No mulligan needed, none granted.

#### External5-I-02 (INFO) — DOCUMENTED
**`UpfrontOGUpgraded` emits gross $80, not net pot contribution**

`grossTarget = OG_PREPAY_AMOUNT ($80)`. Pot receives `$80 - treasury slice`. Off-chain tooling summing `prepayAmount` to track pot inflow overstates by 15%.

This is consistent with the existing contract convention — `CommitmentPaid` also emits gross `cost`. Not a bug, just needs clear documentation.

`UpfrontOGUpgraded` event declaration updated with inline comment: `prepayAmount is gross commitment (OG_PREPAY_AMOUNT), not net pot contribution (gross - treasury slice)`. Emit site also annotated confirming convention consistency with `CommitmentPaid`.

---

### No logic changes in v2.79

---

### Pending Items

| ID | Status | Description |
|---|---|---|
| INJECT-POT | PENDING SESSION | Owner injectToPot() + conditional withdrawal + OG block payment |
| VRF-BONUS | PENDING SESSION | VRF Thursday bonus draw |

---

## v2.80: Upgrader Fairness + Payment Gap + Event Naming

**Source file:** `Crypto42_1Y_v2.80.sol`
**Lines:** 3,612
**Status:** Zero open findings across all severities.

### Summary

Three findings resolved. One fairness fix for upgrader dormancy refunds, one design-gap fix addressing the upgrader payment shortfall (obligation formula + voluntary block payments), one event naming fix. Full double-check audit completed post-build — zero new bugs or edges introduced.

---

### Findings Resolved

#### LOW-01 — FIXED
**Upgrader dormancy refund capped at actual paid amount**

`dormancyPerOGRefund` is calibrated to `OG_UPFRONT_COST` pro-rata. An upgrader who paid `$80` could have received e.g. `$590` dormancy refund. Fix: `claimDormancyRefund()` now caps the refund for `upgradedFromWeekly` players at `p.totalPaid`. Full OG players are unaffected — their `p.totalPaid = $1,040` always exceeds `dormancyPerOGRefund`. Any surplus remaining in `dormancyOGPool` from capped upgraders flows to `sweepDormancyRemainder()` and benefits the endgame distribution.

#### DESIGN-GAP-01 — FIXED
**Upgrader payment gap addressed via honest obligation formula + voluntary block payments**

Three coordinated changes:

**New fields:**
- `bool upgradedFromWeekly` in `PlayerData` — set in `upgradeToUpfrontOG()`
- `uint256 public upgraderOGCount` — incremented alongside `upfrontOGCount` at upgrade

**Honest obligation formula** in `_lockOGObligation()`:
```solidity
uint256 regularOGCount = upfrontOGCount > upgraderOGCount
    ? upfrontOGCount - upgraderOGCount : 0;
ogEndgameObligation = regularOGCount  * OG_UPFRONT_COST
                    + upgraderOGCount * OG_PREPAY_AMOUNT;
```
Previously `maxOGs * OG_UPFRONT_COST` overstated the target when upgraders were present, causing the predictive breath formula to over-suppress prizes to compensate for a shortfall that was baked into the formula, not the pot. Now `requiredEndPot` reflects what was actually committed. If `upgraderOGCount = 0`, the formula is identical to before.

**New function: `payUpgradeBlock()`** — callable during ACTIVE phase only, IDLE drawPhase only. Accepts `OG_PREPAY_AMOUNT` from any `upgradedFromWeekly` player who hasn't yet reached `OG_UPFRONT_COST` total paid. Routes at `OG_TREASURY_BPS`. Updates `p.totalPaid`. Cannot overshoot `OG_UPFRONT_COST`. Each block adds to `prizePot` beyond `requiredEndPot`, widening the breath formula margin — more prizes for everyone. Emits `UpgradeBlockPaid`.

#### INFO-03 — FIXED
**`sweepFailedPregame()` now emits `FailedPregameSwept` instead of `DormancyRemainderSwept`**

New event declared. `sweepFailedPregame()` emits it. `DormancyRemainderSwept` now fires exclusively from `sweepDormancyRemainder()`. Off-chain indexers tracking the dormancy lifecycle receive clean semantics.

---

### Double-check audit: zero new findings

All new code paths verified:
- `upgraderOGCount` cannot be decremented by any existing removal path — upgraders are ACTIVE only, all removal functions are PREGAME only or guarded by `isWeeklyOG` which is false post-upgrade
- `upgraderOGCount > upfrontOGCount` impossible by construction — both increment together
- `payUpgradeBlock()` is net positive to solvency — deposit only, no withdrawal
- Post-obligation-lock `payUpgradeBlock()` calls strengthen the pot beyond `requiredEndPot`, causing breath to open wider — correct and beneficial
- Dormancy pool surplus from capped upgrader refunds flows correctly to `sweepDormancyRemainder()`
- `maxPerOG` in `closeGame()` unchanged — same cap for all upfront OGs regardless of upgrade path

---

### Pending Items

| ID | Status | Description |
|---|---|---|
| VRF-BONUS | PENDING SESSION | VRF Thursday bonus draw |
| PICK432-C-01 | OPEN | Fork registerInterest() references undefined OGIntentStatus — compilation blocker |

---

## v2.81: Commitment Deposit Mechanic — OG Intent Refund

**Source file:** `Crypto42_1Y_v2.81.sol`
**Lines:** 3,640
**Status:** Zero open findings. Double audit passed clean.

### Summary

One targeted change: `claimOGIntentRefund()` now retains the 15% treasury slice as a
permanent commitment deposit when a player voluntarily exits the OG intent queue.
Game-never-started path (`claimSignupRefund()`) unchanged — 100% returned.

---

### Design Rationale

**The problem:** Pre-game OG slot filling was economically free. A bot could pay $1,040,
occupy a slot, wait for the 72-hour window, decline, and receive 100% back. Cost = gas
+ opportunity cost of Aave yield for ~72 hours (~$0.56 per wallet). Not a real deterrent.

**The fix:** Make the commitment signal real. Voluntary exit costs 15% of what was
transferred ($156 on a $1,040 registration). That $156 stays in `treasuryBalance`
permanently — it does not disappear, it funds the protocol that the exiting player chose
to leave.

**The guarantee:** If the game never starts (`claimSignupRefund()` path), players receive
100% back. The commitment deposit only applies to VOLUNTARY exits while the game could
still proceed. A player cannot be penalised for a failure that wasn't their choice.

**Why 15%:** This is the existing `OG_TREASURY_BPS` — no new constant, no new parameter.
The treasury slice was already taken at registration. The change is simply: stop returning
it on voluntary exit. The mechanism was always there; the policy changes.

**Economic deterrent at scale:**
- 1,000 bot wallets filling the cap: $156,000 burned per attack attempt
- Every attack funds treasury (and by extension the protocol's long-term operation)
- Legitimate players who change their mind pay $156 — a fair signal cost for a $4,500
  commitment slot in a year-long game

---

### Changes

**`OGIntentDeclined` event** — updated signature:
```solidity
// Before:
event OGIntentDeclined(address indexed player, uint256 refund);
// After:
event OGIntentDeclined(address indexed player, uint256 netRefund, uint256 grossAmount, uint256 depositKept);
```
Off-chain tooling now has full visibility: what was paid, what was returned, what was kept.

> ⚠️ **BREAKING CHANGE — INFO-01-v2.81:** `OGIntentDeclined` event ABI is not backward-compatible. The signature changed from 2 parameters to 4. Any subgraph, monitoring service, off-chain tool, or front-end decoding this event by ABI will fail silently or decode garbage on v2.81+ contracts. Integrators must update their ABI before indexing any v2.81+ deployment. Coordinate with all monitoring infrastructure before deployment.

**`claimOGIntentRefund()`** — accounting rewrite:
- `depositKept = amount * OG_TREASURY_BPS / 10000` — slice retained in `treasuryBalance`
- `netRefund = amount - depositKept` — 85% returned to player
- `prizePot -= netRefund` — pulls exactly what went in at registration (perfect symmetry)
- `treasuryBalance` not touched in the normal exit path
- Deficit guard retained: if `prizePot` somehow insufficient, pulls from `treasuryBalance`
  (more resilient than before — treasury is now richer by every kept deposit)

**`claimSignupRefund()`** — NatSpec only. Explicit guarantee documented:
100% returned when game never starts. Pulls from prizePot then treasuryBalance to
make whole — unchanged logic, now explicitly documented as the counterpart to the
commitment deposit mechanic.

**`OGIntentStatus.DECLINED`** enum comment — updated to reflect 85% return, not
"Principal refunded."

**`claimOGIntentRefund()` NatSpec** — fully rewritten to document the commitment deposit
mechanic, the 85%/15% split, the game-failed guarantee, and the bot-deterrent design intent.

---

### Double Audit — No New Bugs

Accounting trace verified for all paths:
- Voluntary exit: `prizePot` debited exactly what it received. `treasuryBalance` gains
  `depositKept` permanently. Solvency invariant maintained.
- Game failed: `claimSignupRefund()` still returns 100% by pulling from both buckets.
  100% guarantee mathematically intact — unchanged code path.
- Deficit guard at `prizePot = 0`: `treasuryBalance` more resilient post-v2.81 because
  it retains kept deposits, making this edge case less likely to reach the guard.
- OFFERED path: 15% kept is fair — player received and then voluntarily declined OG status.
- `ogIntentUsedCredit` path: committed credit ($10) not restored + 15% of transfer kept.
  Total forfeit slightly higher but proportionate — two commitment signals, both honoured.

---

### Marketing Note (for whitepaper / pitch)

The commitment deposit mechanic is a new primitive in prize protocol design:

> *"When you register as an OG, your 15% is a commitment deposit — not a fee.
> If you leave voluntarily, it funds the players who stayed. If the game never
> starts, you get everything back. Code enforces all of it. No trust required."*

---

### Pending Items

| ID | Status | Description |
|---|---|---|
| VRF-BONUS | PENDING SESSION | VRF Thursday bonus draw |
| PICK432-C-01 | OPEN | Fork registerInterest() compilation blocker |

