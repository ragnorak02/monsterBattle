# Git Workflow — Monster Catcher

## Remote
- Origin: `https://github.com/ragnorak02/monsterBattle.git`
- Branch: `main`

## Checkpoint Steps

When you say **"Please commit everything"**, the following happens:

1. **`git status`** — review all modified, staged, and untracked files
2. **Secret scan** — search workspace for:
   - `.env` files
   - Private key blocks (`BEGIN.*PRIVATE KEY`)
   - API keys/tokens (patterns like `sk-`, `AKIA`, `ghp_`, `gho_`)
   - OAuth secrets, cloud credentials, database passwords
   - Certificate files (`.pem`, `.key`, `.p12`, `.pfx`)
3. **If secrets found** → STOP, warn, list files, recommend .gitignore updates
4. **If clean** → stage intended files with `git add`
5. **Commit** with message format:
   ```
   chore(checkpoint): update progress + dashboards
   ```
6. **Push** only if:
   - Remote `origin` exists and is configured
   - Authentication succeeds
   - Otherwise: print exact steps to push manually

## Commit Message Format

```
<type>(<scope>): <short description>

[optional body]

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
```

**Types:** `feat`, `fix`, `chore`, `refactor`, `docs`, `test`, `style`
**Scopes:** `battle`, `overworld`, `ui`, `data`, `audio`, `checkpoint`

## Safety Warnings

- **NEVER** force push (`git push --force`) — can destroy remote history
- **NEVER** run `git reset --hard` without explicit user request
- **NEVER** amend published commits — create new commits instead
- **NEVER** commit files matching `.gitignore` patterns (secrets, keys, builds)
- **ALWAYS** run secret scan before staging
- **ALWAYS** verify `git status` output before committing
- Pre-commit hook failures mean the commit did NOT happen — do not use `--amend`

## .gitignore Coverage

The `.gitignore` protects against committing:
- Godot caches: `.godot/`, `.import/`, `.mono/`
- Secrets: `.env`, `*.key`, `*.pem`, `*.p12`, `*.pfx`
- Dependencies: `node_modules/`
- Builds: `build/`, `dist/`, `export/`, `*.exe`, `*.pck`
- OS junk: `.DS_Store`, `Thumbs.db`, `desktop.ini`
- IDE files: `.vscode/`, vim swap files
