# puzzle-state Project Documentation — Report 02: Business Benefits

> **Project:** puzzle-state | **Generated:** 2026-08-25 | **Repo:** worksona/puzzle-state (public)

## Executive Summary

puzzle-state is internal leverage, not a product: it converts a fragment of curiosity — a Slack 🧩 reaction, a URL, a one-line prompt — into a finished, playable, publicly hosted puzzle without the operator having to run a project around it. The measurable return so far is 18 puzzles in `~/bazaar/puzzles/`, 17 at `phase: published`, all live as self-contained HTML at https://puzzle-state.netlify.app, produced by a single author-operator against a repo that contains no application code at all. Its commercial posture should be read honestly: there is no billing, no authentication, no multi-tenancy and no user model anywhere in the 26 tracked files, so the value is throughput, pattern reuse, and a public credential — not revenue.

---

## 1. The job to be done

The operator's actual job statement, reconstructed from the intake design in `templates/manifest.yaml.template` and `plugin/skills/puzzle-harvester-sources/SKILL.md`:

> *"When something puzzling crosses my desk, I want to capture it in one gesture and have a finished, playable, shippable artifact come out the other end — without the capture turning into a project I have to schedule."*

Three properties of that statement drive the whole architecture:

| Property of the job | Design response | Evidence |
|---|---|---|
| Capture must cost one gesture | Reaction-emoji intake; file drop; a manifest seed line | `intake.slack.marker: "🧩"`, `intake.inbox.path`, `intake.sources[]` in `templates/manifest.yaml.template` |
| The work must complete unattended | A fixed phase machine and a router that dispatches purely on phase | `plugin/skills/puzzle-orchestrator/SKILL.md` walk order; `phase` enum in `schemas/puzzle.schema.yaml` |
| A dead end must still produce value | `build-failed` and `tested:unsolvable` advance to report and publish | `puzzle-state-spec.md` §2 invariant 5, §6 phase diagram; three-sense table in `plugin/skills/puzzle-reporter/SKILL.md` |

That third property is the commercially interesting one. Most content pipelines discard failures silently; here a failed playtest becomes a `[finding]`-prefixed publishable post (`plugin/skills/puzzle-publisher/SKILL.md`). Every unit of work yields an output, which is what makes an unattended pipeline economically sane for a solo operator — there is no wasted overnight run.

---

## 2. Value propositions

### 2.1 Throughput on a category of work that does not scale by hand

Puzzle authoring is unusually expensive per unit: you must invent a mechanic, implement it, generate a valid instance, *and prove the instance is solvable*. The `test` block in `schemas/puzzle.schema.yaml` (`solver_passed`, `unique_solution`, `difficulty_actual`) encodes exactly the step a human author cannot skip and hates doing. The evidence that this compressed real effort is the shape of the corpus: PUZ-0010 through PUZ-0018 are nine distinct Nikoli-family logic engines (lights-out, binairo, sudoku, nonogram, fill-a-pix, skyscrapers, numbrix, tents, slitherlink), each a separate generator plus a separate validity proof, all created from one prompt recorded verbatim in `PUZ-0018-slitherlink/puzzle.yaml`:

> `"Expand the deduction wing further — five more interactive Nikoli-style logic puzzles, each self-contained, browser-only, solve-to-reveal-the-flag."`

Nine solver-verified puzzle engines from one sentence is the benefit in one line.

### 2.2 Near-zero marginal infrastructure cost

There is no server to run. The repo has no `package.json`, no `pyproject.toml`, no dependency manifest of any kind; the artifacts are single-file HTML (`PUZ-0012-sudoku/artifact/index.html` is 302 lines, `PUZ-0007-meta-cabinet/artifact/index.html` is 698) with no external scripts, validating answers in-browser via `crypto.subtle` SHA-256. Hosting is a static Netlify deploy of a staged directory. The recurring cost floor is a Netlify free-tier site and a domain-less `.netlify.app` subdomain.

The real costs are elsewhere and should be stated plainly:

- **LLM inference** — the pipeline's only substantial variable cost, unmetered and unbudgeted in the repo. `manifest.sandbox.night_budget_s: 14400` caps wall clock, not tokens.
- **Operator attention** — "nightly" is aspirational. There is no scheduler in the repo and no `.github/` directory; `/puzzle-orchestrator --once` is triggered by a human.
- **Docker Desktop on the operator's machine** — required per README step 1, though see §4 for the caveat that the sandbox has not actually been exercised.

### 2.3 A safe way to run code an LLM just wrote

The two-plane split in `puzzle-state-spec.md` §3 exists because the *generator* is untrusted, not because the input is. Generated game JS, LaTeX and solver code are supposed to touch the host only as bytes written from inside a per-puzzle container with `egress: registries-only`, 2 CPU, 4g, and a 1200s kill. For an operator who intends to run agent-authored code unattended overnight on a machine that also holds an Anthropic key, a Slack token and a GHCR token, this is the difference between a viable habit and an unacceptable one.

**Honesty note:** this benefit is currently architectural rather than realized. Every one of the 18 puzzle records carries `build.base_image: null` and `build.duration_s: 0` — the artifacts were produced without the sandbox path running. The safety property is designed, specified, and unproven.

### 2.4 Solutions stay private while artifacts stay public

The two-repo split is the commercially load-bearing decision. Puzzles have negative value once the answer leaks, so the pipeline enforces asymmetry at three layers:

1. `/puzzle-state scrub kind=public-output` redacts secrets, referenced `solution.md` contents, and inline answer keys (`plugin/skills/puzzle-state/SKILL.md`).
2. The publisher re-scans the outbound body and aborts if any ≥40-character substring of `solution.md` appears in it (`plugin/skills/puzzle-publisher/SKILL.md`, "Solution leak guard").
3. `~/bazaar/deploy.sh` runs a `find` over the staging directory and exits 1 if `solution.md`, `puzzle.yaml`, `research.md` or `design.md` reached it.

The engine repo is public and MIT-licensed; the puzzles and their keys live in private `worksona/bazaar-data`. That structure lets the operator publish the *method* as a credential while retaining the *inventory* as an asset — a genuinely useful commercial arrangement, and one that most single-repo projects cannot express.

### 2.5 Pattern reuse across the portfolio

puzzle-state is explicitly the sibling of forge-state, desk-state, work-state and notella (`README.md` line 5; spec header "Architecture mirrors forge-state §1-§18"). It is the *n*th instance of the house pattern — single-writer substrate, file-per-entity YAML, append-only NDJSON, two-plane isolation, generated distribution. Each new instance costs less than the last, and each proves the pattern against a new domain. The portfolio-level benefit is that the marginal cost of standing up a facility for a new domain is now measured in a spec document and twelve Markdown contracts (414 lines total), not in an application.

The cost of that reuse is visible too: `deck/deck.js` still opens with `/* forge-state deck — vanilla nav, no deps */`. Copy-forward is fast and leaves fingerprints.

---

## 3. Target users and personas

### Persona 1 — The author-operator (primary, and currently the only real one)

David Olsson, Atomic 47 Labs. Every `source.marked_by` in the data plane is `keystone@stonemaps.org`. The intake is configured `markers_self_only: true`. The manifest ships a personal GHCR namespace (`registry: ghcr.io/davidolsson`) and a personal secret store (`store: sops-age`). This is a system built for one person, and it should be evaluated as such.

**What it delivers:** the ability to say yes to a puzzle idea at 11pm without committing a weekend.

### Persona 2 — The puzzle-hunt or ARG author (addressable, not yet addressed)

The taxonomy in `puzzle-state-spec.md` §10 names eight families and twenty template ids, and PUZ-0007 demonstrates real hunt craft: a feeder-to-meta capstone where five cipher rungs' recovered keys unlock five fragments that assemble into `CABINET{the_whole_cabinet_remembers_everything}`, validated by per-fragment SHA-256. That is MIT Mystery Hunt grammar, and the record cites it (`comparables: MIT Mystery Hunt metas`).

**What would have to be true to serve them:** the `templates/types/` tree would need to exist (it does not), and the ARG / escape / treasure-hunt families would need at least one worked instance (none exist).

### Persona 3 — The plugin adopter

The repo is a self-contained one-plugin Claude Code marketplace (`.claude-plugin/marketplace.json`, `source: "./plugin"`), MIT-licensed, installable in three commands per the README. The addressable audience is Claude Code users who want an example of a well-shaped multi-skill facility more than they want puzzles specifically.

**Friction to fix:** the README contains two mutually inconsistent install stories — the "Where everything lives" table says `puzzle-state@local-desktop-app-uploads` via a symlink, the "Install" section says `/plugin install puzzle-state@puzzle-state`. Both are true for different setups; the README does not say so.

### Persona 4 — The pattern reader

Someone evaluating the Atomic 47 / Worksona portfolio who wants the house pattern in its smallest legible form. puzzle-state is arguably the best exhibit for this: 26 tracked files, a 10.6KB spec, and a 15-slide deck at `/deck/` whose slide labels ("Two-plane isolation", "The substrate", "Unsolvable is a finding") are the pattern's vocabulary rather than the puzzle domain's.

---

## 4. Cost implications

### What it saves

| Saved | Basis |
|---|---|
| Puzzle implementation hours | 18 shipped artifacts, each a hand-written interactive HTML puzzle in the counterfactual |
| Solvability verification | `test.solver_passed` / `unique_solution` recorded per puzzle; PUZ-0018's note documents a 22-segment single-loop verification that would be tedious by hand |
| Hosting and ops | Static Netlify deploy; no runtime, no database, no dependency tree to patch |
| Facility bootstrap | `scripts/init-facility.sh` is fully idempotent — every write guarded by `if [[ ! -f ... ]]` — so re-running is free and setup is one command |
| Publication logistics | Three-surface fan-out specified once in `plugin/skills/puzzle-publisher/SKILL.md` rather than repeated per puzzle |

### What it costs, and what is not yet paid for

- **The fan-out has never run.** All 18 records carry `outputs.gist_url: null`, `blog_post_id: null`, `work_state_event_id: null`. The distribution that actually happened is the static path, recorded in an undeclared field `outputs.pages_url` pointing at the legacy GitHub Pages mirror. The gist/scsiwyg/work-state economics are therefore projected, not observed.
- **Curation has never run.** `~/bazaar/collections/` is empty despite 18 puzzles at `phase >= reported`, the curator's stated trigger condition. The "navigable inventory" benefit in `plugin/skills/puzzle-curator/SKILL.md` is unrealized.
- **Only two of eight families are exercised.** The corpus is entirely cipher-wing and logic-wing. `paper`, `casual-web`, `arg`, `riddle`, `escape` and `treasure-hunt` have no instance, which means the `pdf`, `docker-web` and `breadcrumb-pack` artifact kinds and the whole GHCR push path (README setup step 2, `$GHCR_TOKEN`) are unproven and their costs unknown.
- **Verification is unfunded.** `scripts/test-run.sh` is eight lines that `echo` two commands and exit 0. There is no CI. Every guarantee above — including the solution-leak guard the business model depends on — is enforced at runtime by prose contracts that nothing tests.

---

## 5. Competitive positioning

There is no direct competitor, because the category is "one person's overnight puzzle factory". The useful comparisons are to the alternatives the operator actually had:

| Alternative | Where puzzle-state wins | Where it loses |
|---|---|---|
| Hand-authoring in a puzzle editor (Crossword Compiler, Nikoli tooling) | Breadth across families; provenance recorded per puzzle; artifacts ship as web pages, not files | Editors are mature, interactive, and give the author direct control over aesthetics |
| Hunt-authoring platforms (e.g. hunt frameworks with team scoring, hint queues) | No infrastructure, no accounts, artifacts are static and permanent | No teams, no scoring, no live hint economy — puzzle-state ships single-player static pages |
| A generic agent framework + ad-hoc prompts | The phase machine, the substrate, and the leak guard are the value: state survives between runs and answers cannot escape | Generic frameworks have executors, schedulers, retries; puzzle-state has none in-repo |
| Doing nothing | 18 puzzles exist | — |

The defensible position is the **information-asymmetry pipeline**: a publishing system whose central invariant is that a specific derived artifact (the answer) must never appear in output. That is a genuinely unusual constraint and it is enforced in three independent places. Nothing off-the-shelf does it.

---

## 6. Commercialization posture

**Recommended posture: internal leverage plus a public credential. Do not model revenue.**

What exists supports that reading:

- MIT license (`LICENSE`, `plugin/.claude-plugin/plugin.json`), so the engine is a giveaway by design.
- No auth, no accounts, no payment surface, no analytics anywhere in the repo or the artifacts.
- v0.1.0 in both `plugin.json` and `marketplace.json`, two commits, no tags, no `CHANGELOG.md`.
- A hard-coded personal registry namespace and a personal secret store in the shipped manifest template.

Adjacencies that *would* be monetizable, listed with the honest gap in front of each:

1. **Puzzle packs / a hunt commission service.** The corpus is real and the meta-capstone shows the craft. Gap: no fulfilment surface, no licensing terms on the puzzles (the engine is MIT; the puzzles' license is unstated), and 6 of 8 families untested.
2. **The pattern as consulting IP.** The deck at `/deck/` is already a sales artifact for the house pattern. Gap: it argues for a system whose sandbox and fan-out have not been observed running, which is a hard demo to stand behind.
3. **A hosted bazaar with accounts.** Gap: everything. Local-first is invariant 1; adding tenancy contradicts the architecture rather than extending it.

The correct near-term investment is not commercialization. It is closing the gap between the specified system and the operating one — running the sandbox once, running the curator once, running the publisher fan-out once — so that the credential the public repo represents is backed by observed behavior.

---

## Key Takeaways

- **The value is throughput and pattern reuse, not revenue.** 18 solver-verified puzzles from a repo with zero lines of application code is the headline; there is no billing, auth, or tenancy anywhere in it.
- **The job-to-be-done is one-gesture capture to finished artifact,** and the architecture answers it point-for-point: emoji/file/seed intake, a phase-driven router, and failure-as-publishable-finding so no overnight run is wasted.
- **Solution gating is the commercially load-bearing invariant** — enforced at three independent layers (scrub op, ≥40-char leak guard, deploy-time `find` abort) — and it is what allows a public MIT engine to coexist with a private puzzle inventory.
- **Marginal infrastructure cost is effectively zero:** single-file HTML artifacts with in-browser `crypto.subtle` validation on static Netlify hosting; the real costs are LLM inference and operator attention, neither budgeted in-repo.
- **Three headline benefits are specified but unobserved:** the Docker sandbox (`base_image: null`, `duration_s: 0` on all 18 records), curation (`collections/` empty), and the three-surface publishing fan-out (all `outputs.*` gist/blog/work-state fields null).
- **Coverage is narrow:** only the cipher and logic families exist. The `pdf`, `docker-web` and `breadcrumb-pack` paths — and the GHCR push they require — have never been exercised.
- **Nothing verifies any of it.** `scripts/test-run.sh` only prints instructions and there is no CI, so even the leak guard the business case rests on is untested.

---

## Cross-References

- [Report 01b — Technical Specification](01b-technical-specification.md) — the architecture, entity shape, and phase machine referenced throughout.
- [Report 03 — Innovation Themes](03-innovation-themes.md) — which of the value propositions above rest on genuinely novel technique and which on competent assembly.
- [Report 08 — Technical Readiness](08-technical-readiness.md) — the maturity assessment behind the "specified but unobserved" caveats in §4.
- [Report 05 — Extensibility](05-extensibility.md) — what it would cost to close the six-missing-families coverage gap.
- [Report 06 — Work Zones](06-work-zones.md) — per-zone health, including the dormant sandbox, curation, and egress zones.
