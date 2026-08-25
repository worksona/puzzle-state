# puzzle-state Project Documentation — Report 07: Portfolio Position

> **Project:** puzzle-state | **Generated:** 2026-08-25 | **Repo:** worksona/puzzle-state (public)

## Executive Summary

puzzle-state is the portfolio's most literal fork: `puzzle-state-spec.md` opens by declaring that its "Architecture mirrors forge-state §1-§18 with puzzle-domain substitutions," and `deck/deck.js` still carries the header comment `/* forge-state deck — vanilla nav, no deps */` from the copy. That makes it both the cleanest demonstration that the house `*-state` pattern is genuinely portable across domains, and the portfolio's single highest duplication risk. It conforms to the house pattern on two axes of three — canonical public source plus a data plane in a separate private repo — but skips the generated-marketplace axis, publishing itself as a one-plugin marketplace from its own root instead.

## The Portfolio Neighborhood

puzzle-state sits inside a family of at least a dozen local-first state facilities that share three structural commitments: a single-writer spine skill (`/puzzle-state`, `/forge-state`, `/notella-state`, `/sound-state`, `/home-state`, `/project-state`, `/reach-state`, `/learn-state`, `/assess-state`, `/intel-state`), file-per-entity YAML with an append-only NDJSON activity log, and a thin orchestrator that routes rather than reasons.

Within that family it occupies a specific slot: **small, complete, and domain-playful**. Twelve skills and 29 tracked files, against project-state's 42 skills, 8 compliance packs, Tauri desktop app, and OVH appliance. It is the reference-sized member — large enough to demonstrate every element of the pattern, small enough to read in one sitting.

### Closest sibling: forge-state

| Element | forge-state | puzzle-state |
|---|---|---|
| Unit of work | an open-source project (EXP-NNNN) | a puzzle (PUZ-NNNN) |
| Intake marker | 🧪 in `#development` | 🧩 in `#development` |
| Phase machine | candidate → researched → built → experimented → packaged → reported → published | candidate → researched → **designed** → built → **tested** → packaged → reported → published |
| Failure doctrine | `build-failed` is terminal-with-findings | `build-failed` **and** `tested:unsolvable` are terminal-with-findings |
| Data plane | `~/forge/` | `~/bazaar/` |
| Machinery dir | visible `state/` | visible `state/` — README calls it "same convention as forge-state" |
| Publish fan-out | gist + scsiwyg + work-state | gist + scsiwyg + work-state (plus a **gated** solution gist) |
| Sandbox | Docker, no secrets | Docker, no secrets, registries-only egress |

puzzle-state's genuine additions over its parent are three: `puzzle-harvester-sources` (the non-Slack intake path — its own SKILL.md calls it "new vs forge-state because research-driven puzzles need an explicit source pipeline"), `puzzle-curator` (bazaar-shaping into `collections/COL-NNNN`, which forge-state has no analogue for), and **solution gating** (spec §2 invariant 7), a security constraint with no counterpart in the forge domain because forge outputs have no secret half.

### The rest of the map

- **work-state** — a direct downstream consumer. `plugin/skills/puzzle-publisher/SKILL.md` step 5 emits a `puzzle.published` event and records `outputs.work_state_event_id`. puzzle-state is one producer among several (forge-state, the scsiwyg harvester, the GitHub harvester) feeding the same activity ledger.
- **notella-desktop** — the same spine-plus-pipeline shape, but with an enforced fan-out (five L1 vision passes) and a `route_plan` computed per item. That is a pattern puzzle-state lacks: its orchestrator routes purely on `phase`, so every puzzle takes the same path regardless of what it is. notella's route_plan is the more expressive design.
- **the-dashes / the-dashes-vibe** — the closest analogue for *publishing* discipline. Both build a public static site plus a machine-consumable pack from a private-ish source of truth, and both name a validate step before deploy. The difference is decisive: the-dashes has `scripts/validate.py`, an executable. puzzle-state's `validate` op exists only as a row in a Markdown table.
- **sound-flow** — its `sound-state` spine wraps `src/lib/state.mjs` (class `Substrate`), described as "the only code path permitted to write `sound-state/`." That is the structural version of the single-writer rule puzzle-state enforces by prose convention.
- **kairair-ota** — definition-driven generation: definitions YAML compiles into pin maps, wiring diagrams, and firmware headers, "never hand-duplicated." That discipline is precisely what puzzle-state's specced-but-absent `templates/types/<template_id>.template/` tree was supposed to provide.
- **story-flow / stonemaps-flow / pixel-flow** — the "vibe" family, which authors interactive artifacts from natural language and ships them as encoded share URLs. puzzle-state also authors interactive HTML artifacts, from a different direction (pipeline, not conversation).
- **learn-state / pre-calc** — the pedagogical wing. A logic-grid puzzle and a graded exercise are the same object with different framing.
- **home-state, reach-state, assess-state, intel-state, project-state** — same spine, unrelated domains; they establish that the pattern is domain-independent rather than puzzle-specific.

## House Pattern Conformance

The house pattern has three parts: **(a)** a canonical source repo, often private; **(b)** where applicable, a *generated* public plugin-marketplace repo built by a sync script and never hand-edited; **(c)** data facilities outside git or in private repos, with secrets never entering a repo.

| Axis | Verdict | Evidence |
|---|---|---|
| (a) Canonical source | ✅ Conforms | `~/WORKSONA/puzzle-state/` → `worksona/puzzle-state`, public. `plugin/` is declared "canonical skill source" in the README repo-layout block. |
| (b) Generated marketplace | ⚠️ Deliberately skipped | `.claude-plugin/marketplace.json` sits at the root of the canonical repo with `source: "./plugin"`, making the repo its own one-plugin marketplace. There is no `scripts/sync-marketplace.mjs` and no sibling `puzzle-state-plugin` repo. |
| (c) Data outside git | ✅ Conforms, strongly | Puzzles live in `worksona/bazaar-data` (private, working copy `~/bazaar/`). Secrets live in a sops-age store referenced by name only (`manifest.secrets.refs: [anthropic, slack, github, scsiwyg, ghcr]`). Generated public output goes to a third repo, `worksona/bazaar`, described in the README as "generated output only." |

On axis (b), puzzle-state resembles the *other* portfolio convention — the one used by `the-dashes-vibe`, `stonemaps-flow-vibe`, `story-flow-vibe`, and `pixel-flow-vibe`, where a public repo *is* the marketplace. That is defensible here for a specific reason: the sync scripts elsewhere exist to scrub absolute paths and gate operator-only skills out of a *private* canonical repo. puzzle-state's canonical repo is already public and holds nothing that needs scrubbing, so a generator would have nothing to do.

The cost of skipping it is real but small: the "never hand-edit the marketplace" guard does not apply, and `plugin/.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json` each carry an independent `"version": "0.1.0"` kept in sync by hand. Nothing prevents them from drifting.

One genuine nonconformance is in the documentation rather than the structure. The README states both install paths without reconciling them — the "Where everything lives" table says `puzzle-state@local-desktop-app-uploads` via a symlink, while the "Install" section says `/plugin install puzzle-state@puzzle-state` after adding the clone as a marketplace. Both are true (operator setup vs. third-party setup), but a reader is told two things and given no way to choose.

## Complementary Capabilities

What puzzle-state contributes to the portfolio that nothing else does:

1. **Failure as a first-class publishable output.** forge-state has `build-failed`; puzzle-state extends the doctrine to a *semantic* failure — `tested: unsolvable` means the artifact built fine and simply doesn't work as a puzzle. Publishing that with a `[finding]` prefix is a discipline the rest of the portfolio's pipelines do not attempt.
2. **A gated-output pattern.** puzzle-state is the only facility in the portfolio that must publish an artifact while withholding part of it. The three-layer implementation — a `scrub kind=public-output` op, a ≥40-character leak scan in `puzzle-publisher`, and a `find`-based abort in `~/bazaar/deploy.sh` — is a reusable template for any future facility with a public/private output split.
3. **An adversarial evaluation stage.** `puzzle-tester` runs a solver against the artifact "WITHOUT access to `design.solution_sketch` or `solution.md`" and verifies output against `design.win_condition`. That is a blindfolded eval harness built into the pipeline, and it is the closest thing in the portfolio to a self-grading generation loop.
4. **Curation as a distinct phase.** `puzzle-curator` reads across all puzzles at `phase >= reported` and produces themed collections. No other facility has a cross-entity synthesis stage that is neither daily/weekly rollup (notella) nor reporting (project-state).

## Integration Opportunities

| # | Opportunity | Why it's available now |
|---|---|---|
| 1 | **Borrow an executable validator.** Adopt the-dashes' `scripts/validate.py` shape, or sound-flow's `Substrate` class from `src/lib/state.mjs`, to make `/puzzle-state validate` real. | Three of eighteen live records carry `design.type` values (`meta`, `modern-crypto`, `stego`) outside the schema's enum. A validator that already exists in a sibling would have caught all three. |
| 2 | **Render `escape` / `arg` / `treasure-hunt` artifacts as story-flow graphs.** story-flow models experiences as node graphs with Play State and authored `require` gates — which is structurally what an escape room and a breadcrumb trail are. | Three of the eight taxonomy families in spec §10 have never been built, and their template ids (`escape.scene-graph`, `arg.breadcrumb-trail`, `hunt.clue-chain`) describe graphs. Reusing story-flow closes them without inventing a template family. |
| 3 | **Share a Slack harvester core with forge-state.** Both drain the same channel (`#development`) with the same cursor mechanic, differing only in emoji (🧪 vs 🧩) and target facility. | `puzzle-harvester-slack/SKILL.md` and its forge-state counterpart describe an identical five-step algorithm. |
| 4 | **Ship an LLM pack for the bazaar.** the-dashes generates `llms.txt`, `llms-full.txt`, `manifest.json`, and a knowledge graph from its board JSON. | The puzzle site currently publishes only `site/index.html` and `puzzles/*/artifact/`. Eighteen puzzles with typed metadata, difficulty, and tags are already sitting in YAML waiting to be indexed. |
| 5 | **Feed puzzles into learn-state / pre-calc as graded exercises.** | The logic wing (light-up, binairo, sudoku, nonogram, skyscrapers, slitherlink) is pedagogical material with a recorded `difficulty_actual` and a verified unique solution. |
| 6 | **Route curated collections into a scsiwyg series.** `puzzle-curator/SKILL.md` explicitly names this as a non-goal for itself and defers to the publisher — which has no collection path. | `collections/` is empty despite eighteen puzzles at `phase >= reported`. The specced feature has never produced an artifact. |

## Overlap and Duplication Risks

1. **forge-state ↔ puzzle-state is a maintained fork, not an abstraction.** The lock file, the orchestrator walk, the harvester cursor, the publish fan-out, the two-plane sandbox, and the deck chrome all exist twice and will drift independently. The stale `/* forge-state deck */` comment in `deck/deck.js` is the fork made visible. **Highest-value consolidation target in the portfolio.**
2. **Three publish fan-outs.** forge-state, puzzle-state, and the news-desk wing each independently implement gist + scsiwyg + work-state egress. Only puzzle-state adds the gating layer — meaning the *best* version of the pattern is the one least likely to be reused.
3. **Hand-rolled deploy scripts.** `~/bazaar/deploy.sh`, the-dashes' Netlify deploy, sound-flow's, and stonemaps' each stage-and-push by hand. puzzle-state's is the only one with a private-file abort guard; that guard is the part worth extracting.
4. **Naming collision.** The portfolio already contains an `anthropic-skills:puzzle-smith` skill. A user with both installed sees two puzzle-authoring surfaces with no stated relationship.
5. **Two `bazaar` repos.** `worksona/bazaar-data` (private, source of truth) and `worksona/bazaar` (public, generated output only, GitHub Pages mirror) differ by one hyphenated suffix. That is a foot-gun for any future `git push` that reaches for the wrong remote — and the thing being pushed is solutions.

## Key Takeaways

- puzzle-state is the portfolio's clearest proof that the `*-state` pattern ports across domains: the spec says so explicitly, and eighteen live puzzles say so operationally.
- It conforms to the house pattern on canonical-source and data-outside-git, and deliberately skips the generated-marketplace axis — a defensible call for an already-public canonical repo, at the cost of hand-synced version numbers.
- Its three unique contributions are semantic-failure-as-output, the three-layer gated-output pattern, and a blindfolded in-pipeline evaluation stage.
- Its largest structural liability is not internal: it is that forge-state and puzzle-state are two copies of one machine, both actively maintained.
- Every gap flagged in Report 08 has an existing solution somewhere else in the portfolio — an executable validator in the-dashes, a code-enforced single writer in sound-flow, definition-driven generation in kairair. The remediation work is mostly adoption, not invention.

## Cross-References

- [Report 01: Project Overview](./01-project-overview.md) — what the project is, who it serves, and the engine/data-plane split.
- [Report 01b: Technical Specification](./01b-technical-specification.md) — component architecture, data models, and deployment topology.
- [Report 04: Features & Capabilities](./04-features-capabilities.md) — what runs today versus what is specced but unbuilt.
- [Report 08: Technical Readiness](./08-technical-readiness.md) — scored maturity assessment and remediation priorities.
- [Report 09: Worksona Leadership Themes](./09-worksona-themes.md) — evaluation against the seven leadership runbook commands.
- [Report 10: Worksona First Principles](./10-worksona-first-principles.md) — evaluation against the sixteen worksona.fp structural principles.
