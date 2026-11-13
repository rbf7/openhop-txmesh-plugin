# AGENTS.md — openhop-txmesh-plugin (fork)

Rules for AI agents (and humans) working in this repository.

A fork of the upstream openHop txme.sh plugin. The only change of this fork is the Docker
deployment under `deploy/docker/`. Everything else belongs to upstream.

**This repository is public.** Never add private host names, IP addresses, e-mail addresses,
tokens, or details of any other system. Nothing here may depend on private infrastructure.

## Canonical instructions

This file is the canonical instruction set for every AI assistant. `.claude/CLAUDE.md`,
`.gemini/settings.json` and `.github/copilot-instructions.md` point here and must not duplicate
or override it. Any assistant may be used; the rules are the same.

## Change discipline

- Work on a feature branch; never commit to `main`/`master`. The owner merges PRs on GitHub.
- Small, reviewable commits. Do not rewrite history or force-push unless the owner asks.
- Real credentials live in an env file outside git; `env.example` holds placeholders only.

## Continuity

Work must be resumable by a fresh session of any assistant from this repository alone. Whatever
a later session needs (what was decided, what is half done, what comes next) goes into a file in
the same pull request, never only into a chat.

## Org-wide rules (2026-11-05, cheaper subagents 2026-11-12)

- **Branch names say what the change does, in plain words** (owner rule for all `rbf7` repos,
  2026-11-05): `claude/<what-it-does>` in short kebab-case for agent work, e.g.
  `claude/fix-login-redirect`. No internal codes or ticket IDs a person can't read, never the
  random name a session starts with, and never reuse a merged branch.
- **Workflows:** GitHub-hosted runners only (never `runs-on: self-hosted`); a `paths` filter
  that excludes `**/*.md`, `timeout-minutes` on every job and `concurrency`.
- **Cheaper subagents for simple work** (owner rule, 2026-11-12): delegate to a cheaper model
  checking pasted outputs against an expected result, read-only verification lists, and
  mechanical edits (renames, doc sweeps, copying a value). Keep on the main model: design,
  anything touching security, secrets or cost, and judging a failure or an unexpected diff. The
  subagent reports; the main agent decides — a subagent's verdict is never the owner's approval.
