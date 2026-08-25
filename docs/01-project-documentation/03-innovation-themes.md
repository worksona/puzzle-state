# puzzle-state Project Documentation — Report 03: Innovation Themes

> **Project:** puzzle-state | **Generated:** 2026-08-25 | **Repo:** worksona/puzzle-state (public)

## Executive Summary

Three ideas in puzzle-state are genuinely novel: treating a failed playtest as a publishable finding rather than an error, enforcing *semantic* rather than credential secrecy through a three-layer leak guard, and shipping puzzles as zero-backend HTML that validate answers by SHA-256 so the answer key never has to be served. Most of the rest — the single-writer substrate, the file-per-entity YAML plus append-only NDJSON, the self-marketplace plugin, the phase machine with cursors — is competent assembly of a house pattern this repo explicitly inherits from forge-state, and should be credited as disciplined reuse rather than invention. The sharpest observation in this report is that the corpus itself innovated past the spec: a ninth taxonomy family (`meta`) and a whole flag/hash convention emerged in practice and were never written back into the schema.

---

## 1. What counts as innovation here

This repo contains no application code — 26 tracked files, 414 lines of Markdown skill contracts, one JSON Schema, two Bash scripts, and a deck. Innovation therefore cannot live in algorithms. It lives in three places:

1. **Invariants** — constraints chosen and then enforced structurally.
2. **Inversions** — places where the design deliberately does the opposite of the conventional thing and gets a benefit for it.
3. **Emergent technique** — things the operating system does that the specification never anticipated.

The strongest material is in categories 2 and 3.

---

## 2. Genuine innovation

### 2.1 Failure as a first-class publishable output

**The inversion.** Every build pipeline in conventional practice treats failure as a halt. `puzzle-state-spec.md` §2 invariant 5 states the opposite:

> *"Unsolvable is terminal-with-findings. A failed playtest advances to a report, not a halt."*

And it is not rhetoric — it is wired into the type system and the router. The `phase` enum in `schemas/puzzle.schema.yaml` includes `build-failed` as a *phase*, not a status flag. The orchestrator's dispatch table routes `build-failed → /puzzle-reporter (failure sense)` exactly as it routes `packaged → /puzzle-reporter`. `plugin/skills/puzzle-reporter/SKILL.md` carries a three-sense table (`solvable` / `build-failed` / `unsolvable|ambiguous`) with distinct framings, and `plugin/skills/puzzle-publisher/SKILL.md` prefixes findings posts with `[finding]`.

**Why it is more than a nice idea.** In an unattended agentic pipeline, the economics only work if every run produces an output. A conventional fail-fast design means an overnight run can consume budget and return nothing, which trains the operator to stop trusting it. Making the failure branch converge back into the publish path means the pipeline has no dead ends — a structural answer to a behavioral problem. The design also captures something true about the domain: "this puzzle as designed has no unique solution" is genuinely interesting content, not an error.

**Prior art.** Postmortem culture and negative-results publishing exist. What is unusual is encoding it as a *phase transition in a schema* rather than as an editorial habit. The sibling `forge-state` shares the pattern (`build-failed is terminal-with-findings`, per the README), so within the portfolio this is inherited — but it is inherited from an idea worth having.

### 2.2 Semantic secrecy: guarding an answer, not a credential

**The problem restated.** Nearly every publishing pipeline guards *credentials* — API keys, tokens — which are enumerable strings you can grep for. puzzle-state must additionally guard a **derived semantic artifact**: the answer. An answer is not enumerable, has no fixed format, and can be leaked by paraphrase, by a too-specific win condition, or by an artifact that ships its own key. Leaking it does no security harm and total commercial harm.

**The three-layer response**, each layer independent and at a different level of the stack:

| Layer | Mechanism | Location |
|---|---|---|
| Content | `scrub kind=public-output` redacts secret values, the contents of any referenced `solution.md`, and "any decoded plaintext / answer key / cheat string embedded inline" | `plugin/skills/puzzle-state/SKILL.md` |
| Egress | Re-scan the outbound body; **abort if any ≥40-character substring of `solution.md` appears** | `plugin/skills/puzzle-publisher/SKILL.md`, "Solution leak guard" |
| Filesystem | `find` over the Netlify staging dir for `solution.md`, `puzzle.yaml`, `research.md`, `design.md`; `exit 1` if any is present | `~/bazaar/deploy.sh` |

The ≥40-character substring rule is the interesting one. It is a deliberately crude, deliberately cheap approximation of "did the answer leak" — precision traded for the fact that it can run on every publish without a model call, and biased toward false alarms in a domain where a false negative is unrecoverable (once a solution is public, it is public forever). That is a well-judged engineering choice, not a placeholder.

There is also a **structural** layer above all three: the answers live in a different repository. The engine is public and MIT; `worksona/bazaar-data` is private. Even a total failure of all three code-level guards leaks only what was staged, not the corpus.

**Honest limit.** Nothing tests any of this. There is no `.github/` directory and `scripts/test-run.sh` executes nothing. The invariant that matters most is the invariant with the least verification behind it.

### 2.3 Answer-hash artifacts: a zero-backend way to keep a secret

This is the most technically interesting thing in the system, and it is **not in the specification at all** — it emerged in the corpus.

Every shipped artifact is a single self-contained HTML file with no external scripts (`PUZ-0012-sudoku/artifact/index.html`, 302 lines; `PUZ-0007-meta-cabinet/artifact/index.html`, 698 lines). Answers are validated in-browser against stored SHA-256 digests via `crypto.subtle`. `~/bazaar/state/state.json` names the scheme:

```json
"artifacts": { "version": "v3", "upgraded": 18,
  "flag_storage": "encrypted-under-solution (logic wing) / sha256-hash (cipher wing)" }
```

Two distinct techniques are recorded there, and the distinction is thoughtful:

- **`sha256-hash`** — the artifact holds a digest and can *verify* a proposed answer without containing it.
- **`encrypted-under-solution`** — the reward payload is encrypted with a key derived from the solution, so the artifact cannot reveal anything until the player has genuinely solved it. This is stronger: a hash can be brute-forced over a small answer space; a payload encrypted under the solution yields nothing without it.

PUZ-0007 composes both into a hunt structure. Its `win_condition` reads:

> *"Solver supplies all five rung keys; each fragment decodes to its word; the assembled flag `CABINET{the_whole_cabinet_remembers_everything}` matches the stored hash and seals."*

Five feeder puzzles each establish a key (Vigenère/LANTERN, Substitution/NIGHTWATCH, Transposition/QUAYSIDE, Playfair/LIGHTHOUSE, Rotor/II·I·III·KDG); the meta re-uses "the five rung engines verbatim (decode direction)" and gates each fragment on a per-word digest. That is MIT Mystery Hunt feeder-to-meta grammar — the record cites it — implemented as static files with no server anywhere in the chain.

**Why this is the load-bearing innovation.** The invariant "solutions never ship" and the constraint "hosting is a static Netlify directory" are in direct tension: a static page that can tell you whether you won normally has to contain the answer. Cryptographic answer storage dissolves the tension, and it is what makes the entire zero-infrastructure distribution model compatible with the commercial premise. The system's cheapest property and its most important property are the same property because of this technique.

**And it is undocumented.** Grep the engine repo for `flag`, `hash`, `CABINET` or `v3` and you get nothing. The technique that makes the architecture work exists only as convention inside 18 HTML files and one unschema'd JSON key.

### 2.4 Emergent taxonomy: the corpus outgrew its own schema

The eighth-family taxonomy in `puzzle-state-spec.md` §10 is `cipher | logic | paper | casual-web | arg | riddle | escape | treasure-hunt`, mirrored as an enum in `schemas/puzzle.schema.yaml` and as `design.allowed_types` in the manifest template. But `PUZ-0007-meta-cabinet/puzzle.yaml` carries:

```yaml
design:
  type: "meta"
  template: "meta.feeder-key-recovery"
```

`meta` is not in the enum. With `additionalProperties: false` and a closed `enum`, that record is schema-invalid — and nothing noticed, because `/puzzle-state validate` is described in prose in `plugin/skills/puzzle-state/SKILL.md` with no executable behind it.

The template vocabulary drifted just as far. Spec §10 names 20 template ids; the corpus uses 18 ids, and almost none of them match: `cipher.monoalphabetic-substitution`, `cipher.polyalphabetic-vigenere`, `cipher.polygraphic-playfair`, `cipher.machine-rotor`, `crypto.two-time-pad`, `stego.lsb-image`, `logic.nikoli-akari`, `logic.slitherlink`, `logic.binairo`, and so on. The spec's `logic.nikoli-family` became nine concrete engines. `crypto.*` and `stego.*` are new prefixes that no document defines.

**Read this two ways, and both are true.** As a defect, it is uncontrolled drift with no validator to catch it (see Report 05). As an innovation signal, it is the system discovering that the right unit is a *mechanic* (`logic.slitherlink`) rather than a *family* (`logic.nikoli-family`), and that puzzle hunts need a `meta` type that composes other puzzles rather than standing alone. The corpus is a more accurate specification than the specification.

### 2.5 Two-plane isolation motivated by generator distrust

The conventional reason to sandbox is untrusted *input*. `puzzle-state-spec.md` §2 invariant 4 sandboxes because the **generator** is untrusted:

> *"Generated game code never executes in the host shell."*

`plugin/skills/puzzle-builder/SKILL.md` states the boundary precisely: generated game JS, LaTeX and solver code "touch the host only as bytes-on-disk written from inside the container." The container mounts `build/` rw and the template dir ro, gets `egress: registries-only`, 2 CPU / 4g, and is killed at `per_puzzle_timeout_s: 1200` — with the timeout *reclassified as a phase outcome* (`build-failed` or `tested: unsolvable`) rather than surfaced as an infrastructure error. Resource exhaustion becomes domain information.

The tester adds a second, cleverer isolation: the solver container mounts `artifact/` read-only and runs "WITHOUT access to `design.solution_sketch` or `solution.md`." That is not a security boundary — it is an **epistemic** one. The playtest is only meaningful if the solver is as ignorant as a real player, so the sandbox enforces ignorance as a first-class property.

**Honest limit, and it is a large one.** All 18 records carry `build.base_image: null` and `build.duration_s: 0`. The sandbox has never run. This is a well-designed and completely unexercised mechanism.

---

## 3. Competent assembly — real quality, not invention

Named explicitly so the innovative claims above stay credible.

| Pattern | What it is | Where it comes from |
|---|---|---|
| Single-writer substrate | Only `/puzzle-state` writes the facility; `state/bazaar.lock` guards the nightly walk | House pattern; spec §2 invariants 2–3 state it is shared with forge-state, desk-state, work-state, notella |
| File-per-entity YAML + append-only NDJSON + derived index | `puzzles/` and `collections/` durable, `state/` "rebuildable" | Event-sourcing-lite; conventional and well applied |
| Phase machine with per-entity resume | Re-running an interrupted night picks up by phase; lock prevents double-walks | Standard workflow engineering, described in `puzzle-orchestrator/SKILL.md` "Idempotency" |
| Cursor-based harvesting | `state/cursor.yaml` per channel; `source.message_ts` as idempotency key | Standard |
| Self-marketplace plugin distribution | Root `.claude-plugin/marketplace.json` with `source: "./plugin"` makes the repo directly installable | House pattern across the portfolio |
| Idempotent bootstrap | Every write in `scripts/init-facility.sh` guarded by `if [[ ! -f ... ]]` with an "exists: … (left as-is)" branch | Good discipline, unremarkable technique |
| Static hosting with a staging guard | `deploy.sh` copies an allowlist into a temp dir, then denylists by `find` | Sound; the copy-allowlist-then-find-denylist belt-and-braces is a nice touch, not an invention |
| Vanilla dependency-free deck | 785-line `index.html`, 196-line `deck.js`, hash routing, print-to-PDF CSS | Deliberately boring, and `deck/deck.js` still opens `/* forge-state deck — vanilla nav, no deps */` — literally copied |

**Prose-as-program** deserves a separate note. The entire application is 12 Markdown contracts and the runtime is an LLM. This is striking on first encounter, but within this portfolio it is the *default* — the same shape appears in forge-state, notella, project-state, home-state and a dozen others. It is the house architecture, not this project's contribution. What puzzle-state adds to it is a domain where the contracts are unusually crisp because the domain has an objective success test: a puzzle is either solvable or it is not, and `puzzle-tester` can find out.

---

## 4. What is claimed but not demonstrated

An innovation report should be explicit about the distance between the design and the evidence.

| Claim | Status | Evidence |
|---|---|---|
| Two-plane Docker isolation | **Designed, never run** | `base_image: null`, `duration_s: 0` on all 18 records |
| Three-surface publishing fan-out (gist + scsiwyg + work-state) | **Designed, never run** | `outputs.gist_url`, `blog_post_id`, `work_state_event_id` all null on all 18; actual distribution recorded in an undeclared `outputs.pages_url` |
| Bazaar curation into collections | **Designed, never run** | `~/bazaar/collections/` is empty despite 18 puzzles at `phase >= reported`, the curator's stated trigger |
| Failure-as-finding | **Designed, never exercised** | No record carries `build-failed` or `test.status: unsolvable`; every one is `solvable` |
| Full-pipeline provenance (`research.md`, `design.md`, `report.md`, `build/`, `test/`, `deploy/`) | **One instance of 18** | Only `PUZ-0001-cipher-collection` has the complete file set; the other 17 hold `puzzle.yaml` + `solution.md` + `artifact/` only |
| Solution-leak guards | **Implemented in prose, untested** | Three layers specified; no CI, `test-run.sh` asserts nothing |

The pattern is consistent: the **reasoning** stages (research, design, build-as-authoring) ran and produced excellent output, while the **infrastructural** stages (sandbox, package, report, publish, curate) were bypassed. The system's innovation is concentrated in exactly the half that has been demonstrated, and its unproven claims are concentrated in the half that is conventional. That is a favorable distribution — the novel parts are the parts that work.

---

## 5. Where the innovation could go next

Grounded in what already exists rather than speculation:

1. **Promote answer-hash storage from convention to contract.** It is the system's best idea and it lives nowhere in the engine repo. A `build.flag_storage` enum (`sha256-hash | encrypted-under-solution | none`) in `schemas/puzzle.schema.yaml` would make the technique inspectable, testable, and reusable — and would let the deploy guard check that no artifact ships a plaintext answer.
2. **Add `meta` to the taxonomy and let it compose.** PUZ-0007 already proves the mechanic. A `meta` type whose `design` block references feeder `PUZ-` ids would make hunt structure a data relationship rather than prose, and would give the curator something to build collections around.
3. **Execute the leak guard.** A single script that greps every staged artifact for ≥40-char substrings of the corresponding `solution.md`, wired to a `.github/` workflow, would convert the system's most important invariant from an assertion into a fact.
4. **Run the sandbox once, on purpose.** One puzzle built through the container path would move two-plane isolation from architecture to evidence and would be worth more to the project's credibility than five more logic puzzles.

---

## Key Takeaways

- **Three genuine innovations:** failure as a publishable phase (encoded in the schema's `phase` enum, not just editorial policy); semantic secrecy guarded at three independent layers including a deliberately crude ≥40-char substring abort; and cryptographic answer storage that lets a zero-backend static page verify a solution without containing it.
- **The answer-hash technique is the keystone** — it resolves the tension between "solutions never ship" and "hosting is a static directory", and it is the reason the cheapest architecture is also the safest one.
- **It is also entirely undocumented in the engine repo.** `flag_storage` appears once, in an unschema'd key in the data plane's `state.json`.
- **The corpus out-specified the spec:** a ninth type `meta` and 18 mechanic-level template ids emerged in practice; `PUZ-0007` is schema-invalid against its own repo's enum, and nothing caught it because `validate` has no implementation.
- **The sandbox motivation is unusual and correct** — the generator is untrusted, not the input — and the tester's *epistemic* isolation (solver denied the solution sketch) is a genuinely thoughtful extension of the idea.
- **Most of the rest is disciplined house-pattern reuse:** single-writer substrate, YAML-plus-NDJSON, cursors, self-marketplace distribution, prose-as-program. `deck/deck.js` still says `forge-state` in line 1 — reuse leaves fingerprints.
- **The novel half is the demonstrated half.** Research, design and artifact authoring ran and produced 18 working puzzles; the sandbox, curator and three-surface publisher — the conventional parts — have never executed.

---

## Cross-References

- [Report 01b — Technical Specification](01b-technical-specification.md) — the invariants, phase machine, and entity shape this report evaluates.
- [Report 02 — Business Benefits](02-business-benefits.md) — why semantic secrecy and zero-backend artifacts are the commercially load-bearing properties.
- [Report 08 — Technical Readiness](08-technical-readiness.md) — the maturity view of the "designed but never run" table in §4.
- [Report 05 — Extensibility](05-extensibility.md) — the schema-drift problem in §2.4 treated as an extension-mechanism defect, with a worked fix.
- [Report 06 — Work Zones](06-work-zones.md) — which zones the demonstrated innovation lives in and which are dormant.
