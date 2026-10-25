# GAME-004 MathShow — Design

Keep this to one page. Agents read it per task.

## Core loop (vertical slice)
Lobby → **Intermission** (10s) → **Question** (host shows a problem, timer runs) → **Reveal** (answer + who got it, 4s)
→ repeat for N questions → **Results** (podium, 8s) → back to Intermission.

- Everyone answers the same question at the same time by typing a number.
- Score: correct answers earn base points plus a speed bonus. Wrong or no answer earns 0. No elimination in the slice.
- Difficulty ramps by question index within a match.

## Rules that matter
- **The server never sends the answer before Reveal.** The client gets only the problem text and timing.
- The server records submit time on receipt (`os.clock()`); it never trusts client time.
- One accepted submission per player per question. The first valid one wins; later ones are ignored.
- Answers are integers only, parsed server-side from a string with a length cap. No eval of expressions.
- Problems are generated from `Random.new(seed)` so tests are deterministic.

## Modules
| Module | Kind | Job |
|---|---|---|
| `shared/ProblemRules` + `ProblemConfig` | Rules | `generate(seed, difficulty) -> Problem { text, answer, timeLimit }` |
| `shared/ScoringRules` + `ScoringConfig` | Rules | `parseAnswer(string) -> number?`, `score(correct, elapsed, timeLimit) -> number` |
| `shared/RoundRules` + `RoundConfig` | Rules | phase state machine: `nextPhase(phase, questionIndex) -> (Phase, duration)` |
| `server/Services/RoundService` | Service | match loop, owns remotes, validates submissions |
| `client/Hud` | Client | question, timer, input box, feedback, results |

## Remotes (server creates all of them in `ReplicatedStorage.Remotes`)
- `RoundState` (RemoteEvent, server → all): `{ phase, endsAt, questionIndex, problemText?, answer?, scores? }`
- `SubmitAnswer` (RemoteEvent, client → server): `(raw: string)`
- `AnswerResult` (RemoteEvent, server → one client): `{ accepted: boolean, correct: boolean?, points: number? }`

`endsAt` is `workspace:GetServerTimeNow()` based so client timers line up.

## Tasks (in order, one branch each; IDs come from tasks/queue.json)
1. **Scaffold**: folders, bootstrap scripts, TestRunner, check passes.
2. **ProblemRules**: add/sub/mul/div with integer answers, 3 difficulty tiers. Spec.
3. **ScoringRules**: answer parsing and speed-bonus scoring. Spec.
4. **RoundRules**: pure phase transitions and durations. Spec.
5. **RoundService**: match loop, remotes, validation, rate limit. Pass: 1-player playtest log shows full cycle.
6. **Hud**: question, timer, input, feedback. Built in code, no assets.
7. **Scores**: leaderstats + Results screen.
8. **2-player test**: Studio local server with 2 players; file a fix list, no fixes in this task.

## Later (not in the slice)
Stage/podium map, host NPC, SFX/VFX, elimination mode, power-ups, DataStore stats, monetization.
