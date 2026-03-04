# duru-memory

A production-ready markdown memory skill for OpenClaw with:

- Hybrid retrieval (keyword + semantic embedding)
- Local semantic index (`SQLite + sqlite-vec`)
- Incremental embedding cache
- RRF re-ranking with keyword and directory priors
- Negative-memory safeguards (`⚠ Avoided Pitfalls`)
- Local auto-tagging via `qwen3.5:2b`
- Retention lifecycle (hot/warm/cold)
  - weekly compaction
  - monthly archive/forget

## Repository Structure

```text
skills/
  markdown-memory/
    SKILL.md
    scripts/
    references/
```

## Install in OpenClaw

From your OpenClaw workspace:

```bash
mkdir -p skills
cp -R <this-repo>/skills/markdown-memory skills/
```

Or clone this repository and copy the skill folder into your workspace `skills/` directory.

## Runtime Dependencies

For semantic vector retrieval on macOS:

```bash
python3 -m pip install --user sqlite-vec apsw
```

Ollama models used by default:

- `qwen3-embedding:0.6b` (semantic retrieval)
- `qwen3.5:2b` (auto-tagging / compaction suggestions)

## Key Scripts

- `scripts/memory-search.sh` — hybrid search entrypoint
- `scripts/memory-semantic-search.py` — SQLite + sqlite-vec semantic retrieval
- `scripts/memory-auto-tag.py` — incremental auto-tagging (`tag`/`review` modes)
- `scripts/memory-write-tag.sh` — write + immediate tagging helper
- `scripts/memory-compact.py` — weekly compaction
- `scripts/memory-forget.py` — monthly archive/forget

## Suggested Scheduling

- 00:00 daily: auto-tag review
- Weekly: compaction (`daily -> summaries`)
- Monthly: archive old stale entries

Example launchd plists are straightforward to configure for each script.

## Safety Model

- Do not use negative memory as execution basis.
- Surface negative matches as warnings.
- Keep retention actions auditable.
- Prefer review mode over aggressive overwrite.

---

If you use this in production, keep token/credential material out of memory files and rotate any GitHub/Ollama secrets regularly.
