# Contributing to DBB-HACK

Small project, simple process.

## Before you open a PR

- Open an issue first for anything non-trivial (new vector, new level behavior, breaking change) so we don't waste work on something that won't land.
- Branch names: `feat/`, `fix/`, `docs/`, `test/`, `chore/`.
- Commits: clear, atomic, no secrets, no committed `.env` or real target data.
- `main` is protected — everything goes through a Pull Request.

## Adding a vector / playbook

- Vectors live in `dashboard/vectores.json` + their playbook. Follow the existing shape (id, level, ISO/OWASP mapping, remediation prompt).
- A vector that can't actually be verified against a live lab must report **"not tested"**, never a fabricated finding — this is the project's non-negotiable rule (see `README.md` → Integrity guarantee).

## Local setup

```bash
git clone https://github.com/DBB-Labs/dbb-hack.git
cd dbb-hack
npm install
npm run test:e2e   # Playwright suite for the console
```

## Checks before a PR

```bash
npm run test:e2e
```

If you touch the dashboard UI, run `bash dashboard/servir.sh` and click through the change at http://localhost:8899 before opening the PR — a screenshot in the PR description is appreciated.

## License

By contributing, you agree your changes are licensed under this repo's **AGPL-3.0** (see `LICENSE`).
