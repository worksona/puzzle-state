# puzzle-state Project Documentation — Report 05: Extensibility

> **Project:** puzzle-state | **Generated:** 2026-08-25 | **Repo:** worksona/puzzle-state (public)

## Executive Summary

puzzle-state extends well in the two places it was designed to: adding a skill is dropping a `SKILL.md` into `plugin/skills/`, and adding a source feed is adding a list entry to `manifest.intake.sources[]`. Everything else is extended by editing enums — `schemas/puzzle.schema.yaml` uses `additionalProperties: false` and closed `enum`s throughout, which is admirable rigor undermined by the fact that nothing executes the validator, so the live corpus has already drifted past the schema in four separate ways without anyone noticing. The single largest blocker is that `templates/types/` — the extension point named by the spec, the README and `puzzle-designer` alike — does not exist on disk.

---

## 1. The extension surface at a glance

| # | Extension point | Mechanism | Cost to extend | State |
|---|---|---|---|---|
| 1 | Add a skill | Drop `plugin/skills/<name>/SKILL.md` | One file | **Open** — `plugin.json` does not enumerate skills; discovery is by directory |
| 2 | Add a recurring source feed | Append to `manifest.intake.sources[]` | One YAML entry | **Open** for `kind: prompt-seed`; `rss` and `archive` are marked "(future)" |
| 3 | Add an inbox drop format | Extend the classifier in `puzzle-harvester-sources` | One contract edit + the inbox README | **Open** |
| 4 | Add a puzzle type | Enum in schema + manifest + spec §10 + README + tag taxonomy | 5 coordinated edits | **Friction** — see §3 |
| 5 | Add a puzzle template | Create `templates/types/<id>.template/` | One directory | **Blocked** — the directory tree does not exist |
| 6 | Add an artifact kind | Enum in schema + `manifest.sandbox.base_images` + packager table | 3 edits | **Friction** |
| 7 | Add a base image / change sandbox limits | `manifest.sandbox.*` | Config only | **Open** |
| 8 | Add a curation tag | `manifest.curation.tag_taxonomy` | Config only | **Open**, but unenforced |
| 9 | Toggle / configure a publishing surface | `manifest.surfaces.*` | Config only | **Partial** — surfaces are configurable, not pluggable |
| 10 | Relocate either plane | `$BAZAAR_ROOT`, `$PUZZLE_STATE_REPO` | Env var | **Open** |
| 11 | Add a new entity kind (beyond PUZ/COL) | Schema file + `allocate-id` + spine ops | Multiple | **Friction** — `allocate-id` takes `kind (PUZ \| COL)` |
| 12 | Add a persisted field to `puzzle.yaml` | Schema property | One edit | **Friction** — `additionalProperties: false` everywhere |

---

## 2. The four extension surfaces in detail

### 2.1 Skills — the cleanest surface in the project

`plugin/.claude-plugin/plugin.json` contains a name, version, description, author, license, and keywords. It does **not** list skills. Discovery is filesystem-based: 12 directories under `plugin/skills/`, each with a `SKILL.md` carrying YAML frontmatter (`name`, `description`) and a Markdown body.

Adding a thirteenth skill is therefore one new directory and one new file, with no registry to update and no build step to run. The frontmatter `description` is the entire routing surface — it is what makes the skill discoverable, and every existing contract packs trigger phrases into it. From `puzzle-curator/SKILL.md`:

> `Trigger phrases include "/puzzle-curator", "curate the bazaar", "bin recent puzzles into collections", "rebuild the tag map".`

The convention across all 12 is consistent: a one-paragraph description ending in trigger phrases, then a body with **When to use / Inputs / Behavior / Outputs / Idempotency** sections. Contracts run 20–60 lines (414 total). A new skill that matches this shape will feel native.

**The one hard rule** is stated in `plugin/skills/puzzle-state/SKILL.md` and spec §2 invariant 3: no skill writes the substrate directly. Every read and write routes through `/puzzle-state`. A new skill that writes `~/bazaar/` itself violates the architecture even though nothing mechanically stops it.

### 2.2 Intake — declarative and genuinely open

Two independent intake paths, both configured rather than coded.

**Slack** (`intake.slack`): channels list, marker emoji, `markers_self_only`. Changing the marker from 🧩 or adding a second channel is a manifest edit; `plugin/skills/puzzle-harvester-slack/SKILL.md` reads all three keys at runtime and keys idempotency on `source.message_ts`.

**Sources** (`intake.sources[]`): a list of `{kind, name, value, cadence}`. The shipped seed is:

```yaml
- kind: prompt-seed
  name: "weekly theme"
  value: "make a beginner cipher inspired by something atmospheric"
  cadence: weekly
```

`puzzle-harvester-sources` handles `prompt-seed` today and reserves `rss` and `archive` explicitly as future kinds, with per-feed cursors at `state/cursor.yaml → sources.<name>`. The extension shape is already carved out; implementing `rss` means adding a branch to one contract, not restructuring intake.

**Inbox drop** is a third, zero-config path: files in `~/bazaar/inbox/` classified by extension (`.url`, `.query`, `.txt`, `.md`, `.pdf`, `.png`, `.jpg`), processed files moved to `state/processed-inbox/<date>/`. The accepted formats are documented in the inbox README that `scripts/init-facility.sh` writes, so extending the format list means editing two places that must agree.

### 2.3 Configuration — broad, and mostly honest

`templates/manifest.yaml.template` is the primary tuning surface: sandbox runtime and per-kind base images, egress policy, CPU/memory, `per_puzzle_timeout_s: 1200`, `night_budget_s: 14400`, `design.default_difficulty` and `allowed_types`, `testing.solver.{require_unique_solution, max_solve_time_s}`, `packaging.{emit_bundle, push_image, registry}`, `surfaces.*`, `curation.{auto_collection, tag_taxonomy}`, `durability.mirror`, `secrets.{store, refs}`.

Two defects in this surface:

- **`manifest.surfaces.blog.publish_findings` does not exist.** It is referenced twice — in `puzzle-tester/SKILL.md` ("if `manifest.surfaces.blog.publish_findings` is true") and `puzzle-publisher/SKILL.md` ("the publisher still ships if …") — but the manifest template has no such key. Two skills branch on a config value the config cannot express.
- **`durability.mirror.remote: null`** ships as null and the README's setup step 4 says it must be set "before relying on it". The durability guarantee is opt-in and off by default.

### 2.4 Schema — closed by design, unenforced in practice

`schemas/puzzle.schema.yaml` is JSON Schema 2020-12 with `additionalProperties: false` on the root and on every nested block, plus closed enums on `phase`, `source.surface`, `design.type`, `design.difficulty_target`, `build.artifact_kind`, `build.status`, and `test.status`. This is the right call: it makes any new field a deliberate, reviewable act.

It only works if something runs it. `/puzzle-state validate` is described in a table row in `plugin/skills/puzzle-state/SKILL.md` — "walk puzzles + collections, validate against schemas" — with no script, no CI job, and no `.github/` directory behind it. The result is measurable drift in the live corpus:

| Drift | Where | Why it is invalid |
|---|---|---|
| `design.type: "meta"` | `PUZ-0007-meta-cabinet/puzzle.yaml` | Not in the `design.type` enum |
| `outputs.blog_url`, `outputs.pages_url` | All 18 records | `outputs` is `additionalProperties: false` |
| Tags `nikoli`, `deduction`, `slitherlink` | `PUZ-0018` and others | Not in `manifest.curation.tag_taxonomy` |
| Template ids `crypto.two-time-pad`, `stego.lsb-image`, `logic.slitherlink`, … | 18 records | Free-form `string`, so schema-legal — but none match the 20 ids named in spec §10 |

Two further schema gaps: **`collection.yaml` has no schema at all** (the curator writes it and `validate` claims to check it, but `schemas/` contains only `puzzle.schema.yaml`), and **`state/state.json` has no schema**, which is exactly how the undocumented `site{}` and `artifacts{}` blocks appeared in the live file unremarked.

---

## 3. Worked example: adding the `meta` puzzle type

The best worked example is one the project has already half-performed. `PUZ-0007-meta-cabinet` is a working feeder-to-meta capstone — five cipher rungs whose recovered keys unlock five fragments that assemble into a final flag — and it was created by writing `design.type: "meta"` into a record and building the artifact. Nothing else was updated. Here is what a *complete* extension looks like.

### Step 1 — Extend the schema enum

`schemas/puzzle.schema.yaml`, `design.type`:

```yaml
      type:
        type: string
        enum: [cipher, logic, paper, casual-web, arg, riddle, escape, treasure-hunt, meta]
```

This one edit turns `PUZ-0007` from schema-invalid into schema-valid.

### Step 2 — Allow the type in the facility config

`templates/manifest.yaml.template`, `design.allowed_types`: append `- meta`. Note this is the *template*; the live `~/bazaar/manifest.yaml` was copied at init time and does not track template changes, so an existing facility needs the same edit applied by hand. That is a real extensibility wrinkle — there is no migration path from template to installed manifest.

### Step 3 — Add the template family

Spec §10 says templates live at `templates/types/<template_id>.template/`; `puzzle-designer/SKILL.md` says `templates/types/<type>.<template_id>.template/`. **These two paths disagree**, and neither directory exists — `templates/` contains only `manifest.yaml.template` and `puzzle.yaml.template`. Resolving the contradiction is a prerequisite for this step, not part of it.

Assuming the spec form wins, create:

```
templates/types/meta.feeder-key-recovery.template/
  README.md          # what the mechanic is; what the builder must produce
  index.html         # scaffold: N feeder key inputs, per-fragment SHA-256 gates
  manifest.json      # declares feeder count, flag format, hash algorithm
```

The scaffold content is recoverable from `PUZ-0007-meta-cabinet/artifact/index.html` (698 lines, six `crypto.subtle` / `sha256` sites), which is the working reference implementation.

### Step 4 — Document the taxonomy in both places

Spec §10's table and the README's "Puzzle taxonomy" table both enumerate the families. Both need a `meta` row. They are independent prose; nothing keeps them in sync.

### Step 5 — Extend the curation vocabulary

`manifest.curation.tag_taxonomy` is the controlled vocabulary the curator bins against. Add `meta` — and, if the corpus is to be honest, the mechanic-level tags already in use (`nikoli`, `deduction`, `slitherlink`) too.

### Step 6 — Decide the artifact kind

`meta.feeder-key-recovery` produces `html-static`, which already exists in the `build.artifact_kind` enum and already has a base image (`static-html: node:20`) and a packager row (`deploy/RUN.md`, no compose). No change needed — this is the extension working as designed.

### Cost summary

| Step | Files touched | Blocked? |
|---|---|---|
| 1. Schema enum | `schemas/puzzle.schema.yaml` | No |
| 2. Manifest allowed_types | `templates/manifest.yaml.template` + live `~/bazaar/manifest.yaml` | No, but no migration path |
| 3. Template family | `templates/types/…` | **Yes** — tree missing, path contradictory |
| 4. Docs | `puzzle-state-spec.md` §10, `README.md` | No |
| 5. Tag taxonomy | `templates/manifest.yaml.template` | No |
| 6. Artifact kind | — | No |

**Five edits and one blocker to add one enum value.** The blocker is the same one that blocks adding any new mechanic, which makes `templates/types/` the highest-leverage missing artifact in the repo.

---

## 4. A second worked example: adding a publishing surface

Suppose you want puzzles to also post to Mastodon.

**Config side — easy.** `manifest.surfaces` is a map of named surfaces, each with its own shape (`gist` has `auto` and a nested `solution_gist.visibility`; `blog` has `target`, `auto`, `solution_post.visibility`; `work_state` has just `enabled`). Adding a `mastodon:` block is a YAML edit. Recording the result needs one new property in the `outputs` block of the schema — `additionalProperties: false` makes that mandatory rather than optional, which is the rigor working correctly.

**Behavior side — hard-coded.** `plugin/skills/puzzle-publisher/SKILL.md` enumerates the surfaces in a fixed six-step "Order of operations": scrub → public gist → scsiwyg post → gated solution gist → work-state event → advance. There is no surface abstraction, no adapter contract, no loop over `manifest.surfaces`. Adding Mastodon means editing the publisher's prose to insert a step, and every future surface does the same. **Surfaces are configurable, not pluggable** — a real limit, and the clearest place where the architecture's declarative ambition outruns its implementation.

The right refactor is visible from here: make the publisher iterate `manifest.surfaces` and require each surface to declare an `outputs` key it writes, moving surfaces from prose enumeration to data. That would also fix the missing `publish_findings` key by giving surfaces a place to carry their own flags.

---

## 5. Where extension is blocked or hard-coded

| Blocker | Detail | Impact |
|---|---|---|
| **`templates/types/` does not exist** | Named by spec §10, README, `puzzle-designer` and `puzzle-builder` (which mounts it read-only into the container). `ls templates/types` → no such file | Blocks every new mechanic; blocks the sandbox build path entirely |
| **Two contradictory template paths** | Spec: `<template_id>.template/`; designer: `<type>.<template_id>.template/` | Must be resolved before the tree can be created |
| **No executable validator** | `validate` is a table row with no script; no CI | All schema rigor is advisory; four kinds of drift already present |
| **No `collection.schema.yaml`** | Curator writes `collections/COL-NNNN-slug/collection.yaml`; `validate` claims to check collections | A second entity type with no contract |
| **No schema for `state.json`** | Live file has undeclared `site{}` and `artifacts{}` blocks | The `flag_storage` convention — arguably the system's best idea — lives only here |
| **Publisher surfaces enumerated in prose** | Fixed six-step order in `puzzle-publisher/SKILL.md` | New surfaces require contract surgery, not config |
| **`allocate-id` supports only PUZ and COL** | `plugin/skills/puzzle-state/SKILL.md` operations table: `kind (PUZ \| COL)` | A third entity kind needs spine changes |
| **`manifest.surfaces.blog.publish_findings` referenced but undefined** | Two skills branch on it; the template has no such key | Findings-publishing behavior is unspecifiable |
| **No template→facility migration** | `init-facility.sh` copies the manifest only `if [[ ! -f ]]`; existing facilities never see template changes | Every config extension must be applied twice |
| **Netlify site id hard-coded** | `SITE_ID="4c4e7ff5-…"` in `~/bazaar/deploy.sh`; `.netlify/state.json` pins the same | Fine for one operator, blocks a second deployment target |
| **Deploy guard is a fixed denylist** | `find … -name 'solution.md' -o -name 'puzzle.yaml' -o -name 'research.md' -o -name 'design.md'` | A new private filename is invisible to the guard until someone edits the `find` |

---

## 6. How a newcomer should approach extending this project

1. **Read `puzzle-state-spec.md` first, then two `SKILL.md` files** — `puzzle-state` (the write discipline) and `puzzle-orchestrator` (the dispatch table). Those three documents contain the whole contract. Be aware the spec skips sections 8, 9, and 11–17 despite claiming to mirror forge-state §1–§18.
2. **Bootstrap a throwaway facility.** `BAZAAR_ROOT=/tmp/bazaar-test bash scripts/init-facility.sh` — the script is fully idempotent and honors the env var, so experimentation is free and cannot touch the real corpus.
3. **Read the corpus before the schema.** `~/bazaar/puzzles/PUZ-0007-meta-cabinet/puzzle.yaml` and its `artifact/index.html` show what the system actually produces, including conventions (flag format `CABINET{...}`, hash-gated answers) that appear in no document.
4. **Route every write through `/puzzle-state`.** This is the invariant most easily violated by a well-meaning contributor.
5. **When adding a field, add it to the schema in the same change.** `additionalProperties: false` means an unschema'd field is a latent validation failure — and, because nothing runs the validator, a silent one.
6. **Expect to edit prose, not code.** There is no build, no dependency install, no test to run. Verification is reading.

---

## Key Takeaways

- **Two extension surfaces are genuinely open:** adding a skill (one `SKILL.md`; `plugin.json` does not enumerate skills) and adding an intake source (one entry in `manifest.intake.sources[]`, with `rss` and `archive` already reserved).
- **`templates/types/` is the highest-leverage missing artifact.** Three documents depend on it, `puzzle-builder` mounts it into the container, and it has never been created — which blocks every new mechanic and the sandbox build path at once.
- **The two documents that reference it disagree on the path** (`<template_id>.template/` vs `<type>.<template_id>.template/`), so the contradiction must be resolved before the tree can be built.
- **The schema is rigorously closed and completely unenforced.** `additionalProperties: false` throughout, no executable validator, and four kinds of live drift: `design.type: "meta"`, `outputs.blog_url` / `pages_url`, off-taxonomy tags, and 18 template ids matching none of the spec's 20.
- **The worked `meta`-type example costs five edits and hits one blocker,** and the project has already performed the shortcut version — `PUZ-0007` is a working meta-puzzle that is schema-invalid against its own repo.
- **Surfaces are configurable but not pluggable.** `manifest.surfaces` is a map; `puzzle-publisher` is a fixed six-step sequence. Adding a surface means editing the contract, and `publish_findings` is referenced by two skills but absent from the manifest.
- **Two entity types exist, one has a schema.** `collection.yaml` and `state.json` are both written and neither is contracted — which is how the system's best undocumented idea, `flag_storage`, ended up living in an unschema'd JSON key.

---

## Cross-References

- [Report 01b — Technical Specification](01b-technical-specification.md) — the schema, phase machine, and skill contracts this report extends.
- [Report 02 — Business Benefits](02-business-benefits.md) — why the six unexercised puzzle families represent unrealized coverage.
- [Report 03 — Innovation Themes](03-innovation-themes.md) — §2.4 reads the same schema drift as an emergent-taxonomy signal rather than only a defect.
- [Report 08 — Technical Readiness](08-technical-readiness.md) — the missing validator and absent CI in maturity terms.
- [Report 06 — Work Zones](06-work-zones.md) — which zone owns each blocker listed in §5.
