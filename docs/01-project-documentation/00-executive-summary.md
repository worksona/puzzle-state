# puzzle-state Project Documentation — Executive Summary

> **Project:** puzzle-state | **Generated:** 2026-08-25 | **Repo:** worksona/puzzle-state (public)

## Executive Summary

puzzle-state is a local-first "bazaar of puzzles and puzzling things": drop a Slack 🧩 reaction, a URL, a file, or a one-line query, and an agent pipeline researches it, designs a puzzle from it, builds the playable artifact, playtests it for solvability, packages it, and publishes a writeup — while the answer key stays gated in a separate private repo. This repository is the **engine**, not the puzzles: a Claude Code plugin of twelve `/puzzle-*` skills, a normative spec, a JSON Schema for the puzzle record, facility templates, two Bash scripts, and a fifteen-slide onboarding deck, in 26 tracked files with no dependency manifest of any kind. The puzzles live in the private data plane (`worksona/bazaar-data`, working copy `~/bazaar/`), which today holds eighteen real puzzles, seventeen published live at https://puzzle-state.netlify.app.

The suite's central finding, repeated across all eleven reports from different angles: **the outputs are production-grade and the engine repo is a v0.1 scaffold, simultaneously.** The pipeline has been walked end to end many times and has survived two in-place artifact upgrade passes; the repo that documents it has two commits, no tags, no tests, no CI, a spec missing eleven of the eighteen sections it claims to mirror, and a `templates/types/` directory that four documents reference and that has never been created. Every risk in this suite lives in the gap between those two facts.

## What This Project Is

- **Unit of work:** one puzzle, `PUZ-NNNN-slug`, one directory, carried through a fixed nine-value phase machine — `candidate → researched → designed → built → tested → packaged → reported → published`, with `build-failed` and `tested: unsolvable` as **terminal-with-findings** branches that still advance to report and publish.
- **Architecture:** three tiers over two repos. A single-writer spine (`/puzzle-state`) is the only permitted writer to the facility; host reasoning skills hold secrets and reach the network; sandboxed execution skills (builder, tester, packager) run inside a disposable per-puzzle Docker container with `egress: registries-only`.
- **Defining constraint:** a specific derived artifact — the answer — must never appear in output. Enforced at four layers, one of them structural (solutions are absent from the public repo, not merely scrubbed from it).
- **Family:** the *n*th instance of the Atomic 47 / Worksona house `*-state` pattern, forked most directly from `forge-state` — the spec says so in its first line, and `deck/deck.js` still carries the forge-state header comment.

## The Eleven Reports

| # | Report | What it covers |
|---|---|---|
| 01 | [Project Overview](./01-project-overview.md) | What puzzle-state is, the problem stack it solves, who it serves, the tech stack, the two-repo/two-plane architecture, getting started, and the honest split between a production pipeline and a v0.1 engine repo. |
| 01b | [Technical Specification](./01b-technical-specification.md) | Component architecture across three tiers, the `puzzle.yaml` data model and its schema, the command surface, deployment topology, the security architecture, and seven technical decisions with their costs — including the finding that the schema is normative in text and unenforced in practice. |
| 02 | [Business Benefits](./02-business-benefits.md) | The job-to-be-done ("one-gesture capture to finished artifact"), five value propositions, four personas, cost implications, competitive positioning against hand-authoring and hunt platforms, and a recommended posture of internal leverage plus a public credential rather than revenue. |
| 03 | [Innovation Themes](./03-innovation-themes.md) | Separates three genuine innovations — failure as a publishable phase, semantic secrecy guarded at three layers, and zero-backend answer-hash artifacts — from disciplined house-pattern reuse, and observes that the corpus innovated past its own spec with an emergent ninth `meta` family. |
| 04 | [Features & Capabilities](./04-features-capabilities.md) | A capability inventory across six areas, marked explicitly as **built & exercised**, **built but unexercised**, or **specced but not built** — showing that safety controls are the most complete feature set and that the publisher fan-out is the largest unexercised surface. |
| 05 | [Extensibility](./05-extensibility.md) | The four extension surfaces (skills, intake, configuration, schema), two worked examples including adding the `meta` puzzle type, where extension is blocked or hard-coded, and the conclusion that `templates/types/` is the highest-leverage missing artifact in the project. |
| 06 | [Work Zones](./06-work-zones.md) | Nine functional zones across two repos with per-zone health: three healthy (Contract Definition, Artifact Authoring, Distribution & Onboarding), three dormant (Sandbox & Build, Curation, Publishing Fan-Out), and one — Quality & Verification — effectively empty and highest-leverage. |
| 07 | [Portfolio Position](./07-portfolio-position.md) | puzzle-state as the portfolio's most literal fork of `forge-state`, its conformance to the house pattern on two axes of three, its three unique contributions back to the family, and the observation that every gap in Report 08 already has a working reference implementation in a sibling project. |
| 08 | [Technical Readiness](./08-technical-readiness.md) | A ten-dimension scorecard with evidence and gaps, three top strengths, three top risks, and ten prioritized investments — the quantitative backbone of the whole suite. |
| 09 | [Worksona Leadership Themes](./09-worksona-themes.md) | Assessment against the seven commands of the Worksona Leadership Runbook: strongest on `/map-before-make`, `/demonstrate-not-decorate`, and `/mandate-interoperability`; weakest by a wide margin on `/enforce-measurement`. Includes the AI / technology / UX / principles theme map. |
| 10 | [Worksona First Principles](./10-worksona-first-principles.md) | Assessment against the sixteen structural principles of worksona.fp — eight Strong, six Moderate, two Weak — with a work-graph view, validity regions, curvature hotspots, and the finding that all observed drift crossed one uncontracted edge between the engine repo and the data plane. |

## Key Themes

**The recurring signature: excellent contracts, no runner.** Every report reaches this from a different direction. Report 04 finds `validate` is the one spine operation with no implementation. Report 06 finds Quality & Verification is the smallest zone and the highest-leverage. Report 09 names it as the cultural blind spot across all seven leadership commands. Report 10 finds that nearly every "Moderate" principle rating has the same cause — a correct structure with nothing that executes it. Report 08 quantifies the consequence: three of eighteen live records violate the schema right now, and nothing noticed.

**Security by structure, not by care.** The strongest guarantee in the system requires no code to run correctly: solutions cannot leak from a repo that does not contain them. Three further runtime layers (scrub op, ≥40-character leak scan, deploy-time `find` abort) sit on top, and a fourth lives in the artifacts themselves as SHA-256 / XOR-under-solution flag vaults. Reports 02, 03, 08, and 10 all identify this as the project's best design work — and Reports 06 and 08 all identify it as its most consequential untested surface.

**Failure as a first-class output.** Two of nine phase values are failure states, and both advance to publication with a `[finding]` prefix. This is encoded in the schema enum, routed by the orchestrator dispatch table, and given a narrative sense in the reporter — not merely an editorial policy. Reports 01, 02, 03, 08, and 09 each treat it as the project's most transferable idea.

**Reasoning ran; infrastructure did not.** The zones that produced output are the *reasoning* ones — research, design, artifact authoring. The zones that were specified in most detail and then bypassed are the *infrastructural* ones: the Docker sandbox (all 18 records carry `build.base_image: null`), curation (`collections/` is empty despite 18 eligible puzzles), and the three-surface publishing fan-out (all `outputs.*` gist/blog/work-state fields null). "Published" currently means "on Netlify".

**Narrow demonstrated coverage against a broad advertised surface.** All eighteen puzzles are cipher-wing or logic-wing. Six of eight taxonomy families — `paper`, `casual-web`, `arg`, `riddle`, `escape`, `treasure-hunt` — have no instance, taking the `pdf`, `docker-web`, `breadcrumb-pack`, and `scsiwyg-post` artifact kinds and the whole GHCR push path with them.

**The pattern is portable, and the fork is a liability.** puzzle-state is the clearest proof that the house `*-state` pattern ports across domains. It is also two copies of one machine — `forge-state` and `puzzle-state` — both actively maintained.

## Portfolio Tags

`local-first` · `agent-pipeline` · `state-facility` · `single-writer-substrate` · `file-per-entity-yaml` · `append-only-ndjson` · `two-plane-isolation` · `claude-code-plugin` · `one-plugin-marketplace` · `prose-as-program` · `markdown-contracts` · `phase-machine` · `zero-dependency` · `json-schema-2020-12` · `docker-sandbox` · `untrusted-generation-containment` · `semantic-secrecy` · `gated-output` · `answer-hash-artifacts` · `crypto-subtle` · `failure-as-finding` · `blindfolded-evaluator` · `static-hosting` · `netlify` · `ghcr` · `sops-age` · `house-pattern` · `forge-state-fork` · `puzzle-generation` · `MIT`

**Cross-portfolio references:** closest sibling `forge-state` (same machine, different domain). Remediation reference implementations exist elsewhere in the portfolio — an executable `scripts/validate.py` in **the-dashes**, a code-enforced single-writer substrate in **sound-flow**, definition-driven generation in **kairair-ota**. Shared substrate vocabulary with **work-state**, **notella-desktop**, **project-state**, **home-state**, **learn-state**, **reach-state**.

## Headline Readiness Rating

> **Overall: 30/50 — 🟡 Functional (3.0/5)**
>
> **⚠️ Production Ready with Caveats — for its author-operator.**
> **🚧 Needs Investment Before Production — as a distributable plugin.**

Per [Report 08](./08-technical-readiness.md), the ten-dimension breakdown:

| Dimension | Score | Maturity |
|---|---|---|
| Security Posture | 4/5 | 🟢 Mature |
| Dependency Health | 4/5 | 🟢 Mature |
| Error Handling & Resilience | 4/5 | 🟢 Mature |
| Code Quality & Consistency | 3/5 | 🟡 Functional |
| Documentation | 3/5 | 🟡 Functional |
| Observability & Monitoring | 3/5 | 🟡 Functional |
| Scalability Readiness | 3/5 | 🟡 Functional |
| Developer Experience | 3/5 | 🟡 Functional |
| CI/CD & Deployment | 2/5 | 🟠 Developing |
| Test Coverage & Quality | 1/5 | 🔴 Critical |

**The four investments that move the line**, all small and three of them afternoon-sized: write `scripts/validate.py` to walk `$BAZAAR_ROOT/puzzles/*/puzzle.yaml` against the schema; add a solution-leak test fixture; add `.github/workflows/validate.yml` to run them; and resolve the `templates/types/` contradiction by creating the tree or amending the four documents that describe it.

## Key Takeaways

- puzzle-state is an **engine repo, not a puzzle repo** — twelve Markdown contracts, a spec, a schema, two templates, two scripts, and a deck, with zero dependency manifests.
- **Both readiness statements are true at once:** the outputs are in production (18 puzzles, 17 published, two upgrade passes, a live site) and the engine is a two-commit v0.1 scaffold.
- **Solution gating is the design's best work** — four layers, one structural — and its most consequential untested surface.
- **The consistent gap is verification, not architecture.** Nothing in the repo executes: the schema, the single-writer rule, the scrub, the leak scan, and `validate` are all currently claims.
- **Drift has already occurred and went unobserved:** three schema-invalid records, an empty `collections/`, two undocumented `state.json` keys, and a whole `flag_storage` convention that exists in no spec, schema, skill, or README.
- **Remediation is mostly adoption, not invention** — every top-priority fix has a working reference implementation elsewhere in the portfolio.

## Cross-References

- [Report 01: Project Overview](./01-project-overview.md)
- [Report 01b: Technical Specification](./01b-technical-specification.md)
- [Report 02: Business Benefits](./02-business-benefits.md)
- [Report 03: Innovation Themes](./03-innovation-themes.md)
- [Report 04: Features & Capabilities](./04-features-capabilities.md)
- [Report 05: Extensibility](./05-extensibility.md)
- [Report 06: Work Zones](./06-work-zones.md)
- [Report 07: Portfolio Position](./07-portfolio-position.md)
- [Report 08: Technical Readiness](./08-technical-readiness.md)
- [Report 09: Worksona Leadership Themes](./09-worksona-themes.md)
- [Report 10: Worksona First Principles](./10-worksona-first-principles.md)
- [Documentation Index](../README.md)
- [Project README](../../README.md)
