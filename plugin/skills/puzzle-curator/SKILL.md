---
name: puzzle-curator
description: Use to curate the bazaar — group puzzles into themed collections, maintain tag taxonomy, build cross-links between related puzzles, and surface difficulty maps. Reads across all puzzles, writes collections/COL-NNNN-slug/. This is the bazaar-shaping skill that turns N independent puzzles into a navigable inventory. Trigger phrases include "/puzzle-curator", "curate the bazaar", "bin recent puzzles into collections", "rebuild the tag map".
---

# puzzle-curator

The shopkeeper of the bazaar. Reads across `puzzles/`, writes to `collections/`, and back-fills `puzzle.yaml.curation.{collection_ids, tags}` via `puzzle-state`.

## Inputs

- All `puzzles/*/puzzle.yaml` at `phase >= reported`
- Existing `collections/COL-*/collection.yaml`
- `manifest.curation.tag_taxonomy`

## Behavior

1. **Tag pass** — for each puzzle without `curation.tags`, derive tags from design.type + difficulty_target + research.theme keywords, constrained to the taxonomy.
2. **Collection assignment** — for each puzzle, compute fit against existing collections (theme overlap, type cohesion, difficulty arc). If `manifest.curation.auto_collection`, may propose new collections when ≥3 unassigned puzzles share a coherent frame.
3. **Cross-links** — write `collection.yaml` with `puzzle_ids[]`; per-collection `index.md` describing the throughline.
4. **Update puzzles** — write back `curation.collection_ids` on each puzzle via `/puzzle-state write`.

## Output

- `collections/COL-NNNN-slug/collection.yaml`
- `collections/COL-NNNN-slug/index.md` — a magazine-style intro to the collection (themes, suggested play order, difficulty arc)

## Non-goal

The curator does not publish. The publisher decides whether and how to ship a collection (e.g. as an scsiwyg series).
