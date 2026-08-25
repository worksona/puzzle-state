# puzzle-state Documentation

> **Project:** puzzle-state | **Last Updated:** 2026-08-25 | **Repo:** worksona/puzzle-state (public)

The documentation index for puzzle-state — the engine repo behind the bazaar of puzzles at https://puzzle-state.netlify.app. Start with the [Executive Summary](./01-project-documentation/00-executive-summary.md); everything else hangs off it.

## Start Here

| If you want to… | Read |
|---|---|
| Understand the whole project in five minutes | [Executive Summary](./01-project-documentation/00-executive-summary.md) |
| Install it and run a walk | [Project README → Getting Started](../README.md#getting-started) |
| Understand what it is and why | [Report 01: Project Overview](./01-project-documentation/01-project-overview.md) |
| Understand how it is built | [Report 01b: Technical Specification](./01-project-documentation/01b-technical-specification.md) |
| Know what actually works today | [Report 04: Features & Capabilities](./01-project-documentation/04-features-capabilities.md) |
| Know what is safe to rely on | [Report 08: Technical Readiness](./01-project-documentation/08-technical-readiness.md) |
| Extend it | [Report 05: Extensibility](./01-project-documentation/05-extensibility.md) |
| Read the normative contract | [`puzzle-state-spec.md`](../puzzle-state-spec.md) |

## Documentation Categories

### `01-project-documentation/` — Project Documentation Suite

Twelve documents generated 2026-08-25. An evidence-based analysis of the engine repo and its data plane, covering purpose, architecture, capabilities, readiness, extensibility, portfolio position, and alignment against the Worksona leadership and first-principles rubrics.

| Document | Focus |
|---|---|
| [00 — Executive Summary](./01-project-documentation/00-executive-summary.md) | Suite overview, key themes, portfolio tags, headline readiness rating |
| [01 — Project Overview](./01-project-documentation/01-project-overview.md) | What it is, who it serves, tech stack, architecture, current state |
| [01b — Technical Specification](./01-project-documentation/01b-technical-specification.md) | Component architecture, data models, command surface, security architecture, decisions and trade-offs |
| [02 — Business Benefits](./01-project-documentation/02-business-benefits.md) | Job-to-be-done, value propositions, personas, cost implications, commercialization posture |
| [03 — Innovation Themes](./01-project-documentation/03-innovation-themes.md) | Genuine innovation vs. disciplined house-pattern reuse |
| [04 — Features & Capabilities](./01-project-documentation/04-features-capabilities.md) | Capability inventory: built & exercised, built but unexercised, specced but not built |
| [05 — Extensibility](./01-project-documentation/05-extensibility.md) | Extension surfaces, worked examples, where extension is blocked |
| [06 — Work Zones](./01-project-documentation/06-work-zones.md) | Nine functional zones across two repos, with per-zone health |
| [07 — Portfolio Position](./01-project-documentation/07-portfolio-position.md) | Relationship to forge-state and the rest of the `*-state` family |
| [08 — Technical Readiness](./01-project-documentation/08-technical-readiness.md) | Ten-dimension scorecard, strengths, risks, prioritized investments |
| [09 — Worksona Leadership Themes](./01-project-documentation/09-worksona-themes.md) | Assessment against the seven leadership commands; AI / tech / UX theme map |
| [10 — Worksona First Principles](./01-project-documentation/10-worksona-first-principles.md) | Assessment against the sixteen structural principles; work-graph view |

## Headline Assessment

> **30/50 — 🟡 Functional (3.0/5).** ⚠️ Production Ready with Caveats for its author-operator; 🚧 Needs Investment Before Production as a distributable plugin.

Eighteen puzzles live and seventeen published on one side; a two-commit v0.1 engine repo with no tests and no CI on the other. Details in [Report 08](./01-project-documentation/08-technical-readiness.md).

## Documentation That Lives Outside `docs/`

Not everything documenting this project is in this directory, and some of it is normative:

| Document | Location | Role |
|---|---|---|
| Project README | [`../README.md`](../README.md) | Front door: badges, state of development, tech stack, getting started, light spec |
| Normative spec | [`../puzzle-state-spec.md`](../puzzle-state-spec.md) | Invariants, topology, entity shape, phase machine, taxonomy, locked decisions. **Version 0.1 (draft for lock)** — §8, §9, and §11–§17 were never written |
| Record schema | [`../schemas/puzzle.schema.yaml`](../schemas/puzzle.schema.yaml) | JSON Schema 2020-12 for `puzzle.yaml`; the machine-readable contract |
| Skill contracts | [`../plugin/skills/*/SKILL.md`](../plugin/skills/) | Twelve files, 414 lines — simultaneously the developer docs and the machine's operating instructions |
| Onboarding deck | [`../deck/index.html`](../deck/) | Fifteen slides with speaker notes; live at [/deck/](https://puzzle-state.netlify.app/deck/) |
| Data-plane README | `~/bazaar/README.md` | Private repo: facility layout and the two deploy scripts |

## Adding New Documentation Categories

This index is structured so new categories slot in without restructuring. Each category is a numbered subdirectory of `docs/` with its own set of documents and a row in **Documentation Categories** above.

```
docs/
  README.md                      ← this index
  01-project-documentation/      ← the analysis suite (2026-08-25)
  02-<next-category>/            ← e.g. runbooks, ADRs, puzzle-authoring guides
```

Convention: `NN-kebab-case-name/`, two-digit prefix, ordered by when the category was established. Within a category, documents carry their own two-digit prefix and `00-` is reserved for that category's summary or index.

**Candidate future categories**, drawn from gaps the suite identified:

- `02-runbooks/` — the nightly walk, the deploy, and the recovery path for a bad Netlify deploy (no rollback procedure is documented anywhere today).
- `03-decisions/` — ADRs. Spec §18 "Locked decisions" is the seed; six entries already exist there.
- `04-authoring/` — the puzzle-authoring guide, including the undocumented `flag_storage` convention (SHA-256 hash in the cipher wing, encrypted-under-solution in the logic wing) that currently exists only as a string in the data plane's `state.json`.

## Cross-References

- [Project README](../README.md)
- [Executive Summary](./01-project-documentation/00-executive-summary.md)
- [puzzle-state Specification](../puzzle-state-spec.md)
- Live site: [puzzle-state.netlify.app](https://puzzle-state.netlify.app) · Deck: [/deck/](https://puzzle-state.netlify.app/deck/)
