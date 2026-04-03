// SPDX-License-Identifier: BUSL-1.1
// Licensed under the Business Source License 1.1
// Change Date: 24 February 2030
// On the Change Date, this code becomes available under MIT License.

pragma solidity 0.8.24;

/**
 * @title Pick432 1Y v2.05
 * @notice Pick 4 of 32 crypto assets weekly in ranked order. Outperform = prizes. 52 draws, ~1 year.
 * @dev Fork of Crypto42 1Y v2.81. Target chain: Arbitrum One.
 *
 *      AUDIT TRAIL: Full version history, all findings, and resolution notes are in
 *      Pick432_1Y_Changelog.md. Inline [vX.X.X / FINDING] tags throughout the code
 *      cross-reference that changelog. 215+ findings across v1.0 to v2.05 -- full count in changelog.
 *      [v2.0-v2.04] See changelog. [v2.05] L-v2.04-01/02: stale "5 min" and "Six vars" fixed.
 *
 *      [v1.99.11 / I-01] SYSTEMIC RISK: USDC (Circle) is a centralized stablecoin
 *      with a blacklist function. If this contract address is blacklisted, all
 *      safeTransfer and safeTransferFrom calls fail and the protocol becomes
 *      inoperable. This risk is outside the contract's control. See deployment
 *      README for migration considerations.
 *
 *      [v1.99.31 / I-01] ABI CHANGE: getPreGameStats() returns 7 values (was 6).
 *      New 7th field: proposalTimestamp (uint256). Positional callers unaffected.
 *      Named-return callers must update ABI before deployment.
 *      [v1.99.62 / L-03] ABI CHANGE: getPreGameStats() returns 8 values (was 7).
 *      [v1.99.67 / L-02] ABI CHANGE: getGameState() returns 13 values (was 12).
 *      New 13th field: lastResolvedDraw (uint256, position 12). Callers using
 *      positions 0-11 unaffected. Named-return callers must update.
 *      New 7th field (position 6, zero-indexed): intentQueueClear (bool). proposalTimestamp
 *      moved to position 7. Positional callers
 *      using indices 0-6 unaffected. Named-return callers must update.
 *
 * @author DYBL Foundation
 */

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@aave/core-v3/contracts/interfaces/IPool.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// [v1.99.11 / H-01] Minimal Chainlink aggregator interface to read circuit-breaker
// min/max answer bounds. AggregatorV3Interface does not expose these.
// Only minAnswer() and maxAnswer() are needed; cast at call site.
interface AggregatorMinMax {
    function minAnswer() external view returns (int192);
    function maxAnswer() external view returns (int192);
}

contract Pick432_1Y is ReentrancyGuard, Ownable2Step {
    using SafeERC20 for IERC20;

    // ═══════════════════════════════════════════════════════════════════════
    // CUSTOM ERRORS
    // ═══════════════════════════════════════════════════════════════════════

    error GameNotActive();
    error GameNotClosed();
    error DrawInProgress();
    error NotEnoughPlayers();
    error MaxPlayersReached();
    error OwnableUnauthorizedAccount(address account);
    error AlreadyRegistered();
    error AlreadyRegisteredInterest();
    error NotRegistered();
    error AlreadyOG();
    error OGCapReached();
    error NotOG();
    error NotEligible();
    error PicksLocked();
    error AlreadyBoughtThisWeek();
    error InvalidPicks();
    error InvalidAddress();
    error FeedUnchanged();
    error InsufficientBalance();
    error NothingToClaim();
    // [v1.6 / I-01] Three dead errors removed -- declared but never used in any revert:
    // NoActiveResetRefundPool (superseded by dual-pool architecture),
    // ResetRefundAlreadyClaimed (superseded by resetRefundClaimedAtDraw field check),
    // UpfrontOGRegistrationClosed (registerAsOG() ACTIVE reverts WrongPhase() instead). [v1.99.14 / C-01]
    error InsufficientGasForBatch();
    error ResetRefundNotEligible();
    error ResetRefundExpired();
    error AlreadyClaimed();
    error WrongPhase();
    error TooEarly();
    error CooldownActive();
    error ExceedsLimit();
    error BelowMinimum();
    error CanOnlyDecrease();
    error NotStuck();
    error DrawNotProgressing();
    error MalformedPerformData();          // [v2.03 / M-v2.02-02] action-2 performData too short
    error AaveLiquidityLow();
    error SolvencyCheckFailed();
    error AaveAlreadyExited();
    error TimelockPending();
    error NoTimelockPending();
    error GameAlreadyClosed();
    error SignupNotFailed();
    error PregameWindowExpired();
    error AlreadyRefunded();
    error MinimumTicketsRequired();
    error GameNotDormant();
    error AlreadyCommitted();
    error DormancyWindowExpired();
    error NotQualifiedForEndgame();
    error NotEnoughValidPrices();
    error SequencerNotReady();
    error PotBelowTrajectory();
    error BreathUnchanged();
    error RenounceOwnershipDisabled();
    error OwnershipTransferExpired();
    error IntentQueueFull();                   // [v2.67]
    error AlreadyInIntentQueue();              // [v2.67]
    error NoIntentPending();                   // [v2.67]
    error IntentWindowExpired();               // [v2.67]
    error IntentQueueNotEmpty();               // [v2.68] H-01: startGame() blocked while pendingIntentCount > 0
    error ActiveDeclineWindowOpen();           // [v1.99.30] confirmOGSlots fired too recently to propose launch
    error PregameOGNetNotSet();                // [v1.99.2] invariant: pregameOGNetContributed must be set for weekly OG

    // ═══════════════════════════════════════════════════════════════════════
    // EVENTS
    // ═══════════════════════════════════════════════════════════════════════

    // [v1.1 / C-03] SequencerFeedDisabled event removed. address(0) now reverts in constructor —
    // there is no valid no-sequencer mode on Arbitrum, so the event served no purpose.
    event StaleOGsPruned(uint256 pruned, uint256 remaining);
    // [v2.03 / M-v2.02-01] Emitted when _continueUnwind() restores a status-lost weekly OG.
    // picks were cleared by processMatches() at status-loss and are NOT restored.
    // Front-ends must detect this and prompt the player to call submitPicks() before next draw.
    event PicksResetOnUnwind(address indexed player, uint256 atDraw);
    event PlayerRegistered(address indexed player, uint256 totalPlayers);
    event InterestRegistered(address indexed player, uint256 totalInterested);
    event CommitmentPaid(address indexed player, uint256 amount);
    event UpfrontOGRegistered(address indexed player, uint32 picks, uint256 ogCount);
    event WeeklyOGRegistered(address indexed player, uint32 picks, uint256 draw);
    event WeeklyOGStatusLost(address indexed player, uint256 atDraw);
    // [v1.99.82 / STAGE2] picks removed from TicketsBought -- submitted separately.
    event TicketsBought(address indexed player, uint256 draw, uint256 ticketCount);
    // [v1.99.22 / LOW] Emitted when integer division produces perWinner=0 in distributePrizes().
    event TierSkippedDust(uint256 indexed tier, uint256 amount);
    event PicksSubmitted(address indexed player, uint32 picks, uint256 draw);
    // [v1.99.72 / P4-NEW-LOW-01] Emitted when an active OG (upfront or weekly)
    // has picks == 0 at match time. Auto-pick fallback (GENESIS_PICKS) fires.
    // No permanent harm to OG status or endgame entitlement.
    // [v1.99.84 / L-02] PicksMissing event removed. Superseded by AutoPickApplied.
    event AutoPickApplied(address indexed player, uint256 indexed draw, uint32 picks);
    event AutomationForwarderSet(address indexed forwarder);
    event GameStarted(uint256 timestamp, uint256 totalPlayers);
    event StartGameProposed(uint256 launchNotBefore);        // [v1.99.30] 72-hr notice window opened
    event StartGameProposalCancelled();                      // [v1.99.30] proposal withdrawn
    event FeedSubstituted(uint256 indexed slot, address indexed oldFeed, address indexed newFeed);
    event SignupRefund(address indexed player, uint256 amount, uint256 fullAmount);
    // [v1.99.65 / L-05] Emitted when batchRefundPlayers() skips a corrupt weekly OG.
    event SignupRefundSkipped(address indexed player);
    event DrawResolved(uint256 indexed draw, uint32 winningResult);
    event MatchingComplete(uint256 indexed draw, uint256 totalWinners);
    event MatchingBatchProcessed(uint256 indexed draw, uint256 processed, uint256 total);
    event PrizeDistributed(address indexed winner, uint256 amount, uint256 tier);
    event TierNoWinners(uint256 indexed draw, uint256 tier, uint256 returnedToPot);
    event JPMissRedistributed(uint256 indexed draw, uint256 toLowerTiers, uint256 toSeed);
    event SeedReturned(uint256 indexed draw, uint256 amount);
    event WeekFinalized(uint256 indexed draw);
    event GameClosed(uint256 perOG, uint256 charityAmount, uint256 qualifiedOGs);
    event YieldCaptured(uint256 yieldAmount);
    event EndgameClaimed(address indexed og, uint256 amount);
    event CharityClaimed(uint256 amount);
    event TreasuryWithdrawal(uint256 amount, address recipient);
    event TreasuryAccrual(uint256 indexed draw, uint256 amount, uint256 rateBps);
    event PrizeRateReductionProposed(uint256 newMultiplier, uint256 effectiveTime, bytes32 reason);
    event PrizeRateReductionExecuted(uint256 oldMultiplier, uint256 newMultiplier, bytes32 reason);
    event PrizeRateReductionCancelled();
    event PrizeRateIncreaseProposed(uint256 newMultiplier, uint256 effectiveTime, bytes32 reason);
    event PrizeRateIncreaseExecuted(uint256 oldMultiplier, uint256 newMultiplier, bytes32 reason);
    event PrizeRateIncreaseCancelled();
    event AaveExitProposed(uint256 effectiveTime);
    event AaveExitExecuted(uint256 amountWithdrawn);
    event AaveExitForcedOnSettle(uint256 amountWithdrawn);
    // [v1.99.11 / M-01] Emitted when Aave supply() fails; funds held as raw USDC.
    event AaveSupplyFailed(uint256 amount);
    // [v1.99.11 / I-02] All IPool.supply() calls use referral code 0 (no referral).
    // This is intentional. Auditors will confirm this is the correct default.
    // [v1.99.11 / L-03] Emitted when lastValidPrices fallback used; off-chain signal.
    event FeedStaleFallback(uint256 indexed feedIndex);
    event AaveExitCancelled();
    event AaveEmergencyActivated(uint256 usdcBalanceAtActivation);
    event FeedChangeProposed(uint256 indexed index, address newFeed, uint256 effectiveTime);
    event FeedChangeExecuted(uint256 indexed index, address oldFeed, address newFeed);
    event FeedChangeCancelled(uint256 indexed index);
    event EmergencyReset(uint256 indexed draw, DrawPhase fromPhase, uint256 amountReturned);
    event EmergencyUnwindBatch(uint256 indexed draw, uint256 unwoundSoFar, uint256 total);
    event EmergencyUnwindComplete(uint256 indexed draw, uint256 total);
    event PrizeClaimed(address indexed player, uint256 amount);
    event DormancyActivated(uint256 timestamp);
    // [v1.99.27 / I-03] Semantic note: the emitted timestamp is the EARLIEST time
    // sweepDormancyRemainder() can be called -- not a deadline after which player
    // claims are blocked. Players may claim at any point during DORMANT phase.
    // Rename consideration: DormancySweepWindowOpens better captures the intent.
    event DormancyClaimDeadline(uint256 deadline);
    event DormancyRefund(address indexed player, uint256 amount);
    // [v2.04 / NS-v2.03-03] Emitted when the STEP 3 dormancy charity amount is claimed
    // via claimDormancyCharity(). Charity is no longer sent at activation (changed in
    // v2.03 / M-v2.02-03). Distinct from CharityClaimed (closeGame/sweepDormancyRemainder).
    event DormancyCharitySent(uint256 amount);
    event DormancyProposed(uint256 effectiveTime);
    event DormancyCancelled();
    event ResetRefundClaimed(address indexed player, uint256 indexed draw, uint256 amount);
    event ResetRefundPartial(address indexed player, uint256 indexed draw, uint256 paid, uint256 owed);
    event ResetRefundExpiredSwept(uint256 indexed draw, uint256 amount);
    event ResetRefundSkipped(uint256 indexed draw, uint256 unprotectedTicketTotal);
    event ResetRefundOverflow(uint256 indexed draw, uint256 amount);
    event CommitmentRefundActivated(uint256 indexed draw, uint256 poolAmount);
    event CommitmentRefundClaimed(address indexed player, uint256 amount);
    event CommitmentRefundPartial(address indexed player, uint256 paid, uint256 owed);
    event CommitmentRefundExpiredSwept(uint256 indexed draw, uint256 amount);
    // [v1.6 / I-02] DormancyEndgame event removed -- declared but never emitted.
    // sweepDormancyRemainder() uses DormancyRemainderSwept and CharityClaimed instead.
    event DormancyRemainderSwept(uint256 toCharity);
    // [v2.80] Emitted by sweepFailedPregame() — distinct from DormancyRemainderSwept.
    // A failed pregame never entered dormancy; using DormancyRemainderSwept there was misleading.
    event FailedPregameSwept(uint256 toCharity);
    event StreakBroken(address indexed player, uint256 previousStreak);
    event EarnedOGQualified(address indexed player, uint256 atDraw);
    event OGObligationLocked(uint256 obligation, uint256 requiredPot, uint256 qualifiedOGs);
    event BreathMultiplierAdjusted(uint256 oldMultiplier, uint256 newMultiplier, bool isUp);
    event BreathOverrideProposed(uint256 indexed newMultiplier, uint256 effectiveTime, bytes32 reason);
    event BreathOverrideCancelled(uint256 cancelledMultiplier);
    event BreathOverrideExecuted(uint256 oldMultiplier, uint256 newMultiplier, bytes32 reason);
    event BreathRailsUpdated(uint256 newMin, uint256 newMax, uint256 atDraw);
    // [v1.72 / M-02] Breath rails now timelocked. Proposal/execution/cancellation events.
    event BreathRailsProposed(uint256 newMin, uint256 newMax, uint256 effectiveTime, bytes32 reason);
    event BreathRailsProposalCancelled(uint256 cancelledMin, uint256 cancelledMax);
    // [v1.72 / L-01] Emitted when forceDeclineIntent() cannot transfer to a player.
    // State is already cleaned up -- owner must arrange off-chain refund for this address.
    event ForceDeclineRefundClaimed(address indexed player, uint256 amount); // [v1.99.90 / M-NEW-01]
    event OGIntentForceDeclineFailed(address indexed player, uint256 amount);
    event EndgameShortfall(uint256 perOGPaid, uint256 perOGPromised, uint256 shortfallTotal);
    event PlayerLapsed(address indexed player, uint256 atDraw);
    event PlayerUnlapsed(address indexed player, uint256 atDraw);
    // [v2.69] Emitted once at startGame(). Immutable on-chain record of OG ratio and calibrated targets.
    event BreathCalibrated(uint256 ogRatioBps, uint256 targetReturnBps, uint256 initialBreathBps);
    // [v1.99.49 / I-03] NAMING CAVEAT: BreathCalibrated is the PREVIEW (emitted
    // at startGame). BreathRecalibrated is the AUTHORITATIVE value (draw 7).
    // Contrary to typical naming convention -- integrators must consume both.
    // [v1.95 / INFO-01] Emitted at draw 7 close (_calibrateBreathTarget) -- definitive on-chain
    // record of the true OG ratio calibration. Was draw 10 prior to v1.92 redesign.
    // May also re-emit at draw 10 if a future protocol version re-adds calibration there.
    event BreathRecalibrated(uint256 oldTargetBps, uint256 newTargetBps, uint256 oldBreath, uint256 newBreath, uint256 actualRatioBps);
    // [v2.67] Intent queue lifecycle events.
    event OGIntentRegistered(address indexed player, uint256 queueIndex, uint256 amount);
    event OGIntentOffered(address indexed player, uint256 windowExpiry);
    // [v2.81] grossAmount = full ogTransfer (what player paid). netRefund = grossAmount - commitment
    // deposit (OG_TREASURY_BPS slice). The slice is retained in treasuryBalance permanently.
    // [v1.98] Not emitted on game failure -- claimSignupRefund() handles that path.
    event OGIntentDeclined(address indexed player, uint256 netRefund, uint256 grossAmount, uint256 depositKept);
    event OGIntentSwept(address indexed player);
    // [v1.71] Emitted by forceDeclineIntent() -- distinct from OGIntentDeclined (voluntary).
    // depositKept = 0 always: owner-forced exit is not the player's fault, 100% refund.
    event OGIntentForcedDeclined(address indexed player, uint256 refund, uint256 grossAmount);
    event OGSlotsConfirmed(uint256 confirmed, uint256 pendingRemaining);

    // ═══════════════════════════════════════════════════════════════════════
    // ENUMS
    // ═══════════════════════════════════════════════════════════════════════

    enum GamePhase { PREGAME, ACTIVE, DORMANT, CLOSED }
    enum DrawPhase { IDLE, MATCHING, DISTRIBUTING, FINALIZING, RESET_FINALIZING, UNWINDING }

    /// @dev [v2.67] Lifecycle of an OG intent queue entry.
    /// NONE     = not in queue.
    /// PENDING  = registered intent, money in pot, awaiting confirmOGSlots().
    /// OFFERED  = confirmOGSlots() granted full OG status. 72-hour decline window open.
    /// DECLINED = player called claimOGIntentRefund(). 85% of ogTransfer returned; 15% commitment
    ///            deposit kept in treasuryBalance permanently. OG status removed if OFFERED.
    /// SWEPT    = window expired. OG status permanent. Housekeeping marker only.
    enum OGIntentStatus { NONE, PENDING, OFFERED, DECLINED, SWEPT }

    // ═══════════════════════════════════════════════════════════════════════
    // CONSTANTS
    // ═══════════════════════════════════════════════════════════════════════

    uint256 public constant TOTAL_DRAWS = 52;
    uint256 public constant INHALE_DRAWS = 36;
    // EXHALE_DRAWS has no internal callers -- contract logic uses INHALE_DRAWS directly
    // (isExhale = currentDraw > INHALE_DRAWS). Retained as a public constant for front-end
    // integrators and off-chain tooling that need the exhale boundary without computing
    // TOTAL_DRAWS - INHALE_DRAWS. Value: 52 - 36 = 16.
    uint256 public constant EXHALE_DRAWS      = 16;
    // [v1.99.57] Declining breath buffer: holds back a small target margin
    // early to grow exhale prizes. Buffer = requiredEndPot*500*(remaining/42)/10000.
    // Max at draw 11 (remaining=41): ~4.88% of requiredEndPot (not exactly 5% --
    // 500*41/(10000*42) = 4.88%). Declines to 0 at draw 52. Overflow safe.
    uint256 public constant BREATH_BUFFER_BPS  = 500;  // 5.00%
    uint256 public constant POST_LOCK_DRAWS     = 42;   // TOTAL_DRAWS - OG_OBLIGATION_LOCK_DRAW
    // [v1.99.10 / I-03] 548 days = exactly 1.5 years (365 + 183 days). Deliberate design:
    // the 1-year game run + 6-month unclaimed-funds window gives OGs and prize winners
    // ample time to claim before unclaimed funds sweep to charity. Not 365 or 730 days.
    uint256 public constant ENDGAME_SWEEP_WINDOW = 548 days;

    uint256 public constant TICKET_PRICE = 10_000_000;
    uint256 public constant EXHALE_TICKET_PRICE = 15_000_000;
    uint256 public constant OG_UPFRONT_COST = 1_040_000_000;
    uint256 public constant OG_TREASURY_BPS = 1500;
    uint256 public constant MAX_PLAYERS = 55_000;
    uint256 public constant MAX_TICKETS_PER_WEEK = 2;
    uint256 public constant MIN_TICKETS_WEEKLY_OG = 2;
    uint256 public constant MIN_PLAYERS_TO_START = 500;           // [v2.67] reduced from 2_500
    // [v2.68] I-04: at 500 players with 10% OG cap (50 OGs), the obligation lock at draw 10
    // produces a requiredEndPot that breathing alone cannot reach at low population.
    // Prizes suppress to near-zero. Expected behaviour for early/testnet launches. Not a bug.
    // [v2.69] requiredEndPot = ogEndgameObligation * targetReturnBps / 9000.
    // At 100% OG (targetReturnBps=4000): requiredEndPot = obligation * 4000/9000 = 44% of obligation.
    // At  20% OG (targetReturnBps=10000): requiredEndPot = obligation * 10000/9000 = 111% of obligation.

    uint256 public constant UPFRONT_OG_CAP_BPS = 1000;
    uint256 public constant TOTAL_OG_CAP_BPS = 1800;
    uint256 public constant OG_INTENT_HARD_CAP = 5_000;           // [v2.67] max queue depth (anti-bot ceiling)
    uint256 public constant OG_INTENT_WINDOW = 72 hours;          // [v2.67] decline window after slot offered
    uint256 public constant START_GAME_NOTICE_PERIOD = 72 hours; // [v1.99.30] min notice before startGame()
    uint256 public constant OG_DECLINE_WINDOW_TAIL   = 6 hours;  // [v1.99.31] max remaining decline window at proposal time

    // [v2.0] Weekly OG registration is PREGAME-only. All weekly OGs play from draw 1.
    // Draw 7 fires _calibrateBreathTarget() for breath recalibration.
    // Draw 10 locks obligation. No ACTIVE weekly OG joins permitted.
    // [v2.03 / I-v2.02-03] Renamed from OG_UPGRADE_LAST_DRAW in v2.0.
    // The weekly-to-upfront OG upgrade path (upgradeToUpfrontOG, payUpgradeBlock) was
    // removed in v2.0. This constant retains the draw-7 snapshot timing for
    // _calibrateBreathTarget() which is independent of the upgrade path.
    uint256 public constant BREATH_CALIBRATION_DRAW = 7;  // draw when _calibrateBreathTarget() fires
    uint256 public constant OG_OBLIGATION_LOCK_DRAW = 10; // draw when _lockOGObligation() fires
    // [v1.92] 51 = 52 total draws minus 1 mulligan. PREGAME joiners have all 52 draws.
    // Must play every draw, one mulligan allowed. Hard commitment -- no late joiners.
    uint256 public constant WEEKLY_OG_QUALIFICATION_WEEKS = 51;
    uint256 public constant MULLIGAN_THRESHOLD = 17;

    uint256 public constant SIGNUP_DURATION = 4 weeks;
    uint256 public constant MAX_PREGAME_DURATION = 8 weeks;
    uint256 public constant FAILED_PREGAME_SWEEP_EXTENSION = 180 days;

    uint256 public constant NUM_ASSETS   = 32;
    uint256 public constant NUM_PICKS    = 4;
    // [v1.99.82 / STAGE2] Default picks for new players with no pick history.
    // Encodes ranked indices [0, 1, 2, 3] -- first four feed array positions.
    // Published pre-launch with the full 32-asset feed ordering so players
    // understand the default before registering. Informed players can always
    // override via submitPicks(). Prize dilution risk when many players share
    // GENESIS_PICKS in a winning draw is acknowledged and accepted.
    uint32 public constant GENESIS_PICKS =
        uint32(0) | uint32(1 << 5) | uint32(2 << 10) | uint32(3 << 15); // = 0x18820
    uint256 public constant NUM_RESERVES = 6;
    uint256 public constant PICKS_BITS   = 5;         // 5 bits per pick index (0-31)
    uint256 public constant PICKS_MASK   = 0x1F;      // 0b11111
    uint256 public constant FULL_PICKS_MASK = 0xFFFFF; // 20 bits used (4 × 5)

    // Pick4/32 prize tier BPS -- expressed as fractions of the FULL weekly pool using /10000.
    // JP=33%, P2=24%, P3=19%, P4=14% of weekly pool. SEED=10%. Sum = 100%.
    // JP_BPS+P2_BPS+P3_BPS+P4_BPS = 10000 exactly, no dust.
    // [v1.5 / L-02] NON_SEED_BPS removed. Was 9000 -- the (wrong) divisor in _calculatePrizePools()
    // before C-01 fix. Formula now divides by 10000. No callers remained post-fix.
    // JP  = all 4 exact order   P2 = all 4 any order
    // P3  = 3 exact position    P4 = 3 any order (remainder, absorbs rounding)
    uint256 public constant JP_BPS   = 3667; // ~33% of weekly pool
    uint256 public constant P2_BPS   = 2667; // ~24% of weekly pool
    uint256 public constant P3_BPS   = 2111; // ~19% of weekly pool
    // P4 = 10000 - 3667 - 2667 - 2111 = 1555 bps ≈ 14% of weekly pool
    uint256 public constant SEED_BPS     = 1000;

    // JP miss redistribution: 30% to lower tiers, 70% seeds back to pot
    uint256 public constant JP_MISS_P2_BPS = 4000; // 40% of the 30%
    uint256 public constant JP_MISS_P3_BPS = 3500; // 35% of the 30% -- P4 gets remainder (25%)
    // [v1.99.65 / L-03] Named constant for the 30% lower-tier split.
    // 70% flows to eternal seed. Replaces inline 3000 in distributePrizes().
    uint256 public constant JP_MISS_TO_LOWER_TIERS_BPS = 3000;

    // [v2.75] Flat 15% treasury take on all weekly ticket purchases.
    // Matches OG_TREASURY_BPS so all player types pay the same rate.
    uint256 public constant TREASURY_BPS = 1500; // 15.00% to treasuryBalance

    uint256 public constant BREATH_START     = 700;   // [v2.65] 7.00% opening rate
    // [v1.5 / L-02] BREATH_STEP_UP removed. Was +0.50% per eligible pre-lock step. The upward
    // auto-step path was removed when Model B (predictive optimal breath) replaced the two-layer
    // step system. No callers remain. Pre-lock path only steps DOWN (BREATH_STEP_DOWN = 100).
    uint256 public constant BREATH_STEP_DOWN = 100;   // [v2.65] -1.00% per eligible step
    uint256 public constant ABSOLUTE_BREATH_FLOOR   = 100;    // [v2.65] 1.00% hard floor
    uint256 public constant ABSOLUTE_BREATH_CEILING = 2000;   // [v2.65] 20.00% hard cap
    uint256 public constant BREATH_MIN = 100;   // [v2.65] 1.00% nuclear bear floor
    uint256 public constant BREATH_MAX = 1500;  // [v2.65] 15.00% unified ceiling
    uint256 public constant BREATH_FLOOR_BPS = 1000;
    // [v1.6 / L-02] BREATH_CEIL_BPS = 2000 removed. Dead constant missed in v1.5 L-02 pass.
    // setBreathRails() validates against ABSOLUTE_BREATH_CEILING. _checkAutoAdjust() clamps
    // against breathRailMax. Neither reads BREATH_CEIL_BPS. No callers anywhere.
    uint256 public constant BREATH_COOLDOWN_DRAWS = 3;

    // [v2.69] Breath calibration constants. Set once at startGame() from OG ratio.
    uint256 public constant OG_ABSOLUTE_FLOOR     = 500;   // [v2.69] first 500 upfront OG slots always available
    uint256 public constant TARGET_RETURN_FLOOR_BPS = 3000; // [v2.69] 30% safety floor. Natural 100% OG anchor is 40%. Floor fires only below that.

    uint256 public constant DRAW_COOLDOWN              = 7 days;
    uint256 public constant PICK_DEADLINE              = 4 days;
    // [v2.03 / CL-v2.02-01] Increased from 300 (5 min) to 1800 (30 min).
    // Arbitrum sequencer outages require a larger automation runway than ETH Mainnet.
    // 30-minute buffer aligns with documented Chainlink Arbitrum recovery windows.
    // Matches ETH fork direction (1 hour). processMatches() GENESIS_PICKS fallback
    // remains the authoritative safety net if the window is still missed.
    uint256 public constant AUTO_PICK_BUFFER = 1800;
    uint256 public constant DRAW_STUCK_TIMEOUT         = 48 hours;
    // [v1.1 / C-02] Corrected from 24 hours to 25 hours (24h Chainlink heartbeat + 1h buffer).
    // At 24h exactly, any feed last updated 86401 seconds ago returns 0 and falls back to
    // lastValidPrices. 25h matches Pick432Whale v1.5 fix and recommended audit pattern.
    uint256 public constant FEED_STALENESS             = 25 hours;
    uint256 public constant SEQUENCER_GRACE_PERIOD     = 1 hours;
    uint256 public constant TIMELOCK_DELAY             = 7 days;
    uint256 public constant OWNERSHIP_TRANSFER_EXPIRY  = 7 days;
    uint256 public constant DORMANCY_TIMELOCK          = 24 hours;
    uint256 public constant DORMANCY_CLAIM_WINDOW      = 90 days;
    uint256 public constant RESET_REFUND_WINDOW        = 30 days;

    uint256 public constant MAX_MATCH_PER_TX       = 500;
    uint256 public constant MAX_DISTRIBUTE_PER_TX  = 200;
    // [v2.03 / L-v2.02-04] Reduced from 3000 to 500 for Arbitrum.
    // 3000 implied a single-block throughput Arbitrum cannot achieve (~360M gas = 11x block limit).
    // 500 is achievable within the 32M Arbitrum block limit (~25M gas at worst-case 50K/iter).
    // The per-iteration gasleft() < 50_000 guard in _continueUnwind() is the authoritative
    // safety net regardless. This constant is now an accurate batch ceiling, not theoretical.
    uint256 public constant MAX_UNWIND_PER_TX      = 500;
    uint256 public constant MAX_LAPSE_BATCH        = 500; // [v2.55 NEW-L-02] ~12.5M gas at 500x25K
    // [v1.99.58] Separate cap for batchRefundPlayers(). Each player requires an
    // Aave withdrawal (~100K gas). 100 players = ~10M gas -- within Arbitrum 32M limit.
    // Kept distinct from MAX_LAPSE_BATCH: those ops have no Aave withdrawal overhead.
    uint256 public constant BATCH_REFUND_MAX       = 100;
    uint256 public constant UNWIND_CONTINUATION_TIMEOUT = 7 days;

    uint256 public constant SOLVENCY_TOLERANCE    = 1_000_000;
    uint256 public constant PERFORMANCE_PRECISION = 1e18;

    // ═══════════════════════════════════════════════════════════════════════
    // IMMUTABLES
    // ═══════════════════════════════════════════════════════════════════════

    address public immutable USDC;
    address public immutable aUSDC;
    address public immutable AAVE_POOL;
    address public immutable CHARITY;
    uint256 public immutable DEPLOY_TIMESTAMP;
    address public immutable SEQUENCER_FEED;

    // ═══════════════════════════════════════════════════════════════════════
    // PRICE FEEDS
    // ═══════════════════════════════════════════════════════════════════════

    address[NUM_ASSETS] public priceFeeds;
    address[NUM_RESERVES] public reserveFeeds;
    int256[NUM_ASSETS] public lastValidPrices;

    struct PendingFeedChange {
        address newFeed;
        uint256 effectiveTime;
    }
    mapping(uint256 => PendingFeedChange) public pendingFeedChanges;

    // ═══════════════════════════════════════════════════════════════════════
    // GAME STATE
    // ═══════════════════════════════════════════════════════════════════════

    GamePhase public gamePhase;
    // [v1.99.82 / STAGE2] Chainlink Automation forwarder address.
    // Set by owner via setAutomationForwarder(). The forwarder is the
    // specific address Chainlink Automation uses to call performUpkeep().
    // applyAutoPicksForDraw() is callable by owner OR this address only.
    address public automationForwarder;
    DrawPhase public drawPhase;
    uint256 public currentDraw;
    uint256 public lastDrawTimestamp;
    uint256 public scheduleAnchor;
    uint256 public phaseStartTimestamp;
    uint256 public totalRegisteredPlayers;
    uint256 public totalLifetimeBuyers;
    uint256 public signupDeadline;
    uint256 public startGameProposedAt;   // [v1.99.30] 0 = no proposal active
    uint256 public latestOfferTimestamp;  // [v1.99.30] updated by confirmOGSlots() each batch

    // ═══════════════════════════════════════════════════════════════════════
    // FINANCIAL STATE
    // ═══════════════════════════════════════════════════════════════════════

    uint256 public prizePot;
    uint256 public treasuryBalance;
    uint256 public totalUnclaimedPrizes;
    uint256 public totalTreasuryWithdrawn;
    bool public aaveExited;
    bool public gameSettled;
    uint256 public settlementTimestamp;

    uint256 public endgamePerOG;
    uint256 public endgameCharityAmount;
    uint256 public endgameOwed;
    uint256 public dormancyTimestamp;
    uint256 public dormancyEffectiveTime;
    // [v2.03 / M-v2.02-03] Charity amount set aside at dormancy activation.
    // Transferred via claimDormancyCharity() -- not inside activateDormancy() --
    // so the live Aave withdrawal does not block dormancy activation under liquidity stress.
    uint256 public dormancyCharityPending;

    // [v1.99.4] Running total of all active OG gross payments across the game.
    // Increment sites (4): confirmOGSlots, registerAsWeeklyOG, buyTickets (weekly OG),
    //   _continueUnwind (restore).
    // Decrement sites (7): claimOGIntentRefund (OFFERED), forceDeclineIntent (OFFERED),
    //   _cleanupOGOnRefund (both branches), processMatches (statusLost),
    //   claimResetRefund pool1 (isWeeklyOG && !weeklyOGStatusLost),
    //   claimResetRefund pool2 (isWeeklyOG && !weeklyOGStatusLost).
    uint256 public totalOGPrincipal;
    // [v1.99.19 / M-01] Snapshot of totalOGPrincipal at dormancy activation.
    // Used as the frozen denominator in PATH 1/2 proportional formula.
    // Prevents claimResetRefund() calls during DORMANT from shrinking
    // the denominator mid-distribution, which would over-pay later claimants.
    uint256 public totalOGPrincipalSnapshot;

    // [v1.99.4] STEP 1: OG principal pool and frozen snapshot.
    uint256 public dormancyOGPool;
    uint256 public dormancyOGPoolSnapshot;
    bool    public dormancyPrincipalFullCover;

    // [v1.99.4] STEP 2: Casual last-draw ticket refunds.
    uint256 public dormancyCasualRefundPool;
    uint256 public dormancyCasualRefundPoolSnapshot;
    uint256 public dormancyCasualTicketTotal;
    bool    public dormancyCasualFullCover;

    // [v1.99.4] STEP 4: Per-head surplus pool.
    uint256 public dormancyPerHeadPool;
    uint256 public dormancyPerHeadShare;
    uint256 public dormancyParticipantCount;

    // [v1.99.4] Running counter for current-draw non-OG net ticket revenue.
    // Feeds dormancyCasualTicketTotal at activation. Reset each draw.
    // NOT included in solvency accounting -- live counter not a fund pool.
    uint256 public currentDrawCasualNetTicketTotal;
    uint256 public ownershipTransferExpiry;

    // [v1.99.4] dormancyPerOGRefund, dormancyFullOGCover, dormancyWeeklyPool,
    // dormancyWeeklyPoolForCalc, dormancyWeeklyTicketTotal, dormancyWeeklyFullCover removed.

    uint256 public currentDrawTicketTotal;
    uint256 public currentDrawNetTicketTotal;
    uint256 private pregameWeeklyOGTicketTotal;

    uint256 public resetDrawRefundPool;
    uint256 public resetDrawRefundDraw;
    uint256 public resetDrawRefundDeadline;
    uint256 public resetDrawRefundPool2;
    uint256 public resetDrawRefundDraw2;
    uint256 public resetDrawRefundDeadline2;

    uint256 public commitmentRefundPool;
    uint256 public commitmentRefundDraw;
    uint256 public commitmentRefundDeadline;
    uint256 private pregameWeeklyOGNetTotal;

    uint256 public ogCapDenominator;

    uint256 public prizeRateMultiplier = 10000;
    uint256 public pendingMultiplier;
    uint256 public multiplierEffectiveTime;
    bytes32 public pendingMultiplierReason;
    bytes32 public lastMultiplierChangeReason;

    uint256 public aaveExitEffectiveTime;

    uint256 public ogEndgameObligation;
    uint256 public requiredEndPot;
    // [v2.74 I-01] Written once at draw 10 (_lockOGObligation). No internal readers as of v2.73
    // (_currentTrajectoryTarget() was removed). Retained as a public off-chain transparency
    // reference: front-ends and auditors can read the pot value at the moment OG obligation locked.
    // RUNBOOK: this variable is a snapshot, not a control input. Safe to keep indefinitely.
    uint256 public potAtObligationLock;
    bool    public obligationLocked;

    // [v1.5 / M-01] lastDrawHadJPMiss removed. Flag was set in distributePrizes() and cleared
    // one draw later in _checkAutoAdjust() with no effect on any formula. The v2.73 comment
    // "predictive formula accounts for its pot impact directly" was the admission it was dead.
    // The EMA captures JP-miss pot impact naturally via the post-miss pot level each draw.

    uint256 public breathMultiplier = BREATH_START; // [v2.65] default 700 bps. [v2.69] overridden at startGame() by calibration.
    uint256 public lastBreathAdjustDraw;
    uint256 public breathRailMin = BREATH_MIN;
    uint256 public breathRailMax = BREATH_MAX;
    // [v1.72 / M-02] Pending breath rails proposal -- 7-day timelock matching TIMELOCK_DELAY.
    uint256 public pendingBreathRailMin;
    uint256 public pendingBreathRailMax;
    uint256 public breathRailsEffectiveTime;

    uint256 public pendingBreathOverride;
    uint256 public breathOverrideEffectiveTime;
    bytes32 public pendingBreathOverrideReason;
    bytes32 public lastBreathOverrideReason;
    // [v2.71 M-01] Set by executeBreathOverride() to currentDraw + BREATH_COOLDOWN_DRAWS (3).
    // _checkAutoAdjust() post-lock path returns early if currentDraw <= this value,
    // preserving the manual override for 4 draws before the predictive formula resumes.
    // [v1.99.23 / H-L-01] If override executes during draw N IDLE, lockUntilDraw = N+3.
    // The <= check suppresses draws N, N+1, N+2, N+3 -- four draws total, not three.
    // Behaviour is intentionally conservative: one extra draw of protection is harmless.
    // Initial value: 0 (no lock active). Reset implicitly when the draw advances past it.
    uint256 public breathOverrideLockUntilDraw;

    // [v2.69] Set once at startGame(). 0 before game starts. Public for front-end and auditor visibility.
    // targetReturnBps: the return the breathing mechanism strives for (4000=40% to 10000=100%).
    // 30% safety floor (TARGET_RETURN_FLOOR_BPS) applied below 40% natural anchor.
    // [v1.92] Recalibrated at draw 7 close (_calibrateBreathTarget). _lockOGObligation() reads it; does not change it.
    uint256 public targetReturnBps;

    // [v2.70] Exponential moving average of net ticket revenue per draw.
    // Seeded at draw 10 with that draw's net revenue. Updated every post-lock draw.
    // Used by predictive breath to project future pot trajectory.
    // [v2.71 I-01] Pure-OG game note: if no weekly players ever buy tickets,
    // currentDrawNetTicketTotal is 0 every draw. EMA halves toward zero each draw.
    // Formula produces optimalBreathBps = 0, clamped to breathRailMin. Correct behaviour —
    // in a pure-OG game with no incoming revenue, prizes are paid only from existing pot surplus.
    uint256 public avgNetRevenuePerDraw;

    // ═══════════════════════════════════════════════════════════════════════
    // PLAYER STATE
    // ═══════════════════════════════════════════════════════════════════════

    struct PlayerData {
        bool registered;
        bool registeredInterest;
        bool commitmentPaid;
        bool isUpfrontOG;
        bool isWeeklyOG;
        bool weeklyOGStatusLost;
        bool mulliganUsed;
        bool mulliganQualifiedOG;
        bool isLapsed;
        uint256 statusLostAtDraw;
        uint256 mulliganUsedAtDraw;
        bool endgameClaimed;
        bool dormancyRefunded;
        uint32 picks;             // 4 ordered picks, 5 bits each, packed into uint32
        uint256 lastBoughtDraw;
        uint256 lastActiveWeek;
        uint256 firstPlayedDraw;
        uint256 consecutiveWeeks;
        uint256 totalPaid;
        uint256 lastTicketCount;
        uint256 lastTicketCost;
        // [v1.99.1] Restored from v1.87 / AUDIT-L-01. v1.92 removed this assuming the credit
        // path would be eliminated with PREGAME-only registration. The credit path survived:
        // players who paid the $10 commitment deposit before registerAsWeeklyOG() pay only $10
        // fresh (transferCost=$10), so pregameWeeklyOGNetTotal gets $8.50 not $17.00. Without
        // this field, _cleanupOGOnRefund() subtracts the full $17.00 -- $8.50 undercount per
        // credit-path refund. commitmentPaid is cleared at registration so cannot be read here.
        uint256 pregameOGNetContributed;
        // [v1.86 / P5-CYF-I-01] Stores the draw number of the most recently claimed reset pool.
        // [v1.99.69 / I-01] DUAL-FIELD DESIGN (was single-field, retired in v1.99.68):
        // resetRefundClaimedAtDraw tracks pool1 claims ONLY.
        // resetRefundClaimedAtDraw2 (below) tracks pool2 claims ONLY.
        // Prior design used this field for both pools. When pool2 claim set it to
        // resetDrawRefundDraw2, pool1 eligibility check (field != resetDrawRefundDraw)
        // re-opened, allowing a third call to double-refund from pool1 if pool not
        // depleted. Snapshot erasure (lastResetBoughtDraw2 = 0) is insufficient --
        // pool1 eligibility can also be met via lastBoughtDraw == resetDrawRefundDraw.
        uint256 resetRefundClaimedAtDraw;
        // [v1.99.68 / M-01] Independent tracking for pool2. The single-field design
        // allowed pool2 claim to overwrite pool1's record, re-opening pool1 eligibility
        // on a third call if lastBoughtDraw still matched resetDrawRefundDraw and the
        // pool was not yet depleted. Each pool now has its own dedicated claim record.
        uint256 resetRefundClaimedAtDraw2;
        // [v1.84 / AUDIT-L-01] Two independent snapshot pairs -- one per reset pool.
        // Prior single pair was shared: pool2 snapshot overwrote pool1, permanently
        // blocking pool1 recovery when both pools existed simultaneously.
        uint256 lastResetBoughtDraw1;   // pool1 snapshot: draw when player last bought in resetDrawRefundDraw
        uint256 lastResetTicketCost1;   // pool1 snapshot: ticket cost for that draw
        uint256 lastResetBoughtDraw2;   // pool2 snapshot: draw when player last bought in resetDrawRefundDraw2
        uint256 lastResetTicketCost2;   // pool2 snapshot: ticket cost for that draw
        uint256 unclaimedPrizes;
        uint256 totalPrizesWon;
    }

    mapping(address => PlayerData) public players;

    uint256 public interestedCount;
    uint256 public committedPlayerCount;
    uint256 public lapsedPlayerCount;

    address[] public ogList;
    mapping(address => uint256) private ogListIndex;
    address[] public weeklyNonOGPlayers;
    uint256 public upfrontOGCount;
    uint256 public weeklyOGCount;
    uint256 public earnedOGCount;
    uint256 public qualifiedWeeklyOGCount;

    // [v2.67] OG intent queue. Written in PREGAME, read-only after startGame().
    address[] public ogIntentQueue;
    uint256 public ogIntentQueueHead;                              // next index for confirmOGSlots to process
    uint256 public pendingIntentCount;                             // PENDING entries not yet offered a slot
    mapping(address => OGIntentStatus) public ogIntentStatus;     // per-player queue status
    mapping(address => uint256) public ogIntentAmount;            // what they actually transferred in
    mapping(address => uint256) public ogIntentWindowExpiry;      // 0 until confirmOGSlots offers the slot
    mapping(address => bool) private ogIntentUsedCredit;          // true if commitment credit was applied at intent registration
    // [v1.99.90 / M-NEW-01] Pull-refund tracking for failed forceDeclineIntent() transfers.
    // When _externalTransfer fails, funds remain in contract. Tracked here so
    // _captureYield() does not re-inflate prizePot with them as apparent yield.
    mapping(address => uint256) public forceDeclineRefundOwed;
    uint256 public totalForceDeclineRefundOwed;

    // ═══════════════════════════════════════════════════════════════════════
    // DRAW STATE
    // ═══════════════════════════════════════════════════════════════════════

    int256[NUM_ASSETS] public weekStartPrices;
    // [v1.99.65 / L-04] winningResult = 0 is the reset sentinel. After emergencyResetDraw()
    // and before the next resolveWeek(), winningResult == 0 decodes as assets [0,0,0,0]
    // which is indistinguishable from a valid result. [v1.99.67 / L-02] Use lastResolvedDraw as primary stale signal.
    // [v1.99.67 / I-01] SUPPLEMENTARY: after emergencyResetDraw() on draw N
    // then finalizeWeek() advancing to N+1, lastResolvedDraw=N, currentDraw=N+1,
    // winningResult=0. Check: N != N -> false (not stale). But result IS stale.
    // Full check: (lastResolvedDraw != currentDraw - 1) || (winningResult == 0).
    // winningResult=0 is always invalid (four identical indices [0,0,0,0]
    // fail _validatePicks()) -- safe sentinel. No funds at risk.
    // [v1.99.65] Front-ends must check DrawPhase (RESET_FINALIZING or IDLE)
    // to determine whether winningResult is stale.
    uint32  public winningResult;         // packed ordered top-4: rank-i index at bits i*5..i*5+4
    // [v1.99.67 / L-02] Tracks the draw number of the most recently settled week.
    // Updated in resolveWeek() immediately after winningResult is set.
    // Stale-result check: if (lastResolvedDraw != currentDraw - 1) => winningResult stale.
    // EDGE CASE: before draw 1 resolves, lastResolvedDraw=0 and currentDraw=1,
    // so 0 == 1-1 -- check does NOT fire as stale. Additionally check
    // DrawPhase (IDLE = no result yet) for the pre-first-draw scenario.
    // SUPPLEMENTARY CHECK REQUIRED: after emergencyResetDraw() on draw N, then
    // finalizeWeek() advancing to draw N+1, state is lastResolvedDraw=N,
    // currentDraw=N+1, winningResult=0. Check N != N = false (not stale) but
    // winningResult IS stale. Supplement with: winningResult != 0.
    // winningResult=0 is always invalid (decodes as [0,0,0,0], four identical
    // indices fail _validatePicks()). Zero is therefore a safe sentinel.
    // Full recommended check: lastResolvedDraw != currentDraw - 1 || winningResult == 0
    // [v1.99.67 / I-01]
    uint256 public lastResolvedDraw;
    int256[NUM_ASSETS] public weekPerformance;

    uint256[4] public tierPools;
    uint256 public currentDrawSeedReturn;

    uint256 public matchOGIndex;
    uint256 public matchNonOGIndex;
    bool    public ogMatchingDone;

    uint256 public lastResetDraw;
    uint256 public emergencyUnwindIndex;
    uint256 public emergencyUnwindTotal;

    address[] public jpWinners;
    address[] public p2Winners;
    address[] public p3Winners;
    address[] public p4Winners;

    uint256 public distTierIndex;
    uint256 public distWinnerIndex;
    // [v1.99.25 / L-L-01] Valid only for the tier currently being distributed
    // (distTierIndex). Stale if the previous tier completed via TierSkippedDust
    // without setting a new value (perWinner == 0 path does not update this).
    // Off-chain tools reading this between batches should cross-check distTierIndex.
    uint256 public currentTierPerWinner; // [v1.99.44 / F2] Stale after TierSkippedDust
                                          // -- not updated when a tier is skipped (pool=0).
                                          // Off-chain tools must cross-check distTierIndex
                                          // and tierPools[] rather than reading this alone.

    // ═══════════════════════════════════════════════════════════════════════
    // CONSTRUCTOR
    // ═══════════════════════════════════════════════════════════════════════

    /// @notice Deploys the Pick432 1Y contract.
    /// @dev [Pick432 1Y v1.1 / C-03] ARBITRUM DEPLOYER:
    ///      This contract targets Arbitrum One exclusively. `_sequencerFeed` MUST be set to the
    ///      Arbitrum L2 sequencer uptime feed address (currently 0xFdB631F5EE196F0ed6FAa767959853A9F217697D).
    ///      Passing address(0) reverts with InvalidAddress() -- there is no ETH Mainnet mode for
    ///      this contract. address(0) is always wrong here. Verify the feed address against
    ///      Chainlink documentation before deployment.
    constructor(
        address _usdc,
        address _aavePool,
        address _aUSDC,
        address _charity,
        address[NUM_ASSETS] memory _priceFeeds,
        address _sequencerFeed
    ) Ownable2Step() {
        if (_usdc == address(0))           revert InvalidAddress();
        if (_aavePool == address(0))       revert InvalidAddress();
        if (_aUSDC == address(0))          revert InvalidAddress();
        if (_charity == address(0))        revert InvalidAddress();
        if (_charity == address(this))     revert InvalidAddress();
        if (_charity == _usdc)             revert InvalidAddress();
        if (_charity == _aavePool)         revert InvalidAddress();
        if (_charity == _aUSDC)            revert InvalidAddress();
        if (_usdc == _aUSDC)               revert InvalidAddress();
        // [v1.87 / AUDIT-I-01] Symmetric with SEQUENCER_FEED vs _priceFeeds added in v1.85.
        // Deploying with _aavePool = _usdc or _aUSDC would corrupt _captureYield() balance reads.
        if (_aavePool == _usdc)            revert InvalidAddress();
        if (_aavePool == _aUSDC)           revert InvalidAddress();

        for (uint256 i = 0; i < NUM_ASSETS; i++) {
            if (_priceFeeds[i] == address(0)) revert InvalidAddress();
            priceFeeds[i] = _priceFeeds[i];
        }
        for (uint256 i = 0; i < NUM_ASSETS; i++) {
            for (uint256 j = i + 1; j < NUM_ASSETS; j++) {
                if (_priceFeeds[i] == _priceFeeds[j]) revert InvalidAddress();
            }
        }

        USDC            = _usdc;
        AAVE_POOL       = _aavePool;
        aUSDC           = _aUSDC;
        CHARITY         = _charity;
        // [v1.1 / C-03] address(0) is never valid on Arbitrum. There is no ETH Mainnet mode
        // for this contract. A deployment without a valid sequencer feed is a security error.
        // [v1.99.16 / I-01] Check moved before assignment -- consistent with all other
        // zero-address guards in the constructor. Functionally identical (constructor
        // reverts atomically) but matches the established guard-then-assign pattern.
        if (_sequencerFeed == address(0)) revert InvalidAddress();
        SEQUENCER_FEED  = _sequencerFeed;
        DEPLOY_TIMESTAMP = block.timestamp;

        gamePhase    = GamePhase.PREGAME;
        drawPhase    = DrawPhase.IDLE;
        signupDeadline = block.timestamp + SIGNUP_DURATION;

        // [v1.99.11 / L-02] Infinite approval to AAVE_POOL. Revoked at all five
        // exit points: executeAaveExit(), activateAaveEmergency(), closeGame(),
        // sweepDormancyRemainder(), sweepFailedPregame(). In the event of an Aave
        // proxy compromise, activateAaveEmergency() (no timelock) revokes immediately.
        // Accepted DeFi risk: standard practice for Aave V3 integrations.
        IERC20(_usdc).approve(_aavePool, type(uint256).max);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // OWNERSHIP SAFETY
    // ═══════════════════════════════════════════════════════════════════════

    /// @notice Disabled. Ownership cannot be renounced on this contract.
    function renounceOwnership() public override onlyOwner {
        revert RenounceOwnershipDisabled();
    }

    /// @notice Initiates a two-step ownership transfer with a 7-day acceptance window.
    /// @dev [v1.76 / L-02] NOTE: calling transferOwnership() again before acceptOwnership()
    ///      resets ownershipTransferExpiry to a fresh 7 days. The acceptance window is a
    ///      sliding deadline, not a hard one -- repeated calls extend it indefinitely.
    ///      [v1.99.25 / J-INFO-01] OWNERSHIP_TRANSFER_EXPIRY == TIMELOCK_DELAY (both 7 days)
    ///      by design: owner changes carry the same deliberation window as all governance
    ///      proposals. This parity is intentional.
    function transferOwnership(address newOwner) public override onlyOwner {
        // [v1.99.25 / J-L-01] Explicit zero-address guard for consistency with all other
        // address checks in this contract. OZ would revert OwnableInvalidOwner(address(0))
        // without this, but every other guard here emits InvalidAddress().
        if (newOwner == address(0)) revert InvalidAddress();
        ownershipTransferExpiry = block.timestamp + OWNERSHIP_TRANSFER_EXPIRY;
        super.transferOwnership(newOwner);
    }

    /// @notice Completes a pending ownership transfer initiated by transferOwnership().
    /// @dev [v1.77 / L-01] NoTimelockPending guard added. Without it, calling acceptOwnership()
    ///      when no transfer is pending reverts OwnershipTransferExpired (because
    ///      ownershipTransferExpiry == 0 and block.timestamp > 0 is always true). The accurate
    ///      error when no transfer is pending is NoTimelockPending.

    function acceptOwnership() public override {
        // [v1.77 / L-01] Guard first -- prevents misleading OwnershipTransferExpired revert
        // when ownershipTransferExpiry == 0 (no pending transfer).
        if (ownershipTransferExpiry == 0) revert NoTimelockPending();
        if (block.timestamp > ownershipTransferExpiry) revert OwnershipTransferExpired();
        ownershipTransferExpiry = 0;
        super.acceptOwnership();
    }

    // ═══════════════════════════════════════════════════════════════════════
    // SIGNUP PHASE
    // ═══════════════════════════════════════════════════════════════════════

    /// @notice Registers the caller as a standard (non-OG) player.
    /// @dev [v1.78 / I-01] No drawPhase guard -- mid-draw registration is intentionally permitted.
    ///      Registration is now free and stateless -- no financial state written or read.
    ///      [v1.99.81 / STAGE1] Prepaid credit removed. ACTIVE registration requires
    ///      no payment. Player capacity is enforced at first buyTickets() call, not
    ///      at registration time. BREAKING: ACTIVE register() no longer transfers USDC.
    function register() external nonReentrant {
        if (gamePhase != GamePhase.PREGAME && gamePhase != GamePhase.ACTIVE) revert GameNotActive();
        if (players[msg.sender].registered) revert AlreadyRegistered();

        // [v1.99.75 / M-02] CEI: register state before external calls.
        // nonReentrant prevents exploitation today, but strict CEI removes
        // a latent maintenance trap in any fork that loosens the guard.
        // Covers both PREGAME (no external calls) and ACTIVE (safeTransferFrom
        // + Aave supply below). Moved from post-block position.
        players[msg.sender].registered = true;
        totalRegisteredPlayers++;
        emit PlayerRegistered(msg.sender, totalRegisteredPlayers);

        if (gamePhase == GamePhase.ACTIVE) {
            // [v1.99.81 / STAGE1] Prepaid credit system removed. ACTIVE registration
            // is now free and lightweight -- no USDC transfer at registration time.
            // Players buy tickets each draw independently via buyTickets().
            // Capacity check: total active players must not exceed MAX_PLAYERS.
            PlayerData storage pReg = players[msg.sender];
            if (pReg.isUpfrontOG || pReg.isWeeklyOG) revert AlreadyOG();
            if ((totalLifetimeBuyers > lapsedPlayerCount ? totalLifetimeBuyers - lapsedPlayerCount : 0)
                + upfrontOGCount + weeklyOGCount >= MAX_PLAYERS)
                revert MaxPlayersReached();
        }

    }


    /// @notice Registers interest in the game before the PREGAME signup window opens.
    /// @dev [v1.99.86 / NEW-I-02] @notice restored -- was present in prior versions,
    ///      dropped during Stage 1/2 refactor. No NatSpec bleed risk: function stands alone.
    function registerInterest() external {
        if (gamePhase != GamePhase.PREGAME) revert WrongPhase();
        PlayerData storage p = players[msg.sender];
        if (p.registeredInterest) revert AlreadyRegisteredInterest();
        if (p.commitmentPaid || p.isUpfrontOG || p.isWeeklyOG) revert AlreadyCommitted();
        // [v2.75 I-01] Block PENDING/OFFERED intent players from re-registering interest.
        // registerAsOG() clears registeredInterest but not ogIntentStatus, so without this
        // guard they could call registerInterest() again and inflate interestedCount.
        if (ogIntentStatus[msg.sender] == OGIntentStatus.PENDING
            || ogIntentStatus[msg.sender] == OGIntentStatus.OFFERED)
            revert AlreadyInIntentQueue();

        p.registeredInterest = true;
        if (!p.registered) {
            p.registered = true;
            totalRegisteredPlayers++;
            emit PlayerRegistered(msg.sender, totalRegisteredPlayers);
        }
        interestedCount++;
        emit InterestRegistered(msg.sender, interestedCount);
    }

    /// @notice Pays a one-ticket commitment fee during PREGAME to reserve a player slot.
    /// @dev [v1.99.17 / I-01] PENDING+commitment double-increment edge case:
    ///      A player who calls registerAsOG() (increments committedPlayerCount, sets
    ///      ogIntentStatus = PENDING) then calls payCommitment() will increment
    ///      committedPlayerCount a second time and set commitmentPaid = true.
    ///      This leaves a ghost pendingIntentCount entry that blocks startGame().
    ///      Resolution: owner calls forceDeclineIntent([player]) -- returns 100% of
    ///      the intent deposit and decrements pendingIntentCount, unblocking launch.
    ///      Economic cost to attacker: ~$1,040 OG intent + $10 commitment with zero
    ///      benefit. Not a practical attack; documented for audit submission.
    function payCommitment() external nonReentrant {
        if (gamePhase != GamePhase.PREGAME) revert WrongPhase();
        if (block.timestamp >= signupDeadline) revert PregameWindowExpired();
        PlayerData storage p = players[msg.sender];
        if (!p.registered) revert NotRegistered();
        if (p.isUpfrontOG || p.isWeeklyOG) revert AlreadyOG();
        if (p.commitmentPaid) revert AlreadyCommitted();
        // [v1.99.20] Prevent double-increment: a player with PENDING or OFFERED
        // intent would re-increment committedPlayerCount, creating a ghost entry
        // that blocks startGame(). forceDeclineIntent() resolves, but prevention
        // is cleaner. DECLINED/SWEPT players are already OGs or resolved.
        if (ogIntentStatus[msg.sender] == OGIntentStatus.PENDING ||
            ogIntentStatus[msg.sender] == OGIntentStatus.OFFERED)
            revert AlreadyInIntentQueue();
        if (committedPlayerCount >= MAX_PLAYERS) revert MaxPlayersReached();

        uint256 cost  = TICKET_PRICE;
        uint256 treasurySlice = cost * TREASURY_BPS / 10000;
        treasuryBalance += treasurySlice;
        prizePot        += cost - treasurySlice;
        p.totalPaid      += cost;
        p.commitmentPaid  = true;
        committedPlayerCount++;
        if (p.registeredInterest) {
            interestedCount--;
            p.registeredInterest = false;
        }

        IERC20(USDC).safeTransferFrom(msg.sender, address(this), cost);
        if (!aaveExited) {
            // [v1.99.11 / M-01] try/catch: if Aave supply is paused/frozen, hold as USDC.
            // Call activateAaveEmergency() if this persists.
            try IPool(AAVE_POOL).supply(USDC, cost, address(this), 0) {}
            catch { emit AaveSupplyFailed(cost); }
        }
        emit TreasuryAccrual(0, treasurySlice, TREASURY_BPS);
        emit CommitmentPaid(msg.sender, cost);
    }

    /// @notice Registers the caller as an Upfront OG.
    /// @dev [v2.67] PREGAME: enters the caller into the OG intent queue. Payment taken immediately.
    ///      Full OG status is NOT granted yet. Owner calls confirmOGSlots() to offer slots in
    ///      FIFO queue order (approximately registration-timestamp order). Caller has OG_INTENT_WINDOW
    ///      (72 hours) from confirmation to decline via claimOGIntentRefund(). If no decline,
    ///      OG status is permanent after the window.
    ///      A player who has previously declined an intent (status DECLINED) cannot re-enter the queue.
    ///      [v2.0] ACTIVE: direct registration is closed. Calling this function in ACTIVE
    ///      reverts WrongPhase(). [v1.99.14 / C-01]
    ///      [v2.03 / NS-v2.02-05 / I-v2.02-01] ERROR ORDERING: _validatePicks() is called inside
    ///      the PREGAME block only. ACTIVE callers always receive WrongPhase() at the trailing
    ///      revert regardless of picks validity. Prior versions called _validatePicks() before
    ///      the phase branch, meaning an ACTIVE caller with invalid picks got InvalidPicks()
    ///      instead of WrongPhase() -- a misleading diagnostic.
    function registerAsOG(uint32 picks) external nonReentrant {
        if (gamePhase != GamePhase.PREGAME && gamePhase != GamePhase.ACTIVE) revert GameNotActive();
        if (drawPhase != DrawPhase.IDLE) revert DrawInProgress();

        PlayerData storage p = players[msg.sender];
        if (p.isUpfrontOG || p.isWeeklyOG) revert AlreadyOG();
        if (p.dormancyRefunded) revert AlreadyRefunded();

        // ---- PREGAME: intent queue path [v2.67] ----
        if (gamePhase == GamePhase.PREGAME) {
            // [v2.03 / I-v2.02-01] _validatePicks moved here so ACTIVE callers always
            // receive WrongPhase() at the trailing revert regardless of picks validity.
            _validatePicks(picks);
            // [v1.99.75 / I-05] signupDeadline guard mirrors payCommitment().
            // Without this, registerAsOG() accepts new OG registrations after
            // the signup window closes, inconsistent with all other PREGAME
            // entry functions. One-line fix, zero financial risk.
            if (block.timestamp >= signupDeadline) revert PregameWindowExpired();
            // [v1.99.31 / L-02] Block during notice window. Use ActiveDeclineWindowOpen
            // not TimelockPending -- the latter implies a governance timelock which
            // would confuse players. Notice period IS an active window concern.
            // New PENDINGs cannot be processed (confirmOGSlots also blocked).
            if (startGameProposedAt != 0) revert ActiveDeclineWindowOpen();
            if (ogIntentStatus[msg.sender] != OGIntentStatus.NONE) revert AlreadyInIntentQueue();
            if (ogIntentQueue.length >= OG_INTENT_HARD_CAP) revert IntentQueueFull();
            if (committedPlayerCount >= MAX_PLAYERS) revert MaxPlayersReached();

            if (!p.registered) {
                p.registered = true;
                totalRegisteredPlayers++;
                emit PlayerRegistered(msg.sender, totalRegisteredPlayers);
            }

            bool usingOGCredit = p.commitmentPaid;
            uint256 ogCredit   = usingOGCredit ? TICKET_PRICE : 0;
            uint256 ogTransfer = OG_UPFRONT_COST - ogCredit;

            if (usingOGCredit) p.commitmentPaid = false;
            uint256 treasurySlice = ogTransfer * OG_TREASURY_BPS / 10000;
            treasuryBalance += treasurySlice;
            prizePot        += ogTransfer - treasurySlice;
            p.totalPaid     += ogTransfer;
            p.picks          = picks;

            ogIntentStatus[msg.sender]     = OGIntentStatus.PENDING;
            ogIntentAmount[msg.sender]     = ogTransfer;
            ogIntentUsedCredit[msg.sender] = usingOGCredit;
            ogIntentQueue.push(msg.sender);
            pendingIntentCount++;

            // Only increment committedPlayerCount if not already counted via commitment payment.
            // (If usingOGCredit: commitmentPaid was true = already counted in committedPlayerCount.)
            if (!usingOGCredit) committedPlayerCount++;

            IERC20(USDC).safeTransferFrom(msg.sender, address(this), ogTransfer);
            if (!aaveExited) {
            // [v1.99.11 / M-01] try/catch: if Aave supply is paused/frozen, hold as USDC.
            // Call activateAaveEmergency() if this persists.
            try IPool(AAVE_POOL).supply(USDC, ogTransfer, address(this), 0) {}
            catch { emit AaveSupplyFailed(ogTransfer); }
            }
            emit TreasuryAccrual(0, treasurySlice, OG_TREASURY_BPS);

            if (p.registeredInterest) {
                interestedCount--;
                p.registeredInterest = false;
            }

            emit OGIntentRegistered(msg.sender, ogIntentQueue.length - 1, ogTransfer);
            return;
        }

        // ---- ACTIVE: weekly OG upgrade path only ----
        // [v2.0] Direct upfront OG registration in ACTIVE is closed.
        // PREGAME intent queue remains available above and is unchanged.
        // WrongPhase() correctly signals the registration window is closed.
        revert WrongPhase();
    }

    // ═══════════════════════════════════════════════════════════════════════
    // OG INTENT QUEUE  [v2.67]
    // ═══════════════════════════════════════════════════════════════════════

    /// @notice Processes pending OG intent entries in timestamp order, granting full OG status
    ///         to each up to the BPS cap. Each confirmed player gets a 72-hour window to decline.
    /// @dev PREGAME only. Capped by _upfrontOGCapReached(). Safe to call multiple times.
    ///      Processes the queue in FIFO order (approximately registration-timestamp order).
    ///      If cap is reached mid-batch the loop stops without advancing ogIntentQueueHead past
    ///      the blocked entry. Owner can call again later when committedPlayerCount has grown
    ///      and the BPS cap has widened.
    ///      Non-PENDING entries (OFFERED, DECLINED, SWEPT) are skipped automatically.
    ///      Note: sweepExpiredDeclines() is PREGAME-only. OFFERED players whose 72-hour window
    ///      expires after startGame() are never marked SWEPT; their OG status is permanent regardless.
    ///      [v2.78] Emits UpfrontOGRegistered when OG status is granted — canonical upfront OG signal.
    ///      OGIntentOffered is emitted alongside it to signal the 72-hour decline window opening.
    ///      [v1.99.8 / M-02] PENDING+isWeeklyOG griefing note: a player who registers as weekly OG
    ///      then queues an OG intent creates a PENDING entry skipped by confirmOGSlots() without
    ///      decrementing pendingIntentCount. startGame() reverts if pendingIntentCount > 0.
    ///      Resolution: forceDeclineIntent() (owner-only, 100% refund) in batches of 100.
    ///      Worst-case recovery: OG_INTENT_HARD_CAP (5,000) / 100 = 50 owner transactions.
    ///      Economic attack cost: 5,000 x ~$1,030 = ~$5.15M. Not a practical attack vector.
    ///      OG_INTENT_HARD_CAP is the primary on-chain mitigation.
    ///      [v1.99.72 / P6-NEW-LOW-01] CENTRALIZATION DISCLOSURE: confirmOGSlots()
    ///      is onlyOwner. Players cannot force processing of their PENDING intent.
    ///      An operator could selectively confirm or delay indefinitely. Economic
    ///      incentive to abuse is low: treasury accrues 15% of OG payments and
    ///      OG participation strengthens the pot. Permissioned by design.
    /// @param batchSize Maximum number of slots to confirm in this call.
    function confirmOGSlots(uint256 batchSize) external onlyOwner {
        if (gamePhase != GamePhase.PREGAME) revert WrongPhase();
        if (drawPhase != DrawPhase.IDLE) revert DrawInProgress();
        // [v1.99.30] Block new OG confirmations during the launch notice window.
        // Confirming new batches during the 72-hr countdown would extend decline
        // windows beyond game launch. Owner must cancel proposal first if needed.
        if (startGameProposedAt != 0) revert TimelockPending();
        // [v1.71 / L-05] Belt-and-suspenders upper bound. Owner-only but sloppy unbounded input is bad hygiene.
        if (batchSize > 1000) revert ExceedsLimit();
        uint256 confirmed = 0;
        while (ogIntentQueueHead < ogIntentQueue.length && confirmed < batchSize) {
            address player = ogIntentQueue[ogIntentQueueHead];
            OGIntentStatus status = ogIntentStatus[player];

            if (status == OGIntentStatus.PENDING) {
                if (_upfrontOGCapReached()) break; // cap full: leave head here, stop loop
                // [v2.73 M-01] Backstop: if this player somehow registered as weekly OG after
                // entering the intent queue, granting upfront OG would create a dual ogList entry.
                // Skip without changing intent status so they retain the claimOGIntentRefund() path.
                PlayerData storage p = players[player];
                if (p.isWeeklyOG) {
                    // Slot silently skipped. Player retains PENDING status and claimOGIntentRefund() path.
                    // Primary guard in registerAsWeeklyOG() means this branch fires only if that guard
                    // is somehow bypassed. Absence of OGIntentOffered event signals the skip to monitors.
                    // [v1.72 / L-05] RUNBOOK updated: pendingIntentCount is NOT decremented here.
                    // If this branch fires, startGame() will revert on IntentQueueNotEmpty.
                    // Resolution: owner calls forceDeclineIntent([player]) -- 100% refund, unblocks launch.
                    // Alternative: player self-exits via claimOGIntentRefund() (85% returned, 15% kept).
                    ogIntentQueueHead++;
                    continue;
                }
                // Grant full OG status
                ogListIndex[player] = ogList.length;
                ogList.push(player);
                p.isUpfrontOG = true;
                upfrontOGCount++;
                // [v1.99.6 / AUDIT-M-01] Use actual payment not constant.
                // Credit-path OGs paid OG_UPFRONT_COST - TICKET_PRICE ($1,030).
                // Using the constant overstates the denominator by $10 per credit-path OG.
                totalOGPrincipal += ogIntentAmount[player];
                // Open decline window
                ogIntentStatus[player]       = OGIntentStatus.OFFERED;
                ogIntentWindowExpiry[player] = block.timestamp + OG_INTENT_WINDOW;
                // [v1.99.30] Track most recent offer for proposeStartGame() buffer check.
                latestOfferTimestamp = block.timestamp;
                pendingIntentCount--;
                confirmed++;
                // [v2.0] UpfrontOGRegistered is the canonical signal that an address
                // has been granted confirmed upfront OG status. Emitted here (PREGAME intent
                // queue path only -- no ACTIVE upgrade path exists in v2.0).
                // OGIntentOffered signals the 72-hour decline window — a separate concern.
                emit UpfrontOGRegistered(player, p.picks, upfrontOGCount);
                emit OGIntentOffered(player, ogIntentWindowExpiry[player]);
            }
            // Advance past this entry whether just confirmed or already non-PENDING
            ogIntentQueueHead++;
        }
        emit OGSlotsConfirmed(confirmed, pendingIntentCount);
    }

    /// @notice Voluntarily exits the OG intent queue and claims a partial refund.
    /// @dev [v1.99.24] VOLUNTARY EXIT -- PREGAME only. Two eligible statuses:
    ///      PENDING: OG status was never granted. 85% net return (15% commitment deposit kept).
    ///      OFFERED: OG status was granted but player declines within the 72-hour
    ///        ogIntentWindowExpiry window. Reverses OG status grant.
    ///      REFUND SPLIT: player receives 85% (netRefund). The 15% treasury slice
    ///      (OG_TREASURY_BPS = 1500 bps) is kept permanently -- it was recorded
    ///      in treasuryBalance at registration. Prize pot contribution (netAmount)
    ///      is returned to the player from prizePot.
    ///      DEFICIT GUARD: if prizePot < netRefund (extreme edge case), the deficit
    ///      is pulled from treasuryBalance rather than reverting.
    ///      CEI: all state mutations fire before the transfer.
    function claimOGIntentRefund() external nonReentrant {
        if (gamePhase != GamePhase.PREGAME) revert WrongPhase();

        OGIntentStatus status = ogIntentStatus[msg.sender];
        if (status != OGIntentStatus.PENDING && status != OGIntentStatus.OFFERED) revert NoIntentPending();
        if (status == OGIntentStatus.OFFERED
            && block.timestamp > ogIntentWindowExpiry[msg.sender]) revert IntentWindowExpired();

        _captureYield();

        PlayerData storage p = players[msg.sender];
        uint256 amount = ogIntentAmount[msg.sender];

        // State mutations before any transfer (CEI)
        ogIntentStatus[msg.sender] = OGIntentStatus.DECLINED;
        ogIntentAmount[msg.sender] = 0;
        p.totalPaid = 0;
        p.picks     = 0;

        if (status == OGIntentStatus.OFFERED) {
            // confirmOGSlots granted OG status: reverse it
            // [v1.99.6 / AUDIT-M-01] Use `amount` local var (= ogIntentAmount pre-zero).
            // Symmetric with confirmOGSlots increment which now uses ogIntentAmount[player].
            if (totalOGPrincipal >= amount) totalOGPrincipal -= amount;
            else totalOGPrincipal = 0;
            p.isUpfrontOG = false;
            // [v1.81 / I-02] Guard consistent with all other decrement sites.
            if (upfrontOGCount > 0) upfrontOGCount--;
            // [v1.99.35] Defensive guard matching _cleanupOGOnRefund() v1.99.21.
            // Invariant holds (confirmOGSlots only OFFERED after ogList push) but
            // explicit guard prevents underflow revert that would lock player funds.
            uint256 ogLen = ogList.length;
            if (ogLen > 0 && ogListIndex[msg.sender] < ogLen &&
                ogList[ogListIndex[msg.sender]] == msg.sender) {
                uint256 idx  = ogListIndex[msg.sender];
                uint256 last = ogLen - 1;
                if (idx != last) {
                    address lastAddr = ogList[last];
                    ogList[idx]          = lastAddr;
                    ogListIndex[lastAddr] = idx;
                }
                ogList.pop();
                delete ogListIndex[msg.sender];
            }
            // pendingIntentCount was already decremented in confirmOGSlots
        } else {
            // PENDING: OG status was never granted
            pendingIntentCount--;
        }

        // [v1.99.61 / M-01] committedPlayerCount decremented unconditionally.
        // Credit-path players (ogIntentUsedCredit=true) had committedPlayerCount
        // incremented by payCommitment() before registerAsOG(). That increment must
        // be reversed exactly once on exit regardless of which path was used.
        // The prior !ogIntentUsedCredit gate was the source of the ghost-count bug:
        // symmetric to the v1.84/AUDIT-I-01 fix in claimSignupRefund() PENDING path.
        if (committedPlayerCount > 0) committedPlayerCount--;

        // [v2.81] COMMITMENT DEPOSIT: treasury slice is kept. Player receives 85% of ogTransfer.
        // treasuryBalance already holds the slice from registration — no movement needed for it.
        // Only the net (prize-pot portion) is returned to the player.
        // Registration flow: treasuryBalance += slice, prizePot += netAmount.
        // Exit flow:         prizePot -= netAmount → player receives netAmount.
        // treasuryBalance:   unchanged — slice stays permanently.
        uint256 depositKept = amount * OG_TREASURY_BPS / 10000;
        uint256 netRefund   = amount - depositKept;

        // [v2.68 L-01] Guard: if prizePot < netRefund (extreme edge — concurrent yield anomaly
        // or successive refunds draining pot), pull deficit from treasury rather than reverting.
        if (prizePot >= netRefund) {
            prizePot -= netRefund;
        } else {
            uint256 deficit = netRefund - prizePot;
            prizePot = 0;
            if (treasuryBalance >= deficit) {
                treasuryBalance -= deficit;
            } else {
                treasuryBalance = 0; // absolute safety floor
            }
        }

        _withdrawAndTransfer(msg.sender, netRefund);
        emit OGIntentDeclined(msg.sender, netRefund, amount, depositKept);
    }

    /// @notice Closes expired decline windows, permanently confirming OG status for non-responders.
    /// @dev PREGAME only. No fund movement. Housekeeping only: marks OFFERED -> SWEPT.
    ///      Players in SWEPT state are confirmed OGs with no further claim path via this queue.
    ///      Safe to call with an empty or already-swept list (skips gracefully).
    ///      ogIntentAmount is intentionally retained as a historical record of what was paid.
    ///      ogIntentWindowExpiry is cleared to avoid misleading off-chain tooling.
    ///      Limitation: if startGame() is called before all OFFERED windows expire, those players
    ///      will remain in OFFERED status permanently (never SWEPT). This is cosmetic only: OG
    ///      status is already granted and unaffected by the missing SWEPT label.
    ///      [v1.99.8 / L-03] Off-chain indexer note: a non-zero ogIntentWindowExpiry for an
    ///      OFFERED player post-startGame does NOT indicate an open refund option. The window
    ///      is stale. Indexers must treat OFFERED status as permanent OG confirmation once
    ///      gamePhase == ACTIVE. Do not present a refund call-to-action for these players.
    /// @param players_ Addresses to sweep.
    function sweepExpiredDeclines(address[] calldata players_) external onlyOwner {
        if (gamePhase != GamePhase.PREGAME) revert WrongPhase();
        for (uint256 i = 0; i < players_.length; i++) {
            address player = players_[i];
            if (ogIntentStatus[player] != OGIntentStatus.OFFERED) continue;
            if (block.timestamp <= ogIntentWindowExpiry[player]) continue;
            ogIntentStatus[player]       = OGIntentStatus.SWEPT;
            ogIntentWindowExpiry[player] = 0;  // [v2.68] I-02: clear stale expiry timestamp
            emit OGIntentSwept(player);
        }
    }

    /// @notice Owner-callable escape valve: force-declines one or more PENDING or OFFERED
    ///         intent queue entries, unblocking startGame() if a stuck player refuses to self-exit.
    /// @dev [v1.71] PRIMARY USE CASE -- PENDING+isWeeklyOG stuck state:
    ///      A player can register intent (PENDING) then register as weekly OG. confirmOGSlots()
    ///      skips PENDING+isWeeklyOG players silently and does NOT decrement pendingIntentCount.
    ///      startGame() requires pendingIntentCount == 0. Without this function, a stuck player
    ///      (griefing, lost wallet, or simply unresponsive) can hold the entire game hostage
    ///      indefinitely. The only prior escape was off-chain contact + player self-exit.
    ///
    ///      REFUND: 100% of ogIntentAmount[player] is returned. This is owner-FORCED, not
    ///      voluntary -- the player did nothing wrong by ending up in this state. Unlike
    ///      claimOGIntentRefund() which keeps 15% as a commitment deposit, this function
    ///      pulls from both prizePot (85% portion) and treasuryBalance (15% portion) to make
    ///      the player whole. Safety floors prevent reverts if either pool is unexpectedly low.
    ///      [v1.72 / I-01] NOTE on commitment credit: if the player applied a prior $10 commitment
    ///      fee as credit at OG registration, that $10 reduced their ogTransfer and is NOT included
    ///      in ogIntentAmount. The refund here returns 100% of ogIntentAmount -- the $10 commitment
    ///      fee is a separate prior payment and is not restored by this function.
    ///
    ///      ALSO handles OFFERED players (within or after their 72-hour window) -- reverses
    ///      OG status, removes from ogList via swap-and-pop, decrements upfrontOGCount.
    ///
    ///      PREGAME only. Batch-bounded at 100. Emits OGIntentForcedDeclined (distinct from
    ///      voluntary OGIntentDeclined so indexers can distinguish).
    ///
    ///      Addresses not in PENDING or OFFERED status are skipped silently.
    ///      [v1.99.90 / M-NEW-01] FAILED TRANSFER RUNBOOK: if _externalTransfer
    ///      throws, funds remain in the contract tracked in forceDeclineRefundOwed.
    ///      Player calls claimForceDeclineRefund() to recover. Do NOT use
    ///      withdrawTreasury() to compensate manually -- the funds are still
    ///      in the contract balance and the pull mapping is still active.
    ///      Manual treasury payment would double-pay the player.
    ///      totalForceDeclineRefundOwed prevents _captureYield re-inflation.
    /// @param players_ Addresses to force-decline.
    function forceDeclineIntent(address[] calldata players_) external onlyOwner nonReentrant {
        if (gamePhase != GamePhase.PREGAME) revert WrongPhase();
        if (players_.length == 0) revert BelowMinimum();
        if (players_.length > 100) revert ExceedsLimit();
        // [v1.74 / Knock-on 1] breathRails cancel block removed. proposeBreathRails() is
        // ACTIVE-only; this function is PREGAME-only. breathRailsEffectiveTime cannot be
        // non-zero in PREGAME so the block was unreachable dead code. Cancel is retained
        // in proposeDormancy() where both functions are ACTIVE and the condition IS reachable.

        for (uint256 i = 0; i < players_.length; i++) {
            address player    = players_[i];
            OGIntentStatus status = ogIntentStatus[player];

            if (status != OGIntentStatus.PENDING && status != OGIntentStatus.OFFERED) continue;

            uint256 amount        = ogIntentAmount[player];
            PlayerData storage p  = players[player];

            // ── CEI: state changes before transfer ──────────────────────────
            ogIntentStatus[player] = OGIntentStatus.DECLINED;
            ogIntentAmount[player] = 0;
            p.totalPaid            = 0;
            p.picks                = 0;

            if (status == OGIntentStatus.OFFERED) {
                // Reverse OG status granted by confirmOGSlots()
                // [v1.99.6 / AUDIT-M-01] Use `amount` local var (= ogIntentAmount pre-zero).
                // Symmetric with confirmOGSlots increment.
                if (totalOGPrincipal >= amount) totalOGPrincipal -= amount;
                else totalOGPrincipal = 0;
                p.isUpfrontOG = false;
                // [v1.72 / L-02] Guard consistent with all other decrement sites in contract.
                if (upfrontOGCount > 0) upfrontOGCount--;
                // [v1.99.35] Defensive guard matching _cleanupOGOnRefund() v1.99.21.
                uint256 ogLen_ = ogList.length;
                if (ogLen_ > 0 && ogListIndex[player] < ogLen_ &&
                    ogList[ogListIndex[player]] == player) {
                    uint256 idx  = ogListIndex[player];
                    uint256 last = ogLen_ - 1;
                    if (idx != last) {
                        address lastAddr     = ogList[last];
                        ogList[idx]          = lastAddr;
                        ogListIndex[lastAddr] = idx;
                    }
                    ogList.pop();
                    delete ogListIndex[player];
                } // [v1.99.36 / F4] close defensive guard
                // [v1.72 / L-03] Clear stale expiry timestamp -- mirrors claimOGIntentRefund() and
                // sweepExpiredDeclines(). Off-chain tooling reading this for a DECLINED player would
                // otherwise see a non-zero timestamp and misclassify them.
                ogIntentWindowExpiry[player] = 0;
                // pendingIntentCount was already decremented in confirmOGSlots for OFFERED
            } else {
                // PENDING: decrement pendingIntentCount to unblock startGame()
                if (pendingIntentCount > 0) pendingIntentCount--;
            }

            // [v1.99.61 / M-01] Unconditional decrement -- mirrors claimOGIntentRefund fix.
            if (committedPlayerCount > 0) committedPlayerCount--;

            // ── 100% REFUND: pull pot portion then treasury portion ──────────
            // At registration: prizePot received 85%, treasury 15%.
            // Return both portions since this is owner-forced, not voluntary.
            uint256 refund = amount;
            if (refund > 0) {
                if (prizePot >= refund) {
                    prizePot -= refund;
                } else {
                    // [v1.72 / M-01] Snapshot availablePot BEFORE zeroing prizePot.
                    // Prior bug: refund = prizePot + treasuryBalance after both zeroed = 0.
                    uint256 availablePot = prizePot;
                    uint256 fromTreasury = refund - availablePot;
                    prizePot             = 0;
                    if (treasuryBalance >= fromTreasury) {
                        treasuryBalance -= fromTreasury;
                    } else {
                        refund          = availablePot + treasuryBalance; // pay what we can
                        treasuryBalance = 0;
                    }
                }
                // [v1.72 / L-01] try/catch: single Aave failure must not revert the whole batch.
                // State is already cleaned (DECLINED, ogList updated, counts fixed) regardless of
                // transfer outcome. If transfer fails, emit OGIntentForceDeclineFailed so owner
                // can arrange off-chain refund. This player will NOT be re-processable (status=DECLINED).
                try this._externalTransfer(player, refund) {
                    // success -- emit below
                } catch {
                    // [v1.99.90 / M-NEW-01] Store owed amount in pull mapping; do NOT let
                    // _captureYield() re-inflate prizePot with these funds.
                    // The funds remain in the contract balance and the pull mapping
                    // is still active. Manual treasury payment would double-pay the player.
                    // totalForceDeclineRefundOwed prevents _captureYield re-inflation.
                    forceDeclineRefundOwed[player] += refund;
                    totalForceDeclineRefundOwed += refund;
                    emit OGIntentForceDeclineFailed(player, refund);
                    continue;
                }
            }

            emit OGIntentForcedDeclined(player, refund, amount);
        }
    }

    /// @dev [v1.72 / L-01] External wrapper enabling try/catch in forceDeclineIntent().
    ///      Solidity only allows try/catch on external calls. onlySelf guard prevents misuse.
    ///      [v1.73 / L-03] REENTRANCY NOTE: This function has no nonReentrant guard intentionally.
    ///      It is protected by two layers: (a) the onlySelf guard means only this contract can call
    ///      it, and (b) forceDeclineIntent() -- its only caller -- IS nonReentrant. Any reentrant
    ///      path through _externalTransfer would have to re-enter forceDeclineIntent(), which is
    ///      blocked by the ReentrancyGuard. No additional guard needed here.
    ///      [v1.73 / I-04] ABI VISIBILITY: This function appears in the contract ABI with an
    ///      underscore prefix. The onlySelf guard makes it uncallable by anyone except address(this).
    ///      The external visibility is required by Solidity's try/catch mechanism. There is no
    ///      security risk -- any external call reverts immediately on the onlySelf check.
    function _externalTransfer(address recipient, uint256 amount) external {
        if (msg.sender != address(this)) revert OwnableUnauthorizedAccount(msg.sender);
        _withdrawAndTransfer(recipient, amount);
    }

    /// @notice Claims a force-decline refund owed by a failed forceDeclineIntent() transfer.
    /// @dev [v1.99.90 / M-NEW-01] Callable in any phase -- the mapping entry is the
    ///      sole eligibility check. prizePot was decremented at force-decline time.
    ///      Pull claim withdraws from contract balance. CEI: mapping zeroed before transfer.
    ///      On a failed game: call this before sweepFailedPregame() sweeps the balance.
    function claimForceDeclineRefund() external nonReentrant {
        uint256 owed = forceDeclineRefundOwed[msg.sender];
        if (owed == 0) revert NothingToClaim();
        forceDeclineRefundOwed[msg.sender] = 0;
        // [v1.99.90 / M-NEW-01] Keep aggregate in sync before transfer.
        if (totalForceDeclineRefundOwed >= owed) totalForceDeclineRefundOwed -= owed;
        else totalForceDeclineRefundOwed = 0;
        _withdrawAndTransfer(msg.sender, owed);
        emit ForceDeclineRefundClaimed(msg.sender, owed);
    }

    /// @notice Registers the caller as a Weekly OG, paying TICKET_PRICE * MIN_TICKETS_WEEKLY_OG.
    /// @dev [v2.0] PREGAME-only. Weekly OG registration is not permitted in ACTIVE phase.
    ///      All weekly OGs play from draw 1 with a full 52-draw commitment.
    ///      Payment: total cost = TICKET_PRICE * MIN_TICKETS_WEEKLY_OG ($20). If the caller paid
    ///      a $10 commitment fee, that is credited and only the shortfall ($10) transfers fresh.
    ///      Intent queue conflict guard: PENDING or OFFERED players are blocked to prevent dual
    ///      ogList entry (would produce double prizes on every processMatches() call).
    ///      No upgrade path exists -- weekly OGs remain weekly OGs for the full game.
    function registerAsWeeklyOG(uint32 picks) external nonReentrant {
        if (gamePhase != GamePhase.PREGAME) revert WrongPhase();
        if (drawPhase != DrawPhase.IDLE) revert DrawInProgress();
        // [v1.99.31 / L-01] Block during notice window for consistency with
        // registerAsOG(). New weekly OGs would shift ogRatioBps at startGame()
        // without being included in any pre-launch OG ratio communication.
        if (startGameProposedAt != 0) revert ActiveDeclineWindowOpen();
        // [v1.99.76 / P9-NEW-LOW-01] signupDeadline guard mirrors payCommitment()
        // and registerAsOG() (v1.99.75/I-05). Without this, weekly OGs could
        // register after the nominal signup window, silently shifting ogRatioBps
        // used at draw 7 breath calibration without being in any pre-launch
        // OG ratio communication. All three PREGAME entry functions now consistent.
        if (block.timestamp >= signupDeadline) revert PregameWindowExpired();

        PlayerData storage p = players[msg.sender];
        if (p.isUpfrontOG || p.isWeeklyOG) revert AlreadyOG();
        if (p.dormancyRefunded) revert AlreadyRefunded();
        // [v2.73 M-01] Block players with a live intent queue entry.
        if (ogIntentStatus[msg.sender] == OGIntentStatus.PENDING
            || ogIntentStatus[msg.sender] == OGIntentStatus.OFFERED)
            revert AlreadyInIntentQueue();
        if (_weeklyOGCapReached()) revert OGCapReached();
        if (committedPlayerCount >= MAX_PLAYERS) revert MaxPlayersReached();

        if (!p.registered) {
            p.registered = true;
            totalRegisteredPlayers++;
            emit PlayerRegistered(msg.sender, totalRegisteredPlayers);
        }

        _validatePicks(picks);

        uint256 cost = TICKET_PRICE * MIN_TICKETS_WEEKLY_OG;
        bool usingPreCommitment = p.commitmentPaid;
        uint256 creditAmount = usingPreCommitment ? TICKET_PRICE : 0;
        uint256 transferCost = cost - creditAmount;

        if (transferCost > 0) {
            uint256 tSlice = transferCost * TREASURY_BPS / 10000;
            treasuryBalance += tSlice;
            prizePot        += transferCost - tSlice;
            emit TreasuryAccrual(0, tSlice, TREASURY_BPS);
        }

        p.isWeeklyOG      = true;
        p.totalPaid      += transferCost;
        p.lastTicketCount = MIN_TICKETS_WEEKLY_OG;
        p.lastTicketCost  = cost;
        p.picks           = picks;
        p.lastBoughtDraw   = 1;
        p.consecutiveWeeks = 1;
        p.lastActiveWeek   = 1;
        p.firstPlayedDraw  = 1;

        if (usingPreCommitment) {
            p.commitmentPaid = false;
        } else {
            committedPlayerCount++;
        }

        // pregameWeeklyOGTicketTotal: full $20 face value for display accuracy.
        // pregameWeeklyOGNetTotal: net contribution only (no credit double-count).
        uint256 pregameOGNet = transferCost * (10000 - TREASURY_BPS) / 10000;
        // [v1.99.1] Store exact net added for symmetric cleanup in _cleanupOGOnRefund().
        // Credit-path players add $8.50; non-credit add $17.00. Without this field, cleanup
        // always subtracts $17.00, eroding pregameWeeklyOGNetTotal by $8.50 per credit refund.
        p.pregameOGNetContributed = pregameOGNet;
        pregameWeeklyOGTicketTotal += cost;
        pregameWeeklyOGNetTotal    += pregameOGNet;

        // [v1.99.8 / M-01] Track OG principal at face value ($20), not net pot contribution.
        // Credit-path weekly OGs paid $10 commitment (net $8.50 to pot) + $10 transfer
        // (net $8.50 to pot) = $17 net. Face value $20 is used for dormancy proportional
        // formula because p.totalPaid tracks face value and the formula requires
        // totalOGPrincipal = sum(p.totalPaid) for all active OGs to hold exactly.
        // Consequence: at dormancy, a credit-path weekly OG receives $20 back even
        // though they contributed $17 net. The $3 delta is absorbed by pot yield and
        // casual revenue -- never other players' principal. Maximum exposure:
        // TICKET_PRICE ($10) per credit-path weekly OG across the cohort.
        // This is accepted design: face-value tracking is simpler, the delta is small,
        // and DeFi players generally expect zero recovery from a dormant game.
        // The four-step model is already dramatically more protective than the norm.
        totalOGPrincipal += cost;

        ogListIndex[msg.sender] = ogList.length;
        ogList.push(msg.sender);
        weeklyOGCount++;
        earnedOGCount++;
        if (p.registeredInterest) {
            interestedCount--;
            p.registeredInterest = false;
        }

        if (transferCost > 0) {
            IERC20(USDC).safeTransferFrom(msg.sender, address(this), transferCost);
            if (!aaveExited) {
            // [v1.99.11 / M-01] try/catch: if Aave supply is paused/frozen, hold as USDC.
            // Call activateAaveEmergency() if this persists.
            try IPool(AAVE_POOL).supply(USDC, transferCost, address(this), 0) {}
            catch { emit AaveSupplyFailed(transferCost); }
            }
        }

        emit WeeklyOGRegistered(msg.sender, picks, 1);
    }

    /// @notice Sets up to NUM_RESERVES (6) fallback Chainlink price feeds for reserve assets.
    /// @dev [v1.99.23 / G-INFO-01] GREEDY CONSUMPTION ORDER: at startGame(), reserve feeds
    ///      are consumed in array order across all failing primary feeds. The first failing
    ///      primary asset takes reserveFeeds[0], the second takes reserveFeeds[1], etc.
    ///      There is no guaranteed pairing between specific primaries and specific reserves.
    ///      Operators should place the most reliable fallback feeds at lower array indices.
    function setReserveFeeds(address[NUM_RESERVES] calldata _reserveFeeds) external onlyOwner {
        if (gamePhase != GamePhase.PREGAME) revert WrongPhase();
        for (uint256 i = 0; i < NUM_RESERVES; i++) {
            if (_reserveFeeds[i] == address(0)) continue;
            if (_reserveFeeds[i] == USDC)             revert InvalidAddress();
            if (_reserveFeeds[i] == aUSDC)            revert InvalidAddress();
            if (_reserveFeeds[i] == address(this))    revert InvalidAddress();
            // [v1.85 / AUDIT-I-01] Consistent with proposeFeedChange() hardened in v1.82.
            if (_reserveFeeds[i] == SEQUENCER_FEED)   revert InvalidAddress();
            for (uint256 j = i + 1; j < NUM_RESERVES; j++) {
                if (_reserveFeeds[j] != address(0) && _reserveFeeds[j] == _reserveFeeds[i])
                    revert InvalidAddress();
            }
        }
        for (uint256 i = 0; i < NUM_RESERVES; i++) {
            if (_reserveFeeds[i] == address(0)) continue;
            for (uint256 k = 0; k < NUM_ASSETS; k++) {
                if (priceFeeds[k] == _reserveFeeds[i]) revert InvalidAddress();
            }
        }
        for (uint256 i = 0; i < NUM_RESERVES; i++) {
            reserveFeeds[i] = _reserveFeeds[i];
        }
    }



    /// @notice Announces intent to launch, opening a 72-hour notice window for OGs.
    /// @dev [v1.99.30] PREGAME only. Two-step launch: call this, wait 72 hours, then
    ///      call startGame(). Provides all OFFERED OGs a 72-hour exit window.
    ///      Requirements: >= MIN_PLAYERS_TO_START committed, pendingIntentCount == 0,
    ///      no active proposal, and last confirmOGSlots() batch was >= 66 hours ago
    ///      (OG_INTENT_WINDOW - OG_DECLINE_WINDOW_TAIL). The 66-hour threshold ensures
    ///      any OG in the most recent batch has at most 6 hours of decline window
    ///      remaining -- which expires within the 72-hour notice period. Safe.
    ///      If latestOfferTimestamp == 0 (no OG offers ever), buffer check is skipped.
    ///      confirmOGSlots() and registerAsOG() are blocked while proposal is active.
    ///      Can be cancelled via cancelStartGameProposal() and re-proposed.
    ///      [v1.99.31 / I-02] payCommitment() and registerAsWeeklyOG() remain
    ///      open during the notice period. New commitments are included in
    ///      ogCapDenominator at startGame(). The notice period is designed to honour
    ///      OG exit windows -- not a guarantee, and cohort is not frozen.
    ///      If MAX_PREGAME_DURATION expires during the notice window, startGame()
    ///      will revert PregameWindowExpired -- cancel proposal and use refund paths.
    ///      [v1.99.44 / F7] TWO-TIER BEHAVIOUR: if latestOfferTimestamp == 0 (no
    ///      upfront OG offers made -- weekly-OG + casual game), the 66-hour buffer
    ///      check is skipped and proposeStartGame() can fire immediately after
    ///      MIN_PLAYERS_TO_START is met. Correct: no OFFERED OGs to protect.
    ///      Front-ends: zero-OG games have no 66-hour wait, 72-hour notice only.
    ///      [v1.99.49 / L-06] REVERT WINDOW: committedPlayerCount is validated at
    ///      proposal time but OFFERED OGs may decline during the 72-hour notice
    ///      window, dropping count below MIN_PLAYERS_TO_START. startGame() would
    ///      then revert NotEnoughPlayers(). Operator must cancel and re-propose.
    ///      Mechanically correct but creates a public UX cliff after announcement.
    function proposeStartGame() external onlyOwner {
        if (gamePhase != GamePhase.PREGAME) revert GameNotActive();
        if (committedPlayerCount < MIN_PLAYERS_TO_START) revert NotEnoughPlayers();
        if (pendingIntentCount > 0) revert IntentQueueNotEmpty();
        if (startGameProposedAt != 0) revert TimelockPending();
        // [v1.99.30] Buffer: last offer batch must be >= 66 hours old so any
        // OG in that batch (max 6 hrs remaining on decline window) expires
        // before the 72-hour notice period completes.
        if (latestOfferTimestamp > 0 &&
            block.timestamp < latestOfferTimestamp + OG_INTENT_WINDOW - OG_DECLINE_WINDOW_TAIL)
            revert ActiveDeclineWindowOpen();
        // [v1.99.78 / L-01] Expiry guard: startGame() already blocks proposals after
        // signupDeadline + MAX_PREGAME_DURATION via its own PregameExpired() check.
        // Without this mirror guard here, proposeStartGame() can be called after
        // the pregame has technically expired, creating a 72-hour notice window
        // that overlaps an already-invalid pregame. This confuses operators and
        // front-ends that watch for StartGameProposed as the launch signal.
        if (block.timestamp >= signupDeadline + MAX_PREGAME_DURATION) revert PregameWindowExpired();
        startGameProposedAt = block.timestamp;
        emit StartGameProposed(block.timestamp + START_GAME_NOTICE_PERIOD);
    }

    /// @notice Cancels a pending start game proposal. Owner may re-propose later.
    /// @dev [v1.99.30] Does not reset latestOfferTimestamp -- offer timing is
    ///      independent of proposal state. If re-proposing, the same 66-hour
    ///      buffer applies from the original latestOfferTimestamp.
    function cancelStartGameProposal() external onlyOwner {
        if (startGameProposedAt == 0) revert NoTimelockPending();
        startGameProposedAt = 0;
        emit StartGameProposalCancelled();
    }


    /// @notice Starts the game, transitioning from PREGAME to ACTIVE and opening draw 1.
    /// @dev [v2.69] After locking ogCapDenominator, reads confirmed OG ratio and sets
    ///      targetReturnBps (40%-100%, with 30% safety floor) and initial breathMultiplier
    ///      proportionally via a four-segment piecewise scale. [v1.99.48] Corrected from three.
    ///      [v1.97] targetReturnBps set here is a PREVIEW. It will be recalibrated once more
    ///      at draw 7 close (_calibrateBreathTarget) using the actual OG ratio at upgrade
    ///      window close. No ACTIVE weekly OG registrations exist since v1.92 redesign.
    ///      [v1.93] BreathRecalibrated event fires at draw 7 close (_calibrateBreathTarget) --
    ///      the definitive on-chain record of the real OG ratio calibration.
    ///      Emits BreathCalibrated at startGame (preview) and BreathRecalibrated at draw 7 (final).
    ///      [v1.72 / L-04] RUNBOOK: if this reverts on IntentQueueNotEmpty and confirmOGSlots()
    ///      cannot clear the queue (e.g. the backstop branch fired for a PENDING+isWeeklyOG player),
    ///      call forceDeclineIntent([player]) as owner -- returns 100% to the player and decrements
    ///      pendingIntentCount, unblocking launch. Alternatively, the player can self-exit via
    ///      claimOGIntentRefund() (voluntary -- 85% returned, 15% deposit kept).
    ///      [v1.99.16 / L-01] _captureYield() fires first so any Aave yield accrued on
    ///      PREGAME deposits lands in prizePot before BreathCalibrated fires. Without this,
    ///      the initial breath calibration would run on a slightly understated prizePot.
    function startGame() external onlyOwner nonReentrant {
        if (gamePhase != GamePhase.PREGAME) revert GameNotActive();
        // [v1.99.30] Expiry check before timelock -- gives PregameWindowExpired
        // rather than NoTimelockPending if MAX_PREGAME_DURATION expires during notice.
        if (block.timestamp >= signupDeadline + MAX_PREGAME_DURATION) revert PregameWindowExpired();
        if (committedPlayerCount < MIN_PLAYERS_TO_START) revert NotEnoughPlayers();
        // [v1.99.30] Two-step launch: proposeStartGame() must be called 72 hours before
        // startGame(). Designed to provide all OFFERED OGs a 72-hour exit window.
        if (startGameProposedAt == 0) revert NoTimelockPending();
        if (block.timestamp < startGameProposedAt + START_GAME_NOTICE_PERIOD) revert TooEarly();
        // [v2.68] H-01: block launch while any player holds PENDING intent status.
        // Ensures every queued player either received a slot offer or self-exited before
        // ogRatioBps is snapshotted. Closes H-01 and M-01 simultaneously.
        if (pendingIntentCount > 0) revert IntentQueueNotEmpty();
        _checkSequencer();
        // [v1.99.16 / L-01] Capture any Aave yield accrued on PREGAME deposits
        // (OG intents, weekly OG registrations, commitment payments) before
        // BreathCalibrated fires. Without this, initial breath calibration runs
        // on a slightly understated prizePot. Yield is real money -- typically
        // small at PREGAME rates but structurally should be captured here.
        _captureYield();

        uint256 validFeeds;
        uint256 reserveIdx;
        for (uint256 i = 0; i < NUM_ASSETS; i++) {
            int256 price = _readPrice(i);
            if (price == 0) {
                while (reserveIdx < NUM_RESERVES) {
                    address res = reserveFeeds[reserveIdx];
                    reserveIdx++;
                    if (res == address(0)) continue;
                    int256 rPrice = _readPriceFeed(res);
                    if (rPrice > 0) {
                        emit FeedSubstituted(i, priceFeeds[i], res);
                        priceFeeds[i] = res;
                        price = rPrice;
                        break;
                    }
                }
            }
            weekStartPrices[i]  = price;
            lastValidPrices[i]  = price;
            if (price > 0) validFeeds++;
        }
        if (validFeeds < NUM_PICKS) revert NotEnoughValidPrices();

        gamePhase         = GamePhase.ACTIVE;
        currentDraw       = 1;
        lastDrawTimestamp = block.timestamp;
        scheduleAnchor    = block.timestamp;
        ogCapDenominator  = committedPlayerCount;
        startGameProposedAt = 0; // [v1.99.30] clear proposal on successful launch

        // [v2.69] Breath calibration. Read confirmed OG ratio. Set targetReturnBps and
        // initial breathMultiplier proportionally. Initial orientation only --
        // recalibrated at draw 7 close via _calibrateBreathTarget().
        //
        // Four-segment piecewise linear scale matching the design table: [v1.99.52] Corrected from three.
        //   Seg A: 0%-20% OG  → 100% target (flat ceiling)
        //   Seg B: 20%-30% OG → 100% to 80% (steep: -2pp return per 1pp OG)
        //   Seg C: 30%-90% OG → 80% to 50%  (shallow: -0.5pp return per 1pp OG)
        //   Seg D: 90%-100% OG→ 50% to 40%  (mid: -1pp return per 1pp OG)
        // TARGET_RETURN_FLOOR_BPS (3000 = 30%) is a safety net. Normal 100% OG lands at 40%.
        //
        // Opening breath calibrated to match: 165 bps (1.65%) at 40% target,
        // 700 bps (7.00%) at 100% target. Linear between.
        // [v1.99.59 / H-01] Include earnedOGCount (weekly OGs registered PREGAME)
        // in the numerator. Prior formula used upfrontOGCount only, understating
        // the true OG ratio at game launch when weekly OGs are present.
        // This is an orientation snapshot only -- recalibrated at draw 7 close.
        uint256 ogRatioBps = committedPlayerCount > 0
            ? (upfrontOGCount + earnedOGCount) * 10000 / committedPlayerCount : 0;

        if (ogRatioBps <= 2000) {
            targetReturnBps = 10000;                               // Seg A: 100%
        } else if (ogRatioBps <= 3000) {
            // Seg B: 20%->30% OG, 100%->80%. -2000 bps per 1000 bps OG.
            targetReturnBps = 10000 - (ogRatioBps - 2000) * 2;
        } else if (ogRatioBps <= 9000) {
            // Seg C: 30%->90% OG, 80%->50%. -500 bps per 1000 bps OG.
            targetReturnBps = 8000 - (ogRatioBps - 3000) / 2;
        } else if (ogRatioBps < 10000) {
            // Seg D: 90%->100% OG, 50%->40%. -1000 bps per 1000 bps OG.
            // [v1.99.18 / I-02] Same piecewise scale as _calibrateBreathTarget().
            // See that function for the 1-BPS discontinuity note at the 9000/9001 boundary.
            // [v1.99.49 / I-02] 11-BPS truncation zone: targetReturnBps in [4001,4011]
            // produces initialBreath = 165 via (1..11)*535/6000 = 0. Zone is 11 BPS
            // wide, not 1. Harmless at any realistic OG ratio.
            targetReturnBps = 5000 - (ogRatioBps - 9000);
        } else {
            targetReturnBps = 4000;                                // 100% OG natural anchor: 40%
        }
        // Safety floor: never strive for less than 30% regardless of concentration.
        if (targetReturnBps < TARGET_RETURN_FLOOR_BPS) targetReturnBps = TARGET_RETURN_FLOOR_BPS;

        // Calibrate opening breath to match target. 165 bps at 40% target, 700 bps at 100% target.
        uint256 initialBreath;
        if (targetReturnBps <= 4000) {
            initialBreath = 165;
        } else if (targetReturnBps >= 10000) {
            initialBreath = BREATH_START;
        } else {
            initialBreath = 165 + (targetReturnBps - 4000)
                * (BREATH_START - 165) / (10000 - 4000);
        }
        if (initialBreath < BREATH_MIN) initialBreath = BREATH_MIN;
        if (initialBreath > breathRailMax) initialBreath = breathRailMax;
        breathMultiplier = initialBreath;
        emit BreathCalibrated(ogRatioBps, targetReturnBps, initialBreath);

        if (pregameWeeklyOGTicketTotal > 0) {
            currentDrawTicketTotal    += pregameWeeklyOGTicketTotal;
            currentDrawNetTicketTotal += pregameWeeklyOGNetTotal;
        }

        emit GameStarted(block.timestamp, totalRegisteredPlayers);
    }

    /// @notice Refunds all amounts paid by the caller if the PREGAME failed to start.
    /// @dev [v2.81] FULL REFUND AIM -- game never started: — game never started:
    ///      Unlike claimOGIntentRefund() (voluntary exit = 85% returned, 15% deposit kept),
    ///      this path returns 100% of recoverable funds. If the game cannot start,
    ///      players bear zero cost. [v1.99.13 / AUDIT-INFO-01] "100%" is bounded by
    ///      prizePot + treasuryBalance at the time of claim -- in the degenerate case
    ///      where both are exhausted, the claim returns whatever remains.
    ///      The commitment deposit mechanic only applies to VOLUNTARY exits while the
    ///      game could still proceed. Pulls from prizePot first, then treasuryBalance
    ///      to cover any treasury slice — full amount made whole regardless.
    ///      [v1.99.41 / AUDIT-INFO-01] interestedCount is NOT decremented here.
    ///      Players who called registerInterest() and then claimed a failed-pregame
    ///      refund leave a stale count. getPreGameStats() returns the elevated figure
    ///      on the dead game. Display artifact only -- no financial consequence.
    function claimSignupRefund() external nonReentrant {
        if (gamePhase != GamePhase.PREGAME) revert SignupNotFailed();
        if (block.timestamp < signupDeadline) revert TooEarly();

        _captureYield();

        bool signupFailed   = committedPlayerCount < MIN_PLAYERS_TO_START;
        bool pregameExpired = block.timestamp >= signupDeadline + MAX_PREGAME_DURATION;
        if (!signupFailed && !pregameExpired) revert SignupNotFailed();

        PlayerData storage p = players[msg.sender];
        if (p.totalPaid == 0) revert NothingToClaim();
        if (p.dormancyRefunded) revert AlreadyRefunded();

        uint256 fullAmount   = p.totalPaid;
        uint256 refund       = fullAmount;
        uint256 maxDeductible = prizePot + treasuryBalance;
        if (refund > maxDeductible) refund = maxDeductible;
        if (refund == 0) revert NothingToClaim();

        p.dormancyRefunded = true;
        p.totalPaid = 0;

        if (p.isUpfrontOG || p.isWeeklyOG) {
            _cleanupOGOnRefund(msg.sender, p);
        } else if (p.commitmentPaid) {
            p.commitmentPaid = false;
            // [v1.89 / AUDIT-INFO-01] Guard consistent with every other committedPlayerCount--
            // site in the contract. Invariant holds (commitmentPaid=true implies a prior
            // payCommitment() increment) but guard prevents underflow on any invariant break.
            if (committedPlayerCount > 0) committedPlayerCount--;
        } else if (ogIntentStatus[msg.sender] == OGIntentStatus.PENDING) {
            // [v2.67] PENDING intent player (registered intent but never offered OG status)
            // [v1.99.13 / L-01] Guard consistent with all other decrement sites.
            if (pendingIntentCount > 0) pendingIntentCount--;
            ogIntentStatus[msg.sender] = OGIntentStatus.DECLINED;
            ogIntentAmount[msg.sender] = 0;
            // [v1.84 / AUDIT-I-01] Decrement is now unconditional regardless of ogIntentUsedCredit.
            // Prior: credit-path players (ogIntentUsedCredit=true) had their payCommitment()
            // increment never reversed, leaving a ghost count that permanently blocked the
            // allRefunded fast-track in sweepFailedPregame(). The payCommitment() increment
            // was always 1:1 with this path -- one decrement is always correct here.
            if (committedPlayerCount > 0) committedPlayerCount--;
        }

        // [v1.99.73 / H-01] SWEPT intent cleanup.
        // SWEPT players reach this function via the isUpfrontOG branch above
        // (confirmOGSlots set isUpfrontOG=true; sweepExpiredDeclines left it set).
        // _cleanupOGOnRefund handles OG-specific state but does NOT clean up
        // ogIntentAmount, ogIntentStatus, or committedPlayerCount for SWEPT players.
        // Without this block: ogIntentAmount stays non-zero (blocks re-registration),
        // ogIntentStatus stays SWEPT, and committedPlayerCount stays inflated
        // (preventing the allRefunded fast-track in sweepFailedPregame).
        if (ogIntentStatus[msg.sender] == OGIntentStatus.SWEPT) {
            ogIntentAmount[msg.sender]  = 0;
            ogIntentStatus[msg.sender]  = OGIntentStatus.DECLINED;
            if (committedPlayerCount > 0) committedPlayerCount--;
        }

        if (refund <= prizePot) {
            prizePot -= refund;
        } else {
            uint256 fromTreasury = refund - prizePot;
            prizePot = 0;
            // [v1.6 / L-03] Safety floor mirrors claimOGIntentRefund(). If treasury has been
            // depleted by commitment deposits from declined OGs, a bare subtraction would revert
            // in Solidity 0.8.x, permanently blocking the last claimants until an owner injection.
            if (treasuryBalance >= fromTreasury) {
                treasuryBalance -= fromTreasury;
            } else {
                // [v1.99.8 / L-02] Safety floor. If treasury is partly drained, zeroing
                // prevents underflow. The subsequent _withdrawAndTransfer will attempt to
                // withdraw `refund` from Aave. If Aave has lost USDC (insolvency scenario),
                // _withdrawAndTransfer reverts AaveLiquidityLow -- the correct behaviour.
                // _captureYield() at function entry syncs prizePot to real Aave balance,
                // so under Aave solvency this path is safe. Accepted risk.
                treasuryBalance = 0;
            }
        }

        _withdrawAndTransfer(msg.sender, refund);
        emit SignupRefund(msg.sender, refund, fullAmount);
    }

    /// @notice Removes an OG's registry entries and accounting on failed-pregame refund.
    /// @dev [v1.99.24] Called from claimSignupRefund() for PREGAME exits only.
    ///      Handles both upfront OGs (OG_UPFRONT_COST, credit-adjusted) and
    ///      weekly OGs (TICKET_PRICE * MIN_TICKETS_WEEKLY_OG).
    ///      Adjusts: totalOGPrincipal, upfrontOGCount / weeklyOGCount,
    ///        earnedOGCount, pregame revenue totals, ogList swap-and-pop.
    ///      Defensive swap-and-pop guard (v1.99.21): only removes from ogList
    ///      if addr is actually present at the recorded index.
    function _cleanupOGOnRefund(address addr, PlayerData storage p) internal {
        if (p.isUpfrontOG) {
            // [v1.99.7 / AUDIT-I-01] p.totalPaid zeroed before this call, so use actual
            // amount paid. Credit-path OGs paid OG_UPFRONT_COST - TICKET_PRICE ($1,030);
            // non-credit OGs paid OG_UPFRONT_COST ($1,040). Using the constant after the
            // AUDIT-M-01 fix would undercount by $10 per credit-path OG (floor guards prevent
            // underflow but the comment "Use constant" was factually incorrect).
            // Failed-pregame only: dormancy cannot activate before startGame(), so this
            // asymmetry has zero practical impact on the dormancy proportional formula.
            uint256 upfrontActual = OG_UPFRONT_COST - (ogIntentUsedCredit[addr] ? TICKET_PRICE : 0);
            if (totalOGPrincipal >= upfrontActual) totalOGPrincipal -= upfrontActual;
            else totalOGPrincipal = 0;
            p.isUpfrontOG = false;
            p.picks = 0;
            // [v1.78 / L-01] Guard consistent with all other decrement sites.
            if (upfrontOGCount > 0) upfrontOGCount--;
        } else if (p.isWeeklyOG) {
            // [v1.99.4] p.totalPaid zeroed before call. Use fixed constant ($20 at PREGAME registration).
            uint256 weeklyOGCost = TICKET_PRICE * MIN_TICKETS_WEEKLY_OG;
            if (totalOGPrincipal >= weeklyOGCost) totalOGPrincipal -= weeklyOGCost;
            else totalOGPrincipal = 0;
            p.isWeeklyOG       = false;
            p.picks            = 0;
            p.lastBoughtDraw   = 0;
            p.consecutiveWeeks = 0;
            p.lastActiveWeek   = 0;
            p.firstPlayedDraw  = 0;
            // [v1.78 / L-01] Guards consistent with all other decrement sites.
            if (weeklyOGCount > 0) weeklyOGCount--;
            if (earnedOGCount > 0) earnedOGCount--;
            // [v1.99.48] weeklyOGCost removed -- identical to weeklyOGCost above;
            // replaced with weeklyOGCost throughout.
            // [v1.99.2 / AUDIT-L-01] No fallback. pregameOGNetContributed is always set by
            // registerAsWeeklyOG() before isWeeklyOG = true. If this reverts, a new code path
            // reached isWeeklyOG = true without setting the field -- a regression that must be
            // fixed at the source, not silently papered over with a $17 flat subtraction.
            if (p.pregameOGNetContributed == 0) revert PregameOGNetNotSet();
            uint256 netToSubtract = p.pregameOGNetContributed;
            p.pregameOGNetContributed = 0;
            if (pregameWeeklyOGTicketTotal >= weeklyOGCost) pregameWeeklyOGTicketTotal -= weeklyOGCost;
            else pregameWeeklyOGTicketTotal = 0;
            if (pregameWeeklyOGNetTotal >= netToSubtract) pregameWeeklyOGNetTotal -= netToSubtract;
            else pregameWeeklyOGNetTotal = 0;
        }
        if (p.commitmentPaid) p.commitmentPaid = false;

        // [v2.67] Clean up intent queue state for OFFERED players (granted OG via confirmOGSlots
        // but refunding via claimSignupRefund on a failed pregame rather than claimOGIntentRefund).
        if (ogIntentStatus[addr] == OGIntentStatus.OFFERED) {
            ogIntentStatus[addr]       = OGIntentStatus.DECLINED;
            ogIntentAmount[addr]        = 0;
            // [v1.99.49 / L-03] Clear credit-path flag for forensic cleanliness.
            // DECLINED status is the authoritative gate; no downstream code reads
            // ogIntentUsedCredit post-refund. Stale true misleads off-chain tooling.
            ogIntentUsedCredit[addr]    = false;
            // [v1.99.38 / A2] Clear stale expiry timestamp -- mirrors forceDeclineIntent()
            // L-03 fix. Functional impact zero (DECLINED blocks claimOGIntentRefund before
            // expiry check) but prevents off-chain tooling misclassifying this player
            // as holding an open decline window.
            ogIntentWindowExpiry[addr] = 0;
            // pendingIntentCount was already decremented in confirmOGSlots for OFFERED players.
        // [v1.78 / L-02] SWEPT branch: sweepExpiredDeclines() sets status SWEPT but never clears
        // ogIntentAmount. A SWEPT player who then calls claimSignupRefund() on failed pregame
        // arrives here with a stale non-zero ogIntentAmount. No funds at risk but misleading
        // to auditors and off-chain tooling. Clear it here.
        } else if (ogIntentStatus[addr] == OGIntentStatus.SWEPT) {
            ogIntentAmount[addr]     = 0;
            // [v1.99.50 / INFO-01] Mirror OFFERED branch L-03 fix.
            // ogIntentUsedCredit stays true post-SWEPT otherwise.
            // No functional impact; forensic cleanliness only.
            ogIntentUsedCredit[addr] = false;
            // [v1.99.74 / H-01-FIX] Set DECLINED so the outer SWEPT cleanup
            // blocks in claimSignupRefund() and batchRefundPlayers() see
            // DECLINED and skip their committedPlayerCount-- decrement.
            // Without this line: _cleanupOGOnRefund decrements committedPlayerCount
            // unconditionally at its end, THEN the outer block fires again because
            // ogIntentStatus is still SWEPT, producing a double-decrement.
            ogIntentStatus[addr] = OGIntentStatus.DECLINED;
        }

        uint256 ogLen = ogList.length;
        // [v1.99.21 / LOW] Defensive guard: only swap-and-pop if addr is actually
        // in the list at the recorded index. Prevents silent array corruption if
        // a future code path sets isUpfrontOG = true without a corresponding push.
        if (ogLen > 0 && ogListIndex[addr] < ogLen && ogList[ogListIndex[addr]] == addr) {
            uint256 idx  = ogListIndex[addr];
            address last = ogList[ogLen - 1];
            ogList[idx]       = last;
            ogListIndex[last] = idx;
            ogList.pop();
            delete ogListIndex[addr];
        }
        // [v2.68] L-02: This decrement is correct for both credit and non-credit intent-queue paths.
        // Credit path: counted once via payCommitment(). ogIntentUsedCredit = true, registerAsOG()
        //   did NOT increment committedPlayerCount a second time (line: if (!usingOGCredit)).
        // Non-credit path: counted once in registerAsOG() PREGAME branch (if (!usingOGCredit)++).
        // Either way: exactly one prior increment, exactly one decrement here.
        // [v1.78 / L-01] Guard added -- consistent with all other decrement sites.
        if (committedPlayerCount > 0) committedPlayerCount--;
    }
    /// @notice Removes OGs who lost weekly status from ogList to keep the list compact.
    /// @dev Swap-and-pop removal -- each pruned entry is replaced by the tail element so
    ///      ogList stays dense. ogListIndex is updated for the moved tail. The pruned player's
    ///      isWeeklyOG, picks, weeklyOGStatusLost, and statusLostAtDraw fields are all cleared.
    ///      Only players with both isWeeklyOG = true AND weeklyOGStatusLost = true are removed --
    ///      upfront OGs and active weekly OGs are left untouched.
    ///      IDLE draw phase required -- cannot prune mid-match or mid-distribute.
    ///      maxPrune bounds the batch size to prevent block gas limit issues on large lists.
    ///      Capped at MAX_LAPSE_BATCH (500) for consistency with batchMarkLapsed().
    ///      [v1.99.43 / B] SWAP-AND-POP SAFETY: bare ogList.length - 1 is used
    ///      without the three-condition defensive guard applied in v1.99.21 /
    ///      v1.99.35 / v1.99.39. Safety guaranteed by the while condition:
    ///      i < ogList.length ensures ogList.length >= 1 at the bare subtraction,
    ///      making underflow impossible. The pattern difference is intentional.
    /// @param maxPrune Maximum number of entries to remove in this call.
    /// @dev [v1.99.62 / L-04] PHASE ACCESSIBILITY: only drawPhase == IDLE is
    ///      enforced. No gamePhase guard. Callable in DORMANT and CLOSED phases.
    ///      In DORMANT: status-lost weekly OGs are ineligible for PATH 2 of
    ///      claimDormancyRefund() anyway (!weeklyOGStatusLost required). Pruning
    ///      them (isWeeklyOG = false) makes claimDormancyRefund() isWeeklyOG
    ///      branch a no-op for these players -- end state identical, path differs.
    ///      No financial harm. Intentional multi-phase accessibility.
    function pruneStaleOGs(uint256 maxPrune) external onlyOwner {
        if (drawPhase != DrawPhase.IDLE) revert DrawInProgress();
        // [v1.71 / L-05] Cap at MAX_LAPSE_BATCH for consistency. Owner-only but bounded is better.
        if (maxPrune > MAX_LAPSE_BATCH) revert ExceedsLimit();
        uint256 pruned = 0;
        uint256 i = 0;
        while (i < ogList.length && pruned < maxPrune) {
            address addr = ogList[i];
            PlayerData storage p = players[addr];
            if (p.isWeeklyOG && p.weeklyOGStatusLost) {
                uint256 last = ogList.length - 1;
                address tail = ogList[last];
                ogList[i]         = tail;
                ogListIndex[tail] = i;
                ogList.pop();
                delete ogListIndex[addr];
                p.isWeeklyOG          = false; // [v2.55 v2.53-L-01]
                p.picks               = 0;     // [v2.55 v2.53-L-01]
                p.weeklyOGStatusLost  = false; // [v2.55 v2.53-L-01]
                p.statusLostAtDraw    = 0;     // [v2.55 v2.53-L-01]
                pruned++;
            } else {
                i++;
            }
        }
        emit StaleOGsPruned(pruned, ogList.length);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // TICKET PURCHASE
    // ═══════════════════════════════════════════════════════════════════════

    /// @notice Buys tickets for the current draw and submits asset picks.
    /// @dev One call per player per draw (AlreadyBoughtThisWeek guard). Picks must be 4 unique
    ///      asset indices packed as 5-bit fields in a uint32 (use encodePicks() off-chain).
    ///      Ticket count: 1 (inhale, $10) or 2 (exhale, $15 total) -- exhale draws are
    ///      currentDraw > INHALE_DRAWS. Upfront OGs are blocked -- they auto-match via p.picks.
    ///      Payment: 15% treasury slice applied to fresh USDC transfer.
    ///      [v1.99.81 / STAGE1] Prepaid credit removed -- full cost always from wallet.
    ///      Draw-1 commitment credit: if p.commitmentPaid, the $10 credit is applied and
    ///      committedPlayerCount is decremented (M-02 fix -- prevents reset pool overstatement).
    ///      Player capacity: first-time buyers counted against (MAX_PLAYERS - OG slots - active
    ///      registrations). Lapsed players do not consume a slot until they re-engage.
    ///      [v1.77 / L-03] DRAW 52 ZERO-PRIZE EDGE CASE: If prizePot == requiredEndPot exactly
    ///      at draw 52, surplus = 0, weeklyPool = 0, and all prize tiers pay zero. Players who
    ///      buy tickets for draw 52 win nothing in this scenario. buyTickets() does not revert
    ///      in this case -- participation is still valid even with no prizes available.
    ///      Probability of exact equality is negligible; any pot above requiredEndPot produces
    ///      prizes. Front-ends may wish to display projected draw-52 prize pool. [v1.99.14 / I-04]
    ///      Use getProjectedEndgamePerOG() for OG endgame and prizePot - requiredEndPot for
    ///      surplus prizes. getSolvencyStatus() is a health check, not a prize estimator.
    // [v1.99.82 / STAGE2] picks parameter removed. Players submit picks separately
    // via submitPicks() before PICK_DEADLINE. Auto-pick fires 30 min before deadline.
    function buyTickets(uint256 ticketCount) external nonReentrant {
        if (gamePhase != GamePhase.ACTIVE) revert GameNotActive();
        if (drawPhase != DrawPhase.IDLE)   revert DrawInProgress();
        if (block.timestamp > lastDrawTimestamp + PICK_DEADLINE) revert PicksLocked();

        PlayerData storage p = players[msg.sender];
        if (!p.registered) revert NotRegistered();
        if (p.isUpfrontOG)  revert AlreadyOG();
        // [v1.99.21 / INFO] Weekly OGs registered in PREGAME have lastBoughtDraw
        // pre-set to 1 at registration. In draw 1 they will hit this revert even
        // though they have never called buyTickets(). This is correct -- they are
        // already credited for draw 1. Use submitPicks() to update picks instead.
        if (p.lastBoughtDraw == currentDraw) revert AlreadyBoughtThisWeek();
        if (ticketCount == 0 || ticketCount > MAX_TICKETS_PER_WEEK) revert ExceedsLimit();
        if (p.isWeeklyOG && !p.weeklyOGStatusLost && ticketCount < MIN_TICKETS_WEEKLY_OG)
            revert MinimumTicketsRequired();

        // [v1.99.83 / C-01] Residual _validatePicks(picks) removed.
        // picks no longer in scope -- validation belongs exclusively to submitPicks().
        uint256 cost;
        bool isExhale         = currentDraw > INHALE_DRAWS;
        bool isActiveWeeklyOG = p.isWeeklyOG && !p.weeklyOGStatusLost;
        if (isExhale && !isActiveWeeklyOG) {
            cost = EXHALE_TICKET_PRICE * ticketCount;
        } else {
            cost = TICKET_PRICE * ticketCount;
        }

        // [v1.99.8 / I-01] Draw-2+ commitment forfeiture: if a player paid payCommitment()
        // in PREGAME ($10) but did not buy a ticket in draw 1, their commitment is cleared
        // here with no ticket credit applied. The $10 stays in prizePot. The player effectively
        // paid $10 + $10 = $20 for their first ticket. This fires silently with no event.
        // UX note: the $10 commitment fee serves ONLY as a draw-1 ticket credit.
        // Players who miss draw 1 forfeit that credit to the prize pool.
        if (p.commitmentPaid && currentDraw > 1 && commitmentRefundPool == 0) {
            p.commitmentPaid = false;
            // [v1.77 / L-02] Decrement consistent with all other commitmentPaid clear sites.
            // Without this, committedPlayerCount drifts high for players whose commitment was
            // silently cleared mid-game. Low probability but real counter discrepancy.
            if (committedPlayerCount > 0) committedPlayerCount--;
        }
        // [v1.99.81 / STAGE1] Prepaid credit removed. Commitment draw-1 credit retained.
        bool usingCommitment = p.commitmentPaid && currentDraw == 1;
        uint256 creditAmount  = usingCommitment ? TICKET_PRICE : 0;
        uint256 transferAmount = cost > creditAmount ? cost - creditAmount : 0;

        if (usingCommitment) {
            p.commitmentPaid = false;
            // [v1.5 / M-02] Decrement committedPlayerCount. The player's commitment slot is
            // consumed here. Without this, an emergencyResetDraw() on draw 1 would calculate
            // commitmentRefundPool = committedPlayerCount * TICKET_PRICE, overstating the pool
            // for players who already spent their commitment as a ticket.
            if (committedPlayerCount > 0) committedPlayerCount--;
            uint256 pregameNet = TICKET_PRICE * (10000 - TREASURY_BPS) / 10000;
            currentDrawTicketTotal    += TICKET_PRICE;
            currentDrawNetTicketTotal += pregameNet;
        }

        if (transferAmount > 0) {
            uint256 tSlice = transferAmount * TREASURY_BPS / 10000;
            treasuryBalance += tSlice;
            prizePot        += transferAmount - tSlice;
            p.totalPaid     += transferAmount;
            emit TreasuryAccrual(currentDraw, tSlice, TREASURY_BPS);
            currentDrawTicketTotal    += transferAmount;
            currentDrawNetTicketTotal += transferAmount - tSlice;
        }

        bool isFirstBuy = (p.lastBoughtDraw == 0);
        if (resetDrawRefundDraw != 0
            && p.lastBoughtDraw == resetDrawRefundDraw
            && p.resetRefundClaimedAtDraw != resetDrawRefundDraw) {
            p.lastResetBoughtDraw1 = p.lastBoughtDraw;
            p.lastResetTicketCost1 = p.lastTicketCost;
        } else if (resetDrawRefundDraw2 != 0
            && p.lastBoughtDraw == resetDrawRefundDraw2
            // [v1.99.68 / M-01] Uses independent pool2 claim field.
            && p.resetRefundClaimedAtDraw2 != resetDrawRefundDraw2) {
            p.lastResetBoughtDraw2 = p.lastBoughtDraw;
            p.lastResetTicketCost2 = p.lastTicketCost;
        }
        // [v1.99.64 / I-05] CEI gate: p.lastBoughtDraw = currentDraw must fire
        // before weeklyNonOGPlayers.push() to enforce the AlreadyBoughtThisWeek
        // dedup guarantee. Moving this assignment would silently break that invariant.
        p.lastBoughtDraw  = currentDraw;
        p.lastTicketCount = ticketCount;
        p.lastTicketCost  = cost;

        if (!p.isWeeklyOG || p.weeklyOGStatusLost) {
            if (p.isLapsed) {
                p.isLapsed = false;
                if (lapsedPlayerCount > 0) lapsedPlayerCount--;
                emit PlayerUnlapsed(msg.sender, currentDraw);
            }
            if (isFirstBuy) {
                // [v1.99.23 / I-L-01] Status-lost weekly OGs who re-engage as casual
                // buyers have lastBoughtDraw pre-set from PREGAME (not 0), so isFirstBuy
                // is false for them and this check does not fire. They are absent from
                // every term of the capacity formula. Theoretical overshoot = number of
                // status-lost OGs who re-buy. Bounded, carries no financial risk.
                uint256 ogSlotsTaken  = upfrontOGCount + weeklyOGCount;
                // [v1.99.81 / STAGE1] activeRegistrationCount removed.
                // Slot reservation gone -- casual capacity = MAX_PLAYERS - OG slots.
                uint256 buyerCap = MAX_PLAYERS > ogSlotsTaken ? MAX_PLAYERS - ogSlotsTaken : 0;
                uint256 activeBuyers  = totalLifetimeBuyers > lapsedPlayerCount
                    ? totalLifetimeBuyers - lapsedPlayerCount : 0;
                if (activeBuyers >= buyerCap) revert MaxPlayersReached();
                // [v1.99.37 / A2] totalLifetimeBuyers is counter-up-only.
                // Players exiting via dormancy refund or sweep are NOT decremented.
                // Capacity formula activeBuyers = totalLifetimeBuyers - lapsedPlayerCount
                // approximates active buyers well within a single 52-draw lifecycle.
                // batchMarkLapsed() covers players who stop buying. Dormancy is a
                // late-game event; no re-use scenario is possible per contract design.
                totalLifetimeBuyers++;
            }
            // [v1.91 / #5] AlreadyBoughtThisWeek is the sole duplicate guard for this array.
            // An array-level dedup check would be O(n) per push across up to 55,000 entries --
            // gas-prohibitive. AlreadyBoughtThisWeek (checked at buyTickets() entry via
            // p.lastBoughtDraw == currentDraw) is robust: the only way to bypass it is if
            // lastBoughtDraw is not updated, which the code guarantees it always is on a
            // successful buy. A future code path that sets lastBoughtDraw incorrectly would be
            // the single point of failure; this comment serves as a maintenance flag.
            weeklyNonOGPlayers.push(msg.sender);
        }

        // [v1.99.4] Maintain OG principal and casual net ticket counters.
        // Upfront OGs blocked at entry. isActiveWeeklyOG computed above.
        if (isActiveWeeklyOG) {
            totalOGPrincipal += cost;
        } else {
            currentDrawCasualNetTicketTotal += cost * (10000 - TREASURY_BPS) / 10000;
        }

        _updateStreakTracking(msg.sender);

        if (transferAmount > 0) {
            IERC20(USDC).safeTransferFrom(msg.sender, address(this), transferAmount);
            if (!aaveExited) {
            // [v1.99.11 / M-01] try/catch: if Aave supply is paused/frozen, hold as USDC.
            // Call activateAaveEmergency() if this persists.
            try IPool(AAVE_POOL).supply(USDC, transferAmount, address(this), 0) {}
            catch { emit AaveSupplyFailed(transferAmount); }
            }
        }

        emit TicketsBought(msg.sender, currentDraw, ticketCount);
    }

    /// @notice Updates asset picks for an active OG (upfront or weekly) during the pick window of the current draw. [v1.99.14 / M-03]
    // [v1.99.82 / STAGE2] submitPicks opened to all registered players who have
    // bought a ticket this draw (lastBoughtDraw == currentDraw). OGs can still
    // submit picks without buying (auto-entered). Casuals must buy first.
    // [v1.99.83 / M-01] CALL ORDER: casual players MUST call buyTickets() for
    // this draw BEFORE calling submitPicks(). hasBoughtThisDraw checks
    // p.lastBoughtDraw == currentDraw. Error changed from NotOG() to
    // NotEligible() -- ABI-breaking for error-catching callers. Alert integrators.
    function submitPicks(uint32 picks) external {
        if (gamePhase != GamePhase.ACTIVE) revert GameNotActive();
        if (drawPhase != DrawPhase.IDLE)   revert DrawInProgress();
        if (block.timestamp > lastDrawTimestamp + PICK_DEADLINE) revert PicksLocked();
        PlayerData storage p = players[msg.sender];
        // OGs are auto-entered every draw -- they can always submit picks.
        // Casuals must have bought a ticket this draw before submitting picks.
        bool isOG = p.isUpfrontOG || (p.isWeeklyOG && !p.weeklyOGStatusLost);
        bool hasBoughtThisDraw = p.lastBoughtDraw == currentDraw;
        if (!isOG && !hasBoughtThisDraw) revert NotEligible();
        _validatePicks(picks);
        p.picks = picks;
        emit PicksSubmitted(msg.sender, picks, currentDraw);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // DRAW PHASE 1: RESOLVE WEEK
    // ═══════════════════════════════════════════════════════════════════════

    /// @notice Kicks off a new draw. Reads all 32 price feeds, records performance,
    ///         captures Aave yield, and transitions drawPhase to MATCHING.
    /// @dev [v2.0 / I-02] Draw 10 breath sequencing note:
    ///      _calculatePrizePools() is called before _lockOGObligation() in this function.
    ///      At draw 10, draw 10 prizes are calculated using the draw-7-calibrated breathMultiplier
    ///      (set by _calibrateBreathTarget() at BREATH_CALIBRATION_DRAW close). _lockOGObligation()
    ///      then fires but does NOT change breathMultiplier -- that responsibility sits at draw 7.
    ///      Draws 11 through 51 use the post-lock predictive formula (_checkAutoAdjust).
    ///      No transition artifact exists at draw 10. The rate is stable from draw 7 through draw 10.
    ///      [v1.99.12 / I-01] GAS NOTE: _readPrice() now makes up to 3 external calls per
    ///      asset (latestRoundData + minAnswer + maxAnswer). For 32 feeds: up to 96 additional
    ///      external calls per resolveWeek(). Chainlink aggregators will be warm after the
    ///      first call; additional overhead ~100-200K gas on Arbitrum (<$0.10 at typical
    ///      gas prices). Front-end gas estimators should account for this.
    ///      [v1.99.22] PERMISSIONLESS DESIGN: any caller may initiate draw resolution.
    ///      Owner absence or inaction cannot prevent the game from progressing.
    ///      [v1.99.46] Subject to Arbitrum sequencer liveness: _checkSequencer()
    ///      reverts on sequencer downtime, blocking resolution until recovery.
    function resolveWeek() external nonReentrant {
        if (gamePhase != GamePhase.ACTIVE) revert GameNotActive();
        if (drawPhase != DrawPhase.IDLE)   revert DrawInProgress();
        if (block.timestamp < lastDrawTimestamp + DRAW_COOLDOWN) revert CooldownActive();
        if (currentDraw > TOTAL_DRAWS) revert GameAlreadyClosed();

        uint256 totalOGs = upfrontOGCount + weeklyOGCount;
        if (weeklyNonOGPlayers.length == 0 && totalOGs == 0) revert NotEnoughPlayers();

        _checkSequencer();
        _captureYield();
        _solvencyCheck();

        int256[NUM_ASSETS] memory currentPrices;
        int256[NUM_ASSETS] memory performance;
        uint256 validAssets;

        for (uint256 i = 0; i < NUM_ASSETS; i++) {
            currentPrices[i] = _readPrice(i);

            if (weekStartPrices[i] > 0 && currentPrices[i] > 0) {
                performance[i] = (currentPrices[i] - weekStartPrices[i])
                    * int256(PERFORMANCE_PRECISION) / weekStartPrices[i];
                lastValidPrices[i] = currentPrices[i];
                validAssets++;
            } else if (weekStartPrices[i] > 0 && currentPrices[i] == 0 && lastValidPrices[i] > 0) {
                // [v1.99.11 / L-03] Historical fallback: using last known price for this feed.
                // If feed stays down for multiple consecutive draws, this value ages without notice.
                // FeedStaleFallback event alerts off-chain monitoring. Operator should call
                // proposeFeedChange() if a feed is repeatedly stale.
                emit FeedStaleFallback(i);
                performance[i] = (lastValidPrices[i] - weekStartPrices[i])
                    * int256(PERFORMANCE_PRECISION) / weekStartPrices[i];
                // [v1.99.49 / M-03] Setting currentPrices[i] = lastValidPrices[i]
                // here means the final loop below updates weekStartPrices[i]
                // = lastValidPrices[i]. The baseline drift concern (14-day return
                // measured as 7-day) does NOT occur -- the stale draw correctly
                // anchors weekStartPrices for the next draw via this assignment.
                currentPrices[i] = lastValidPrices[i];
                validAssets++;
            } else if (weekStartPrices[i] > 0 && currentPrices[i] == 0 && lastValidPrices[i] == 0) {
                // [v1.99.13 / AUDIT-INFO-01] Widespread feed failure path: asset counts
                // as valid with performance = 0. If 4+ feeds land here simultaneously,
                // the ranking becomes fully deterministic (tied at 0, lower feed index
                // wins). Operator should call proposeFeedChange() for dead feeds.
                performance[i] = 0;
                currentPrices[i] = weekStartPrices[i];
                validAssets++;
            } else {
                performance[i] = type(int256).min;
            }

            weekPerformance[i] = performance[i];
        }

        if (validAssets < NUM_PICKS) revert NotEnoughValidPrices();

        // Build winningResult: packed ordered uint32 — rank-i asset index at bits i*5..i*5+4.
        // Tie-break: among equal-performance assets, lower feed array index wins.
        uint32 result;
        bool[NUM_ASSETS] memory used;
        for (uint256 rank = 0; rank < NUM_PICKS; rank++) {
            int256 bestPerf = type(int256).min;
            // [v1.82 / L-02] Explicit init. Loop always overwrites this: validAssets >= NUM_PICKS
            // is confirmed before this block, so at least NUM_PICKS assets have perf > min.
            uint256 bestIdx = 0;
            // [v1.99.67 / M-01] TIE-BREAK: strictly-greater-than (>) means equal
            // performers are resolved by lower feed array index. This is deterministic,
            // permanent, and publicly known before the game starts. Players who always
            // pick lower-index assets gain positive EV when feeds tie (correlation
            // events, correlated assets (similar-sector pairs), simultaneous feed failures
            // returning perf=0). Note: this deployment uses volatile crypto assets only --
            // no stablecoins. [v1.99.70 / I-03]
            // This is accepted design -- no randomisation is applied to tie-breaking.
            // Cyfrin submission note: acknowledged game-design asymmetry, not an exploit.
            for (uint256 j = 0; j < NUM_ASSETS; j++) {
                if (!used[j] && performance[j] > bestPerf) {
                    bestPerf = performance[j];
                    bestIdx  = j;
                }
            }
            used[bestIdx] = true;
            result |= uint32(bestIdx) << (rank * PICKS_BITS);
        }

        winningResult = result;
        lastResolvedDraw = currentDraw; // [v1.99.67 / L-02]
        _calculatePrizePools();

        if (currentDraw == OG_OBLIGATION_LOCK_DRAW && !obligationLocked) {
            _lockOGObligation();
        }

        for (uint256 i = 0; i < NUM_ASSETS; i++) {
            if (currentPrices[i] > 0) weekStartPrices[i] = currentPrices[i];
        }

        drawPhase           = DrawPhase.MATCHING;
        phaseStartTimestamp = block.timestamp;
        matchOGIndex        = 0;
        matchNonOGIndex     = 0;
        ogMatchingDone      = false;
        currentTierPerWinner = 0;

        // [v1.83 / AUDIT-I-01] Length-zero clear: sets packed-slot length word to 0. Element storage
        // at keccak256(slot)+i persists but is unreachable -- Solidity access always checks length
        // first. Subsequent push() calls overwrite prior elements. Gas-efficient by design.
        assembly {
            sstore(jpWinners.slot, 0)
            sstore(p2Winners.slot, 0)
            sstore(p3Winners.slot, 0)
            sstore(p4Winners.slot, 0)
        }

        // [v1.85 / AUDIT-M-01] Emit restored. v1.83 OZ-I-01 edit accidentally dropped this line.
        // Off-chain indexers, dashboards, and Subgraphs use DrawResolved to detect weekly results.
        emit DrawResolved(currentDraw, result);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // DRAW PHASE 2: MATCH PLAYERS (BATCHED)
    // ═══════════════════════════════════════════════════════════════════════

    /// @notice Sets the Chainlink Automation forwarder address.
    /// @dev [v1.99.82 / STAGE2] The forwarder is the specific address that
    ///      Chainlink Automation uses when calling performUpkeep().
    ///      Only this address (plus owner) can call applyAutoPicksForDraw().
    ///      Set before game launch. Can be updated by owner if CL subscription changes.
    ///      [v1.99.84 / I-03] Relocated from ownership section to automation section.
    function setAutomationForwarder(address forwarder) external onlyOwner {
        if (forwarder == address(0)) revert InvalidAddress();
        automationForwarder = forwarder;
        emit AutomationForwarderSet(forwarder);
    }

    /// @dev [v1.99.84 / I-04] Shared loop extracted from applyAutoPicksForDraw()
    ///      and performUpkeep() to eliminate code duplication.
    ///      [v1.99.85 / NS-07] PHASE GUARD DEPENDENCY: this internal function
    ///      has no gamePhase or drawPhase guards of its own. Callers must
    ///      enforce phase checks before calling. Both current callers do.
    ///      Any future call site must replicate the ACTIVE+IDLE guards.
    ///      [v1.99.85 / INFO-01] GAS NOTE: applyAutoPicksForDraw() passes
    ///      calldata players_ as memory to this function, forcing a copy
    ///      (~3 gas/element + base overhead). Max 500 elements = ~1,500 gas
    ///      on Arbitrum (<$0.01). Functionally correct. performUpkeep() uses
    ///      abi.decode which already produces a memory array -- no regression.
    function _applyAutoPicks(address[] memory players_) internal {
        for (uint256 i = 0; i < players_.length; i++) {
            address addr = players_[i];
            PlayerData storage p = players[addr];
            if (p.lastBoughtDraw != currentDraw) continue;
            if (p.picks != 0) continue;
            p.picks = GENESIS_PICKS;
            emit AutoPickApplied(addr, currentDraw, GENESIS_PICKS);
        }
    }

    /// @notice Assigns default picks to players who bought tickets but have not submitted picks.
    /// @dev [v1.99.82 / STAGE2] Best-effort pre-draw assignment. processMatches() is the
    ///      authoritative fallback -- any player missed here still gets auto-picks at match time.
    ///      For each address: if lastBoughtDraw == currentDraw and p.picks == 0, assigns
    ///      GENESIS_PICKS and emits AutoPickApplied.
    ///      Called by Chainlink Automation 30 minutes before PICK_DEADLINE (Tuesday close).
    ///      [v2.04 / L-v2.03-02] Updated from "5 minutes" -- AUTO_PICK_BUFFER increased
    ///      to 1800 seconds (30 min) in v2.03 for Arbitrum sequencer recovery headroom.
    ///      Callable by owner or automationForwarder only.
    ///      Batch-bounded at 500. draw phase must be IDLE.
    ///      [v1.99.82 / STAGE2] ACCESS CONTROL: open access would allow griefing --
    ///      an adversary could lock players into GENESIS_PICKS just before they submit.
    ///      Players can override with submitPicks() immediately after, but the pattern
    ///      is poor UX. Restricted to owner and registered automationForwarder.
    function applyAutoPicksForDraw(address[] calldata players_) external {
        if (msg.sender != owner() && msg.sender != automationForwarder)
            revert OwnableUnauthorizedAccount(msg.sender);
        if (gamePhase != GamePhase.ACTIVE) revert GameNotActive();
        if (drawPhase != DrawPhase.IDLE)   revert DrawInProgress();
        if (players_.length > 500) revert ExceedsLimit();
        // [v1.99.84 / I-04] Delegates to _applyAutoPicks internal.
        _applyAutoPicks(players_);
    }

    /// @notice Chainlink Automation upkeep check. [v1.99.87]
    /// @dev Returns true for two conditions:
    ///      1. Draw in progress (drawPhase != IDLE): step the draw forward.
    ///         performData = abi.encode(uint8(1))
    ///      2. Auto-pick window: IDLE + within AUTO_PICK_BUFFER of PICK_DEADLINE.
    ///         performData = abi.encode(uint8(2)) -- keeper must append the
    ///         player address list before calling performUpkeep:
    ///         performData = abi.encode(uint8(2), players_)
    ///      Draw progression (1) takes priority over auto-picks (2).
    ///      [v1.99.83 / I-01] checkUpkeep() window is advisory (view only).
    ///      Permissioned callers may call performUpkeep() outside the window.
    ///      [v2.03 / NS-v2.02-01] ACTION 2 AUGMENTATION REQUIREMENT:
    ///      checkUpkeep returns abi.encode(uint8(2)) as a signal only (32 bytes).
    ///      The off-chain keeper MUST re-encode as abi.encode(uint8(2), address[] players)
    ///      before passing to performUpkeep(). Passing checkUpkeep output directly for
    ///      action 2 reverts with MalformedPerformData() (performData.length < 64 guard).
    ///      The player list is built off-chain from TicketsBought and PicksSubmitted events.
    function checkUpkeep(bytes calldata) external view returns (bool upkeepNeeded, bytes memory performData) {
        if (gamePhase != GamePhase.ACTIVE) return (false, "");
        // Priority 1: draw in progress -- step it forward
        if (drawPhase != DrawPhase.IDLE) {
            return (true, abi.encode(uint8(1)));
        }
        // Priority 2: auto-pick window
        if (block.timestamp >= lastDrawTimestamp + PICK_DEADLINE - AUTO_PICK_BUFFER &&
            block.timestamp <= lastDrawTimestamp + PICK_DEADLINE) {
            return (true, abi.encode(uint8(2)));
        }
        return (false, "");
    }

    /// @notice Chainlink Automation upkeep execution. [v1.99.87]
    /// @dev action 1: advances draw state machine via completeDrawStep().
    ///      action 2: applies auto-picks to zero-picks ticket buyers.
    ///        For action 2, performData must be abi.encode(uint8(2), address[] players_).
    ///        checkUpkeep() returns abi.encode(uint8(2)) only -- the keeper must
    ///        build the player list from TicketsBought events and re-encode before
    ///        calling performUpkeep. Passing checkUpkeep output directly will revert.
    ///      [v1.99.83 / H-01] Access: owner or automationForwarder only.
    ///      [v1.99.87] nonReentrant restored -- _distributePrizesCore and
    ///        _finalizeWeekCore write multiple state variables including prizes.
    function performUpkeep(bytes calldata performData) external nonReentrant {
        if (msg.sender != owner() && msg.sender != automationForwarder)
            revert OwnableUnauthorizedAccount(msg.sender);
        uint8 action = abi.decode(performData, (uint8));
        if (action == 1) {
            // Draw progression: route to the appropriate core step
            if (gamePhase != GamePhase.ACTIVE) revert GameNotActive();
            if (drawPhase == DrawPhase.MATCHING) {
                _processMatchesCore();
            } else if (drawPhase == DrawPhase.DISTRIBUTING) {
                _distributePrizesCore();
            } else if (drawPhase == DrawPhase.FINALIZING || drawPhase == DrawPhase.RESET_FINALIZING) {
                _finalizeWeekCore();
            } else if (drawPhase == DrawPhase.UNWINDING) {
                _continueUnwind();
            } else {
                revert DrawNotProgressing();
            }
        } else {
            // Action 2: auto-picks. performData = abi.encode(uint8(2), address[])
            // [v2.03 / M-v2.02-02] Pre-check: action-2 requires at least 64 bytes
            // (32 for uint8 action + 32 for array offset). Passing checkUpkeep output
            // directly (abi.encode(uint8(2)) = 32 bytes) causes a low-level ABI decode
            // panic with no diagnostic. Named error surfaces the misconfiguration
            // explicitly in keeper job history.
            if (performData.length < 64) revert MalformedPerformData();
            (, address[] memory players_) = abi.decode(performData, (uint8, address[]));
            if (gamePhase != GamePhase.ACTIVE) revert GameNotActive();
            if (drawPhase != DrawPhase.IDLE)   revert DrawInProgress();
            if (players_.length > 500) revert ExceedsLimit();
            _applyAutoPicks(players_);
        }
    }

    /// @notice Processes OG and casual player pick matches for the current draw.
    /// @dev [v1.99.88 / NS-01] @notice restored -- eaten by checkUpkeep/performUpkeep
    ///      replacement in v1.99.87. Batched -- call repeatedly until drawPhase
    ///      advances to DISTRIBUTING. Delegates to _processMatchesCore().
    function processMatches() external nonReentrant {
        if (drawPhase != DrawPhase.MATCHING) revert WrongPhase();
        _processMatchesCore();
    }

    /// @dev [v1.99.87] Core matching logic extracted for completeDrawStep().
    ///      Callers must enforce phase guards.
    function _processMatchesCore() internal {
        uint256 processed;

        if (!ogMatchingDone) {
            uint256 ogTotal = ogList.length;

            while (matchOGIndex < ogTotal && processed < MAX_MATCH_PER_TX) {
                address addr = ogList[matchOGIndex];
                PlayerData storage p = players[addr];

                // [v1.99.72 / P4-NEW-INFO-01] A status-lost weekly OG
                // (weeklyOGStatusLost=true) appears in both ogList (until
                // pruneStaleOGs() runs) and weeklyNonOGPlayers (if they
                // re-bought as a casual player). This guard ensures they
                // are skipped in the OG loop. They will be matched once
                // in the non-OG (weeklyNonOGPlayers) loop via p.picks.
                // Correct: matched exactly once. No double-count possible.
                if (p.isWeeklyOG && !p.weeklyOGStatusLost) {
                    if (p.lastBoughtDraw != currentDraw) {
                        if (p.consecutiveWeeks >= MULLIGAN_THRESHOLD && !p.mulliganUsed) {
                            p.mulliganUsed       = true;
                            p.mulliganUsedAtDraw = currentDraw;
                            uint256 prevWeeks    = p.consecutiveWeeks;
                            p.consecutiveWeeks++;
                            p.lastActiveWeek = currentDraw;
                            if (prevWeeks < WEEKLY_OG_QUALIFICATION_WEEKS
                                && p.consecutiveWeeks >= WEEKLY_OG_QUALIFICATION_WEEKS) {
                                qualifiedWeeklyOGCount++;
                                p.mulliganQualifiedOG = true;
                                emit EarnedOGQualified(addr, currentDraw);
                            }
                            matchOGIndex++;
                            processed++;
                            continue;
                        } else {
                            // [v1.99.4] Decrement totalOGPrincipal BEFORE flag set.
                            // Symmetric with _continueUnwind() re-increment which fires
                            // BEFORE weeklyOGStatusLost = false is cleared.
                            if (totalOGPrincipal >= p.totalPaid) totalOGPrincipal -= p.totalPaid;
                            else totalOGPrincipal = 0;
                            p.weeklyOGStatusLost = true;
                            p.statusLostAtDraw   = currentDraw;
                            // [v1.99.27 / L-04] Clear picks on status loss to prevent
                            // contradictory state (statusLost=true + non-zero picks)
                            // in getPlayerInfo() before pruneStaleOGs() runs.
                            // NOTE: _continueUnwind() does NOT restore picks on
                            // status-loss restoration -- OG must call submitPicks().
                            p.picks = 0;
                            // [v1.85 / AUDIT-L-01] Guard added -- consistent with earnedOGCount below.
                            if (weeklyOGCount > 0) weeklyOGCount--;
                            if (earnedOGCount > 0) earnedOGCount--;
                            // [v1.88 / AUDIT-L-01] Guard -- last two unguarded sites in contract.
                            // weeklyOGCount and earnedOGCount above were guarded in v1.85 but
                            // this adjacent decrement was missed across all seven prior passes.
                            if (p.consecutiveWeeks >= WEEKLY_OG_QUALIFICATION_WEEKS
                                && qualifiedWeeklyOGCount > 0) {
                                qualifiedWeeklyOGCount--;
                            }
                            emit WeeklyOGStatusLost(addr, currentDraw);
                            if (p.mulliganQualifiedOG) p.mulliganQualifiedOG = false;
                            matchOGIndex++;
                            processed++;
                            continue;
                        }
                    }
                    if (p.mulliganQualifiedOG) p.mulliganQualifiedOG = false;
                }

                bool isActive = p.isUpfrontOG || (p.isWeeklyOG && !p.weeklyOGStatusLost);
                if (isActive) {
                    // [v1.99.82 / STAGE2] Auto-pick fallback: if picks == 0, use
                    // GENESIS_PICKS [0,1,2,3]. p.picks persists between draws so
                    // returning players keep their last submission automatically.
                    // New players and post-upgrade OGs (picks cleared) get GENESIS_PICKS.
                    // [v2.05 / L-v2.04-01] applyAutoPicksForDraw() should have fired
                    // 30 minutes before deadline -- this is the on-chain authoritative fallback.
                    uint32 effectivePicks = p.picks != 0 ? p.picks : GENESIS_PICKS;
                    if (p.picks == 0) {
                        p.picks = GENESIS_PICKS;
                        emit AutoPickApplied(addr, currentDraw, GENESIS_PICKS);
                    }
                    _matchAndCategorize(addr, effectivePicks);
                }

                matchOGIndex++;
                processed++;
            }

            if (matchOGIndex >= ogTotal) ogMatchingDone = true;
        }

        if (ogMatchingDone) {
            uint256 nonOGTotal = weeklyNonOGPlayers.length;

            while (matchNonOGIndex < nonOGTotal && processed < MAX_MATCH_PER_TX) {
                address addr = weeklyNonOGPlayers[matchNonOGIndex];
                PlayerData storage p = players[addr];
                // [v1.99.82 / STAGE2] Auto-pick fallback for casual players.
                // Every player with a ticket participates -- no silent skips.
                // p.picks persists: returning players use their last picks.
                // New players (picks==0) get GENESIS_PICKS [0,1,2,3].
                // [v1.99.83 / I-02] STALE PICKS: a player who submitted picks
                // in draw N and buys again in draw N+K without re-submitting
                // is matched with their draw-N picks. Front-ends should display
                // current stored picks each draw and prompt re-submission.
                uint32 casualPicks = p.picks != 0 ? p.picks : GENESIS_PICKS;
                if (p.picks == 0) {
                    p.picks = GENESIS_PICKS;
                    emit AutoPickApplied(addr, currentDraw, GENESIS_PICKS);
                }
                _matchAndCategorize(addr, casualPicks);
                matchNonOGIndex++;
                processed++;
            }

            if (matchNonOGIndex >= nonOGTotal) {
                drawPhase           = DrawPhase.DISTRIBUTING;
                phaseStartTimestamp = block.timestamp;
                distTierIndex       = 0;
                distWinnerIndex     = 0;
                uint256 totalWinners = jpWinners.length + p2Winners.length
                    + p3Winners.length + p4Winners.length;
                emit MatchingComplete(currentDraw, totalWinners);
                return;
            }
        }

        emit MatchingBatchProcessed(currentDraw,
            matchOGIndex + matchNonOGIndex,
            ogList.length + weeklyNonOGPlayers.length);
    }
    function _matchAndCategorize(address player, uint32 picks) internal {
        uint32 result = winningResult;

        uint32[4] memory pIdx;
        uint32[4] memory wIdx;
        for (uint256 i = 0; i < NUM_PICKS; i++) {
            pIdx[i] = (picks  >> (i * PICKS_BITS)) & uint32(PICKS_MASK);
            wIdx[i] = (result >> (i * PICKS_BITS)) & uint32(PICKS_MASK);
        }

        uint256 exactMatches;
        for (uint256 i = 0; i < NUM_PICKS; i++) {
            if (pIdx[i] == wIdx[i]) exactMatches++;
        }

        uint256 anyMatches;
        for (uint256 i = 0; i < NUM_PICKS; i++) {
            for (uint256 j = 0; j < NUM_PICKS; j++) {
                if (pIdx[i] == wIdx[j]) {
                    anyMatches++;
                    break;
                }
            }
        }

        if (exactMatches == 4)                        jpWinners.push(player); // all 4, exact order
        else if (anyMatches == 4)                     p2Winners.push(player); // all 4, any order
        else if (exactMatches == 3)                   p3Winners.push(player); // 3 exact position
        else if (anyMatches >= 3 && exactMatches < 3) p4Winners.push(player); // 3 any order
    }

    // ═══════════════════════════════════════════════════════════════════════
    // DRAW PHASE 3: DISTRIBUTE PRIZES (BATCHED)
    // ═══════════════════════════════════════════════════════════════════════

    /// @notice Distributes prize pools to winners in batches (up to MAX_DISTRIBUTE_PER_TX).
    /// @dev [v1.99.22] PERMISSIONLESS DESIGN: any caller may advance distribution.
    ///      Owner absence or inaction cannot block prize delivery to winners.
    ///      Player funds should never be held hostage to operator liveness.
    /// @dev Iterates tierPools[0..3] (JP, P2, P3, P4) in order. Within each tier, each winner
    ///      receives tierPools[tier] / winnerCount, credited to p.unclaimedPrizes (not transferred).
    ///      currentTierPerWinner is set once per tier at distWinnerIndex == 0 and reused for the
    ///      batch. Dust (rounding remainder) is returned to prizePot, not allocated to any
    ///      individual winner. [v1.85 / AUDIT-I-01] NatSpec corrected -- prior text said dust
    ///      "is added to the last winner" which contradicts the implementation.
    ///      JP miss path: if JP tier has no winners, 70% seeds back to prizePot (Eternal Seed),
    ///      30% redistributes to P2/P3/P4 via JP_MISS_P2_BPS/JP_MISS_P3_BPS constants.
    ///      Per winner: p.unclaimedPrizes and totalUnclaimedPrizes are incremented inside
    ///      the inner winner loop -- not in a bulk operation at the end. [v1.99.14 / L-02]
    ///      After all tiers complete, the SEED return (currentDrawSeedReturn) is added back to
    ///      prizePot and drawPhase moves to FINALIZING.
    ///      State variables distTierIndex and distWinnerIndex track resumption across batched calls.
    function distributePrizes() external nonReentrant {
        if (gamePhase != GamePhase.ACTIVE) revert GameNotActive();
        if (drawPhase != DrawPhase.DISTRIBUTING) revert WrongPhase();
        _distributePrizesCore();
    }

    /// @dev [v1.99.87] Core prize distribution logic extracted for completeDrawStep().
    ///      Callers must enforce phase guards.
    function _distributePrizesCore() internal {
        uint256 credited;

        while (distTierIndex < 4 && credited < MAX_DISTRIBUTE_PER_TX) {
            address[] storage winners = _getWinnersForTier(distTierIndex);
            uint256 pool = tierPools[distTierIndex];

            if (winners.length == 0) {
                if (distTierIndex == 0) {
                    // [v1.77] pool == tierPools[0] at this point -- jpPool was redundant.
                    uint256 toP234  = pool * JP_MISS_TO_LOWER_TIERS_BPS / 10000;
                    uint256 toSeed  = pool - toP234;
                    uint256 toP2    = toP234 * JP_MISS_P2_BPS / 10000;
                    uint256 toP3    = toP234 * JP_MISS_P3_BPS / 10000;
                    uint256 toP4    = toP234 - toP2 - toP3;
                    tierPools[1] += toP2;
                    tierPools[2] += toP3;
                    tierPools[3] += toP4;
                    prizePot     += toSeed;
                    emit JPMissRedistributed(currentDraw, toP234, toSeed);
                } else {
                    prizePot += pool;
                    emit TierNoWinners(currentDraw, distTierIndex, pool);
                }
                tierPools[distTierIndex] = 0;
                distTierIndex++;
                distWinnerIndex = 0;
                continue;
            }

            uint256 perWinner = pool / winners.length;

            if (perWinner == 0) {
                // [v1.99.22 / LOW] Integer division produced zero per-winner share.
                // Pool absorbed back into prizePot. Emit for off-chain monitoring.
                // [v1.99.61 / I-04] Zero currentTierPerWinner to prevent stale-read
                // by off-chain tooling after a dust-skip.
                currentTierPerWinner = 0;
                prizePot += pool;
                emit TierSkippedDust(distTierIndex, pool);
                tierPools[distTierIndex] = 0;
                distTierIndex++;
                distWinnerIndex = 0;
                continue;
            }

            if (distWinnerIndex == 0) {
                uint256 dust = pool - (perWinner * winners.length);
                if (dust > 0) {
                    prizePot += dust;
                    tierPools[distTierIndex] -= dust;
                }
                currentTierPerWinner = perWinner;
            }

            while (distWinnerIndex < winners.length && credited < MAX_DISTRIBUTE_PER_TX) {
                address winner = winners[distWinnerIndex];
                PlayerData storage p = players[winner];
                p.unclaimedPrizes    += perWinner;
                p.totalPrizesWon     += perWinner;
                totalUnclaimedPrizes += perWinner;
                emit PrizeDistributed(winner, perWinner, distTierIndex);
                distWinnerIndex++;
                credited++;
            }

            if (distWinnerIndex >= winners.length) {
                tierPools[distTierIndex] = 0;
                distTierIndex++;
                distWinnerIndex = 0;
            }
        }

        if (distTierIndex >= 4) {
            prizePot += currentDrawSeedReturn;
            emit SeedReturned(currentDraw, currentDrawSeedReturn);
            currentDrawSeedReturn = 0;
            drawPhase           = DrawPhase.FINALIZING;
            phaseStartTimestamp = block.timestamp;
        }
    }
    /// @notice Finalises the current draw after all prizes have been distributed.
    /// @dev [v1.99.88 / NS-02] @notice added. Wrapper delegates to _finalizeWeekCore().
    ///      Call once after distributePrizes() completes. Clears weekly state and
    ///      advances currentDraw. Also handles RESET_FINALIZING after emergencyResetDraw.
    function finalizeWeek() external nonReentrant {
        bool isResetFinalize = (drawPhase == DrawPhase.RESET_FINALIZING);
        if (!isResetFinalize && drawPhase != DrawPhase.FINALIZING) revert WrongPhase();
        _finalizeWeekCore();
    }

    /// @notice Advances the draw state machine by one step.
    /// @dev [v1.99.87] Routes to the appropriate core function based on drawPhase.
    ///      MATCHING     -> _processMatchesCore() (call until drawPhase == DISTRIBUTING)
    ///      DISTRIBUTING -> _distributePrizesCore() (call until drawPhase == FINALIZING)
    ///      FINALIZING / RESET_FINALIZING -> _finalizeWeekCore() (single call)
    ///      UNWINDING    -> _continueUnwind() (call until drawPhase == RESET_FINALIZING)
    ///      IDLE         -> reverts DrawNotProgressing
    ///      Permissionless. Any address may call during a live draw.
    ///      Chainlink Automation calls via performUpkeep() action 1.
    ///      [v1.99.89 / M-01] UNWINDING branch intentionally bypasses
    ///      UNWIND_CONTINUATION_TIMEOUT. The timeout in emergencyResetDraw()
    ///      was designed for manual non-owner callers without automation.
    ///      With Chainlink Automation driving the unwind via this function,
    ///      immediate continuation is correct. The timeout path in
    ///      emergencyResetDraw() is retained as a manual fallback only.
    function completeDrawStep() external nonReentrant {
        // [v1.99.89 / L-01] Unified gamePhase guard. All non-IDLE draw phases
        // are only reachable during ACTIVE (resolveWeek/emergencyResetDraw both
        // require ACTIVE or enforce it implicitly). Guard added here for
        // consistency and fork safety rather than per-branch inconsistency.
        if (gamePhase != GamePhase.ACTIVE) revert GameNotActive();
        if (drawPhase == DrawPhase.MATCHING) {
            _processMatchesCore();
        } else if (drawPhase == DrawPhase.DISTRIBUTING) {
            _distributePrizesCore();
        } else if (drawPhase == DrawPhase.FINALIZING || drawPhase == DrawPhase.RESET_FINALIZING) {
            _finalizeWeekCore();
        } else if (drawPhase == DrawPhase.UNWINDING) {
            _continueUnwind();
        } else {
            revert DrawNotProgressing();
        }
    }

    /// @dev [v1.99.87] Core week-finalization logic extracted for completeDrawStep().
    ///      isResetFinalize re-evaluated from drawPhase at call time.
    ///      Callers must enforce phase guards before calling.
    function _finalizeWeekCore() internal {
        bool isResetFinalize = (drawPhase == DrawPhase.RESET_FINALIZING);
        if (!isResetFinalize && drawPhase != DrawPhase.FINALIZING) revert WrongPhase();

        // [v1.83 / AUDIT-I-01] Length-zero clear -- see resolveWeek() for full pattern explanation.
        // [v1.99.68 / I-04] DORMANCY WINDOW NOTE: this clear fires at the END of draw N.
        // If dormancy activates immediately after finalizeWeek() of draw N (before any
        // draw N+1 buyers), weeklyNonOGPlayers.length == 0 and dormancyParticipantCount
        // will not include draw-N casual buyers (already swept). The PICK_DEADLINE guard
        // in activateDormancy() (requires pick window closed) largely mitigates this:
        // draw-N buyers typically submit before PICK_DEADLINE. Residual edge case
        // accepted -- dormancy activation in this precise window is negligibly narrow.
        assembly { sstore(weeklyNonOGPlayers.slot, 0) }

        // [v1.85 / AUDIT-C-01] Guard restored. v1.83 OZ-I-01 comment insertion accidentally
        // deleted this if() opening brace. Without it: scheduleAnchor resets on every
        // finalizeWeek() call, setting lastDrawTimestamp = block.timestamp each draw and
        // eliminating the 7-day cooldown. All 52 draws could resolve back-to-back.
        if (isResetFinalize) {
            // [v1.99.23 / F-L-01] Subtraction safe: isResetFinalize only fires after
            // at least one draw has resolved, so block.timestamp >= DEPLOY_TIMESTAMP
            // + currentDraw * DRAW_COOLDOWN. No underflow possible.
            scheduleAnchor = block.timestamp - currentDraw * DRAW_COOLDOWN;
        }
        // [v1.99.35] SCHEDULE ANCHOR CATCH-UP: lastDrawTimestamp is anchored to
        // scheduleAnchor + draw * DRAW_COOLDOWN, not to actual resolution time.
        // If a draw resolves late (e.g. 10 days after eligible), the next draw
        // is immediately resolvable since the scheduled window is already past.
        // This prevents one late draw from compounding delays across all 52 draws.
        // Multiple draws can resolve back-to-back after a stall.
        lastDrawTimestamp = scheduleAnchor + currentDraw * DRAW_COOLDOWN;

        currentDrawTicketTotal              = 0;
        currentDrawNetTicketTotal           = 0;
        // [v1.99.6 / AUDIT-M-01] Reset casual counter each draw.
        // Without this, activateDormancy() reads all-time cumulative spend,
        // inflating the proportional denominator and near-zeroing PATH 3 refunds.
        currentDrawCasualNetTicketTotal     = 0;

        // [v2.0] Draw 7 breath calibration. Weekly OG count is stable from draw 1
        // (PREGAME-only registration, no upgrade path). Draw 7 snapshot gives 6 draws
        // of real participation data before obligation locks at draw 10.
        if (currentDraw == BREATH_CALIBRATION_DRAW && !obligationLocked) {
            _calibrateBreathTarget();
        }

        if (currentDraw >= TOTAL_DRAWS) {
            gamePhase = GamePhase.CLOSED;
        }

        emit WeekFinalized(currentDraw);
        currentDraw++;
        drawPhase = DrawPhase.IDLE;
    }
    function closeGame() external nonReentrant {
        if (gamePhase != GamePhase.CLOSED) revert GameNotClosed();
        if (gameSettled) revert GameAlreadyClosed();

        _captureYield();
        if (!aaveExited) {
            uint256 aBalance = IERC20(aUSDC).balanceOf(address(this));
            if (aBalance > 0) {
                uint256 balBefore = IERC20(USDC).balanceOf(address(this));
                IPool(AAVE_POOL).withdraw(USDC, type(uint256).max, address(this));
                uint256 received = IERC20(USDC).balanceOf(address(this)) - balBefore;
                if (received < aBalance) revert AaveLiquidityLow();
            }
            // [v1.99.11 / I-04] aBalance > 0 guard prevents withdraw(0). Confirmed intentional.
            aaveExited            = true;
            aaveExitEffectiveTime = 0;
            // [v1.86 / AUDIT-L-01] Revoke infinite approval -- mirrors executeAaveExit/activateAaveEmergency.
            IERC20(USDC).approve(AAVE_POOL, 0);
            emit AaveExitForcedOnSettle(IERC20(USDC).balanceOf(address(this)));
        }

        uint256 qualifiedOGs = _countQualifiedOGs();
        uint256 ogShare      = prizePot * 9000 / 10000;
        uint256 charityShare = prizePot - ogShare;

        if (qualifiedOGs > 0) {
            uint256 rawPerOG = ogShare / qualifiedOGs;
            // [v1.92] Cap raised to OG_UPFRONT_COST. Survivors get up to 100% return
            // when dropout reduces qualified count below draw-7 snapshot maximum.
            // Pot was sized at draw 10 for the full OG cohort -- surplus funds survivor bonus.
            uint256 maxPerOG = OG_UPFRONT_COST;

            if (rawPerOG > maxPerOG) {
                endgamePerOG = maxPerOG;
                uint256 ogTotal = endgamePerOG * qualifiedOGs;
                charityShare += ogShare - ogTotal;
            } else {
                endgamePerOG = rawPerOG;
                if (rawPerOG < maxPerOG) {
                    uint256 shortfall = (maxPerOG - rawPerOG) * qualifiedOGs;
                    emit EndgameShortfall(rawPerOG, maxPerOG, shortfall);
                }
                uint256 ogDust = ogShare - (endgamePerOG * qualifiedOGs);
                charityShare += ogDust;
            }
        } else {
            charityShare = prizePot;
            // [v1.99.64 / L-01] Emit EndgameShortfall when qualifiedOGs==0
            // and an obligation existed.
            // [v1.99.65 / L-01] PATH C shortfallTotal semantics note:
            // shortfallTotal = ogEndgameObligation (total initial obligation),
            // NOT (perOGPromised - perOGPaid) * qualifiedOGs which equals 0.
            // Monitors must handle PATH C (perOGPaid==0 AND shortfallTotal>0)
            // distinctly from PATH A/B shortfalls.
            if (ogEndgameObligation > 0) {
                emit EndgameShortfall(0, OG_UPFRONT_COST, ogEndgameObligation);
            }
        }

        // [v1.99.22] FORMAL INVARIANT: endgameOwed == prizePot_at_closeGame in all paths.
        // PATH A (normal): endgameOwed = endgamePerOG * qualifiedOGs + charityShare.
        //   charityShare = prizePot - ogShare; ogShare = endgamePerOG * qualifiedOGs.
        //   => endgameOwed = prizePot. ✓
        // PATH B (cap overflow): excess added to charityShare before endgameOwed.
        //   endgameOwed = maxPerOG * qualifiedOGs + charityShare_with_excess = prizePot. ✓
        // PATH C (qualifiedOGs == 0): endgameOwed = 0 + prizePot = prizePot. ✓
        //   Also emits EndgameShortfall(0, OG_UPFRONT_COST, ogEndgameObligation) when obligation > 0. [v1.99.64 / L-01]
        // Invariant verified algebraically. prizePot = 0 after settlement.
        endgameCharityAmount = charityShare;
        endgameOwed          = (qualifiedOGs > 0 ? endgamePerOG * qualifiedOGs : 0) + charityShare;
        prizePot             = 0;
        gameSettled          = true;
        settlementTimestamp  = block.timestamp;

        emit GameClosed(endgamePerOG, charityShare, qualifiedOGs);
    }

    /// @notice Claims the caller's endgame share after the game has been settled via closeGame().
    /// @dev [v1.99.14 / M-01] Stale dual-claim @dev removed. Superseded by v1.99.4.
    /// @dev [v1.99.4] DORMANCY GUARD: if dormancy was activated, claimEndgame() is fully
    ///      blocked for all player types. The dual-claim design (endgame + dormancy refund
    ///      as separate pools) described in earlier NatSpec is superseded in v1.99.4.
    ///      All players settle exclusively via the four-step dormancy model.
    ///      sweepDormancyRemainder() sends all remaining funds to charity.
    ///      [v1.99.6 / AUDIT-I-01] NatSpec updated to reflect v1.99.4 design change.
    function claimEndgame() external nonReentrant {
        // [v1.99.23 / E-L-01] dormancyTimestamp is permanently non-zero after
        // dormancy activates -- even in CLOSED phase. This guard correctly blocks
        // endgame claims when settlement was via dormancy (no per-OG endgame pool).
        // See sweepDormancyRemainder() @dev for the authoritative design explanation.
        if (dormancyTimestamp > 0) revert NothingToClaim();
        PlayerData storage p = players[msg.sender];
        if (!gameSettled) revert GameNotClosed();
        if (!_isQualifiedForEndgame(p)) revert NotQualifiedForEndgame();
        if (p.endgameClaimed) revert AlreadyClaimed();
        if (endgamePerOG == 0) revert NothingToClaim();
        // [v1.86 / P4-CYF-I-01] endgameOwed tracks remaining pool. < endgamePerOG means
        // the pool is depleted beyond this claim -- protects last claimant from a rounding
        // shortfall. In practice endgameOwed should always be an exact multiple of endgamePerOG
        // since all qualified OGs receive the same amount. The guard is belt-and-suspenders.
        if (endgameOwed < endgamePerOG) revert NothingToClaim();

        p.endgameClaimed  = true;
        endgameOwed      -= endgamePerOG;
        _withdrawAndTransfer(msg.sender, endgamePerOG);
        emit EndgameClaimed(msg.sender, endgamePerOG);
    }

    /// @notice Sends the charity portion of the endgame prize pool to the CHARITY address.
    /// @dev [v1.99.14 / L-04] Permissionless -- no onlyOwner. Anyone may trigger.
    ///      endgameCharityAmount is set in closeGame() as: [v1.99.15 / L-01]
    ///      (a) full prizePot if no qualified OGs exist (qualifiedOGs == 0),
    ///      (b) cap-overflow surplus when rawPerOG exceeds OG_UPFRONT_COST,
    ///      (c) OG share rounding dust in normal settlement.
    ///      Callable after gameSettled = true. ENDGAME_SWEEP_WINDOW (548 days) does not
    ///      gate this call -- sweepUnclaimedEndgame() handles the sweep window separately.
    ///      [v1.99.66 / L-01] PATH C (qualifiedOGs == 0): endgameCharityAmount equals
    ///      the full prizePot at settlement. A single call to claimCharity() settles
    ///      the entire game. sweepUnclaimedEndgame() will correctly revert NothingToClaim().
    function claimCharity() external nonReentrant {
        // [v1.99.29 / L-02] Explicit phase guard for consistency with claimEndgame()
        // and all other settlement functions. The implicit guard (endgameCharityAmount
        // only non-zero after closeGame()) is functionally equivalent but relies on
        // a cross-function invariant that future code paths could silently break.
        if (!gameSettled) revert GameNotClosed();
        if (endgameCharityAmount == 0) revert NothingToClaim();
        uint256 amount       = endgameCharityAmount;
        endgameCharityAmount = 0;
        // [v1.99.63 / I-01] Decrements endgameOwed by charityShare. sweepUnclaimedEndgame()
        // subsequently decrements by remaining OG claims. Combined decrements equal
        // the initial endgameOwed per the invariant proved in closeGame() NatSpec.
        // [v1.99.67 / I-05] Belt-and-suspenders guard. The algebraic invariant in
        // closeGame() guarantees endgameOwed >= amount, but a defensive check here
        // costs zero gas in the normal path and prevents silent underflow if any
        // future code path sets endgameCharityAmount independently of endgameOwed.
        // [v1.99.67 / I-05] Defensive guard -- algebraic invariant in closeGame()
        // guarantees endgameOwed >= amount. Guards against future code path drift.
        if (endgameOwed < amount) revert InsufficientBalance();
        endgameOwed         -= amount;
        _withdrawAndTransfer(CHARITY, amount);
        emit CharityClaimed(amount);
    }

    /// @notice Sweeps all unclaimed endgame and charity funds to CHARITY after the sweep window.
    /// @dev [v1.99.14 / L-04] Gated by ENDGAME_SWEEP_WINDOW (548 days = 1.5 years) after
    ///      settlementTimestamp. Zeroes endgameOwed and endgameCharityAmount.
    ///      onlyOwner -- not permissionless. Sweeps to CHARITY address.
    ///      [v1.99.29 / I-02] endgameCharityAmount may already be zero if
    ///      claimCharity() was called before this sweep. The zero-assignment
    ///      is a safe no-op; endgameOwed is always correct regardless.
    function sweepUnclaimedEndgame() external onlyOwner nonReentrant {
        if (!gameSettled) revert GameNotClosed();
        if (block.timestamp < settlementTimestamp + ENDGAME_SWEEP_WINDOW) revert TooEarly();
        if (endgameOwed == 0) revert NothingToClaim();
        uint256 amount       = endgameOwed;
        endgameOwed          = 0;
        endgameCharityAmount = 0;
        _withdrawAndTransfer(CHARITY, amount);
        emit CharityClaimed(amount);
    }

    /// @notice Sweeps all unclaimed weekly prizes to CHARITY after the sweep window.
    /// @dev [v1.99.14 / L-04] Gated by ENDGAME_SWEEP_WINDOW (548 days = 1.5 years) after
    ///      settlementTimestamp. Zeroes totalUnclaimedPrizes. After this fires,
    ///      claimPrize() correctly reverts (totalUnclaimedPrizes == 0 sentinel guard).
    ///      onlyOwner -- not permissionless. Sweeps to CHARITY address.
    function sweepUnclaimedPrizes() external onlyOwner nonReentrant {
        if (!gameSettled) revert GameNotClosed();
        if (block.timestamp < settlementTimestamp + ENDGAME_SWEEP_WINDOW) revert TooEarly();
        if (totalUnclaimedPrizes == 0) revert NothingToClaim();
        uint256 amount       = totalUnclaimedPrizes;
        totalUnclaimedPrizes = 0;
        _withdrawAndTransfer(CHARITY, amount);
        emit CharityClaimed(amount);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // DORMANCY
    // ═══════════════════════════════════════════════════════════════════════

    /// @notice Proposes entering dormancy mode, starting a DORMANCY_TIMELOCK (24-hour) delay.
    /// @dev [v1.99.61 / L-05] AAVE EXIT CANCELLATION: if a proposeAaveExit() timelock
    ///      is pending, this function silently cancels it (sets aaveExitEffectiveTime = 0,
    ///      emits AaveExitCancelled). An operator running a parallel managed Aave exit
    ///      will have that exit voided. Re-propose after dormancy if needed.
    ///      The symmetric behaviour in emergencyResetDraw() is documented at v1.99.34/F2.
    /// @dev [v1.99.9 / L-03] TIMELOCK vs PICK_DEADLINE: DORMANCY_TIMELOCK (24h) is shorter
    ///      than PICK_DEADLINE (4 days). A rogue owner could propose and activate dormancy
    ///      within 24h, mid-pick-window. Fixed in activateDormancy(): the pick-window guard
    ///      (block.timestamp <= lastDrawTimestamp + PICK_DEADLINE) blocks activation until
    ///      the current pick window has closed. Proposal may still be submitted at any time
    ///      during IDLE -- the guard fires only at activation, not at proposal.
    ///      [v1.99.49 / I-05] SIDE EFFECTS: cancels breath override, breath rails,
    ///      prize rate multiplier, AND Aave exit timelock (emits AaveExitCancelled).
    ///      Pending feed changes are NOT cancelled (v1.99.46 disclosure).
    ///      [v1.99.72 / P6-NEW-INFO-02] RUNBOOK: call cancelFeedChange() for
    ///      all pending feed changes before calling proposeDormancy(). After
    ///      activateDormancy(), executeFeedChange() reverts WrongPhase() and
    ///      the stale pendingFeedChanges entry is unexecutable but persists
    ///      in storage. cancelFeedChange() remains callable by owner to clean up.
    function proposeDormancy() external onlyOwner {
        if (gamePhase != GamePhase.ACTIVE) revert GameNotActive();
        if (drawPhase != DrawPhase.IDLE)   revert DrawInProgress();
        if (dormancyEffectiveTime != 0)    revert TimelockPending();
        if (pendingBreathOverride != 0) {
            uint256 cancelled           = pendingBreathOverride;
            pendingBreathOverride       = 0;
            pendingBreathOverrideReason = bytes32(0);
            breathOverrideEffectiveTime = 0;
            emit BreathOverrideCancelled(cancelled);
        }
        // [v1.73 / L-01] Cancel pending breath rails proposal -- consistent with override cancellation.
        if (breathRailsEffectiveTime != 0) {
            uint256 cMin             = pendingBreathRailMin;
            uint256 cMax             = pendingBreathRailMax;
            pendingBreathRailMin     = 0;
            pendingBreathRailMax     = 0;
            breathRailsEffectiveTime = 0;
            emit BreathRailsProposalCancelled(cMin, cMax);
        }
        // [v1.99.28 / L-01] Cancel any pending prize-rate multiplier proposal,
        // mirroring the pattern added to emergencyResetDraw() in v1.99.27.
        // Between proposeDormancy() and activateDormancy() (24-hour window),
        // a proposal could still execute if its timelock elapsed. Cancel it now.
        if (pendingMultiplier != 0) {
            bool isReduction = pendingMultiplier < prizeRateMultiplier;
            pendingMultiplier       = 0;
            pendingMultiplierReason = bytes32(0);
            multiplierEffectiveTime = 0;
            if (isReduction) emit PrizeRateReductionCancelled();
            else             emit PrizeRateIncreaseCancelled();
        }
        // [v1.99.40 / AUDIT-LOW-01] Cancel pending Aave exit timelock for consistency
        // with emergencyResetDraw(). A pending exit could execute silently in the
        // 24-hour proposeDormancy→activateDormancy window with no AaveExitCancelled
        // event (it would execute, not cancel). activateDormancy() handles both
        // aaveExited states safely, but operator surprise risk is real.
        if (aaveExitEffectiveTime != 0) {
            aaveExitEffectiveTime = 0;
            emit AaveExitCancelled();
        }
        // [v1.99.46] NOTE: pendingFeedChanges are NOT cancelled here. The five
        // timelocks cancelled above do not include pending feed changes.
        // executeFeedChange() remains callable during the 24-hour window.
        // After activateDormancy() transitions to DORMANT, the ACTIVE-only
        // guard in executeFeedChange() will block it. Operator awareness required.
        dormancyEffectiveTime = block.timestamp + DORMANCY_TIMELOCK;
        emit DormancyProposed(dormancyEffectiveTime);
    }

    /// @notice Cancels a pending dormancy proposal before the timelock elapses.
    function cancelDormancy() external onlyOwner {
        if (dormancyEffectiveTime == 0) revert NoTimelockPending();
        dormancyEffectiveTime = 0;
        emit DormancyCancelled();
    }

    /// @notice Activates dormancy after the DORMANCY_TIMELOCK has elapsed.
    /// @dev [v1.99.4] Four-step model. [v1.99.14 / C-02] Prior two-pool model removed.
    ///      STEP 1: OG principal. All active OGs receive full totalPaid back.
    ///        Proportional if pot insufficient. Snapshot frozen at activation.
    ///      STEP 2: Casual last-draw ticket refunds. Non-OG last-draw buyers get net cost.
    ///        Only if step 1 fully covered.
    ///      STEP 3: Charity. 10% of gross OG returns sent immediately.
    ///        Only if both steps 1 and 2 fully covered. Players take priority over charity.
    ///      STEP 4: Per-head surplus. All last-draw participants share equally.
    ///        upfrontOGCount + weeklyOGCount + weeklyNonOGPlayers.length.
    ///        ogList.length NOT used -- contains stale status-lost OGs.
    ///      Owner timing incentive eliminated: model is fair at any draw.
    function activateDormancy() external onlyOwner nonReentrant {
        if (gamePhase != GamePhase.ACTIVE) revert GameNotActive();
        if (drawPhase != DrawPhase.IDLE)   revert DrawInProgress();
        if (dormancyEffectiveTime == 0)    revert NoTimelockPending();
        if (block.timestamp < dormancyEffectiveTime) revert TooEarly();
        // [v1.99.9 / L-03] Pick-window guard: prevent dormancy activation while
        // the current draw's pick window is open. DORMANCY_TIMELOCK (24h) is
        // shorter than PICK_DEADLINE (4 days), so without this guard a rogue owner
        // could activate dormancy mid-pick-window with only 24h notice, cancelling
        // a live draw before players have had a full cycle to participate.
        // Players who already bought tickets this draw receive PATH 3 refunds;
        // this guard ensures they had the full pick window before dormancy fires.
        if (block.timestamp <= lastDrawTimestamp + PICK_DEADLINE) revert PicksLocked();

        gamePhase             = GamePhase.DORMANT;
        dormancyTimestamp     = block.timestamp;
        dormancyEffectiveTime = 0;

        _captureYield();

        // ── STEP 1: OG PRINCIPAL POOL ────────────────────────────────────
        // [v1.99.19 / M-01] Snapshot totalOGPrincipal here as the frozen denominator
        // for PATH 1/2 proportional calculations. claimResetRefund() can be called
        // during DORMANT and decrements totalOGPrincipal, which would otherwise
        // shrink the denominator mid-distribution, over-paying later claimants.
        totalOGPrincipalSnapshot = totalOGPrincipal;
        // [v1.99.8 / M-01] Design rationale for face-value tracking:
        // totalOGPrincipal = sum of p.totalPaid for all active OGs (face value).
        // Credit-path weekly OGs contributed slightly less net (see registerAsWeeklyOG).
        // At dormancy, OGs receive their full face-value contributions back.
        // Priority: upfront OGs first (step 1), casual last-draw buyers second (step 2),
        // charity third from surplus (step 3), per-head surplus to all (step 4).
        // In DeFi, no player would expect principal recovery from a failed game.
        // This model is materially more protective -- players made whole if pot allows.
        uint256 ogPrincipal = totalOGPrincipal;
        if (ogPrincipal == 0 || (upfrontOGCount == 0 && weeklyOGCount == 0)) {
            dormancyOGPool             = 0;
            dormancyOGPoolSnapshot     = 0;
            dormancyPrincipalFullCover = true;
        } else if (prizePot >= ogPrincipal) {
            dormancyOGPool             = ogPrincipal;
            dormancyOGPoolSnapshot     = ogPrincipal;
            dormancyPrincipalFullCover = true;
            prizePot                  -= ogPrincipal;
        } else {
            dormancyOGPool             = prizePot;
            dormancyOGPoolSnapshot     = prizePot;
            dormancyPrincipalFullCover = false;
            prizePot                   = 0;
        }

        // ── STEP 2: CASUAL LAST-DRAW TICKET REFUNDS ──────────────────────
        dormancyCasualTicketTotal = currentDrawCasualNetTicketTotal;
        if (!dormancyPrincipalFullCover || dormancyCasualTicketTotal == 0) {
            dormancyCasualRefundPool         = 0;
            dormancyCasualRefundPoolSnapshot = 0;
            dormancyCasualFullCover          = (dormancyCasualTicketTotal == 0);
        } else if (prizePot >= dormancyCasualTicketTotal) {
            dormancyCasualRefundPool         = dormancyCasualTicketTotal;
            dormancyCasualRefundPoolSnapshot = dormancyCasualTicketTotal;
            dormancyCasualFullCover          = true;
            prizePot                        -= dormancyCasualTicketTotal;
        } else {
            dormancyCasualRefundPool         = prizePot;
            dormancyCasualRefundPoolSnapshot = prizePot;
            dormancyCasualFullCover          = false;
            prizePot                         = 0;
        }

        // ── STEP 3: CHARITY (deferred pull) ──────────────────────────────
        // [v2.03 / M-v2.02-03] Design change from live-send to pull model.
        // Previously the charity amount was transferred immediately here via
        // _withdrawAndTransfer(), creating an Aave withdrawal inside the activation
        // critical path. Under Aave liquidity stress this blocked dormancy activation
        // entirely (M-v2.02-03). The charity amount is now set aside in
        // dormancyCharityPending and sent via claimDormancyCharity() by anyone
        // after activation. No player refund is affected: STEP 3 only fires when
        // dormancyPrincipalFullCover AND dormancyCasualFullCover are both true,
        // meaning every player's full entitlement is already in STEP 1 and STEP 2.
        // Included in nonPotAllocated accounting to prevent _captureYield re-inflation.
        if (dormancyPrincipalFullCover && dormancyCasualFullCover
                && ogPrincipal > 0 && prizePot > 0) {
            uint256 charityTarget = ogPrincipal * 1000 / 10000;
            uint256 charityActual = charityTarget > prizePot ? prizePot : charityTarget;
            if (charityActual > 0) {
                prizePot -= charityActual;
                dormancyCharityPending = charityActual;
            }
        }

        // ── STEP 4: PER-HEAD SURPLUS POOL ────────────────────────────────
        // dormancyParticipantCount = active OGs + last-draw casual buyers.
        // Commitment-only players (PATH 4) are NOT included in this count --
        // they consume from the same pool (up to net $8.50 each) but their
        // small number and capped claim make material pool depletion implausible.
        // [v1.99.7 / AUDIT-I-01] If many PATH 4 players claim before PATH 1-3 players,
        // the pool may be partially depleted. Late PATH 1-3 claimants receive
        // min(dormancyPerHeadShare, dormancyPerHeadPool) -- the dust clamp already
        // handles this gracefully. No revert. Accepted design: per-head is surplus
        // only and PATH 4 players have no principal at risk.
        dormancyParticipantCount = upfrontOGCount + weeklyOGCount
            + weeklyNonOGPlayers.length;
        dormancyPerHeadPool = prizePot;
        if (dormancyParticipantCount > 0 && dormancyPerHeadPool > 0) {
            dormancyPerHeadShare = dormancyPerHeadPool / dormancyParticipantCount;
        } else {
            dormancyPerHeadShare = 0;
        }
        prizePot = 0;

        emit DormancyActivated(block.timestamp);
        emit DormancyClaimDeadline(block.timestamp + DORMANCY_CLAIM_WINDOW);
    }

    /// @notice Sends the STEP 3 charity amount to CHARITY after dormancy is activated.
    /// @dev [v2.03 / M-v2.02-03] Extracted from activateDormancy() to remove a live
    ///      Aave withdrawal from the activation critical path. Under Aave liquidity
    ///      stress, the original live transfer blocked dormancy activation entirely.
    ///      Callable by anyone once dormancyTimestamp > 0. The amount is already
    ///      allocated in dormancyCharityPending and excluded from prizePot and all
    ///      nonPotAllocated accounting. Zero reverts if no charity was set aside
    ///      (step 3 only fires when both full-cover flags are true).
    ///      CEI: dormancyCharityPending zeroed before transfer.
    ///      [v2.04 / NS-v2.03-02] ORDERING NOTE: if sweepDormancyRemainder() executes
    ///      before this function, dormancyCharityPending is zeroed by the sweep and
    ///      this call reverts NothingToClaim(). The charity amount is absorbed into the
    ///      swept remainder in that case -- no funds are lost.
    function claimDormancyCharity() external nonReentrant {
        if (dormancyTimestamp == 0) revert GameNotDormant();
        uint256 amount = dormancyCharityPending;
        if (amount == 0) revert NothingToClaim();
        dormancyCharityPending = 0;
        _withdrawAndTransfer(CHARITY, amount);
        emit DormancyCharitySent(amount);
    }

    /// @notice Claims dormancy refund. Players have DORMANCY_CLAIM_WINDOW (90 days).
    /// @dev [v1.99.4] Five paths:
    ///      PATH 1 -- Upfront OG: full totalPaid from OG pool + per-head surplus.
    ///      PATH 2 -- Active weekly OG: full totalPaid + per-head. Full flag cleanup.
    ///      PATH 3 -- Casual last-draw buyer: net ticket cost + per-head surplus.
    ///      PATH 4 -- Commitment-only: net $8.50 from per-head pool (capped).
    ///      [v1.99.5 / AUDIT-I-01] totalOGPrincipal intentionally NOT decremented here.
    ///      [v1.99.20] totalOGPrincipalSnapshot provides the frozen denominator
    ///      guarantee. totalOGPrincipal itself is NOT frozen -- claimResetRefund()
    ///      can decrement it during DORMANT. Use snapshot in proportional formula.
    ///      [v1.99.5 / AUDIT-I-02] PATH 3 casual block silently skips if pool drained.
    ///      Per-head still runs. Player not stranded.
    function claimDormancyRefund() external nonReentrant {
        if (gamePhase == GamePhase.CLOSED) {
            if (dormancyTimestamp > 0) revert DormancyWindowExpired();
            revert GameNotDormant();
        }
        if (gamePhase != GamePhase.DORMANT) revert GameNotDormant();

        PlayerData storage p = players[msg.sender];
        if (p.dormancyRefunded) revert AlreadyRefunded();

        uint256 refund;

        if (p.isUpfrontOG) {
            // ── PATH 1: UPFRONT OG ────────────────────────────────────────
            if (dormancyOGPool == 0) revert NothingToClaim();
            uint256 principal;
            if (dormancyPrincipalFullCover) {
                principal = p.totalPaid;
            } else {
                // [v1.99.19 / M-01] Use frozen snapshot, not live totalOGPrincipal.
                if (totalOGPrincipalSnapshot == 0) revert NothingToClaim();
                principal = p.totalPaid * dormancyOGPoolSnapshot / totalOGPrincipalSnapshot;
            }
            if (principal > dormancyOGPool) principal = dormancyOGPool;
            dormancyOGPool -= principal;
            refund = principal;
            if (dormancyPerHeadShare > 0 && dormancyPerHeadPool > 0) {
                uint256 perHead = dormancyPerHeadShare > dormancyPerHeadPool
                    ? dormancyPerHeadPool : dormancyPerHeadShare;
                dormancyPerHeadPool -= perHead;
                refund += perHead;
            }
            // [v1.99.44 / F1] Symmetric with PATH 2 (v1.99.39 CYF-NEW-LOW-01).
            // Clear isUpfrontOG and remove stale ogList entry. No financial
            // risk in current version (draw-phase functions cannot fire in
            // DORMANT/CLOSED) but state asymmetry would be dangerous in any
            // fork that re-enters ACTIVE after dormancy settlement.
            // [v1.99.45] Decrement counters matching PATH 2 pattern.
            if (upfrontOGCount > 0) upfrontOGCount--;
            p.isUpfrontOG = false;
            uint256 ogLenP1 = ogList.length;
            if (ogLenP1 > 0 && ogListIndex[msg.sender] < ogLenP1 &&
                ogList[ogListIndex[msg.sender]] == msg.sender) {
                uint256 idxP1  = ogListIndex[msg.sender];
                uint256 lastP1 = ogLenP1 - 1;
                if (idxP1 != lastP1) {
                    address lastAddrP1      = ogList[lastP1];
                    ogList[idxP1]           = lastAddrP1;
                    ogListIndex[lastAddrP1] = idxP1;
                }
                ogList.pop();
                delete ogListIndex[msg.sender];
            }

        } else if (p.isWeeklyOG && !p.weeklyOGStatusLost) {
            // ── PATH 2: ACTIVE WEEKLY OG ─────────────────────────────────
            if (dormancyOGPool == 0) revert NothingToClaim();
            uint256 principal;
            if (dormancyPrincipalFullCover) {
                principal = p.totalPaid;
            } else {
                // [v1.99.19 / M-01] Use frozen snapshot, not live totalOGPrincipal.
                if (totalOGPrincipalSnapshot == 0) revert NothingToClaim();
                principal = p.totalPaid * dormancyOGPoolSnapshot / totalOGPrincipalSnapshot;
            }
            if (principal > dormancyOGPool) principal = dormancyOGPool;
            dormancyOGPool -= principal;
            refund = principal;
            if (dormancyPerHeadShare > 0 && dormancyPerHeadPool > 0) {
                uint256 perHead = dormancyPerHeadShare > dormancyPerHeadPool
                    ? dormancyPerHeadPool : dormancyPerHeadShare;
                dormancyPerHeadPool -= perHead;
                refund += perHead;
            }
            if (weeklyOGCount > 0) weeklyOGCount--;
            if (earnedOGCount > 0) earnedOGCount--;
            if (p.consecutiveWeeks >= WEEKLY_OG_QUALIFICATION_WEEKS
                && qualifiedWeeklyOGCount > 0) qualifiedWeeklyOGCount--;
            p.isWeeklyOG         = false;
            // [v1.99.49 / L-02] p.weeklyOGStatusLost = false removed.
            // PATH 2 entry requires !p.weeklyOGStatusLost so this was a
            // dead write (always false at this point). Saves one SSTORE.
            // [v1.99.39 / AUDIT-LOW-01] Remove stale ogList entry.
            // PATH 2 cleared all weekly OG flags but left address in ogList.
            // No financial risk (no draws in DORMANT) but ghost entry visible
            // to off-chain tooling. Defensive guard matches v1.99.21 pattern.
            uint256 ogLenD2 = ogList.length;
            if (ogLenD2 > 0 && ogListIndex[msg.sender] < ogLenD2 &&
                ogList[ogListIndex[msg.sender]] == msg.sender) {
                uint256 idxD2  = ogListIndex[msg.sender];
                uint256 lastD2 = ogLenD2 - 1;
                if (idxD2 != lastD2) {
                    address lastAddrD2     = ogList[lastD2];
                    ogList[idxD2]          = lastAddrD2;
                    ogListIndex[lastAddrD2] = idxD2;
                }
                ogList.pop();
                delete ogListIndex[msg.sender];
            }

        } else if (p.lastBoughtDraw == currentDraw && p.lastTicketCost > 0) {
            // ── PATH 3: CASUAL LAST-DRAW BUYER ───────────────────────────
            // [v1.99.61 / I-05] Covers only tickets purchased for the in-progress
            // IDLE draw (p.lastBoughtDraw == currentDraw). NOT the most recently
            // resolved draw. A player whose last buy was draw N (fully resolved)
            // does not qualify here -- their draw-N cost went to the draw-N prize
            // pool which resolved normally. No refund is owed or expected.
            uint256 playerNetCost = p.lastTicketCost * (10000 - TREASURY_BPS) / 10000;
            if (playerNetCost > 0 && dormancyCasualRefundPool > 0) {
                uint256 casualRefund;
                if (dormancyCasualFullCover) {
                    casualRefund = playerNetCost;
                } else {
                    if (dormancyCasualTicketTotal == 0) revert NothingToClaim();
                    casualRefund = dormancyCasualRefundPoolSnapshot * playerNetCost
                        / dormancyCasualTicketTotal;
                }
                if (casualRefund > dormancyCasualRefundPool) casualRefund = dormancyCasualRefundPool;
                dormancyCasualRefundPool -= casualRefund;
                refund = casualRefund;
            }
            if (dormancyPerHeadShare > 0 && dormancyPerHeadPool > 0) {
                uint256 perHead = dormancyPerHeadShare > dormancyPerHeadPool
                    ? dormancyPerHeadPool : dormancyPerHeadShare;
                dormancyPerHeadPool -= perHead;
                refund += perHead;
            }

        } else if (p.commitmentPaid && p.lastBoughtDraw == 0) {
            // ── PATH 4: COMMITMENT-ONLY PLAYER ───────────────────────────
            // [v1.99.40 / AUDIT-INFO-01] p.lastBoughtDraw == 0 guard added.
            // Restricts PATH 4 to true commitment-only players who never bought
            // a ticket. Without this, a player who committed, bought tickets in
            // several draws, then went inactive with a stale commitmentPaid flag
            // (from draw-1 reset + 30-day expiry clearing the pool without clearing
            // the flag) would misroute here and draw ~$8.50 from dormancyPerHeadPool.
            // They are not commitment-only. Their revenue is in the pot. Falling
            // through to NothingToClaim correctly reflects their state.
            // Paid payCommitment() in PREGAME, never bought a ticket.
            // Takes from per-head pool (their payment reached prizePot/surplus).
            // NOT in dormancyParticipantCount -- consumes from surplus only.
            // In underfunded scenarios where pool = 0, they receive nothing.
            // [v1.99.6 / AUDIT-I-02] Integer dust edge case: if PATH 1-3 claimants
            // drain dormancyPerHeadPool to zero, a PATH 4 player with no other
            // refund source reverts NothingToClaim. Accepted corner case --
            // commitment-only players have no principal at risk, revert is honest.
            if (dormancyPerHeadPool == 0) revert NothingToClaim();
            uint256 net = TICKET_PRICE * (10000 - TREASURY_BPS) / 10000;
            uint256 commitRefund = net > dormancyPerHeadPool ? dormancyPerHeadPool : net;
            if (commitRefund == 0) revert NothingToClaim();
            dormancyPerHeadPool -= commitRefund;
            p.commitmentPaid = false;
            // [v1.99.27 / M-01] Zero stale totalPaid: payCommitment() set
            // p.totalPaid += TICKET_PRICE but the refund makes the player whole.
            // Leaving $10 in storage misleads getPlayerInfo() and future checks.
            p.totalPaid = 0;
            if (committedPlayerCount > 0) committedPlayerCount--;
            refund = commitRefund;

        } else {
            revert NothingToClaim();
        }

        // ── UNIVERSAL CLEANUP ─────────────────────────────────────────────
        if (p.isWeeklyOG) {
            p.isWeeklyOG         = false;
            p.weeklyOGStatusLost = false;
        }
        // [v1.99.33] Clear stale commitmentPaid flag. PATH 4 clears it explicitly;
        // PATH 3 (casual buyer who also has commitmentPaid=true from a draw-1 reset
        // scenario) did not. Their $10 commitment would be silently unreturnable
        // after dormancyRefunded=true blocks re-entry.
        // [v1.99.34 / F1] Also decrement committedPlayerCount symmetrically with PATH 4.
        if (p.commitmentPaid) {
            p.commitmentPaid = false;
            if (committedPlayerCount > 0) committedPlayerCount--;
        }
        // [v1.99.39 / AUDIT-INFO-01] Zero p.totalPaid for all paths.
        // PATH 4 zeroed it explicitly (v1.99.27 M-01). PATH 3, 2, 1 did not.
        // After dormancyRefunded=true, getPlayerInfo() returned stale totalPaid
        // for fully-refunded players. No financial function reads totalPaid
        // post-dormancy. Safe: all path refund calculations already read
        // totalPaid above this point. Self-audit confirmed clean.
        p.totalPaid = 0;
        // [v1.99.34 / F3] Remove revert guard: PATH 3 players with drained pools
        // would be permanently wedged (dormancyRefunded never set, flags never
        // cleared, every re-call hits the same revert). They legitimately entered
        // a PATH -- strangers are already blocked by the PATH chain else-revert.
        // Zero-refund players get state resolved cleanly; transfer is skipped.
        p.dormancyRefunded = true;
        // [v1.99.81 / STAGE1] prepaidCredit removed -- no credit balance to add.
        if (refund > 0) _withdrawAndTransfer(msg.sender, refund);
        emit DormancyRefund(msg.sender, refund);
    }
    /// @notice Sweeps all unclaimed dormancy funds to charity after the claim window.
    /// @dev [v1.99.4] Simplified. No endgame distribution after dormancy.
    ///      _captureYield() fires OUTSIDE the !aaveExited block to capture 90-day
    ///      Aave yield regardless of whether executeAaveExit was called during DORMANT.
    ///      Zeroes all dormancy state variables to prevent stale reads post-settlement.
    ///      [v2.05 / L-v2.04-02] Seven additional state vars zeroed: dormancyParticipantCount,
    ///      dormancyCasualTicketTotal, dormancyPrincipalFullCover, dormancyCasualFullCover,
    ///      dormancyCharityPending (added v2.03), totalOGPrincipal, totalOGPrincipalSnapshot
    ///      -- no functional use after DORMANT phase closes. Updated from "six" (v1.99.47).
    /// @dev [v1.99.22] dormancyTimestamp is permanently non-zero after activateDormancy()
    ///      fires -- including in CLOSED phase post-settlement. This is intentional.
    ///      dormancyTimestamp > 0 in CLOSED signals the game reached settlement via
    ///      dormancy (no endgame-per-OG pool). claimEndgame() uses this flag to block
    ///      upfront OG endgame claims post-dormancy. Never zeroed by design.
    function sweepDormancyRemainder() external nonReentrant {
        if (gamePhase != GamePhase.DORMANT) revert GameNotDormant();
        if (gameSettled) revert GameAlreadyClosed();
        if (block.timestamp < dormancyTimestamp + DORMANCY_CLAIM_WINDOW) revert TooEarly();

        _captureYield();

        if (!aaveExited) {
            uint256 aBalance = IERC20(aUSDC).balanceOf(address(this));
            if (aBalance > 0) {
                uint256 balBefore = IERC20(USDC).balanceOf(address(this));
                IPool(AAVE_POOL).withdraw(USDC, type(uint256).max, address(this));
                uint256 received = IERC20(USDC).balanceOf(address(this)) - balBefore;
                if (received < aBalance) revert AaveLiquidityLow();
            }
            aaveExited            = true;
            aaveExitEffectiveTime = 0;
            IERC20(USDC).approve(AAVE_POOL, 0);
            emit AaveExitForcedOnSettle(IERC20(USDC).balanceOf(address(this)));
        }

        gamePhase           = GamePhase.CLOSED;
        settlementTimestamp = block.timestamp;
        gameSettled         = true;

        uint256 remaining = dormancyOGPool
            + dormancyCasualRefundPool
            + dormancyPerHeadPool
            + dormancyCharityPending  // [v2.03 / M-v2.02-03] unclaimed charity swept with remainder
            + prizePot;

        // Zero all dormancy state post-settlement.
        dormancyOGPool                   = 0;
        dormancyOGPoolSnapshot           = 0;
        dormancyCasualRefundPool         = 0;
        dormancyCasualRefundPoolSnapshot = 0;
        dormancyPerHeadPool              = 0;
        dormancyPerHeadShare             = 0;
        prizePot                         = 0;
        // [v1.99.5 / AUDIT-L-01] Additional vars zeroed post-settlement.
        // [v2.04 / I-v2.03-02] Count updated: dormancyCharityPending added in v2.03
        // brings the total to seven (dormancyParticipantCount, dormancyCasualTicketTotal,
        // dormancyPrincipalFullCover, dormancyCasualFullCover, dormancyCharityPending,
        // totalOGPrincipal, totalOGPrincipalSnapshot).
        dormancyParticipantCount  = 0;
        dormancyCasualTicketTotal = 0;
        dormancyPrincipalFullCover = false;
        dormancyCasualFullCover   = false;
        dormancyCharityPending    = 0; // [v2.03 / M-v2.02-03]
        totalOGPrincipal          = 0;
        // [v1.99.20] Zero snapshot alongside parent -- prevents stale read asymmetry.
        totalOGPrincipalSnapshot  = 0;

        if (remaining > 0) {
            _withdrawAndTransfer(CHARITY, remaining);
            emit CharityClaimed(remaining);
        }

        emit DormancyRemainderSwept(remaining);
    }
    /// @notice Owner pushes refunds to a batch of players on a failed pregame.
    /// @dev [v1.99.58] PREGAME only. Callable when signup failed or pregame expired.
    ///      Replicates claimSignupRefund() accounting for each address in the batch.
    ///      Player types handled: upfront OGs (via _cleanupOGOnRefund), weekly OGs
    ///      (via _cleanupOGOnRefund), commitment-only players, PENDING intent players.
    ///      SKIP conditions (silent continue, not revert):
    ///        - dormancyRefunded = true (already claimed or batch-processed)
    ///        - totalPaid == 0 (nothing owed, incl. voluntary exiters)
    ///      CEI compliant: all state mutations per player happen before _withdrawAndTransfer().
    ///      _captureYield() called once before the loop (not per-player). Yield accrued
    ///      during the batch itself is negligible (<$0.01) -- safety floor covers it.
    ///      Duplicate addresses in playerList are safe -- second occurrence hits
    ///      dormancyRefunded = true and is skipped.
    ///      ogList mutations inside _cleanupOGOnRefund are safe -- this function
    ///      iterates playerList (calldata), not ogList (storage).
    ///      Voluntary exiters (claimOGIntentRefund called) are skipped correctly:
    ///      totalPaid = 0 post-exit. Their 15% commitment deposit is NOT returned.
    ///      The deposit penalty survives game failure for voluntary exits. Intentional.
    ///      RUNBOOK: call batchRefundPlayers() until committedPlayerCount == 0, then
    ///      call sweepFailedPregame(). This eliminates the sweep-before-claim risk where
    ///      unclaimed players lose funds to charity.
    ///      RUNBOOK: verify all addresses in playerList are EOAs before calling.
    ///      If a contract address with a reverting receive() is included, safeTransfer
    ///      reverts and bricks that batch call. That player retains claimSignupRefund().
    ///      Reconstruct the batch without that address and call again.
    ///      Gas: ~100K per player (Aave withdrawal). BATCH_REFUND_MAX = 100 keeps
    ///      worst-case ~10M gas, within Arbitrum 32M block limit.
    ///      If aaveExited = true (emergency exit already done): safeTransfer only,
    ///      ~30K per player -- can safely process more per call in that case.
    /// @dev [v1.99.66 / I-01] SignupRefundSkipped RUNBOOK: a skipped address has
    ///      pregameOGNetContributed == 0 (invariant violation, should never occur).
    ///      Player state is fully preserved (dormancyRefunded=false, totalPaid intact).
    ///      Operator must investigate and make the player whole via direct treasury
    ///      action before calling sweepFailedPregame(). This state indicates a bug
    ///      in a preceding registration flow -- audit all state-setting paths.
    ///      [v1.99.77 / P1-NEW-LOW-02] TREASURY DRAINAGE RUNBOOK: when prizePot is
    ///      exhausted mid-batch, remaining refunds are pulled from treasuryBalance.
    ///      The SignupRefund(addr, refund, fullAmount) event is emitted for every
    ///      player regardless of funding source -- it does NOT indicate whether
    ///      prizePot or treasuryBalance covered the refund. On a large failed-pregame
    ///      batch, treasury could drain significantly across multiple calls without
    ///      any per-player signal.
    ///      Operator monitoring pattern:
    ///        1. Read treasuryBalance before the batch call.
    ///        2. Call batchRefundPlayers().
    ///        3. Read treasuryBalance after. Delta = treasury consumed this batch.
    ///        4. Repeat until allRefunded == true (committedPlayerCount == 0).
    ///      No player funds are at risk. This is an operator tooling gap only.
    /// @param playerList Addresses to refund. Construct off-chain from registered events.
    function batchRefundPlayers(address[] calldata playerList) external onlyOwner nonReentrant {
        if (gamePhase != GamePhase.PREGAME) revert WrongPhase();
        if (block.timestamp < signupDeadline) revert TooEarly();

        bool signupFailed   = committedPlayerCount < MIN_PLAYERS_TO_START;
        bool pregameExpired = block.timestamp >= signupDeadline + MAX_PREGAME_DURATION;
        if (!signupFailed && !pregameExpired) revert SignupNotFailed();
        if (playerList.length > BATCH_REFUND_MAX) revert ExceedsLimit();

        _captureYield();

        uint256 len = playerList.length;
        for (uint256 i = 0; i < len; i++) {
            address addr = playerList[i];
            PlayerData storage p = players[addr];

            // [v1.99.58] Skip: already refunded
            if (p.dormancyRefunded) continue;
            // [v1.99.58] Skip: nothing owed (includes voluntary exiters with totalPaid zeroed)
            if (p.totalPaid == 0) continue;

            uint256 fullAmount    = p.totalPaid;
            uint256 refund        = fullAmount;
            uint256 maxDeductible = prizePot + treasuryBalance;
            if (refund > maxDeductible) refund = maxDeductible;
            if (refund == 0) continue;

            // [v1.99.66 / M-01] PRE-CHECK before all state mutations.
            // A weekly OG with pregameOGNetContributed == 0 is an invariant
            // violation. _cleanupOGOnRefund() would revert PregameOGNetNotSet(),
            // bricking this batch. Skip here (before any state writes) so the
            // player retains dormancyRefunded=false and totalPaid intact --
            // their state is fully preserved for separate operator resolution.
            if (p.isWeeklyOG && p.pregameOGNetContributed == 0) {
                emit SignupRefundSkipped(addr);
                continue;
            }

            // -- State mutations before transfer (CEI) --
            p.dormancyRefunded = true;
            p.totalPaid        = 0;


            if (p.isUpfrontOG || p.isWeeklyOG) {
                _cleanupOGOnRefund(addr, p);
            } else if (p.commitmentPaid) {
                p.commitmentPaid = false;
                if (committedPlayerCount > 0) committedPlayerCount--;
            } else if (ogIntentStatus[addr] == OGIntentStatus.PENDING) {
                if (pendingIntentCount > 0) pendingIntentCount--;
                ogIntentStatus[addr] = OGIntentStatus.DECLINED;
                ogIntentAmount[addr] = 0;
                if (committedPlayerCount > 0) committedPlayerCount--;
            }

            // [v1.99.73 / H-01] SWEPT intent cleanup -- mirrors claimSignupRefund.
            if (ogIntentStatus[addr] == OGIntentStatus.SWEPT) {
                ogIntentAmount[addr]  = 0;
                ogIntentStatus[addr]  = OGIntentStatus.DECLINED;
                if (committedPlayerCount > 0) committedPlayerCount--;
            }

            // -- Fund deduction: prizePot first, treasury covers shortfall --
            if (refund <= prizePot) {
                prizePot -= refund;
            } else {
                uint256 fromTreasury = refund - prizePot;
                prizePot = 0;
                if (treasuryBalance >= fromTreasury) {
                    treasuryBalance -= fromTreasury;
                } else {
                    treasuryBalance = 0;
                }
            }

            _withdrawAndTransfer(addr, refund);
            emit SignupRefund(addr, refund, fullAmount);
        }
    }

    /// @notice Closes a failed pregame and sweeps remaining funds to charity.
    /// @dev PREGAME only. Two activation paths:
    ///      (a) Time gate: block.timestamp >= signupDeadline + MAX_PREGAME_DURATION
    ///          + FAILED_PREGAME_SWEEP_EXTENSION. Callable regardless of whether
    ///          all players have claimed. Unclaimed funds go to charity.
    ///      (b) allRefunded: committedPlayerCount == 0 AND block.timestamp >=
    ///          signupDeadline. All committed players have claimed -- safe to close.
    ///      RUNBOOK: call batchRefundPlayers() to drain committedPlayerCount to 0
    ///      before calling this function. Eliminates the risk of unclaimed player
    ///      funds going to charity via the time-gate path.
    ///      Fund routing: all USDC in contract minus treasuryBalance goes to charity.
    ///      treasuryBalance is retained (includes treasury slices and kept 15%
    ///      commitment deposits from voluntary OG exiters). [v1.99.58]
    function sweepFailedPregame() external onlyOwner nonReentrant {
        if (gamePhase != GamePhase.PREGAME) revert WrongPhase();
        bool timeGateOpen = block.timestamp >= signupDeadline + MAX_PREGAME_DURATION + FAILED_PREGAME_SWEEP_EXTENSION;
        // [v1.76 / L-01] Gate on signupDeadline to prevent deployment-day bricking.
        // committedPlayerCount starts at 0 -- without this, any actor can call immediately.
        bool allRefunded  = committedPlayerCount == 0 && block.timestamp >= signupDeadline;
        if (!timeGateOpen && !allRefunded) revert TooEarly();

        if (!aaveExited) {
            _captureYield();
            uint256 aBalance = IERC20(aUSDC).balanceOf(address(this));
            if (aBalance > 0) {
                uint256 balBefore = IERC20(USDC).balanceOf(address(this));
                IPool(AAVE_POOL).withdraw(USDC, type(uint256).max, address(this));
                uint256 received = IERC20(USDC).balanceOf(address(this)) - balBefore;
                if (received < aBalance) revert AaveLiquidityLow();
            }
            aaveExited            = true;
            aaveExitEffectiveTime = 0;
            // [v1.86 / AUDIT-L-01] Revoke infinite approval.
            IERC20(USDC).approve(AAVE_POOL, 0);
            emit AaveExitForcedOnSettle(IERC20(USDC).balanceOf(address(this)));
        }

        gamePhase           = GamePhase.CLOSED;
        gameSettled         = true;
        settlementTimestamp = block.timestamp;

        uint256 usdcBalance = IERC20(USDC).balanceOf(address(this));
        // [v1.99.90 / M-NEW-01] Exclude pull refunds owed to force-declined players.
        // Without this, their funds would be swept to charity.
        uint256 toCharity = usdcBalance > treasuryBalance + totalForceDeclineRefundOwed
            ? usdcBalance - treasuryBalance - totalForceDeclineRefundOwed : 0;
        prizePot            = 0;

        if (toCharity > 0) {
            // [v2.03 / NS-v2.02-04 / I-v2.02-04] Direct IERC20.safeTransfer() is correct here.
            // aaveExited is guaranteed true at this point (forced exit block just above).
            // _withdrawAndTransfer() would attempt IPool.withdraw() when !aaveExited then
            // safeTransfer -- the Aave path is unreachable. Direct transfer is equivalent
            // and avoids a redundant external call. Every other charity transfer site uses
            // _withdrawAndTransfer() -- this divergence is intentional by design.
            IERC20(USDC).safeTransfer(CHARITY, toCharity);
            emit CharityClaimed(toCharity);
        }
        emit FailedPregameSwept(toCharity);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // RESET REFUND
    // ═══════════════════════════════════════════════════════════════════════

    /// @notice Claims a ticket-cost refund if the caller's last draw was an emergency-reset draw.
    /// @dev [v1.3 / I-03] Dual reset pool note:
    ///      If a player bought tickets in two different emergency-reset draws, they may be eligible
    ///      for both resetDrawRefundPool (pool 1) and resetDrawRefundPool2 (pool 2) simultaneously.
    ///      This function pays pool 1 on the first call and pool 2 on a second call. No funds are
    ///      lost -- both pools remain independently claimable until their respective deadlines.
    ///      Front-ends should check both pool eligibility flags and prompt a second call if needed.
    ///      [v2.03 / L-v2.02-01 / NS-v2.02-02] Two-call requirement formally documented here.
    ///      The pool-1 early-return (return; after pool-1 success) is intentional -- it prevents
    ///      pool-2 evaluation in the same transaction. A second call is required for pool-2.
    function claimResetRefund() external nonReentrant {
        PlayerData storage p = players[msg.sender];
        if (p.isUpfrontOG) revert ResetRefundNotEligible();

        bool pool1Active = resetDrawRefundDraw != 0 && block.timestamp <= resetDrawRefundDeadline;
        bool pool2Active = resetDrawRefundDraw2 != 0 && block.timestamp <= resetDrawRefundDeadline2;

        // [v1.84 / AUDIT-L-01] Each pool reads its own indexed snapshot field.
        // Prior: both pools shared lastResetBoughtDraw -- pool2 snapshot overwrote pool1.
        bool eligiblePool1 = pool1Active &&
            ((p.lastBoughtDraw == resetDrawRefundDraw) || (p.lastResetBoughtDraw1 == resetDrawRefundDraw)) &&
            p.resetRefundClaimedAtDraw != resetDrawRefundDraw;

        // [v1.99.68 / M-01] Pool2 eligibility uses its own independent claim field.
        bool eligiblePool2 = pool2Active &&
            ((p.lastBoughtDraw == resetDrawRefundDraw2) || (p.lastResetBoughtDraw2 == resetDrawRefundDraw2)) &&
            p.resetRefundClaimedAtDraw2 != resetDrawRefundDraw2;

        if (!eligiblePool1 && !eligiblePool2) revert ResetRefundNotEligible();

        uint256 tRate = TREASURY_BPS;

        // [v1.99.36] Restructured from if/else to sequential if/if.
        // Pool1: process if eligible and funded. Return early on success.
        // Pool2: runs if (a) pool1 not eligible, OR (b) pool1 eligible but drained.
        // Fixes: player eligible for both pools permanently blocked from pool2
        // when pool1 drains -- prior if/else structure routed to pool1 every call.
        if (eligiblePool1) {
            // [v1.90 / AUDIT-INFO-01] Fallback to lastTicketCost when snapshot was not captured
            // (player's lastBoughtDraw matched at eligibility check but lastResetBoughtDraw1
            // is 0). In dual-pool scenarios where pool1 was claimed first and lastTicketCost
            // has since changed via a new buyTickets() call, this fallback uses the current
            // cost not the reset-draw cost. Accepted approximation: exposure bounded to the
            // difference between two draw ticket costs ($10-$15 range). Single-pool scenario
            // (the common case) is always exact.
            uint256 costForCalc = (p.lastResetBoughtDraw1 == resetDrawRefundDraw)
                ? p.lastResetTicketCost1 : p.lastTicketCost;
            uint256 netCost = costForCalc * (10000 - tRate) / 10000;
            if (netCost == 0) revert ResetRefundNotEligible();
            uint256 claim = netCost <= resetDrawRefundPool ? netCost : resetDrawRefundPool;
            if (claim > 0) {
                p.resetRefundClaimedAtDraw = resetDrawRefundDraw;
                p.lastResetBoughtDraw1     = 0;
                p.lastResetTicketCost1     = 0;
                resetDrawRefundPool       -= claim;
                // [v1.99.5 / AUDIT-M-01] Prevent double-recovery at dormancy.
                // [v1.99.28 / M-02] Removed !weeklyOGStatusLost guard.
                if (p.isWeeklyOG) {
                    if (p.totalPaid >= claim) p.totalPaid -= claim;
                    else p.totalPaid = 0;
                    // [v1.99.61 / M-02] Guard totalOGPrincipal with !weeklyOGStatusLost.
                    // processMatches() already decremented totalOGPrincipal by
                    // p.totalPaid at status-loss. Decrementing again here would
                    // double-count, understating the dormancy proportional denominator.
                    // p.totalPaid is decremented unconditionally (correct -- tracks
                    // running balance). Only the principal tracking is guarded.
                    if (!p.weeklyOGStatusLost) {
                        if (totalOGPrincipal >= claim) totalOGPrincipal -= claim;
                        else totalOGPrincipal = 0;
                    }
                }
                _withdrawAndTransfer(msg.sender, claim);
                emit ResetRefundClaimed(msg.sender, resetDrawRefundDraw, claim);
                if (claim < netCost) emit ResetRefundPartial(msg.sender, resetDrawRefundDraw, claim, netCost);
                return;
            }
            // pool1 drained (claim==0). Fall through to pool2 check.
            if (!eligiblePool2) revert NothingToClaim();
        }
        if (eligiblePool2) {
            // [v1.90 / AUDIT-INFO-01] Same fallback design as pool1 above. See pool1 comment.
            uint256 costForCalc = (p.lastResetBoughtDraw2 == resetDrawRefundDraw2)
                ? p.lastResetTicketCost2 : p.lastTicketCost;
            uint256 netCost = costForCalc * (10000 - tRate) / 10000;
            if (netCost == 0) revert ResetRefundNotEligible();
            uint256 claim = netCost <= resetDrawRefundPool2 ? netCost : resetDrawRefundPool2;
            if (claim == 0) revert NothingToClaim();
            p.resetRefundClaimedAtDraw2 = resetDrawRefundDraw2; // [v1.99.68 / M-01]
            p.lastResetBoughtDraw2     = 0;
            p.lastResetTicketCost2     = 0;
            resetDrawRefundPool2      -= claim;
            // [v1.99.5 / AUDIT-M-01] Prevent double-recovery at dormancy.
            // [v1.99.28 / M-02] Removed !weeklyOGStatusLost guard (see pool 1 note).
            if (p.isWeeklyOG) {
                if (p.totalPaid >= claim) p.totalPaid -= claim;
                else p.totalPaid = 0;
                // [v1.99.62 / M-01-pool2] Symmetric with pool1 fix.
                // Status-lost OGs already had totalOGPrincipal removed
                // at status-loss in processMatches(). Decrementing again
                // here double-counts, understating the dormancy denominator.
                if (!p.weeklyOGStatusLost) {
                    if (totalOGPrincipal >= claim) totalOGPrincipal -= claim;
                    else totalOGPrincipal = 0;
                }
                // [v1.99.38 / A1] Same guard as pool1 -- decrement on parity loss.
                // [v1.99.39 / AUDIT-INFO-01] Unreachable -- same reasoning as pool1.
            }
            _withdrawAndTransfer(msg.sender, claim);
            emit ResetRefundClaimed(msg.sender, resetDrawRefundDraw2, claim);
            if (claim < netCost) emit ResetRefundPartial(msg.sender, resetDrawRefundDraw2, claim, netCost);
        }
    }

    /// @notice Refunds the caller's commitment deposit if it was not consumed as a draw-1 ticket. [v1.99.18 / I-01]
    /// @dev [v1.99.16 / I-03] commitmentRefundPool is set by emergencyResetDraw() if
    ///      draw 1 is reset: the full TICKET_PRICE (net) is returned to the pool.
    ///      Refund = min(TICKET_PRICE, commitmentRefundPool) -- partial refund possible
    ///      if pool is nearly depleted. commitmentRefundDeadline (30 days) gates claims.
    ///      Clears p.commitmentPaid and decrements committedPlayerCount.
    ///      Distinct from claimSignupRefund() (failed PREGAME) and claimResetRefund()
    ///      (emergency reset of draws 2+). This refund is specifically for draw-1 resets.
    ///      [v1.99.43 / C] NO PHASE GUARD -- intentional by design. commitmentRefundPool
    ///      is only created by emergencyResetDraw() during ACTIVE draw 1. The pool expires
    ///      after commitmentRefundDeadline (30 days) and is swept by sweepResetRefundRemainder().
    ///      [v1.99.46] Callable in any phase including DORMANT (dormancy can activate
    ///      within 30 days of a draw-1 reset while the pool is still live). Prior
    ///      wording "pool is gone by other phases" was inaccurate. Pool expires at
    ///      commitmentRefundDeadline (30 days) or is swept -- not at phase boundary.
    ///      Identical rationale to withdrawTreasury() (v1.79 / I-03 NatSpec).
    function claimCommitmentRefund() external nonReentrant {
        if (commitmentRefundPool == 0) revert NothingToClaim();
        if (commitmentRefundDeadline > 0 && block.timestamp > commitmentRefundDeadline)
            revert ResetRefundExpired();

        PlayerData storage p = players[msg.sender];
        if (!p.commitmentPaid) revert ResetRefundNotEligible();

        uint256 claim = TICKET_PRICE <= commitmentRefundPool ? TICKET_PRICE : commitmentRefundPool;
        if (claim == 0) revert NothingToClaim();

        p.commitmentPaid = false;
        if (committedPlayerCount > 0) committedPlayerCount--;
        if (p.totalPaid >= claim) p.totalPaid -= claim;
        commitmentRefundPool -= claim;

        _withdrawAndTransfer(msg.sender, claim);
        emit CommitmentRefundClaimed(msg.sender, claim);
        if (claim < TICKET_PRICE) emit CommitmentRefundPartial(msg.sender, claim, TICKET_PRICE);
    }

    /// @notice Sweeps expired reset refund pool balances back into prizePot (or charity if DORMANT/CLOSED).
    /// @dev [v1.99.61 / L-06] POST-SETTLEMENT YIELD ATTRIBUTION: when this function
    ///      runs in CLOSED or DORMANT, it routes remainder to CHARITY and zeroes the
    ///      pool. _captureYield() subsequently sees a smaller nonPotAllocated and may
    ///      attribute the swept amount as apparent Aave yield landing in prizePot.
    ///      This is consequence-free in the current lifecycle (prizePot = 0
    ///      post-settlement). Any fork that re-opens ACTIVE after settlement must
    ///      address this yield-attribution gap before deployment.
    /// @dev [v1.77] Intentionally permissionless (no onlyOwner). Any caller can trigger the sweep
    ///      so the protocol does not rely on owner liveness to clear expired pools. The function
    ///      is safe to call by anyone: all routing is phase-gated (DORMANT/CLOSED routes to
    ///      CHARITY, otherwise to prizePot) and nonReentrant prevents concurrent execution.
    ///      No sensitive state is read during the sweep beyond the pool balance. [v1.99.14 / M-02]
    ///      [v1.99.6 / INFO] dormancyWeeklyPool reference removed. Since v1.99.4, DORMANT phase
    ///      routes directly to charity (dormancyPerHeadShare is pre-calculated at activation;
    ///      adding to dormancyPerHeadPool after the fact would create unclaimable funds).
    ///      sweepDormancyRemainder() atomically transitions DORMANT to CLOSED before returning,
    ///      making DORMANT and CLOSED routing mutually exclusive across calls.
    ///      [v1.86 / P5-OZ-I-01] The mutual exclusivity relies on EVM single-threaded execution
    ///      within a block -- there is no explicit lock mechanism. Concurrent execution is not
    ///      possible in the EVM; each transaction completes fully before the next begins.
    ///      [v1.99.9 / L-02] UX NOTE: ResetRefundExpiredSwept fires at pool level when this
    ///      function runs, but does NOT enumerate individual unclaimed players. A player who
    ///      misses the 30-day window receives no on-chain notification of forfeiture.
    ///      Front-ends MUST prominently display resetDrawRefundDeadline with a countdown
    ///      for all eligible claimants. The on-chain record is the pool deadline only.
    function sweepResetRefundRemainder() external nonReentrant {
        bool ticketPoolSweepable  = resetDrawRefundDraw != 0 && block.timestamp > resetDrawRefundDeadline;
        bool ticketPool2Sweepable = resetDrawRefundDraw2 != 0 && block.timestamp > resetDrawRefundDeadline2;
        bool commitmentPoolSweepable = commitmentRefundPool > 0
            && commitmentRefundDeadline > 0
            && block.timestamp > commitmentRefundDeadline;
        if (!ticketPoolSweepable && !ticketPool2Sweepable && !commitmentPoolSweepable)
            revert NothingToClaim();
        // [v1.99.27 / L-03 + M-01] CLOSED revert removed. The inner routing already
        // handles CLOSED by directing remainder to CHARITY. Blocking CLOSED with
        // any revert would permanently strand pools that expire post-game-close,
        // since no other function sweeps resetDrawRefundPool or resetDrawRefundPool2.

        if (ticketPoolSweepable) {
            uint256 remainder  = resetDrawRefundPool;
            uint256 closedDraw = resetDrawRefundDraw;
            resetDrawRefundPool     = 0;
            resetDrawRefundDraw     = 0;
            resetDrawRefundDeadline = 0;
            if (remainder > 0) {
                // [v1.99.4] DORMANT: route to charity. dormancyPerHeadShare pre-calculated
                // at activation -- adding to dormancyPerHeadPool creates unclaimable funds.
                // [v1.99.7 / AUDIT-I-01] Reformatted to match pool2/commitment block style.
                if (gamePhase == GamePhase.DORMANT || gamePhase == GamePhase.CLOSED) {
                    // [v1.99.37 / A3] POST-SETTLEMENT INVARIANT NOTE: after this
                    // transfer, the next _captureYield() call sees smaller
                    // nonPotAllocated (resetDrawRefundPool now 0), creating a gap
                    // that routes to prizePot as apparent yield. But prizePot is
                    // already 0 post-settlement, so this lands in a dead variable.
                    // USDC physically moved to CHARITY correctly. Accounting drift
                    // is consequence-free in CLOSED/DORMANT. Accepted design.
                    _withdrawAndTransfer(CHARITY, remainder);
                    emit CharityClaimed(remainder);
                } else {
                    prizePot += remainder;
                }
            }
            emit ResetRefundExpiredSwept(closedDraw, remainder);
        }

        if (ticketPool2Sweepable) {
            uint256 remainder2  = resetDrawRefundPool2;
            uint256 closedDraw2 = resetDrawRefundDraw2;
            resetDrawRefundPool2     = 0;
            resetDrawRefundDraw2     = 0;
            resetDrawRefundDeadline2 = 0;
            if (remainder2 > 0) {
                // [v1.99.4] DORMANT: route to charity.
                // [v1.99.6 / AUDIT-L-01] Removed dead else-if(CLOSED) -- CLOSED already
                // handled by the preceding DORMANT||CLOSED condition.
                if (gamePhase == GamePhase.DORMANT || gamePhase == GamePhase.CLOSED) {
                    _withdrawAndTransfer(CHARITY, remainder2);
                    emit CharityClaimed(remainder2);
                } else {
                    prizePot += remainder2;
                }
            }
            emit ResetRefundExpiredSwept(closedDraw2, remainder2);
        }

        if (commitmentPoolSweepable) {
            uint256 commitRemainder = commitmentRefundPool;
            uint256 savedCommitDraw = commitmentRefundDraw;
            commitmentRefundPool     = 0;
            commitmentRefundDraw     = 0;
            commitmentRefundDeadline = 0;
            if (commitRemainder > 0) {
                // [v1.99.4] DORMANT: route to charity.
                // [v1.99.6 / AUDIT-L-01] Removed dead else-if(CLOSED) -- CLOSED already
                // handled by the preceding DORMANT||CLOSED condition.
                if (gamePhase == GamePhase.DORMANT || gamePhase == GamePhase.CLOSED) {
                    _withdrawAndTransfer(CHARITY, commitRemainder);
                    emit CharityClaimed(commitRemainder);
                } else {
                    prizePot += commitRemainder;
                }
            }
            emit CommitmentRefundExpiredSwept(savedCommitDraw, commitRemainder);
        }
    }

    /// @notice Marks a single inactive non-OG player as lapsed.
    function markLapsed(address player) external onlyOwner {
        if (gamePhase != GamePhase.ACTIVE) revert GameNotActive();
        if (drawPhase != DrawPhase.IDLE)   revert DrawInProgress();
        PlayerData storage p = players[player];
        if (p.lastBoughtDraw == 0)               revert NothingToClaim();
        if (p.isUpfrontOG)                       revert AlreadyOG();
        if (p.isWeeklyOG && !p.weeklyOGStatusLost) revert AlreadyOG();
        if (p.isLapsed)                          revert NothingToClaim();
        if (p.lastBoughtDraw >= currentDraw)     revert NothingToClaim();
        p.isLapsed = true;
        lapsedPlayerCount++;
        emit PlayerLapsed(player, currentDraw);
    }

    /// @notice Marks up to MAX_LAPSE_BATCH (500) inactive non-OG players as lapsed in one call.
    /// @dev [v1.79 / I-02] Players that fail a guard condition (isUpfrontOG, isWeeklyOG without
    ///      statusLost, isLapsed, lastBoughtDraw == 0, lastBoughtDraw >= currentDraw) are silently
    ///      skipped -- no event, no revert. Operators submitting mixed-validity batches receive
    ///      no on-chain indication of which addresses were skipped. Use markLapsed() for
    ///      single-address validation if needed (it reverts on any failed guard).
    function batchMarkLapsed(address[] calldata playerList) external onlyOwner {
        if (gamePhase != GamePhase.ACTIVE) revert GameNotActive();
        if (drawPhase != DrawPhase.IDLE)   revert DrawInProgress();
        if (playerList.length > MAX_LAPSE_BATCH) revert ExceedsLimit();
        uint256 len = playerList.length;
        for (uint256 i = 0; i < len; i++) {
            PlayerData storage p = players[playerList[i]];
            if (p.lastBoughtDraw == 0)                 continue;
            if (p.isUpfrontOG)                         continue;
            if (p.isWeeklyOG && !p.weeklyOGStatusLost) continue;
            if (p.isLapsed)                            continue;
            if (p.lastBoughtDraw >= currentDraw)       continue;
            p.isLapsed = true;
            lapsedPlayerCount++;
            emit PlayerLapsed(playerList[i], currentDraw);
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // PRIZE CLAIMS
    // ═══════════════════════════════════════════════════════════════════════

    /// @notice Claims all accumulated weekly prizes for the caller.
    /// @dev [v1.99.10 / L-01] POST-SWEEP GUARD: totalUnclaimedPrizes == 0 is a
    ///      permanent sentinel after sweepUnclaimedPrizes() runs. Without this guard,
    ///      a player with stale p.unclaimedPrizes could call after the sweep and
    ///      receive a transfer funded by treasury USDC if aaveExited=true and owner
    ///      has not yet withdrawn. This guard closes the double-pay vector entirely.
    ///      Parallel: claimEndgame() uses endgameOwed < endgamePerOG as its sentinel.
    function claimPrize() external nonReentrant {
        // [v1.99.10 / L-01] Guard must fire before p.unclaimedPrizes check.
        if (totalUnclaimedPrizes == 0) revert NothingToClaim();
        PlayerData storage p = players[msg.sender];
        uint256 amount = p.unclaimedPrizes;
        if (amount == 0) revert NothingToClaim();
        p.unclaimedPrizes = 0;
        if (totalUnclaimedPrizes >= amount) totalUnclaimedPrizes -= amount;
        else totalUnclaimedPrizes = 0;
        _withdrawAndTransfer(msg.sender, amount);
        emit PrizeClaimed(msg.sender, amount);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // TREASURY
    // ═══════════════════════════════════════════════════════════════════════

    /// @notice Withdraws a specified amount from the protocol treasury to a recipient address.
    /// @dev [v1.78 / I-03] No gamePhase restriction -- intentional. treasuryBalance is protocol
    ///      revenue (15% slice of all ticket/OG payments), segregated from player-facing pools.
    ///      dormancyOGPool, dormancyCasualRefundPool, dormancyPerHeadPool,
    ///      resetDrawRefundPool and commitmentRefundPool are all tracked
    ///      independently. Withdrawing treasury during DORMANT or CLOSED does not reduce player
    ///      refund entitlements. The solvency check in resolveWeek() confirms this separation.
    ///      [v1.99.7 / AUDIT-I-02] dormancyWeeklyPool removed in v1.99.4; replaced by
    ///      dormancyCasualRefundPool + dormancyPerHeadPool as listed above.
    function withdrawTreasury(uint256 amount, address recipient) external onlyOwner nonReentrant {
        if (amount == 0 || amount > treasuryBalance) revert InsufficientBalance();
        if (recipient == address(0)) revert InvalidAddress();
        treasuryBalance        -= amount;
        // [v1.99.63 / I-03] Pure audit counter. Never used in any formula or guard.
        // Overflow unreachable: at max scale 55K players x 2 tickets x 52 draws
        // x $1.50 treasury share = ~$8.58M << uint256 max.
        totalTreasuryWithdrawn += amount;
        _withdrawAndTransfer(recipient, amount);
        emit TreasuryWithdrawal(amount, recipient);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // EMERGENCY BRAKE
    // ═══════════════════════════════════════════════════════════════════════

    /// @notice Proposes a reduction to the prizeRateMultiplier, subject to a 7-day timelock.
    /// @dev [v1.76 / I-01] Proposals intentionally permitted during active draw phases
    ///      (no drawPhase guard at proposal time). Only execution requires IDLE.
    ///      This asymmetry vs breath proposals is by design -- rate proposals write only
    ///      to pendingMultiplier without reading sensitive financial state.
    function proposePrizeRateReduction(uint256 newMultiplier, bytes32 reason) external onlyOwner {
        if (gamePhase != GamePhase.ACTIVE)           revert WrongPhase();
        if (newMultiplier >= prizeRateMultiplier)    revert CanOnlyDecrease();
        if (newMultiplier < 5000)                    revert BelowMinimum();
        if (pendingMultiplier != 0)                  revert TimelockPending();
        pendingMultiplier       = newMultiplier;
        pendingMultiplierReason = reason;
        multiplierEffectiveTime = block.timestamp + TIMELOCK_DELAY;
        emit PrizeRateReductionProposed(newMultiplier, multiplierEffectiveTime, reason);
    }

    /// @notice Executes a pending prize rate reduction after the 7-day timelock has elapsed.
    function executePrizeRateReduction() external onlyOwner {
        if (gamePhase != GamePhase.ACTIVE) revert WrongPhase();
        if (drawPhase != DrawPhase.IDLE)   revert DrawInProgress();
        if (pendingMultiplier == 0)        revert NoTimelockPending();
        if (pendingMultiplier >= prizeRateMultiplier) revert WrongPhase();
        if (block.timestamp < multiplierEffectiveTime) revert TooEarly();
        uint256 old             = prizeRateMultiplier;
        prizeRateMultiplier     = pendingMultiplier;
        lastMultiplierChangeReason = pendingMultiplierReason;
        pendingMultiplier       = 0;
        pendingMultiplierReason = 0;
        multiplierEffectiveTime = 0;
        emit PrizeRateReductionExecuted(old, prizeRateMultiplier, lastMultiplierChangeReason);
    }

    /// @notice Cancels a pending prize rate reduction before it is executed.
    /// @dev [v1.78 / L-03] Direction check uses current prizeRateMultiplier at cancel time.
    ///      This is safe: prizeRateMultiplier only changes via executePrizeRateReduction/Increase,
    ///      which atomically clears pendingMultiplier. A pending proposal and a changed
    ///      prizeRateMultiplier therefore cannot coexist -- the direction check is always correct.
    function cancelPrizeRateReduction() external onlyOwner {
        if (pendingMultiplier == 0) revert NoTimelockPending();
        if (pendingMultiplier >= prizeRateMultiplier) revert WrongPhase();
        pendingMultiplier       = 0;
        pendingMultiplierReason = 0;
        multiplierEffectiveTime = 0;
        emit PrizeRateReductionCancelled();
    }

    /// @notice Cancels a pending prize rate increase before it is executed.
    /// @dev [v1.78 / L-03] See cancelPrizeRateReduction() -- same direction check safety applies.
    function cancelPrizeRateIncrease() external onlyOwner {
        if (pendingMultiplier == 0) revert NoTimelockPending();
        if (pendingMultiplier <= prizeRateMultiplier) revert WrongPhase();
        pendingMultiplier       = 0;
        pendingMultiplierReason = 0;
        multiplierEffectiveTime = 0;
        emit PrizeRateIncreaseCancelled();
    }

    /// @notice Proposes an increase to the prizeRateMultiplier, subject to a 7-day timelock.
    /// @dev [v1.76 / I-01] Proposals intentionally permitted during active draw phases
    ///      (no drawPhase guard at proposal time). Only execution requires IDLE.
    ///      This asymmetry vs breath proposals is by design -- rate proposals write only
    ///      to pendingMultiplier without reading sensitive financial state.
    function proposePrizeRateIncrease(uint256 newMultiplier, bytes32 reason) external onlyOwner {
        if (gamePhase != GamePhase.ACTIVE)           revert WrongPhase();
        if (!obligationLocked)                       revert TooEarly();
        if (newMultiplier <= prizeRateMultiplier)    revert WrongPhase();
        if (newMultiplier > 10000)                   revert ExceedsLimit();
        if (pendingMultiplier != 0)                  revert TimelockPending();
        pendingMultiplier       = newMultiplier;
        pendingMultiplierReason = reason;
        multiplierEffectiveTime = block.timestamp + TIMELOCK_DELAY;
        emit PrizeRateIncreaseProposed(newMultiplier, multiplierEffectiveTime, reason);
    }

    /// @notice Executes a pending prize rate increase after the 7-day timelock has elapsed.
    function executePrizeRateIncrease() external onlyOwner {
        if (gamePhase != GamePhase.ACTIVE) revert WrongPhase();
        if (drawPhase != DrawPhase.IDLE)   revert DrawInProgress();
        if (pendingMultiplier == 0)        revert NoTimelockPending();
        if (pendingMultiplier <= prizeRateMultiplier) revert WrongPhase();
        if (block.timestamp < multiplierEffectiveTime) revert TooEarly();
        uint256 old             = prizeRateMultiplier;
        prizeRateMultiplier     = pendingMultiplier;
        lastMultiplierChangeReason = pendingMultiplierReason;
        pendingMultiplier       = 0;
        pendingMultiplierReason = 0;
        multiplierEffectiveTime = 0;
        emit PrizeRateIncreaseExecuted(old, prizeRateMultiplier, lastMultiplierChangeReason);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // BREATH OVERRIDE
    // ═══════════════════════════════════════════════════════════════════════

    /// @notice Proposes a manual override of the breathMultiplier, subject to a 7-day timelock.
    /// @dev [v2.71 L-01] Upward overrides (newMultiplier > breathMultiplier) are gated:
    ///      pot must be >= 80% of requiredEndPot when obligationLocked. Prevents manually
    ///      opening breath while the pot is under-funded relative to OG obligation target.
    ///      After executeBreathOverride() confirms the override, the predictive formula
    ///      is suppressed for BREATH_COOLDOWN_DRAWS (3 draws), giving the override time
    ///      to take meaningful effect before the formula resumes. See breathOverrideLockUntilDraw.
    ///      Downward overrides have no pot-health gate — reducing breath is always safe.
    function proposeBreathOverride(uint256 newMultiplier, bytes32 reason)
        external onlyOwner nonReentrant
    {
        // [v1.74 / I-05] Phase guard moved before _captureYield(). Previously _captureYield()
        // fired before the guard, wasting an Aave balance read when called in DORMANT/CLOSED.
        if (gamePhase != GamePhase.ACTIVE) revert WrongPhase();
        if (drawPhase != DrawPhase.IDLE)   revert DrawInProgress();
        _captureYield();
        if (newMultiplier < breathRailMin || newMultiplier > breathRailMax) revert ExceedsLimit();
        if (newMultiplier == breathMultiplier) revert BreathUnchanged();
        if (pendingBreathOverride != 0)    revert TimelockPending();

        if (newMultiplier > breathMultiplier) {
            // [v2.71 L-01] Gate: pot must be >= 80% of requiredEndPot before breath can be raised manually.
            // Replaces old trajectory-line gate which no longer governs auto-breathe in v2.70+.
            if (obligationLocked && requiredEndPot > 0
                && prizePot * 10000 / requiredEndPot < 8000) revert PotBelowTrajectory();
        }

        pendingBreathOverride       = newMultiplier;
        pendingBreathOverrideReason = reason;
        breathOverrideEffectiveTime = block.timestamp + TIMELOCK_DELAY;

        emit BreathOverrideProposed(newMultiplier, breathOverrideEffectiveTime, reason);
    }

    /// @notice Executes a pending breath override after the 7-day timelock has elapsed.
    /// @dev [v2.71 L-02] Three guards run at execution time:
    ///      1. Timelock: block.timestamp >= breathOverrideEffectiveTime (7-day delay).
    ///      2. Pot-health gate for upward overrides: prizePot >= 80% of requiredEndPot
    ///         when obligationLocked. Consistent with the gate at proposeBreathOverride().
    ///      3. After execution: sets breathOverrideLockUntilDraw = currentDraw + BREATH_COOLDOWN_DRAWS.
    ///         The predictive formula in _checkAutoAdjust() is suppressed for 3 draws, preserving
    ///         the override before the formula resumes normal operation.
    function executeBreathOverride() external onlyOwner nonReentrant {
        if (pendingBreathOverride == 0) revert NoTimelockPending();
        if (block.timestamp < breathOverrideEffectiveTime) revert TooEarly();
        // [v1.99.28 / L-02] gamePhase guard added: modifying breathMultiplier
        // in DORMANT/CLOSED is semantically incorrect -- breath has no effect
        // when gamePhase != ACTIVE. Consistent with executeBreathRails().
        if (gamePhase != GamePhase.ACTIVE) revert WrongPhase();

        _captureYield();
        if (drawPhase != DrawPhase.IDLE) revert DrawInProgress();
        uint256 oldMultiplier = breathMultiplier;
        uint256 newMultiplier = pendingBreathOverride;

        if (newMultiplier < breathRailMin || newMultiplier > breathRailMax) revert ExceedsLimit();

        if (newMultiplier > oldMultiplier) {
            // [v2.71 L-01] Consistent with proposeBreathOverride gate.
            if (obligationLocked && requiredEndPot > 0
                && prizePot * 10000 / requiredEndPot < 8000) revert PotBelowTrajectory();
        }

        breathMultiplier            = newMultiplier;
        lastBreathAdjustDraw        = currentDraw;
        lastBreathOverrideReason    = pendingBreathOverrideReason;
        pendingBreathOverride       = 0;
        pendingBreathOverrideReason = bytes32(0);
        breathOverrideEffectiveTime = 0;
        // [v2.71 M-01] Protect the override from predictive formula for 3 draws.
        breathOverrideLockUntilDraw = currentDraw + BREATH_COOLDOWN_DRAWS;

        emit BreathMultiplierAdjusted(oldMultiplier, newMultiplier, newMultiplier > oldMultiplier);
        emit BreathOverrideExecuted(oldMultiplier, newMultiplier, lastBreathOverrideReason);
    }

    /// @notice Cancels a pending breath override proposal before it is executed.
    function cancelBreathOverride() external onlyOwner {
        if (pendingBreathOverride == 0) revert NoTimelockPending();
        uint256 cancelled           = pendingBreathOverride;
        pendingBreathOverride       = 0;
        pendingBreathOverrideReason = bytes32(0);
        breathOverrideEffectiveTime = 0;
        emit BreathOverrideCancelled(cancelled);
    }

    /// @notice Proposes updated minimum and maximum bounds for breathMultiplier, subject to 7-day timelock.
    /// @dev [v1.72 / M-02] Resolves C-04 carry-forward. Without a timelock, an owner (or compromised
    ///      key) could instantly set breathRailMin = breathRailMax = 2000 (20%), forcing the predictive
    ///      formula to extract 20% of prizePot in the next draw -- a prize manipulation vector even if
    ///      not direct theft. Timelock matches TIMELOCK_DELAY (7 days) used for all other rate controls.
    ///      Only one pending rails proposal allowed at a time.
    /// @param reason Off-chain label for audit trail (bytes32, consistent with all other proposals).
    function proposeBreathRails(uint256 newMin, uint256 newMax, bytes32 reason) external onlyOwner {
        // [v1.73 / M-01] ACTIVE only -- same restriction as proposePrizeRateReduction.
        // A PREGAME proposal could fire mid-game 7 days later. Rails have no meaning in DORMANT/CLOSED.
        if (gamePhase != GamePhase.ACTIVE) revert WrongPhase();
        if (drawPhase != DrawPhase.IDLE)   revert DrawInProgress();
        if (newMin < ABSOLUTE_BREATH_FLOOR)   revert BelowMinimum();
        if (newMax > ABSOLUTE_BREATH_CEILING) revert ExceedsLimit();
        if (newMax < newMin)                  revert ExceedsLimit();
        // [v1.73 / L-04] No-op guard -- consistent with proposeBreathOverride and proposeFeedChange.
        if (newMin == breathRailMin && newMax == breathRailMax) revert BreathUnchanged();
        if (breathRailsEffectiveTime != 0)    revert TimelockPending();
        pendingBreathRailMin     = newMin;
        pendingBreathRailMax     = newMax;
        breathRailsEffectiveTime = block.timestamp + TIMELOCK_DELAY;
        emit BreathRailsProposed(newMin, newMax, breathRailsEffectiveTime, reason);
    }

    /// @notice Cancels a pending breath rails proposal before it is executed.
    function cancelBreathRails() external onlyOwner {
        if (breathRailsEffectiveTime == 0) revert NoTimelockPending();
        uint256 cMin             = pendingBreathRailMin;
        uint256 cMax             = pendingBreathRailMax;
        pendingBreathRailMin     = 0;
        pendingBreathRailMax     = 0;
        breathRailsEffectiveTime = 0;
        emit BreathRailsProposalCancelled(cMin, cMax);
    }

    /// @notice Executes a pending breath rails update after the 7-day timelock has elapsed.
    /// @dev Clamps breathMultiplier to new rails immediately if it falls outside.
    ///      Cancels any pending breath override that would fall outside the new rails.
    ///      [v1.99.70 / L-01 CORRECTION] Both gamePhase == ACTIVE and drawPhase == IDLE
    ///      are enforced at execution. The stuck-draw mid-execution scenario is not
    ///      possible -- the function reverts DrawInProgress() if drawPhase != IDLE.
    ///      Prior v1.99.68 note incorrectly stated only gamePhase was checked.
    ///      [v1.73 / L-02] Also cancels pending override if it equals breathMultiplier after clamping --
    ///      executing it would revert BreathUnchanged(). Cleaner to cancel it now.
    function executeBreathRails() external onlyOwner {
        if (breathRailsEffectiveTime == 0)                   revert NoTimelockPending();
        if (block.timestamp < breathRailsEffectiveTime)      revert TooEarly();
        // [v1.73 / M-01] ACTIVE only -- rails are dead state in DORMANT/CLOSED.
        if (gamePhase != GamePhase.ACTIVE) revert WrongPhase();
        if (drawPhase != DrawPhase.IDLE)                     revert DrawInProgress();
        uint256 newMin           = pendingBreathRailMin;
        uint256 newMax           = pendingBreathRailMax;
        pendingBreathRailMin     = 0;
        pendingBreathRailMax     = 0;
        breathRailsEffectiveTime = 0;
        if (breathMultiplier < newMin) {
            emit BreathMultiplierAdjusted(breathMultiplier, newMin, true);
            breathMultiplier     = newMin;
            lastBreathAdjustDraw = currentDraw;
        } else if (breathMultiplier > newMax) {
            emit BreathMultiplierAdjusted(breathMultiplier, newMax, false);
            breathMultiplier     = newMax;
            lastBreathAdjustDraw = currentDraw;
        }
        breathRailMin = newMin;
        breathRailMax = newMax;
        emit BreathRailsUpdated(newMin, newMax, currentDraw);
        // Cancel pending override if out of new rails OR if it now equals breathMultiplier
        // (clamping could have set breathMultiplier == pendingBreathOverride, making it a no-op).
        if (pendingBreathOverride != 0
            && (pendingBreathOverride < newMin
                || pendingBreathOverride > newMax
                || pendingBreathOverride == breathMultiplier)) {
            uint256 cancelled           = pendingBreathOverride;
            pendingBreathOverride       = 0;
            pendingBreathOverrideReason = bytes32(0);
            breathOverrideEffectiveTime = 0;
            emit BreathOverrideCancelled(cancelled);
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // AAVE EXIT
    // ═══════════════════════════════════════════════════════════════════════

    /// @notice Proposes a managed exit from Aave, starting a 7-day timelock.
    /// @dev [v1.79 / I-01] No gamePhase or drawPhase guard -- intentional. The 7-day timelock
    ///      is the primary protection against hasty exit. Aave withdrawal can be proposed at any
    ///      game phase; _withdrawAndTransfer() handles aaveExited correctly throughout the draw
    ///      cycle so a mid-draw execution (though requiring a deliberate 7-day wait) is safe.
    function proposeAaveExit() external onlyOwner {
        if (aaveExited) revert AaveAlreadyExited();
        if (aaveExitEffectiveTime != 0) revert TimelockPending();
        aaveExitEffectiveTime = block.timestamp + TIMELOCK_DELAY;
        emit AaveExitProposed(aaveExitEffectiveTime);
    }

    /// @notice Executes the Aave exit after the 7-day timelock, withdrawing all aUSDC to USDC.
    /// @dev [v1.99.43 / A+1] Also uses a bare IPool.withdraw() call -- see
    ///      activateAaveEmergency() NatSpec for the shared intentional-bare-call rationale.
    function executeAaveExit() external onlyOwner nonReentrant {
        if (aaveExited) revert AaveAlreadyExited();
        if (aaveExitEffectiveTime == 0) revert NoTimelockPending();
        if (block.timestamp < aaveExitEffectiveTime) revert TooEarly();
        aaveExitEffectiveTime = 0;
        uint256 aBalance = IERC20(aUSDC).balanceOf(address(this));
        if (aBalance > 0) {
            uint256 balBefore = IERC20(USDC).balanceOf(address(this));
            IPool(AAVE_POOL).withdraw(USDC, type(uint256).max, address(this));
            uint256 received = IERC20(USDC).balanceOf(address(this)) - balBefore;
            if (received < aBalance) revert AaveLiquidityLow();
        }
        aaveExited = true;
        IERC20(USDC).approve(AAVE_POOL, 0);
        emit AaveExitExecuted(IERC20(USDC).balanceOf(address(this)));
    }

    /// @notice Cancels a pending Aave exit before the timelock elapses.
    function cancelAaveExit() external onlyOwner {
        if (aaveExitEffectiveTime == 0) revert NoTimelockPending();
        aaveExitEffectiveTime = 0;
        emit AaveExitCancelled();
    }

    /// @notice Immediately exits Aave without a timelock in anticipation of a liquidity crisis.
    /// @dev [v1.77 / M-02] Pre-check gate removed. The prior guard was:
    ///      `if (aBalance < effectiveObligation / 2) revert AaveLiquidityLow()`
    ///      This had inverted logic: it blocked emergency exit precisely when Aave liquidity
    ///      was genuinely failing (low aBalance). The function exists to handle that exact
    ///      scenario. onlyOwner + nonReentrant is sufficient access control. The post-withdraw
    ///      check `if (received < aBalance) revert AaveLiquidityLow()` is retained -- it
    ///      catches the case where Aave's withdraw returns less than the aToken balance,
    ///      which is a genuine mid-call liquidity failure distinct from the pre-call gate.
    ///      [v1.99.11 / M-02] FULL AAVE PAUSE RISK: if Aave's Guardian pauses both supply
    ///      AND withdraw (extreme scenario: hack mitigation, catastrophic depeg), all five
    ///      exit functions revert and game settlement is blocked. aUSDC remains safely in
    ///      the contract -- no funds lost. The correct response is to wait for Aave to
    ///      unfreeze and then call this function. Adding try/catch would set aaveExited=true
    ///      without receiving USDC, breaking _captureYield() accounting entirely.
    ///      Accepted risk: a full Aave V3 withdraw pause has never occurred in production.
    ///      [v1.99.43 / A+1] BARE WITHDRAW -- INTENTIONAL: IPool.withdraw() is called
    ///      without try/catch here and in executeAaveExit(). A try/catch that continues
    ///      after failure would dangerously set aaveExited=true with no USDC withdrawn.
    ///      The bare call is intentionally strict -- owner sees the revert, can retry.
    ///      Supply() calls elsewhere use try/catch because supply failure is recoverable;
    ///      exit failure during a crisis is not -- the function must be atomic.
    function activateAaveEmergency() external onlyOwner nonReentrant {
        if (aaveExited) revert AaveAlreadyExited();

        uint256 aBalance = IERC20(aUSDC).balanceOf(address(this));
        if (aBalance > 0) {
            uint256 balBefore = IERC20(USDC).balanceOf(address(this));
            IPool(AAVE_POOL).withdraw(USDC, type(uint256).max, address(this));
            uint256 received = IERC20(USDC).balanceOf(address(this)) - balBefore;
            if (received < aBalance) revert AaveLiquidityLow();
        }
        aaveExited            = true;
        // [v1.90 / AUDIT-INFO-01] Emit AaveExitCancelled if a pending proposeAaveExit() timelock
        // is being silently abandoned. Emergency activation bypasses the timelock by design,
        // but without this event off-chain monitors would have no signal the proposal was voided.
        if (aaveExitEffectiveTime != 0) emit AaveExitCancelled();
        aaveExitEffectiveTime = 0;
        IERC20(USDC).approve(AAVE_POOL, 0);
        emit AaveEmergencyActivated(IERC20(USDC).balanceOf(address(this)));
    }

    // ═══════════════════════════════════════════════════════════════════════
    // FEED MANAGEMENT
    // ═══════════════════════════════════════════════════════════════════════

    /// @notice Proposes replacing one of the 32 primary Chainlink price feeds, with a 7-day timelock.
    /// @dev [v1.79 / I-03] SEQUENCER_FEED guard added. Proposing the sequencer uptime feed as
    ///      a price feed is owner-error only (onlyOwner), but would cause silent fallback to
    ///      lastValidPrices since the sequencer feed returns 0/1 rather than an asset price.
    ///      [v1.79 / L-01] Concurrent pending feed changes are safe: the execution-time cross-check
    ///      in executeFeedChange() re-verifies no two active slots point to the same aggregator,
    ///      accounting for any concurrent proposals or staggered executions.
    ///      [v1.99.39 / AUDIT-L-01] OPERATOR RUNBOOK: This function does not validate that the
    ///      candidate feed returns live data. Address collision guards pass for a correctly
    ///      formatted but dead or misconfigured aggregator. The 7-day timelock IS the
    ///      verification window -- not a rubber stamp. Before proposing:
    ///      1. Simulate _readPrice() logic against the candidate address on Arbitrum mainnet.
    ///      2. Confirm latestRoundData() returns a non-stale, in-range price.
    ///      3. Include the candidate address in monitoring alert workflow so any anomaly
    ///         triggers cancelFeedChange() before executeFeedChange() becomes callable.
    ///      An in-contract latestRoundData() call at proposal time was considered and
    ///      rejected: adds external call complexity to governance; a feed passing at
    ///      proposal time may die before execution. Off-chain verification is correct.
    function proposeFeedChange(uint256 index, address newFeed) external onlyOwner {
        if (index >= NUM_ASSETS) revert ExceedsLimit();
        if (gamePhase != GamePhase.ACTIVE) revert WrongPhase();
        if (newFeed == address(0))         revert InvalidAddress();
        if (newFeed == USDC)               revert InvalidAddress();
        if (newFeed == aUSDC)              revert InvalidAddress();
        if (newFeed == address(this))      revert InvalidAddress();
        // [v1.82 / I-01] Null check removed -- constructor (C-03) reverts if SEQUENCER_FEED == 0.
        // SEQUENCER_FEED is immutable, so != address(0) is permanently true. Dead condition removed.
        if (newFeed == SEQUENCER_FEED) revert InvalidAddress();
        if (newFeed == priceFeeds[index])  revert FeedUnchanged();
        if (pendingFeedChanges[index].effectiveTime != 0) revert TimelockPending();
        for (uint256 k = 0; k < NUM_ASSETS; k++) {
            if (k != index && priceFeeds[k] == newFeed) revert InvalidAddress();
        }
        for (uint256 j = 0; j < NUM_ASSETS; j++) {
            if (j != index && pendingFeedChanges[j].effectiveTime != 0
                && pendingFeedChanges[j].newFeed == newFeed) revert InvalidAddress();
        }
        // [v1.83 / AUDIT-I-02] Reject addresses matching any reserveFeeds slot.
        // reserveFeeds is consumed only at PREGAME (startGame), so no functional impact on a
        // live game. But a feed change that duplicates a reserve address is a latent correctness
        // gap for any fork extending reserve fallback logic into ACTIVE. Close it now.
        for (uint256 r = 0; r < NUM_RESERVES; r++) {
            if (reserveFeeds[r] != address(0) && reserveFeeds[r] == newFeed)
                revert InvalidAddress();
        }
        pendingFeedChanges[index] = PendingFeedChange(newFeed, block.timestamp + TIMELOCK_DELAY);
        emit FeedChangeProposed(index, newFeed, block.timestamp + TIMELOCK_DELAY);
    }

    /// @notice Executes a pending feed change after the 7-day timelock in IDLE draw phase.
    /// @dev Replaces priceFeeds[index] with the proposed newFeed. Zeroes lastValidPrices[index]
    ///      and weekStartPrices[index] so the new feed starts fresh next resolveWeek() call --
    ///      no stale price from the old feed bleeds into the first draw using the new feed.
    ///      Cross-check: rejects newFeed if it already exists at any other priceFeeds slot.
    ///      Duplicate guard runs against current priceFeeds (after prior changes are already live)
    ///      to prevent two slots pointing to the same Chainlink aggregator.
    ///      Only callable in ACTIVE phase, IDLE draw phase, after timelock has elapsed.
    ///      Deletes the pendingFeedChanges[index] entry on completion.
    ///      [v1.99.49 / L-04] No liveness check at execution time -- accepted.
    ///      A feed that died after proposal but before execution installs
    ///      a stale feed; resolveWeek() will emit FeedStaleFallback on the next
    ///      draw. Adding _readPriceFeed() revert at execution time would block
    ///      valid feeds that are momentarily stale. The 7-day window and the
    ///      proposeFeedChange() RUNBOOK (v1.99.39) are the correct mitigations.
    function executeFeedChange(uint256 index) external onlyOwner {
        PendingFeedChange storage pending = pendingFeedChanges[index];
        if (gamePhase != GamePhase.ACTIVE) revert WrongPhase();
        if (drawPhase != DrawPhase.IDLE)   revert DrawInProgress();
        if (pending.effectiveTime == 0)    revert NoTimelockPending();
        if (block.timestamp < pending.effectiveTime) revert TooEarly();
        address oldFeed = priceFeeds[index];
        for (uint256 k = 0; k < NUM_ASSETS; k++) {
            if (k != index && priceFeeds[k] == pending.newFeed) revert InvalidAddress();
        }
        priceFeeds[index]      = pending.newFeed;
        lastValidPrices[index] = 0;
        weekStartPrices[index] = 0;
        emit FeedChangeExecuted(index, oldFeed, pending.newFeed);
        delete pendingFeedChanges[index];
    }

    /// @notice Cancels a pending price feed change proposal.
    function cancelFeedChange(uint256 index) external onlyOwner {
        if (pendingFeedChanges[index].effectiveTime == 0) revert NoTimelockPending();
        emit FeedChangeCancelled(index);
        delete pendingFeedChanges[index];
    }

    // ═══════════════════════════════════════════════════════════════════════
    // EMERGENCY RESET
    // ═══════════════════════════════════════════════════════════════════════

    /// @notice Cancels the current draw mid-flight and issues refund pools for affected players.
    /// @dev [v1.88 / AUDIT-I-01] ACCESS CONTROL (corrected):
    ///      UNWINDING phase: both owner and non-owner may call _continueUnwind(). Non-owners are
    ///      gated by UNWIND_CONTINUATION_TIMEOUT to prevent owner censorship of unwind completion.
    ///      MATCHING / DISTRIBUTING phase: owner only, and owner must also wait DRAW_STUCK_TIMEOUT
    ///      (48 hours from phaseStartTimestamp). No bypass exists for the owner -- the timeout
    ///      applies equally to all callers. Non-owners cannot call in these phases at all.
    ///      FINALIZING / RESET_FINALIZING: both revert WrongPhase(). Use finalizeWeek() instead.
    ///      IDLE: reverts NotStuck(). No active draw to reset.
    ///      Fund recovery: Aave yield is captured first. Any prizes already distributed to
    ///      p.unclaimedPrizes in this draw are recovered from tierPools (the already-paid portion
    ///      is subtracted via distTierIndex/distWinnerIndex/currentTierPerWinner tracking).
    ///      Recovered funds return to prizePot. Two refund pools are funded:
    ///      [v1.99.3 / AUDIT-L-01] NOTE: EmergencyReset event amountReturned = recovered
    ///      undistributed tier pool funds only. Prizes already credited to p.unclaimedPrizes
    ///      in completed tiers are NOT included (they remain in totalUnclaimedPrizes, correctly
    ///      accounted). Full draw disruption = amountReturned + (distWinnerIndex * currentTierPerWinner).
    ///      [v1.99.29 / I-01] Prizes already credited to p.unclaimedPrizes in
    ///      fully-completed tiers (0 through distTierIndex-1) are NOT included
    ///      in amountReturned -- they legitimately belong to those winners.
    ///      commitmentRefundPool: draw-1 resets only, one-time, for pregame commitment payers.
    ///      resetDrawRefundPool / resetDrawRefundPool2: net ticket cost for this draw's buyers.
    ///      Unwind: _continueUnwind() reverses weeklyOGStatusLost and mulliganUsed state for any
    ///      OG whose status changed in this draw. Per-iteration gas guard prevents block overruns.
    ///      On completion drawPhase transitions to RESET_FINALIZING for finalizeWeek() to close.
    ///      [v1.99.10 / L-02] DRAW-52 EDGE CASE: if emergency reset fires during draw 52's
    ///      DISTRIBUTING phase (requires a 48h+ stall on the final draw -- extremely unlikely),
    ///      undistributed tier pool funds return to prizePot. After refinalize, resolveWeek()
    ///      reverts GameAlreadyClosed (currentDraw > TOTAL_DRAWS), so draw 52 cannot re-run.
    ///      Prizes already credited to p.unclaimedPrizes before the reset remain with those
    ///      players. Prizes not yet distributed are lost to the draw-52 pool; that surplus
    ///      instead flows through closeGame() as OG endgame. Net effect: casual draw-52 ticket
    ///      buyers who would have won prizes receive nothing from that pool; OGs gain proportional
    ///      endgame surplus. Economically visible but mechanically correct.
    ///      [v2.03 / NS-v2.02-03 / I-v2.02-07] CASUAL REBUY LOCKOUT: after emergencyResetDraw()
    ///      a casual player who already bought this draw (lastBoughtDraw == currentDraw) cannot
    ///      rebuy. Their AlreadyBoughtThisWeek guard fires. Their net ticket cost is refundable
    ///      via claimResetRefund() within RESET_REFUND_WINDOW (30 days).
    function emergencyResetDraw() external nonReentrant {
        if (drawPhase == DrawPhase.UNWINDING) {
            // [v1.99.89 / M-01] Timeout for non-owner manual callers.
            // Chainlink Automation bypasses this via completeDrawStep() --
            // immediate continuation is correct when automation is active.
            // This path is retained as a manual fallback only.
            if (msg.sender != owner()) {
                if (block.timestamp < phaseStartTimestamp + UNWIND_CONTINUATION_TIMEOUT)
                    revert TooEarly();
            }
            _continueUnwind();
            return;
        }

        if (msg.sender != owner()) revert OwnableUnauthorizedAccount(msg.sender);
        if (drawPhase == DrawPhase.IDLE) revert NotStuck();
        if (drawPhase == DrawPhase.FINALIZING
            || drawPhase == DrawPhase.RESET_FINALIZING) revert WrongPhase();
        if (block.timestamp < phaseStartTimestamp + DRAW_STUCK_TIMEOUT) revert TooEarly();

        uint256 amountReturned;
        for (uint256 i = 0; i < 4; i++) {
            if (tierPools[i] > 0) {
                // [v1.99.13 / AUDIT-INFO-01] alreadyPaid = 0 for completed tiers (i < distTierIndex)
                // is correct by invariant: distributePrizes() zeros tierPools[i] on tier
                // completion before advancing distTierIndex. So tierPools[i] == 0 already,
                // and remaining = 0 regardless. Only the active tier needs the offset.
                uint256 alreadyPaid = (i == distTierIndex)
                    ? distWinnerIndex * currentTierPerWinner : 0;
                uint256 remaining = tierPools[i] > alreadyPaid
                    ? tierPools[i] - alreadyPaid : 0;
                amountReturned += remaining;
                prizePot       += remaining;
                tierPools[i]    = 0;
            }
        }
        currentTierPerWinner = 0;
        if (currentDrawSeedReturn > 0) {
            amountReturned       += currentDrawSeedReturn;
            prizePot             += currentDrawSeedReturn;
            currentDrawSeedReturn = 0;
        }

        emergencyUnwindTotal = ogList.length;
        emergencyUnwindIndex = 0;
        lastResetDraw        = currentDraw;

        if (pendingBreathOverride != 0) {
            uint256 cancelled           = pendingBreathOverride;
            pendingBreathOverride       = 0;
            pendingBreathOverrideReason = bytes32(0);
            breathOverrideEffectiveTime = 0;
            emit BreathOverrideCancelled(cancelled);
        }
        // [v1.74 / Knock-on 2] Cancel pending breath rails proposal -- consistent with
        // proposeDormancy(). A pending rails proposal surviving an emergency reset would
        // be an operator surprise and is cleaner to discard with the rest of mid-draw state.
        if (breathRailsEffectiveTime != 0) {
            uint256 cMin             = pendingBreathRailMin;
            uint256 cMax             = pendingBreathRailMax;
            pendingBreathRailMin     = 0;
            pendingBreathRailMax     = 0;
            breathRailsEffectiveTime = 0;
            emit BreathRailsProposalCancelled(cMin, cMax);
        }
        // [v1.83 / AUDIT-L-01] Cancel pending dormancy proposal. Without this, a queued dormancy
        // (whose 24-hour timelock may have already elapsed) becomes callable at the next IDLE
        // window after reset finalizes -- a draw the owner never intended as a dormancy trigger.
        // proposeDormancy() cancels both pendingBreathOverride and breathRailsEffectiveTime;
        // symmetrically, emergencyResetDraw() should cancel dormancyEffectiveTime.
        if (dormancyEffectiveTime != 0) {
            dormancyEffectiveTime = 0;
            emit DormancyCancelled();
        }
        // [v1.99.27 / L-02] Cancel any pending prize-rate timelock for consistency
        // with breath override, breath rails, and dormancy cancellation above.
        // Without this, a stale proposal silently executes in the next IDLE window.
        if (pendingMultiplier != 0) {
            bool isReduction = pendingMultiplier < prizeRateMultiplier;
            pendingMultiplier       = 0;
            pendingMultiplierReason = bytes32(0);
            multiplierEffectiveTime = 0;
            if (isReduction) emit PrizeRateReductionCancelled();
            else             emit PrizeRateIncreaseCancelled();
        }
        // [v1.99.34 / F2] Cancel pending Aave exit timelock for consistency
        // with the other four cancelled timelocks. A proposed exit from before
        // the reset would silently become executable after 7 days with no
        // signal that the game state has changed. Mirrors dormancyEffectiveTime
        // cancellation pattern. Uses existing AaveExitCancelled event.
        if (aaveExitEffectiveTime != 0) {
            aaveExitEffectiveTime = 0;
            emit AaveExitCancelled();
        }

        matchOGIndex    = 0;
        matchNonOGIndex = 0;
        ogMatchingDone  = false;
        distTierIndex   = 0;
        distWinnerIndex = 0;
        winningResult   = 0;
        // [v1.99.63 / I-02] delete on fixed-size int256[NUM_ASSETS] array writes
        // 0 to all 32 elements individually (32 SSTOREs). Warm-slot: ~640K gas;
        // cold-slot: ~707K gas (32 x 22,100). Both within Arbitrum 32M block limit.
        // Unlike assembly length-zero for dynamic arrays, no cheaper alternative
        // exists for fixed-size arrays.
        delete weekPerformance;

        if (currentDraw == 1 && committedPlayerCount > 0 && commitmentRefundPool == 0) {
            // [v1.99.33 / LOW] PREGAME WEEKLY OG INTERACTION: at startGame(),
            // currentDrawNetTicketTotal += pregameWeeklyOGNetTotal. On a draw-1 reset,
            // this entire pregame weekly OG net revenue feeds resetDrawRefundPool.
            // Weekly OGs are eligible claimants (lastBoughtDraw=1 set at registration).
            // Their PREGAME registration fee refunds via this pool on draw-1 reset.
            // totalPaid and totalOGPrincipal are correctly decremented by
            // claimResetRefund(). Accounting is consistent -- interaction non-obvious.
            // [v1.99.21 / INFO] committedPlayerCount includes credit-path weekly OGs
            // who applied commitment credit at PREGAME registration (commitmentPaid = false).
            // Those players cannot call claimCommitmentRefund() -- it checks commitmentPaid.
            // Pool is oversized by TICKET_PRICE per credit-path weekly OG; the excess
            // sweeps to CHARITY after RESET_REFUND_WINDOW (30 days). No player is shorted.
            uint256 poolAmount = committedPlayerCount * TICKET_PRICE;
            if (poolAmount > prizePot) poolAmount = prizePot;
            commitmentRefundPool     = poolAmount;
            commitmentRefundDraw     = 1;
            commitmentRefundDeadline = block.timestamp + RESET_REFUND_WINDOW;
            prizePot                -= poolAmount;
            emit CommitmentRefundActivated(1, poolAmount);
        }

        if (currentDrawNetTicketTotal > 0) {
            uint256 poolAmount = currentDrawNetTicketTotal;
            if (poolAmount > prizePot) poolAmount = prizePot;
            if (resetDrawRefundDraw == 0) {
                resetDrawRefundPool     = poolAmount;
                resetDrawRefundDraw     = currentDraw;
                resetDrawRefundDeadline = block.timestamp + RESET_REFUND_WINDOW;
                prizePot               -= poolAmount;
            } else if (resetDrawRefundDraw2 == 0) {
                resetDrawRefundPool2     = poolAmount;
                resetDrawRefundDraw2     = currentDraw;
                resetDrawRefundDeadline2 = block.timestamp + RESET_REFUND_WINDOW;
                prizePot                -= poolAmount;
                emit ResetRefundOverflow(currentDraw, poolAmount);
            } else {
                // [v1.99.27 / M-03] THREE-RESET RUNBOOK: if both pools are occupied
                // when a third reset fires, this path is taken and affected players
                // receive no targeted refund. Their funds remain in prizePot (indirect
                // benefit to all players). To prevent this: call
                // sweepResetRefundRemainder() after each expired pool to free the slot
                // before a subsequent emergency reset. ResetRefundSkipped provides
                // off-chain visibility; no on-chain recourse exists for this path.
                // [v1.99.44 / F4] THREE-RESET WINDOW: if three resets fire within
                // 30 days without sweepResetRefundRemainder() clearing expired pools
                // between them, third-reset buyers have ticket revenue in prizePot
                // with no refund path. Their $10-$15 is permanently in the pot.
                // Operator MUST call sweepResetRefundRemainder() after each reset
                // to free a slot before the next reset can provide refunds.
                // Front-ends MUST monitor ResetRefundSkipped and alert affected users.
                emit ResetRefundSkipped(currentDraw, currentDrawNetTicketTotal);
            }
        }
        currentDrawTicketTotal              = 0;
        currentDrawNetTicketTotal           = 0;
        // [v1.99.6 / AUDIT-M-01] Reset casual counter on emergency reset.
        currentDrawCasualNetTicketTotal     = 0;
        _captureYield();
        // [v1.83 / AUDIT-I-01] Length-zero clear -- see resolveWeek() for full pattern explanation.
        assembly {
            sstore(jpWinners.slot, 0)
            sstore(p2Winners.slot, 0)
            sstore(p3Winners.slot, 0)
            sstore(p4Winners.slot, 0)
            sstore(weeklyNonOGPlayers.slot, 0)
        }

        DrawPhase fromPhase = drawPhase;
        phaseStartTimestamp = block.timestamp;
        // [v1.99.72 / P4-NEW-LOW-02] amountReturned = undistributed funds only.
        // Prizes already credited to p.unclaimedPrizes in completed tiers
        // REMAIN with those players and are NOT included here.
        // Full disruption = amountReturned + (distWinnerIndex * currentTierPerWinner).
        emit EmergencyReset(currentDraw, fromPhase, amountReturned);

        if (emergencyUnwindTotal == 0) {
            drawPhase = DrawPhase.RESET_FINALIZING;
            emit EmergencyUnwindComplete(currentDraw, 0);
        } else {
            drawPhase = DrawPhase.UNWINDING;
            _continueUnwind();
        }
    }

    /// @notice Processes one batch of OG status restorations after emergencyResetDraw().
    /// @dev [v1.99.24] Called from emergencyResetDraw() and recursively on UNWINDING
    ///      re-entry. Iterates ogList from emergencyUnwindIndex, restoring OGs whose
    ///      status was lost in the reset draw (statusLostAtDraw == lastResetDraw).
    ///      Gas guard: returns early if gasleft < 150,000. Caller retries on next tx.
    ///      Restoration: weeklyOGStatusLost = false, mulliganUsed = false (if used
    ///      in the reset draw). lastActiveWeek = lastResetDraw (v1.99.8 fix: prevents
    ///      streak gap on next buy). consecutiveWeeks NOT restored -- OG genuinely
    ///      missed the reset draw.
    ///      Asymmetry: statusLost path does not set lastActiveWeek; mulliganUsed
    ///      path does (see OZ-INFO-02 NatSpec in _continueUnwind inline comments).
    ///      [v1.99.27 / L-01 + I-02] PICKS ASYMMETRY: status-loss-restored OGs have
    ///      picks = 0 (cleared by processMatches() L-04 fix during the reset draw).
    ///      They must call submitPicks() or buyTickets() before the next draw resolves
    ///      to receive prize matching. Front-ends should check picks == 0 &&
    ///      isWeeklyOG && !weeklyOGStatusLost and prompt the player to re-submit.
    ///      Mulligan-restored OGs retain their prior picks -- no action required.
    ///      On completion: drawPhase = RESET_FINALIZING, emits EmergencyUnwindComplete.
    function _continueUnwind() internal {
        if (gasleft() < 150_000) revert InsufficientGasForBatch();
        // [v1.99.3 / AUDIT-L-01] STREAK RESTORATION: weeklyOGStatusLost and mulliganUsed are
        // restored. consecutiveWeeks is NOT restored (OG genuinely did not play draw N).
        // [v1.99.8 / I-05 -> LOW] lastActiveWeek is now set to lastResetDraw (not -1).
        // Prior code: lastResetDraw - 1. This caused _updateStreakTracking() to see a gap
        // of 2 on the next draw, resetting streak to 1 even for an OG at streak N-1 who was
        // a victim of the reset draw. Fix: lastResetDraw means "last active was draw N-1,
        // so draw N+1 is consecutive." Streak preserved correctly for restored OGs.
        // Condition for issue: emergency reset AND OG missed that draw AND near qualification.
        // Disclosed proactively in audit submission narrative.
        uint256 start = emergencyUnwindIndex;
        uint256 end   = start + MAX_UNWIND_PER_TX;
        if (end > emergencyUnwindTotal) end = emergencyUnwindTotal;

        for (uint256 i = start; i < end; i++) {
            // [v1.6 / I-03] Per-iteration gas guard. Worst-case iteration (OG with both
            // weeklyOGStatusLost and mulliganUsed reversals) writes 6-8 storage slots (~120K gas).
            // [v2.04 / L-v2.03-01] At MAX_UNWIND_PER_TX = 500 that is ~25M gas --
            // within Arbitrum's 32M block limit. The per-iteration gasleft() < 50_000 guard
            // is the authoritative safety net regardless of the batch ceiling.
            // Without this guard, the transaction reverts mid-loop, emergencyUnwindIndex does NOT
            // advance, and the same over-heavy batch is retried forever -- bricking the unwind.
            // With this guard, the loop exits cleanly after saving progress. The next call resumes
            // from exactly where this one stopped. Any batch size is safe.
            // [v1.99.49 / L-01] WARM-SLOT DEPENDENCY: 50K guard assumes warm
            // SSTOREs (~100 gas each). processMatches() always precedes this
            // function in normal game flow, warming all relevant slots.
            // Cold-slot worst case: ~132K gas per iteration (6 x 22,100).
            // Unreachable on Arbitrum in production. Any fork calling this
            // without preceding processMatches() should raise guard to 250K.
            if (gasleft() < 50_000) {
                end = i; // save how far we got
                break;
            }
            address addr = ogList[i];
            PlayerData storage p = players[addr];

            if (p.weeklyOGStatusLost && p.statusLostAtDraw == lastResetDraw) {
                // [v1.99.4] Re-increment totalOGPrincipal BEFORE clearing flag.
                // Symmetric with processMatches() decrement which fires BEFORE flag set.
                // [v1.99.13 / AUDIT-INFO-02] ASYMMETRY NOTE: this statusLost path does NOT
                // update lastActiveWeek -- the OG genuinely missed draw N (reset draw).
                // The mulliganUsed path below DOES set lastActiveWeek = lastResetDraw
                // (v1.99.8 fix) because a mulligan player was active in that draw.
                // The asymmetry is intentional and correct.
                totalOGPrincipal += p.totalPaid;
                p.weeklyOGStatusLost = false;
                p.statusLostAtDraw   = 0;
                weeklyOGCount++;
                earnedOGCount++;
                // [v1.90 / AUDIT-INFO-02] No upper-bound guard on increment -- accepted design.
                // Overflow requires restoring a status-loss that was incorrectly applied, which
                // the invariant prevents. Decrement guards exist at all other sites; this
                // increment is trusted because _continueUnwind() only fires for players who
                // had weeklyOGStatusLost set by this exact draw's processMatches().
                if (p.consecutiveWeeks >= WEEKLY_OG_QUALIFICATION_WEEKS) {
                    qualifiedWeeklyOGCount++;
                }
                if (p.isLapsed) {
                    p.isLapsed = false;
                    if (lapsedPlayerCount > 0) lapsedPlayerCount--;
                    emit PlayerUnlapsed(addr, lastResetDraw);
                }
                // [v2.03 / M-v2.02-01] picks remain 0 (cleared by processMatches() L-04).
                // NOT restored here: the OG genuinely missed this draw and has no prior
                // picks to restore to. Emitting this event lets front-ends surface a
                // targeted prompt to call submitPicks() before the next resolveWeek().
                emit PicksResetOnUnwind(addr, lastResetDraw);
            }

            if (p.mulliganUsed && p.mulliganUsedAtDraw == lastResetDraw) {
                p.mulliganUsed       = false;
                p.mulliganUsedAtDraw = 0;
                if (p.mulliganQualifiedOG) {
                    // [v1.86 / AUDIT-L-01] Guard consistent with all other decrement sites.
                    if (qualifiedWeeklyOGCount > 0) qualifiedWeeklyOGCount--;
                    p.mulliganQualifiedOG = false;
                }
                if (p.consecutiveWeeks > 0) p.consecutiveWeeks--;
                // [v1.99.8 / I-05 -> L] Set lastActiveWeek = lastResetDraw, not -1.
                // Emergency reset voids draw N entirely. An OG at streak N-1 who
                // is restored should see N as the next expected draw (consecutive).
                // Prior: lastResetDraw-1 caused _updateStreakTracking() to see a
                // gap of 2 on the next buy, resetting streak to 1 and potentially
                // stripping endgame qualification through no fault of the player.
                p.lastActiveWeek = lastResetDraw;
            }
        }

        emergencyUnwindIndex = end;

        if (emergencyUnwindIndex >= emergencyUnwindTotal) {
            drawPhase = DrawPhase.RESET_FINALIZING;
            emit EmergencyUnwindComplete(lastResetDraw, emergencyUnwindTotal);
        } else {
            emit EmergencyUnwindBatch(lastResetDraw, emergencyUnwindIndex, emergencyUnwindTotal);
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // VIEW FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════


    function getPlayerInfo(address addr)
        external view
        returns (
            bool registered, bool upfrontOG, bool weeklyOG, bool statusLost,
            uint32 picks, uint256 streak, uint256 unclaimed, uint256 totalWon,
            bool boughtThisWeek, bool mulliganUsedVal, uint256 totalPaid,
            bool qualifiedForEndgame
        )
    {
        PlayerData storage p = players[addr];
        // [v1.99.19 / AUDIT-M-01] Return 0 for unclaimedPrizes if sweepUnclaimedPrizes()
        // has run (totalUnclaimedPrizes == 0 sentinel). p.unclaimedPrizes stays
        // non-zero in storage post-sweep but claimPrize() correctly blocks claims.
        // Returning stale non-zero here would mislead front-end integrators.
        uint256 displayUnclaimed = totalUnclaimedPrizes == 0 ? 0 : p.unclaimedPrizes;
        return (
            p.registered, p.isUpfrontOG, p.isWeeklyOG, p.weeklyOGStatusLost,
            p.picks, p.consecutiveWeeks, displayUnclaimed, p.totalPrizesWon,
            p.lastBoughtDraw == currentDraw, p.mulliganUsed, p.totalPaid,
            // [v1.99.40 / AUDIT-INFO-01] Qualify only when endgame is still live.
            // [v1.99.46] Guard fires when dormancy ACTIVATES (dormancyTimestamp > 0),
            // not only post-settlement. gameSettled plays no role in this check.
            // claimEndgame() reverts NothingToClaim() whenever dormancyTimestamp > 0,
            // regardless of whether sweepDormancyRemainder() has been called.
            // [NEW-I-02] Also clears after claim -- prevents front-ends re-displaying
            // "Claim Endgame" button after claimEndgame() has already been called.
            _isQualifiedForEndgame(p) && dormancyTimestamp == 0 && !p.endgameClaimed
        );
    }

    /// @notice Returns a high-level snapshot of overall game state.
    /// @dev [v1.99.41 / AUDIT-INFO-01] prizePot (field: pot) is phase-dependent.
    ///      During MATCHING and DISTRIBUTING draw phases, the weekly draw allocation
    ///      has already been deducted from prizePot at resolveWeek() start. The
    ///      value is temporarily deflated until finalizeWeek() seeds the Eternal
    ///      Seed return back in. Front-ends should display drawPhase alongside pot
    ///      to contextualise the live snapshot. IDLE/CLOSED phases are always clean.
        /// @dev [v1.99.67 / L-02] ABI CHANGE: 13th return field lastResolvedDraw
    ///      (uint256, position 12). Updated each time resolveWeek() settles a draw.
    ///      Use as primary stale-result signal. Full check:
    ///      (lastResolvedDraw != currentDraw - 1) || (winningResult == 0).
    ///      The OR clause covers the post-reset-then-finalizeWeek gap where
    ///      lastResolvedDraw == currentDraw-1 but winningResult was zeroed.
    ///      winningResult=0 is always invalid -- safe sentinel. [v1.99.67 / I-01]
    ///      See lastResolvedDraw declaration for pre-draw-1 edge case. Positional callers using indices 0-11 unaffected.
    /// @notice Returns true when winningResult should be treated as stale or invalid.
    /// @dev [v1.99.67 / I-03] On-chain convenience for integrators. Implements the
    ///      full two-condition stale check documented in lastResolvedDraw NatSpec.
    ///      (lastResolvedDraw != currentDraw - 1) catches normal post-reset stale.
    ///      (winningResult == 0) catches post-reset-then-finalizeWeek gap.
    ///      winningResult=0 is always invalid -- safe sentinel.
    ///      Pre-game and pre-draw-1: currentDraw=0 or lastResolvedDraw=0 edge cases
    ///      handled explicitly. Gate additionally on gamePhase/drawPhase as needed.
    ///      [v1.99.69 / I-02] RESOLUTION-PHASE FALSE POSITIVE: during MATCHING,
    ///      DISTRIBUTING and FINALIZING phases of draw N, lastResolvedDraw=N and
    ///      currentDraw=N, so (N != N-1) = true -- isResultStale() returns true
    ///      even though winningResult is the valid just-resolved result for draw N.
    ///      Front-ends displaying live draw results should additionally check
    ///      drawPhase != IDLE to distinguish "result valid, draw settling" from
    ///      "result genuinely stale." Do not blank out results solely on isResultStale()
    ///      during active resolution without also reading drawPhase.
    ///      [v1.99.71 / P1-NEW-LOW-01] Severity: LOW. Canonical front-end check:
    ///        bool resultReady = !isResultStale() ||
    ///                          drawPhase != DrawPhase.IDLE;
    ///      Use resultReady to gate result display. isResultStale() alone is
    ///      insufficient during MATCHING, DISTRIBUTING and FINALIZING phases.
    function isResultStale() external view returns (bool) {
        if (currentDraw == 0) return true;  // PREGAME -- no draws resolved
        return (lastResolvedDraw != currentDraw - 1) || (winningResult == 0);
    }

    /// @notice Returns a high-level snapshot of overall game state.
    // [v1.99.80 / INFO] NatSpec @notice repositioned directly above getGameState()
    // to prevent Solidity NatSpec parsers from attaching it to isResultStale().
    // The full @dev block above (v1.99.41 through v1.99.67 notes) remains in the
    // contiguous block before isResultStale() as historical context.
    function getGameState()
        external view
        returns (
            GamePhase gPhase, DrawPhase dPhase, uint256 draw, uint256 pot,
            uint256 treasury, uint256 unclaimed,
            uint256 playerCount, uint256 upfrontOGs, uint256 weeklyOGs,
            uint256 breathMult, bool obligLocked, uint256 ogObligation,
            // [v1.99.67 / L-02] ABI CHANGE: new 13th field lastResolvedDraw (uint256).
            // Positional index 12 (zero-indexed). Positional callers using 0-11 unaffected.
            uint256 lastResolved
        )
    {
        return (
            gamePhase, drawPhase, currentDraw, prizePot,
            treasuryBalance, totalUnclaimedPrizes,
            totalRegisteredPlayers, upfrontOGCount, weeklyOGCount,
            breathMultiplier, obligationLocked, ogEndgameObligation,
            lastResolvedDraw // [v1.99.67 / L-02] position 12
        );
    }

    /// @notice Returns current solvency figures for off-chain monitoring and dashboards.
    function getSolvencyStatus()
        external view
        returns (uint256 totalValue, uint256 totalAllocated, bool isSolvent)
    {
        // [v1.99.11 / LOW-1] Same belt-and-suspenders as _solvencyCheck.
        totalValue = aaveExited
            ? IERC20(USDC).balanceOf(address(this))
            : IERC20(aUSDC).balanceOf(address(this))
                + IERC20(USDC).balanceOf(address(this));
        uint256 tierPoolsTotal;
        for (uint256 i = 0; i < 4; i++) tierPoolsTotal += tierPools[i];
        // [v1.99.4] dormancyWeeklyPool replaced by two pools.
        totalAllocated = prizePot + treasuryBalance
            + totalUnclaimedPrizes + endgameOwed
            + dormancyOGPool + dormancyCasualRefundPool + dormancyPerHeadPool
            + dormancyCharityPending // [v2.03 / M-v2.02-03]
            + tierPoolsTotal + currentDrawSeedReturn
            + resetDrawRefundPool + resetDrawRefundPool2
            + commitmentRefundPool + totalForceDeclineRefundOwed; // [v1.99.90 / M-NEW-01]
        isSolvent = totalValue + SOLVENCY_TOLERANCE >= totalAllocated;
    }

    /// @notice Returns the effective prize rate in BPS for the current draw.
    /// @dev [v2.65] breathMultiplier IS the rate (bps). No base-rate layer.
    ///      [v2.69] Initial value calibrated at startGame() to match targetReturnBps.
    ///      [v1.92] Recalibrated at draw 7 close (_calibrateBreathTarget).
    ///      _lockOGObligation() reads it without changing it. Post-lock, the
    ///      predictive formula updates breathMultiplier every draw — this function reflects
    ///      the current live rate at any point in the game.
    ///      [v1.80 / I-02] DRAW 52 RETURNS ZERO -- but draw 52 prizes are NOT zero.
    ///      At currentDraw == TOTAL_DRAWS, this function returns 0 because draw 52 does not
    ///      use breathMultiplier. Instead, _calculatePrizePools() uses the exact-landing branch:
    ///      surplus = prizePot - requiredEndPot (if positive). Front-ends should NOT display
    ///      "0% prize rate" at draw 52. [v1.99.14 / I-04] For draw-52 prize estimation
    ///      use getProjectedEndgamePerOG() for OG endgame and prizePot - requiredEndPot
    ///      for surplus. [v1.99.15 / I-02] No single view function returns this surplus
    ///      directly -- callers need getGameState() for prizePot and requiredEndPot,
    ///      then compute the difference manually.
    ///      getSolvencyStatus() is a health check, not a prize estimator.
    ///      [v1.99.42 / AUDIT-INFO-01] PREGAME RETURNS DEFAULT CALIBRATION:
    ///      During PREGAME, currentDraw=0 which is less than TOTAL_DRAWS=52,
    ///      so the draw-52 early return does not fire. This function returns
    ///      breathMultiplier * prizeRateMultiplier / 10000 -- the default breath
    ///      calibration (~700 bps, ~7%). This is a real contract value but
    ///      represents nothing: no draw has resolved, no prize rate is active.
    ///      Front-ends should suppress or contextualise this value during PREGAME.
    function getCurrentPrizeRate() public view returns (uint256) {
        if (currentDraw >= TOTAL_DRAWS) return 0;
        return breathMultiplier * prizeRateMultiplier / 10000;
    }

    /// @notice Returns projected endgame payout per OG, total obligation, and pot health.
    /// @dev [v2.71 L-02] potHealth is now prizePot as a percentage of requiredEndPot (10000 = 100%).
    ///      Prior versions returned pot vs the old straight-line trajectory, which no longer governs
    ///      auto-breathe since v2.70 replaced it with predictive optimal breath. The new metric is
    ///      simpler and honest: how far is the pot toward the finish line right now?
    ///      10000 = pot already meets or exceeds target. Below 10000 = still closing the gap.
    ///      [v1.75 / AUDIT-03] RETURN VALUE CLARIFICATION:
    ///      `obligation` = ogEndgameObligation * targetReturnBps / 10000. This is the TOTAL
    ///      calibrated endgame pool target across all OGs combined -- NOT a per-OG promise.
    ///      Do NOT display `obligation` to players as their expected endgame payout. Use
    ///      `currentPerOG` (= 90% of current prizePot divided by qualified OG count) for that.
    ///      `obligation` is useful for dashboards tracking how well-funded the pot is relative
    ///      to the target. At high OG concentration (targetReturnBps = 4000), obligation may
    ///      appear lower than OG_UPFRONT_COST -- this reflects the calibrated design, not a
    ///      shortfall. See closeGame() T-03 NatSpec for the full design explanation.
    ///      [v1.80 / L-02] POTHEALTH AND THE /9000 BUFFER:
    ///      potHealth = 10000 means the pot has reached requiredEndPot, the breathing formula's
    ///      target. requiredEndPot = ogEndgameObligation * targetReturnBps / 9000, while obligation
    ///      uses / 10000 -- making requiredEndPot approximately 11% larger than the minimum pot
    ///      needed to pay obligation in full. Front-ends should present potHealth = 10000 as
    ///      "OG obligations on track with safety buffer intact", NOT "pot exactly meets payout".
    ///      This ~11% buffer serves two simultaneous purposes:
    ///      (a) SAFETY MARGIN: throughout draws 10-51, the pot can fall up to ~11% below
    ///          requiredEndPot and OG endgame payouts remain on track. The breathing
    ///          formula reacts and tightens prizes before any shortfall becomes critical.
    ///      (b) FINAL PRIZE POOL: at draw 52, _calculatePrizePools() awards
    ///          surplus = prizePot - requiredEndPot as draw 52 prizes. Any pot above
    ///          requiredEndPot at game end flows entirely to players -- the buffer is NOT
    ///          retained by the protocol. A pot landing exactly on requiredEndPot produces
    ///          zero draw 52 prizes but full OG endgame cover. A pot landing above
    ///          requiredEndPot pays out the full excess (not just the ~11%) as prizes.
    /// @dev [v1.99.19 / AUDIT-M-02] OBLIGATION vs DISTRIBUTION DENOMINATOR:
    ///      `obligation` = ogEndgameObligation * targetReturnBps / 10000.
    ///      ogEndgameObligation is set in _lockOGObligation() from ALL active OGs
    ///      at draw 10 (maxOGs = upfrontOGCount + earnedOGCount) * OG_UPFRONT_COST.
    ///      [v1.99.54 / H-02] Weekly OGs are included. It is the protocol's capital
    ///      commitment anchor.
    ///      `currentPerOG` = 90% of prizePot / _countQualifiedOGs(), which
    ///      includes BOTH upfront and qualified weekly OGs in the denominator.
    ///      These are different things: `obligation` is NOT the total endgame
    ///      payout promise to all qualified OGs. Front-ends should display
    ///      `currentPerOG` as the player-facing endgame estimate, not `obligation`.
    function getProjectedEndgamePerOG() external view returns (
        uint256 currentPerOG, uint256 obligation, uint256 potHealth
    ) {
        if (!obligationLocked) return (0, 0, 0);
        // [v1.82 / L-03] Return calibrated obligation (/ 10000) on settled path for consistency.
        // Prior: returned raw ogEndgameObligation post-settlement -- a ~40-60% drop vs pre-settlement
        // value, causing front-end dashboards to show a sudden obligation crash at closeGame().
        // Both paths now return ogEndgameObligation * targetReturnBps / 10000.
        // [v1.99.40 / AUDIT-INFO-02] Dormancy settlement: closeGame() never called,
        // endgamePerOG = 0. Returning (0, non-zero-obligation, 10000) is misleading
        // and triggers false shortfall alerts. Dormancy means OGs were refunded
        // principal -- no endgame distribution exists. Return (0,0,0).
        if (dormancyTimestamp > 0) return (0, 0, 0);
        if (gameSettled) return (endgamePerOG, ogEndgameObligation * targetReturnBps / 10000, 10000);

        // [v2.01] _countQualifiedOGs() returns upfrontOGCount + qualifiedWeeklyOGCount.
        // No upgrader distinction exists in v2.0+. All upfront OGs qualify unconditionally.
        uint256 ogCount   = _countQualifiedOGs();
        uint256 ogShare   = prizePot * 9000 / 10000;
        currentPerOG      = ogCount > 0 ? ogShare / ogCount : 0;
        obligation        = ogEndgameObligation * targetReturnBps / 10000; // [v2.69] calibrated target

        // [v2.71 L-02] Direct pot-vs-target health. Replaces old trajectory-line health.
        potHealth = requiredEndPot > 0 ? prizePot * 10000 / requiredEndPot : 10000;
        if (potHealth > 10000) potHealth = 10000; // cap at 100% — surplus is prizes, not health
    }

    /// @notice Returns current OG registration counts and remaining capacity.
    /// @dev [v2.69] upfrontMax reflects OG_ABSOLUTE_FLOOR: first 500 slots always available
    ///      regardless of ratio. Matches _upfrontOGCapReached() logic exactly.
    ///      [v1.86 / AUDIT-I-01] In non-PREGAME phases, denominator uses ogCapDenominator which is
    ///      snapshotted at startGame() from committedPlayerCount and never updated. [v1.99.14 / I-02]
    ///      OG caps are therefore fixed relative to the launch cohort, not the live player count.
    ///      This is intentional -- the cap design locks in at launch to prevent cap gaming.
    ///      [v1.99.41 / AUDIT-INFO-01] SMALL-GAME FLOOR INTERACTION: OG_ABSOLUTE_FLOOR (500)
    ///      guarantees 500 upfront OG slots regardless of the BPS-derived cap. On small
    ///      games where denominator * TOTAL_OG_CAP_BPS / 10000 < 500, upfrontOGCount can
    ///      reach the floor (500) while exceeding the total BPS ceiling. This zeroes
    ///      weeklyMax (wMax = tMax - upfrontOGCount, saturates to 0). Weekly OG slots
    ///      are unavailable once upfrontOGCount >= tMax on small games. Intentional:
    ///      the floor is player-first design. Not a bug. Operators of small deployments
    ///      should set MIN_PLAYERS_TO_START high enough that the floor is not dominant.
    function getOGCapInfo()
        external view
        returns (
            uint256 upfrontCurrent, uint256 upfrontMax,
            uint256 weeklyCurrent,  uint256 weeklyMax,
            uint256 totalMax,       uint256 availableWeeklySlots
        )
    {
        uint256 denominator = gamePhase == GamePhase.PREGAME
            ? committedPlayerCount : ogCapDenominator;
        uint256 uMax      = denominator * UPFRONT_OG_CAP_BPS / 10000;
        if (uMax < OG_ABSOLUTE_FLOOR) uMax = OG_ABSOLUTE_FLOOR; // [v2.69] absolute floor
        uint256 tMax      = denominator * TOTAL_OG_CAP_BPS / 10000;
        // [v1.99.49 / I-07] wMax = 0 has two distinct causes: (a) weekly cap reached
        // (tMax > upfrontOGCount but wMax - weeklyOGCount = 0), or (b) upfront floor
        // exceeded total cap (upfrontOGCount >= tMax). Both return 0 available.
        // Integrators should compare upfrontOGCount vs tMax to distinguish them.
        uint256 wMax      = tMax > upfrontOGCount ? tMax - upfrontOGCount : 0;
        uint256 available = wMax > weeklyOGCount   ? wMax - weeklyOGCount  : 0;
        return (upfrontOGCount, uMax, weeklyOGCount, wMax, tMax, available);
    }

    /// @notice Returns current pregame participation stats and launch readiness.
    /// @dev [v1.76] NOTE: readyToStart does not check pendingIntentCount == 0.
    ///      startGame() will revert on IntentQueueNotEmpty if any PENDING intents remain.
    ///      Front-ends must also check pendingIntentCount before enabling the launch button.
    ///      Use forceDeclineIntent() to clear stuck PENDING entries if needed.
    ///      [v1.88 / AUDIT-I-01] readyToStart also does not check sequencer liveness.
    ///      startGame() calls _checkSequencer() internally and will revert if the Arbitrum
    ///      sequencer feed is stale or reports downtime -- even when readyToStart == true.
    ///      [v1.90 / AUDIT-INFO-01] readyToStart=true does not guarantee payCommitment() is open.
    ///      Between signupDeadline and signupDeadline+MAX_PREGAME_DURATION, readyToStart=true
    ///      but payCommitment() reverts PregameWindowExpired. Front-ends should also check
    ///      block.timestamp < signupDeadline before showing the commitment call-to-action.
    function getPreGameStats()
        external view
        returns (
            uint256 interested, uint256 committed, uint256 upfrontOGs,
            uint256 weeklyOGs,  uint256 neededToStart, bool readyToStart,
            // [v1.99.64 / L-02] intentQueueClear is at position 6 (zero-indexed).
            // proposalTimestamp is at position 7. First introduced in v1.99.62.
            // Named-return callers must update.
            bool intentQueueClear,
            // [v1.99.30 / ABI NOTE] New field. Named-return callers must update.
            // Positional index 7 (zero-indexed). Moved from 6 to 7 by v1.99.62 intentQueueClear insertion. 0 = no proposal active.
            uint256 proposalTimestamp
        )
    {
        return (
            interestedCount, committedPlayerCount, upfrontOGCount, weeklyOGCount,
            MIN_PLAYERS_TO_START,
            committedPlayerCount >= MIN_PLAYERS_TO_START
                && gamePhase == GamePhase.PREGAME
                && block.timestamp < signupDeadline + MAX_PREGAME_DURATION,
            // [v1.99.64 / C-01] intentQueueClear at position 6 (bool).
            // readyToStart can be true while intentQueueClear is false.
            // startGame() reverts IntentQueueNotEmpty if pendingIntentCount > 0.
            // Front-ends must check BOTH fields before enabling the launch button.
            pendingIntentCount == 0,
            // proposalTimestamp at position 7 (uint256). 0 = no proposal active.
            startGameProposedAt
        );
    }

    /// @notice Returns the current dormancy refund pool state.
    /// @dev [v1.99.4] Returns four-step model state.
    ///      [v1.99.6 / AUDIT-I-01] POST-SETTLEMENT NOTE: After sweepDormancyRemainder() fires,
    ///      dormancyPrincipalFullCover and dormancyCasualFullCover are zeroed to false.
    ///      Off-chain tooling should not interpret these flags after gameSettled = true --
    ///      they reflect activation-time cover status and are invalid post-settlement.
    /// @dev [v1.99.71 / P3-NEW-LOW-04] MONITORING NOTE: when dormancyParticipantCount
    ///      == 0 (no eligible per-head claimants), perHeadShare returns 0 but
    ///      perHeadPool may still be > 0. In that case PATH 4 claims are still
    ///      live -- commitment-only players can still drain the pool at their
    ///      net cost per draw. Operators must not treat perHeadShare == 0 as a
    ///      signal that PATH 4 is exhausted. Check perHeadPool > 0 directly.
    /// @dev [v1.99.29 / L-01] ABI NOTE: the ninth return value was renamed from
    ///      claimDeadline to sweepWindowOpens in v1.99.27. On-chain positional
    ///      decoding (index 8, zero-indexed) is unaffected. Named-return callers
    ///      (Solidity destructuring, TypeScript/Python ABI decoders, subgraph ABIs)
    ///      must update claimDeadline -> sweepWindowOpens before deployment.
    function getDormancyInfo()
        external view
        returns (
            uint256 ogPoolRemaining,
            bool    principalFullCover,
            uint256 casualPoolRemaining,
            bool    casualFullCover,
            uint256 casualTicketTotal,
            uint256 perHeadPoolRemaining,
            uint256 perHeadShare,
            uint256 participantCount,
            // [v1.99.27 / I-01] Renamed from claimDeadline: this is the earliest
            // time sweepDormancyRemainder() can be called, not the last time players
            // can claim. Players may claim any time during DORMANT phase.
            uint256 sweepWindowOpens
        )
    {
        return (
            dormancyOGPool,
            dormancyPrincipalFullCover,
            dormancyCasualRefundPool,
            dormancyCasualFullCover,
            dormancyCasualTicketTotal,
            dormancyPerHeadPool,
            dormancyPerHeadShare,
            dormancyParticipantCount,
            dormancyTimestamp > 0 ? dormancyTimestamp + DORMANCY_CLAIM_WINDOW : 0
        );
    }
    /// @notice Returns per-asset price performance for the most recently resolved draw.
    /// @dev [v1.99.14 / L-03] type(int256).min is returned for any asset where no valid
    ///      price data was available at any stage of the draw (weekStartPrices == 0
    ///      and currentPrices == 0). Distinguishes dead feeds from genuinely
    ///      zero-performance assets. Integrators must handle this sentinel explicitly.
    ///      A return value of 0 means the asset had valid prices but zero net change.
    function getWeekPerformance() external view returns (int256[NUM_ASSETS] memory) {
        return weekPerformance;
    }

    /// @notice Returns the number of winners in each prize tier for the current draw.
    /// @return jp  Jackpot winners (all 4 exact order).
    /// @return p2  P2 winners (all 4 any order).
    /// @return p3  P3 winners (3 exact position).
    /// @return p4  P4 winners (3 any order, most common).
    function getWinnerCounts()
        external view
        returns (uint256 jp, uint256 p2, uint256 p3, uint256 p4)
    {
        return (jpWinners.length, p2Winners.length, p3Winners.length, p4Winners.length);
    }

    /// @notice Validates a picks uint32 off-chain before submitting a transaction.
    /// @dev Checks: non-zero, bits above bit 19 clear, each 5-bit index < 32, all four unique.
    ///      [Pick432 1Y v1.0 / INFO-02] The `idx[i] >= NUM_ASSETS` guard below is permanently
    ///      false — a 5-bit field (PICKS_MASK = 0x1F) gives values 0-31, and NUM_ASSETS = 32,
    ///      so the condition can never fire. It is deliberately RETAINED here because this function
    ///      is called by front-end developers who may not know the encoding is exactly sized —
    ///      returning "Asset index out of range (0-31)" gives useful diagnostic messaging for
    ///      any future encoding change. Belt-and-suspenders in a pure view is zero cost on-chain.
    ///      The internal _validatePicks() correctly has this dead guard removed to keep it lean.
    function isValidPicks(uint32 picks) external pure returns (bool valid, string memory reason) {
        if (picks == 0)
            return (false, "No picks submitted");
        if (picks & ~uint32(FULL_PICKS_MASK) != 0)
            return (false, "Bits above position 19 must be zero");

        uint32[4] memory idx;
        for (uint256 i = 0; i < NUM_PICKS; i++) {
            idx[i] = (picks >> (i * PICKS_BITS)) & uint32(PICKS_MASK);
            if (idx[i] >= NUM_ASSETS)
                return (false, "Asset index out of range (0-31)");
        }
        for (uint256 i = 0; i < NUM_PICKS; i++) {
            for (uint256 j = i + 1; j < NUM_PICKS; j++) {
                if (idx[i] == idx[j])
                    return (false, "Duplicate asset index");
            }
        }
        return (true, "");
    }

    /// @notice Decodes a packed uint32 picks value into four ranked asset indices.
    function decodePicks(uint32 picks)
        external pure
        returns (uint256 rank1, uint256 rank2, uint256 rank3, uint256 rank4)
    {
        rank1 = (picks >> 0)  & PICKS_MASK;
        rank2 = (picks >> 5)  & PICKS_MASK;
        rank3 = (picks >> 10) & PICKS_MASK;
        rank4 = (picks >> 15) & PICKS_MASK;
    }

    /// @notice Encodes four ranked asset indices into a packed uint32 picks value.
    /// @dev [v1.80 / I-04] INPUT VALIDATION ADDED in v1.99.71: reverts InvalidPicks()
    ///      if any rank >= NUM_ASSETS (32). Prior design masked silently (rank1=32
    ///      became 0, passing isValidPicks() with wrong picks -- no diagnostic).
    ///      [v1.99.44 / F5] ASYMMETRY WITH isValidPicks() (pre-v1.99.71): after
    ///      silent truncation, masked value passed isValidPicks() without error.
    ///      This path is now unreachable since out-of-range inputs revert first.
    ///      [v1.99.71 / P2-NEW-INFO-01] Always call isValidPicks() after encodePicks()
    ///      to verify unique indices (duplicate ranks still allowed by encodePicks).
    function encodePicks(uint256 rank1, uint256 rank2, uint256 rank3, uint256 rank4)
        external pure
        returns (uint32 picks)
    {
        // [v1.99.71 / P2-NEW-INFO-01] Input validation added. Prior design masked
        // silently: rank1=32 became 0, passing isValidPicks() with wrong picks.
        // Now reverts InvalidPicks() for any rank >= NUM_ASSETS (32).
        if (rank1 >= NUM_ASSETS || rank2 >= NUM_ASSETS ||
            rank3 >= NUM_ASSETS || rank4 >= NUM_ASSETS) revert InvalidPicks();
        picks = uint32(rank1 & PICKS_MASK)
              | uint32((rank2 & PICKS_MASK) << 5)
              | uint32((rank3 & PICKS_MASK) << 10)
              | uint32((rank4 & PICKS_MASK) << 15);
    }

    /// @notice Returns the ogList index for a given address.
    /// @dev [v1.99.21 / INFO] INDEX-0 MEMBERSHIP TRAP: this function returns 0 for
    ///      BOTH non-members (default mapping value) AND the legitimate OG at slot 0.
    ///      Checking getOGListIndex(addr) != 0 will misidentify the slot-0 OG as a
    ///      non-member. Correct membership check: ogList.length > 0 &&
    ///      ogList[ogListIndex[addr]] == addr (or use isUpfrontOG / isWeeklyOG flags).
    function getOGListIndex(address addr) external view returns (uint256) {
        return ogListIndex[addr];
    }

    // ═══════════════════════════════════════════════════════════════════════
    // INTERNAL: OG OBLIGATION LOCK
    // ═══════════════════════════════════════════════════════════════════════

    // [v2.73 I-01] _currentTrajectoryTarget() removed. It had no internal callers as of v2.72.
    // The straight-line trajectory model was superseded by predictive optimal breath in v2.70.
    // Override gates use the 80% pot-health check instead (v2.71 L-01).

    /// @dev [v2.0] Called at draw 7 close (BREATH_CALIBRATION_DRAW). All OGs are finalised --
    ///      weekly OGs registered in PREGAME only, no upgrade path exists.
    ///      Recalibrates targetReturnBps from the true OG ratio and adjusts breathMultiplier.
    ///      Draws 8-9 then breathe against the real ratio before obligation locks at draw 10.
    ///      Does NOT set obligationLocked, ogEndgameObligation, or requiredEndPot --
    ///      those remain draw-10 operations.
    ///      [v1.99.8 / I-03] Uses earnedOGCount not qualifiedWeeklyOGCount intentionally.
    ///      qualifiedWeeklyOGCount tracks only those with 51+ consecutive weeks. At draw 7
    ///      no player can have 51 consecutive weeks (only 7 draws fired), so
    ///      qualifiedWeeklyOGCount = 0 at this point. earnedOGCount correctly captures
    ///      all active weekly OGs at calibration point -- the right denominator for
    ///      the OG concentration ratio used in breath calibration.
    ///      [v1.99.2 / AUDIT-I-01] Emits BreathRecalibrated, NOT BreathMultiplierAdjusted.
    ///      Off-chain indexers watching BreathMultiplierAdjusted will miss this draw-7
    ///      breathMultiplier change. Integration tooling must consume both events.
    ///      [v1.99.14 / I-03] This function can also fire on the RESET_FINALIZING path after
    ///      an emergency-reset. In that case earnedOGCount reflects the post-unwind state
    ///      (restored OGs) -- correctly accounting for any OG status restorations.
    function _calibrateBreathTarget() internal {
        uint256 maxOGs = upfrontOGCount + earnedOGCount;
        // [v1.99.59 / H-02] Use totalRegisteredPlayers as denominator (not
        // ogCapDenominator which only captures committedPlayerCount at startGame).
        // Casual weekly buyers who joined draws 1-7 are invisible to ogCapDenominator,
        // causing actualRatioBps to be overstated and targetReturnBps understated.
        // [v1.99.78 / INFO] KNOWN LIMITATION: registerInterest() increments
        // totalRegisteredPlayers for zero-capital PREGAME players who may never
        // commit.
        // [v1.99.83 / L-01] ACTIVE free registration (v1.99.81/STAGE1) extends
        // this: spam registrations draws 1-7 inflate denominator at zero gas cost
        // beyond USDC. Effect is conservative and self-corrects after draw 10.
        // Noted for Cyfrin submission. These inflate the denominator at draw 7, reducing apparent
        // ogRatioBps and pushing targetReturnBps higher (more conservative --
        // better for casual players, slightly smaller per-OG endgame pot sizing).
        // This bias is accepted: the error is conservative and bounded by
        // interestedCount at game start. Documented for Cyfrin submission.
        // totalRegisteredPlayers tracks all registered players across all types.
        uint256 actualRatioBps = totalRegisteredPlayers > 0
            ? maxOGs * 10000 / totalRegisteredPlayers : 0;
        uint256 oldTargetBps = targetReturnBps;
        if (actualRatioBps <= 2000)      { targetReturnBps = 10000; }
        else if (actualRatioBps <= 3000) { targetReturnBps = 10000 - (actualRatioBps - 2000) * 2; }
        else if (actualRatioBps <= 9000) { targetReturnBps = 8000 - (actualRatioBps - 3000) / 2; }
        else if (actualRatioBps < 10000) { targetReturnBps = 5000 - (actualRatioBps - 9000); }
        // [v1.99.17 / I-02] 1-BPS discontinuity: at actualRatioBps = 9000, Seg C yields
        // targetReturnBps = 5000; at 9001, Seg D yields 4999. The gap is a consequence
        // of integer division in the piecewise-linear approximation. Immaterial at any
        // realistic OG concentration. Known and accepted design artefact.
        else                             { targetReturnBps = 4000; }
        if (targetReturnBps < TARGET_RETURN_FLOOR_BPS) targetReturnBps = TARGET_RETURN_FLOOR_BPS;
        uint256 oldBreath = breathMultiplier;
        uint256 recalBreath;
        if (targetReturnBps <= 4000)      { recalBreath = 165; }
        else if (targetReturnBps >= 10000){ recalBreath = BREATH_START; }
        else { recalBreath = 165 + (targetReturnBps - 4000) * (BREATH_START - 165) / (10000 - 4000); }
        if (recalBreath < BREATH_MIN)    recalBreath = BREATH_MIN;
        if (recalBreath > breathRailMax) recalBreath = breathRailMax;
        breathMultiplier = recalBreath;
        emit BreathRecalibrated(oldTargetBps, targetReturnBps, oldBreath, recalBreath, actualRatioBps);
    }

    /// @dev [v2.0] Called once at draw OG_OBLIGATION_LOCK_DRAW (10). targetReturnBps was already
    ///      set by _calibrateBreathTarget() at draw 7. This function uses the live OG
    ///      counts at draw 10. targetReturnBps was set at draw 7 and is not re-checked here.
    ///      earnedOGCount reflects post-unwind state if emergency reset fired in draws 8-9.
    ///      1. ogEndgameObligation: all active OGs at draw 10 (upfrontOGCount +
    ///         earnedOGCount = maxOGs) multiplied by OG_UPFRONT_COST.
    ///      2. requiredEndPot: obligation * targetReturnBps / 9000.
    ///      3. Seeds avgNetRevenuePerDraw with draw 10 net revenue as EMA starting point.
    ///      4. Sets obligationLocked = true, switching _checkAutoAdjust to predictive optimal breath.
    function _lockOGObligation() internal {
        uint256 maxOGs = upfrontOGCount + earnedOGCount;

        // [v2.0] targetReturnBps was already set by _calibrateBreathTarget() at draw 7.
        // [v1.94 / AUDIT-I-01] EDGE CASE: earnedOGCount can rise between draw 7 and draw 10
        // if an emergency reset during draws 8-9 causes _continueUnwind() to restore
        // weeklyOGStatusLost OGs, incrementing earnedOGCount. If so, targetReturnBps here
        // may underestimate the actual ratio slightly, making requiredEndPot mildly conservative.
        // ogEndgameObligation below uses maxOGs (upfrontOGCount + earnedOGCount) and is always correct.
        // The effect is self-correcting: predictive breath post-lock uses the actual requiredEndPot.
        // Impact bounded to two draws (8-9), emergency reset only, and only if OGs were restored.
        //
        // [v1.99.54 / H-02] COUNT ALL ACTIVE OGs AT DRAW 10 -- upfront AND weekly.
        // maxOGs = upfrontOGCount + earnedOGCount (all weekly OGs still active at draw 10).
        // Breath targets a pot large enough to return OG_UPFRONT_COST to every one of them.
        // Weekly OGs who drop off over draws 10-52 create surplus above requiredEndPot.
        // That surplus flows to draw 52 prize pool -- dropout converts directly to prizes.
        // This is the intended design: deliberate over-provisioning, not hope.
        ogEndgameObligation = maxOGs * OG_UPFRONT_COST;
        // [v1.99.56] AIM: breath targets this pot level -- not a guarantee.
        // OG return depends on actual revenue and player count at draw 52.
        requiredEndPot      = ogEndgameObligation * targetReturnBps / 9000;
        potAtObligationLock = prizePot;
        obligationLocked    = true;

        // [v2.0] EMA seed. Draw 10 net revenue seeds avgNetRevenuePerDraw.
        // Weekly OG ticket revenue in currentDrawNetTicketTotal is the primary
        // signal. No upgrade block payments exist to inflate this seed.
        avgNetRevenuePerDraw = currentDrawNetTicketTotal;

        emit OGObligationLocked(ogEndgameObligation, requiredEndPot, maxOGs);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // INTERNAL: AUTO-BREATHE
    // ═══════════════════════════════════════════════════════════════════════

    /// @dev [v2.71 L-03] Called every draw from _calculatePrizePools after the weekly prize is taken.
    ///      PRE-LOCK (draws 1-10): DOWN-only step adjustment. Checks proxy OG obligation vs pot.
    ///        [v1.99.46] Draw 10 also runs pre-lock: _calculatePrizePools() calls
    ///        _checkAutoAdjust() before _lockOGObligation() sets obligationLocked.
    ///        If pot < (1 - BREATH_FLOOR_BPS) of proxy: step breath down by BREATH_STEP_DOWN.
    ///        3-draw cooldown (BREATH_COOLDOWN_DRAWS). No upward adjustment pre-lock.
    ///      POST-LOCK (draws 11-51): Predictive optimal breath.
    ///        Solves for the exact breathMultiplier that projects prizePot to requiredEndPot
    ///        given remaining draws and EMA revenue. Sets directly each draw — no cooldown, no steps.
    ///        Skips if breathOverrideLockUntilDraw is active (v2.71 M-01 protection).
    ///        Clamps result to [breathRailMin, breathRailMax].
    ///      Draw 52: skipped entirely — exact-landing branch in _calculatePrizePools handles it.
    function _checkAutoAdjust(uint256 potSnapshot) internal {
        if (!obligationLocked) {
            uint256 enrolledOGs = upfrontOGCount + earnedOGCount;
            if (enrolledOGs == 0) return;
            // [v1.99.13 / AUDIT-INFO-02] When lastBreathAdjustDraw == 0 (no prior adjustment),
            // the cooldown block is skipped entirely -- no cooldown applies without history.
            // This means breath can step down on the very first eligible draw if the pot
            // is already below the solvency threshold. Extremely unlikely at game start
            // (OGs just committed capital). Intentional design: first draw is unconstrained.
            if (lastBreathAdjustDraw > 0 &&
                // [v1.74 / L-02] Subtraction is safe: lastBreathAdjustDraw is always set to
                // currentDraw at adjustment time; currentDraw only increments in finalizeWeek()
                // after _checkAutoAdjust() has already run. So lastBreathAdjustDraw <= currentDraw
                // always holds and currentDraw - lastBreathAdjustDraw cannot underflow.
                // [v1.99.27 / L-01] ASYMMETRY NOTE: this < comparison produces
                // BREATH_COOLDOWN_DRAWS - 1 (= 2) effective draws of suppression,
                // not 3. The override lock uses <= and produces 4 draws. The 2-draw
                // auto-cooldown is deliberate -- faster auto-adjust recovery.
                currentDraw - lastBreathAdjustDraw < BREATH_COOLDOWN_DRAWS) return;

            // [v2.0] proxyObligation uses OG_UPFRONT_COST for all enrolled OGs.
            // No upgrader bias exists -- all OGs paid via standard paths.
            uint256 proxyObligation = enrolledOGs * OG_UPFRONT_COST;
            if (proxyObligation == 0) return;

            uint256 solvBps       = potSnapshot * 10000 / proxyObligation;
            uint256 downThreshold = 10000 - BREATH_FLOOR_BPS;

            if (solvBps < downThreshold) {
                uint256 newMult = breathMultiplier > breathRailMin
                    ? breathMultiplier - BREATH_STEP_DOWN : breathRailMin;
                if (newMult < breathRailMin) newMult = breathRailMin;
                if (newMult != breathMultiplier) {
                    emit BreathMultiplierAdjusted(breathMultiplier, newMult, false);
                    breathMultiplier     = newMult;
                    lastBreathAdjustDraw = currentDraw;
                }
            }
            return;
        }

        if (ogEndgameObligation == 0) return;

        // [v1.5 / M-01] lastDrawHadJPMiss removed -- it was cleared here unconditionally with
        // no effect on any formula. EMA update retained unconditionally as before.
        // Update EMA unconditionally every post-lock draw regardless of override lock state.
        // [v1.75 / I-02] EMA ALPHA = 0.5 -- DELIBERATE DESIGN CHOICE:
        // This is a 2-period simple moving average (alpha = 0.5). The most recent draw gets
        // 50% weight. Three draws back gets 12.5%. This is intentionally fast-decaying.
        // Rationale: the post-lock window is only 41 draws (draws 11-51). A slower alpha
        // (e.g. 0.25) would take 8-10 draws to meaningfully incorporate new revenue signals --
        // too slow for a short game where player count can swing materially week to week.
        // The predictive formula recalculates every draw and self-corrects; EMA reactivity
        // is a feature, not a bug -- it lets breath respond quickly to real participation changes.
        avgNetRevenuePerDraw = (avgNetRevenuePerDraw + currentDrawNetTicketTotal) / 2;

        // [v2.71 M-01] Honour breath override lock window — don't overwrite a manual override.
        // EMA is already updated above so data stays current during the protection window.
        if (breathOverrideLockUntilDraw > 0 && currentDraw <= breathOverrideLockUntilDraw) return;

        // [v2.70] PREDICTIVE OPTIMAL BREATH
        // [v1.99.59 / LOW-2] NatSpec updated: formula now targets breathTarget
        //   (requiredEndPot + declining buffer) not requiredEndPot directly.
        //   The buffer is 0 at draw 52 so the draw-52 exact-landing is unaffected.
        // Every draw after lock: solve for the exact breath rate that projects
        // the pot to breathTarget (requiredEndPot + 5% buffer declining to 0)
        // given remaining draws and projected revenue.
        //
        // Formula (linear approximation):
        //   projectedEndPot = prizePot + avgRevenue*remaining
        //                     - prizePot * (rate/10000) * remaining
        //   Set projectedEndPot = breathTarget, solve for rate:
        //
        //   optimalRate = (prizePot + avgRevenue*remaining - breathTarget)
        //                 * 10000 / (prizePot * remaining)
        //   where breathTarget = requiredEndPot + buffer [v1.99.57]
        //
        // If pot + projected revenue can't reach target: clamp to breathRailMin.
        // If formula exceeds rail: clamp to breathRailMax.
        // Recalculates every draw — no cooldown, no steps, no trajectory line.

        uint256 remainingDraws = currentDraw < TOTAL_DRAWS ? TOTAL_DRAWS - currentDraw : 0;
        if (remainingDraws == 0) return; // draw 52 uses exact-landing branch
        // [v1.99.10 / I-01] DRAW-51 NOTE: at draw 51 remainingDraws = 1.
        // Formula: optimalBreathBps = (pot + avgRevenue - requiredEndPot) * 10000 / pot
        // A well-funded pot at draw 51 will produce a high optimalBreathBps (clamped to
        // breathRailMax if needed). This is correct: the formula distributes nearly all
        // surplus above requiredEndPot as draw-51 prizes, leaving the pot close to target
        // for the draw-52 exact-landing branch. Dashboard: breathRailMax may limit actual
        // prizes at draw 51; check getCurrentPrizeRate() for the live effective rate.

        // [v1.99.9 / L-01] EFFECTIVE RATE NOTE: this formula targets breathMultiplier
        // directly. Effective prize rate = breathMultiplier * prizeRateMultiplier / 10000.
        // When prizeRateMultiplier < 10000 (crisis mode via executePrizeRateReduction()),
        // actual prizes per draw are lower than the formula projects. The pot therefore
        // builds faster than projected and arrives ABOVE requiredEndPot at draw 52.
        // Surplus flows to draw-52 prizes. OG endgame is fully covered with extra cushion.
        // This conservative behaviour is intentional: the multiplier reduction signals the
        // owner wants to slow prize flow -- the formula should not compensate by inflating
        // breath. Off-chain dashboards should use getCurrentPrizeRate() (which applies
        // prizeRateMultiplier) not breathMultiplier alone for accurate trajectory projections.
        uint256 optimalBreathBps;
        if (prizePot > 0) {
            // [v1.99.54 / H-02] requiredEndPot is the frozen draw-10 target --
            // (upfrontOGCount + earnedOGCount) * OG_UPFRONT_COST * targetReturnBps / 9000.
            // Breath targets this number for all 42 post-lock draws. Weekly OG dropout
            // over draws 10-52 creates surplus above requiredEndPot at draw 52.
            // That surplus flows to draw 52 prize pool -- dropout converts to prizes.
            // This is deliberate over-provisioning. Sims show OG endgame is on
            // track in all normal scenarios including exhale revenue collapse to 0%.
            // [v1.99.57] DECLINING BUFFER: adds ~4.88% of requiredEndPot at draw 11
            // (500*41/(10000*42)), declining linearly to 0 at draw 52. Forces breath higher earlier so
            // prizes build toward the end rather than plateau. Overflow safe:
            // [v1.99.66 / I-01] max intermediate = requiredEndPot * 500 * 41 ≈ 1.3e18 << uint256 max.
            // NOTE: draw 37 still dips briefly at the inhale->exhale transition.
            // This is EMA lag (revenue jumped but EMA needs ~1 draw to absorb it),
            // not a buffer bug. Buffer is zero-effect when pot < breathTarget
            // (revenue collapse scenario) -- breathRailMin governs that case.
            uint256 buffer           = requiredEndPot * BREATH_BUFFER_BPS
                                       * remainingDraws / (10000 * POST_LOCK_DRAWS);
            uint256 breathTarget     = requiredEndPot + buffer;
            uint256 projectedRevenue = avgNetRevenuePerDraw * remainingDraws;
            uint256 available        = prizePot + projectedRevenue;
            if (available > breathTarget) {
                uint256 distributable = available - breathTarget;
                uint256 denom         = prizePot * remainingDraws;
                optimalBreathBps      = distributable * 10000 / denom;
            }
            // available <= requiredEndPot: pot cannot reach target at any breath rate.
            // optimalBreathBps stays 0 and will clamp to breathRailMin.
            // [v1.99.35] DRAW-51 UNDERFUNDED NOTE: at draw 51 (remainingDraws=1)
            // an underfunded pot still extracts breathRailMin (1%) as prizes
            // rather than preserving capital. OG endgame comes from closeGame()
            // not draw-52 prizes, so OGs are not harmed. Casual draw-52 buyers
            // in an underfunded game receive less. Accepted design.
        }

        if (optimalBreathBps < breathRailMin) optimalBreathBps = breathRailMin;
        if (optimalBreathBps > breathRailMax) optimalBreathBps = breathRailMax;

        if (optimalBreathBps != breathMultiplier) {
            emit BreathMultiplierAdjusted(breathMultiplier, optimalBreathBps, optimalBreathBps > breathMultiplier);
            breathMultiplier     = optimalBreathBps;
            lastBreathAdjustDraw = currentDraw;
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // INTERNAL: YIELD CAPTURE
    // ═══════════════════════════════════════════════════════════════════════

    /// @dev [v1.86 / P4-OZ-I-01] nonPotAllocated includes currentDrawSeedReturn: the 10% seed
    ///      portion set aside during prize distribution for the current active draw. It sits
    ///      in the contract balance but is committed back to prizePot at draw resolution and
    ///      must be excluded from yield calculation to avoid double-counting.
    function _captureYield() internal {
        // [v1.99.12 / L-01] Mirror _solvencyCheck: include raw USDC when !aaveExited.
        // When M-01 supply() fails, raw USDC accumulates while aUSDC understates total.
        // Without this addition, nonPotAllocated > aUSDC balance, so realPot < prizePot
        // and genuine Aave yield on successfully-deposited funds cannot be captured.
        // With this addition: actualBalance = aUSDC + rawUSDC = nonPotAllocated + yield,
        // so realPot = prizePot + yield and capture works correctly.
        // No double-count: nonPotAllocated already includes the failed supply amount
        // via the pre-supply accounting (prizePot/treasuryBalance updated before supply).
        uint256 actualBalance = aaveExited
            ? IERC20(USDC).balanceOf(address(this))
            : IERC20(aUSDC).balanceOf(address(this))
                + IERC20(USDC).balanceOf(address(this));

        uint256 tierPoolsTotal;
        for (uint256 i = 0; i < 4; i++) tierPoolsTotal += tierPools[i];

        // [v1.99.4] dormancyWeeklyPool replaced by dormancyCasualRefundPool + dormancyPerHeadPool.
        uint256 nonPotAllocated = treasuryBalance + totalUnclaimedPrizes + endgameOwed
            + dormancyOGPool + dormancyCasualRefundPool + dormancyPerHeadPool
            + dormancyCharityPending // [v2.03 / M-v2.02-03]
            + tierPoolsTotal + currentDrawSeedReturn
            + resetDrawRefundPool + resetDrawRefundPool2
            + commitmentRefundPool + totalForceDeclineRefundOwed; // [v1.99.90 / M-NEW-01]

        if (actualBalance > nonPotAllocated) {
            uint256 realPot = actualBalance - nonPotAllocated;
            if (realPot > prizePot) {
                uint256 yieldCaptured = realPot - prizePot;
                prizePot = realPot;
                emit YieldCaptured(yieldCaptured);
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // INTERNAL: PRIZE POOLS
    // ═══════════════════════════════════════════════════════════════════════

    /// @dev [v2.69] breathMultiplier is set at startGame() calibrated to targetReturnBps.
    ///      [v1.92] Recalibrated at draw 7 close (_calibrateBreathTarget). Post-lock: predictive optimal
    ///      breath solves for exact rate each draw using EMA revenue and remaining draws.
    ///      potSnapshot taken BEFORE deduction so _checkAutoAdjust receives pre-deduction value.
    function _calculatePrizePools() internal {
        uint256 weeklyPool;
        uint256 distributable;

        if (currentDraw == TOTAL_DRAWS) {
            // [v2.65] DRAW 52: EXACT LANDING
            uint256 surplus = prizePot > requiredEndPot
                ? prizePot - requiredEndPot : 0;
            weeklyPool            = surplus;
            currentDrawSeedReturn = 0;
            prizePot             -= weeklyPool;
            distributable         = weeklyPool;
        } else {
            // DRAWS 1-51: NORMAL BREATH RATE
            uint256 rate   = getCurrentPrizeRate();
            weeklyPool     = prizePot * rate / 10000;

            uint256 potSnapshot = prizePot; // [v2.65-fix] snapshot BEFORE deduction
            prizePot           -= weeklyPool;
            _checkAutoAdjust(potSnapshot);
            currentDrawSeedReturn = weeklyPool * SEED_BPS / 10000;
            distributable         = weeklyPool - currentDrawSeedReturn;
        }

        // [v1.1 / C-01] Divisor corrected from NON_SEED_BPS (9000) to 10000.
        // BPS values (3667, 2667, 2111) express each tier as a fraction of the FULL weekly pool
        // via the distributable sub-pool. Correct reading:
        //   JP: 3667/10000 x distributable = 36.67% of distributable = 33.0% of weekly pool.
        // Wrong reading (old /9000): 3667/9000 x distributable = 40.7% of distributable = 36.7% of weekly.
        // With the old divisor JP/P2/P3 each received ~11% more than designed; P4 remainder was
        // only 5.5% of weekly pool instead of the intended 14%. Fix: divide by 10000. P4 is still remainder.
        // The BPS constants and tier % comments are correct as written -- only the divisor changed.
        tierPools[0] = distributable * JP_BPS  / 10000;
        tierPools[1] = distributable * P2_BPS  / 10000;
        tierPools[2] = distributable * P3_BPS  / 10000;
        tierPools[3] = distributable - tierPools[0] - tierPools[1] - tierPools[2];
    }

    // ═══════════════════════════════════════════════════════════════════════
    // INTERNAL: STREAK TRACKING
    // ═══════════════════════════════════════════════════════════════════════

    /// @notice Updates a player's consecutive-week streak after a successful ticket buy.
    /// @dev [v1.99.24] Three paths based on lastActiveWeek vs currentDraw:
    ///      FIRST BUY (lastActiveWeek == 0): initialises streak to 1, sets
    ///        firstPlayedDraw and lastActiveWeek. Returns.
    ///      SAME DRAW (lastActiveWeek == currentDraw): already updated this draw.
    ///        No-op return (buyTickets can be called multiple times in same draw
    ///        for ticket batches).
    ///      CONSECUTIVE (currentDraw == lastActiveWeek + 1): streak++. If weekly OG
    ///        and newly reaches WEEKLY_OG_QUALIFICATION_WEEKS, increments
    ///        qualifiedWeeklyOGCount and emits EarnedOGQualified.
    ///      GAP (any other): streak resets to 1. If previously qualified, decrements
    ///        qualifiedWeeklyOGCount. Emits StreakBroken for active weekly OGs.
    function _updateStreakTracking(address addr) internal {
        PlayerData storage p  = players[addr];
        uint256 lastActive    = p.lastActiveWeek;
        uint256 current       = currentDraw;

        if (lastActive == 0) {
            p.consecutiveWeeks = 1;
            p.lastActiveWeek   = current;
            p.firstPlayedDraw  = current;
            return;
        }
        if (lastActive == current) return;

        if (current == lastActive + 1) {
            uint256 prevWeeks = p.consecutiveWeeks;
            p.consecutiveWeeks++;
            p.lastActiveWeek = current;
            if (p.isWeeklyOG && !p.weeklyOGStatusLost
                && prevWeeks < WEEKLY_OG_QUALIFICATION_WEEKS
                && p.consecutiveWeeks >= WEEKLY_OG_QUALIFICATION_WEEKS) {
                qualifiedWeeklyOGCount++;
                emit EarnedOGQualified(addr, current);
            }
            return;
        }

        uint256 prevStreak = p.consecutiveWeeks;
        if (p.isWeeklyOG && !p.weeklyOGStatusLost
            && prevStreak >= WEEKLY_OG_QUALIFICATION_WEEKS
            // [v1.86 / AUDIT-L-01] Guard consistent with all other decrement sites.
            && qualifiedWeeklyOGCount > 0) {
            qualifiedWeeklyOGCount--;
        }
        p.consecutiveWeeks = 1;
        p.lastActiveWeek   = current;
        if (p.isWeeklyOG && !p.weeklyOGStatusLost) {
            // [v1.76 / I-04] StreakBroken fires for any missed draw including streak-of-1.
            // Front-ends: prevStreak == 1 is a valid emission. Filter by threshold if needed.
            emit StreakBroken(addr, prevStreak);
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // INTERNAL: OG CAPS + QUALIFICATION
    // ═══════════════════════════════════════════════════════════════════════
    // [v1.5 / L-03] _getCurrentTreasuryBps() removed. It returned TREASURY_BPS unconditionally.
    // The indirection implied the rate might vary by context -- it does not. All 4 call sites
    // now reference TREASURY_BPS directly.

    function _upfrontOGCapReached() internal view returns (bool) {
        uint256 denominator = gamePhase == GamePhase.PREGAME
            ? committedPlayerCount : ogCapDenominator;
        if (denominator == 0) return false;
        // [v2.69] Absolute floor: first OG_ABSOLUTE_FLOOR slots always available regardless
        // of ratio. Early adopters never blocked by a small pregame denominator.
        uint256 maxUpfront = denominator * UPFRONT_OG_CAP_BPS / 10000;
        if (maxUpfront < OG_ABSOLUTE_FLOOR) maxUpfront = OG_ABSOLUTE_FLOOR;
        return upfrontOGCount >= maxUpfront;
    }

    function _weeklyOGCapReached() internal view returns (bool) {
        uint256 denominator = gamePhase == GamePhase.PREGAME
            ? committedPlayerCount : ogCapDenominator;
        if (denominator == 0) return false;
        uint256 maxTotal  = denominator * TOTAL_OG_CAP_BPS / 10000;
        if (maxTotal == 0) maxTotal = 1;
        uint256 maxEarned = maxTotal > upfrontOGCount ? maxTotal - upfrontOGCount : 0;
        return weeklyOGCount >= maxEarned;
    }

    /// @dev [v2.0] Upfront OGs always qualify. Weekly OGs qualify if they have maintained
    ///      the required consecutive-week streak (WEEKLY_OG_QUALIFICATION_WEEKS = 51).
    ///      The upgrade path has been removed -- there are no longer two upfront OG classes.
    function _isQualifiedForEndgame(PlayerData storage p) internal view returns (bool) {
        if (p.isUpfrontOG) return true; // all upfront OGs qualify
        if (p.isWeeklyOG && !p.weeklyOGStatusLost
            && p.consecutiveWeeks >= WEEKLY_OG_QUALIFICATION_WEEKS) return true;
        return false;
    }

    /// @dev [v2.0] Simplified. No upgrader distinction -- all upfront OGs qualify.
    ///      Formula: upfrontOGCount + qualifiedWeeklyOGCount.
    function _countQualifiedOGs() internal view returns (uint256) {
        return upfrontOGCount + qualifiedWeeklyOGCount;
    }

    // ═══════════════════════════════════════════════════════════════════════
    // INTERNAL: PICKS + MATCHING
    // ═══════════════════════════════════════════════════════════════════════

    // ═══════════════════════════════════════════════════════════════════════
    // INTERNAL: PICKS VALIDATION
    // ═══════════════════════════════════════════════════════════════════════

    /// @dev Validates a uint32 picks value for Pick4/32 ordered mechanic.
    ///      Checks: non-zero, no bits above position 19 set, all four indices unique.
    ///      No idx >= NUM_ASSETS guard needed — 5-bit field (0-31) exactly matches NUM_ASSETS=32.
    function _validatePicks(uint32 picks) internal pure {
        if (picks == 0) revert InvalidPicks();
        if (picks & ~uint32(FULL_PICKS_MASK) != 0) revert InvalidPicks();

        uint32[4] memory idx;
        for (uint256 i = 0; i < NUM_PICKS; i++) {
            idx[i] = (picks >> (i * PICKS_BITS)) & uint32(PICKS_MASK);
        }
        for (uint256 i = 0; i < NUM_PICKS; i++) {
            for (uint256 j = i + 1; j < NUM_PICKS; j++) {
                if (idx[i] == idx[j]) revert InvalidPicks();
            }
        }
    }

    function _getWinnersForTier(uint256 tier) internal view returns (address[] storage) {
        if (tier == 0) return jpWinners;
        if (tier == 1) return p2Winners;
        if (tier == 2) return p3Winners;
        return p4Winners;
    }

    // ═══════════════════════════════════════════════════════════════════════
    // INTERNAL: PRICE FEEDS
    // ═══════════════════════════════════════════════════════════════════════

    /// @dev [v1.99.11 / L-01] Arbitrum-specific note for audit review:
    ///      startedAt = timestamp when sequencer last came back online. The 1-hour
    ///      SEQUENCER_GRACE_PERIOD prevents draws resolving while stale L1 messages
    ///      may still be processing. Normal path (sequencer never down): startedAt is
    ///      very old, block.timestamp - startedAt >> 1 hour, resolves correctly.
    ///      L1 reorg edge case: updatedAt may briefly exceed block.timestamp at L2.
    ///      Guard `if (updatedAt > block.timestamp) revert` handles this correctly.
    function _checkSequencer() internal view {
        // [v1.99.17 / I-03] Dead branch removed: SEQUENCER_FEED is immutable and the
        // constructor enforces non-zero since C-03 (v1.1). The address(0) guard was
        // permanently unreachable on Pick432 1Y (Arbitrum deployment only).
        // In Pick432Whale (ETH Mainnet fork), address(0) is the valid no-sequencer path.
        AggregatorV3Interface seqFeed = AggregatorV3Interface(SEQUENCER_FEED);
        try seqFeed.latestRoundData() returns (
            uint80, int256 answer, uint256 startedAt, uint256 updatedAt, uint80
        ) {
            if (updatedAt > block.timestamp) revert SequencerNotReady();
            if (block.timestamp - updatedAt > FEED_STALENESS) revert SequencerNotReady();
            if (answer != 0) revert SequencerNotReady();
            if (startedAt > block.timestamp ||
                block.timestamp - startedAt < SEQUENCER_GRACE_PERIOD)
                revert SequencerNotReady();
        } catch {
            revert SequencerNotReady();
        }
    }

    /// @dev [v1.99.11 / H-01] Circuit-breaker check: read minAnswer/maxAnswer from
    ///      the aggregator (via AggregatorMinMax cast). Chainlink clamps returned price
    ///      to [minAnswer, maxAnswer] on extreme moves (e.g. BTC -95%). The contract
    ///      would otherwise use the clamped floor/ceiling and produce wrong rankings.
    ///      If price <= minAnswer or >= maxAnswer, treat feed as stale -- return 0 and
    ///      fall back to lastValidPrices. try/catch on minAnswer/maxAnswer calls: if
    ///      the aggregator does not expose these (some legacy feeds), skip bounds check.
    ///      [v1.99.12 / L-03] DEPLOYMENT CHECK: verify minAnswer > 0 AND maxAnswer > 0
    ///      on all 32 feeds before deployment. A feed returning maxAnswer = 0 would
    ///      cause the bounds check to reject all positive prices (price >= 0 is true).
    ///      The maxAns > 0 guard added in v1.99.12 mitigates this at runtime, but
    ///      a deployment-time check is the cleanest defence.
    ///      [v1.99.11 / I-03] Zero-round edge: roundId=0 AND answeredInRound=0 gives
    ///      0 < 0 = false (passes answeredInRound check), then price <= 0 returns 0.
    function _readPrice(uint256 index) internal view returns (int256) {
        AggregatorV3Interface feed = AggregatorV3Interface(priceFeeds[index]);
        try feed.latestRoundData() returns (
            uint80 roundId, int256 price, uint256, uint256 updatedAt, uint80 answeredInRound
        ) {
            if (updatedAt > block.timestamp) return 0;
            if (block.timestamp - updatedAt > FEED_STALENESS) return 0;
            if (answeredInRound < roundId) return 0;
            if (price <= 0) return 0;
            // [v1.99.13 / M-01] Independent circuit-breaker checks.
            // Floor and ceiling checked independently: a feed exposing only minAnswer()
            // still gets floor protection; only maxAnswer() still gets ceiling protection.
            // Prior nested structure silently skipped the floor check if maxAnswer() reverted.
            // [v1.99.44 / F8] DEPLOYMENT CHECKLIST: verify minAnswer > 0 on all 32 feeds
            // before deployment. If minAnswer = 0, this check degenerates to price <= 0
            // which is already handled below. A feed clamped at floor price=1 during a
            // depeg would pass through as a real price, producing wrong rankings without
            // the contract detecting it. All 32 production feeds must have minAnswer > 0.
            try AggregatorMinMax(priceFeeds[index]).minAnswer() returns (int192 minAns) {
                if (price <= int256(minAns)) return 0;
            } catch {}
            try AggregatorMinMax(priceFeeds[index]).maxAnswer() returns (int192 maxAns) {
                // [v1.99.12 / L-03] maxAns > 0: skip ceiling if misconfigured (0 rejects all).
                if (maxAns > 0 && price >= int256(maxAns)) return 0;
            } catch {}
            return price;
        } catch {
            return 0;
        }
    }

    /// @dev [v1.99.11 / H-01] Same circuit-breaker pattern as _readPrice().
    function _readPriceFeed(address feedAddr) internal view returns (int256) {
        AggregatorV3Interface feed = AggregatorV3Interface(feedAddr);
        try feed.latestRoundData() returns (
            uint80 roundId, int256 price, uint256, uint256 updatedAt, uint80 answeredInRound
        ) {
            if (updatedAt > block.timestamp) return 0;
            if (block.timestamp - updatedAt > FEED_STALENESS) return 0;
            if (answeredInRound < roundId) return 0;
            if (price <= 0) return 0;
            // [v1.99.13 / M-01] Independent circuit-breaker checks.
            // Same pattern as _readPrice() -- see that function for rationale.
            try AggregatorMinMax(feedAddr).minAnswer() returns (int192 minAns) {
                if (price <= int256(minAns)) return 0;
            } catch {}
            try AggregatorMinMax(feedAddr).maxAnswer() returns (int192 maxAns) {
                if (maxAns > 0 && price >= int256(maxAns)) return 0;
            } catch {}
            return price;
        } catch {
            return 0;
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // INTERNAL: WITHDRAWAL + SOLVENCY
    // ═══════════════════════════════════════════════════════════════════════

    /// @dev [v1.99.12 / L-02] SUPPLY FAILURE RUNBOOK: if M-01 supply() failed
    ///      previously, raw USDC is held in the contract but Aave holds less than
    ///      totalAllocated. Any withdraw() call requesting more than the Aave balance
    ///      will revert AaveLiquidityLow, blocking prize claims, treasury withdrawals,
    ///      dormancy refunds, and signup refunds.
    ///      RESOLUTION: call activateAaveEmergency() immediately after AaveSupplyFailed
    ///      is emitted. This sets aaveExited=true and all transfers use raw USDC path.
    function _withdrawAndTransfer(address recipient, uint256 amount) internal {
        if (aaveExited) {
            IERC20(USDC).safeTransfer(recipient, amount);
        } else {
            uint256 balBefore = IERC20(USDC).balanceOf(address(this));
            try IPool(AAVE_POOL).withdraw(USDC, amount, address(this)) {
                uint256 received = IERC20(USDC).balanceOf(address(this)) - balBefore;
                if (received < amount) revert AaveLiquidityLow();
                // [v1.79 / L-02] Transfer amount not received. The received >= amount guard
                // above already confirmed funds exist. Transferring received risked sending
                // Aave-return dust to recipient and leaving contract accounting short.
                IERC20(USDC).safeTransfer(recipient, amount);
            } catch {
                revert AaveLiquidityLow();
            }
        }
    }

    function _solvencyCheck() internal view {
        // [v1.99.11 / LOW-1] Raw USDC belt-and-suspenders: if Aave supply() failed
        // (M-01 try/catch path), raw USDC accumulates in contract while !aaveExited.
        // aUSDC balance alone would understate total value and cause false SolvencyCheckFailed,
        // blocking resolveWeek(). Adding USDC.balanceOf() catches both pools.
        // After activateAaveEmergency() sets aaveExited=true, only USDC balance is used.
        uint256 totalValue = aaveExited
            ? IERC20(USDC).balanceOf(address(this))
            : IERC20(aUSDC).balanceOf(address(this))
                + IERC20(USDC).balanceOf(address(this));
        uint256 tierPoolsTotal;
        for (uint256 i = 0; i < 4; i++) tierPoolsTotal += tierPools[i];
        // [v1.99.4] dormancyWeeklyPool replaced by dormancyCasualRefundPool + dormancyPerHeadPool.
        uint256 totalAllocated = prizePot + treasuryBalance
            + totalUnclaimedPrizes + endgameOwed
            + dormancyOGPool + dormancyCasualRefundPool + dormancyPerHeadPool
            + dormancyCharityPending // [v2.03 / M-v2.02-03]
            + tierPoolsTotal + currentDrawSeedReturn
            + resetDrawRefundPool + resetDrawRefundPool2
            + commitmentRefundPool + totalForceDeclineRefundOwed; // [v1.99.90 / M-NEW-01]
        if (totalValue + SOLVENCY_TOLERANCE < totalAllocated) revert SolvencyCheckFailed();
    }
}
