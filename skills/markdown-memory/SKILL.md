---
name: markdown-memory
description: Markdown-based memory continuity system for agents without embeddings or vector RAG. Use when building or operating local memory files (daily logs, project memory, handoff notes), implementing deterministic keyword retrieval, maintaining current-state records, or setting session start/close memory protocols.
---

# Markdown Memory

Use this skill to run a low-complexity, high-traceability memory system based on plain Markdown files.

## Core workflow

1. Load `memory/CORE/hard-rules.md` and `memory/CORE/current-state.md`.
2. Load recent daily logs from `memory/daily/` (default: last 2 days).
3. Before answering context-dependent questions, run `scripts/memory-search.sh "<query>"`.
4. Update `current-state.md` when project/task state changes.
5. Append a state diff entry in `state-changelog.md` for every meaningful state update.
6. At session close, run `scripts/session-close.sh`.

## Directory contract

```text
memory/
  CORE/
    hard-rules.md
    current-state.md
    state-changelog.md
  daily/
  projects/
  people/
  concepts/
  handoff/
  archive/raw/
  INDEX.md
```

## Memory admission rules

Record only high-value memory:

- decisions
- commitments
- deadlines
- preferences
- blockers
- postmortem conclusions

Add attributes when possible:
- `status: active | superseded | invalid`
- `polarity: positive | negative`
- `confidence: high | medium | low`
- `avoid_reason: ...` (required for negative/pitfall entries)

Avoid logging casual chat unless it impacts future execution.

## Retrieval policy (hybrid: keyword + optional semantic)

Default path is deterministic retrieval with weighted matching:

- exact keyword / phrase in headings
- tags and fields (`decision`, `todo`, `blocker`, `preference`)
- recency boost for recent daily logs
- path boost for likely directories (`projects`, `people`, `CORE`)

When local Ollama embedding is available, add semantic recall as a second pass (recommended model: `qwen3-embedding:0.6b`).

Semantic mode uses SQLite + sqlite-vec with incremental indexing:
- DB path: `memory/.semantic-index.db`
- Vector extension: `sqlite-vec` (loaded via APSW)
- Incremental policy: file mtime/size/hash detection + chunk-level embedding cache
- Consistency keys: fixed `model`, embedding `dimension`, and `pipeline_version`
- Threshold: `SEMANTIC_MIN_SCORE` (default `0.48`)
- Fusion rerank mode: `FUSION_MODE=rrf|linear` (default `rrf`)
- RRF parameter: `RRF_K` (default `60`)
- Keyword boost in RRF mode: `KEYWORD_BOOST` (default `0.006`)
- Linear fallback weights: `FUSION_SEM_WEIGHT` + `FUSION_KEY_WEIGHT` (defaults `0.65/0.35`)
- Daily warmup: `session-start.sh` runs `memory-semantic-search.py --build-only` once per day
- Negative memory handling: entries with `polarity=negative` or `status in {invalid,superseded}` are excluded from positive ranking and surfaced in a dedicated `⚠ Avoided Pitfalls` warning block

If no strong hit exists, explicitly report uncertainty.

## Scripts

- `scripts/session-start.sh`: startup checklist + quick context load hints
- `scripts/memory-search.sh`: hybrid retrieval entry (keyword first, semantic optional)
- `scripts/memory-semantic-search.py`: semantic recall via Ollama `/api/embeddings`
- `scripts/memory-auto-tag.py`: local-model auto-tagger (`qwen3.5:2b`) for incremental memory changes (`--mode tag|review`, `--files`, `--force`)
- `scripts/memory-write-tag.sh`: write/append helper that immediately tags the target file
- `scripts/memory-compact.py`: weekly compaction (daily -> summaries, mark stale, re-sync vectors)
- `scripts/memory-forget.py`: monthly forgetting (archive old stale daily logs, keep negative pitfalls)
- `scripts/session-close.sh`: runs auto-tagger in `--mode review` first, then daily log append + state freshness check
- `scripts/auto-commit.sh`: optional git safety-net commit

## References

- `references/templates.md`: canonical templates for state/daily/project/handoff files
