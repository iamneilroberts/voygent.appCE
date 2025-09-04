# Project Workspace

This `.project` directory mirrors our internal project structure used in claude-travel-agent-v2. It centralizes tasks, active work, plans, and notes for Voygent CE.

Sections
- ACTIVE-TASKS.md: single page of what’s in flight now.
- tasks/: backlog items as individual task files.
- plans/: short implementation or rollout plans.
- known-issues/: operational issues and diagnostics.
- guidelines/: links to contributor rules and patterns.
- architecture/: quick system overview and references.

Usage
- Add new work as a task in `tasks/` and link it from `ACTIVE-TASKS.md` when prioritized.
- Keep files short and actionable; prefer links to code/docs over duplication.
- Reference environment-sensitive details via `.env.example` rather than committing secrets.
