# cameltech-ci

Single source of truth for linting, testing, and Cloudflare deployment across Cameron's webdev sites. Mirrors the penwern-ci pattern. Callers pin `camlyall/cameltech-ci/.github/workflows/<wf>.yml@v1`.

## Reusable workflows

- `reusable-lint.yml` — `astro check` + `prettier --check`. Input: `language` (default `astro`).
- `reusable-test.yml` — `vitest`/`npm test` (skips when `test-mode=none`).
- `reusable-deploy.yml` — Cloudflare deploy. Inputs: `deploy_kind` (pages|worker), `project_name`, `environment` (dev|prod), `site_url`, `build_command`, `wrangler_config`. Secrets: `CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ACCOUNT_ID`.

## registry.tsv

`repo  language  lint-mode  test-mode  deploy  owner`. Modes: `none|advisory|gate`. Mode is resolved centrally; flip advisory to gate here, then re-tag `v1` (no change in the target repo).

## Onboard a site

1. Add a registry row; commit; re-tag `v1`.
2. `CI_ROOT=$PWD bash scripts/sync-config.sh <slug> <path-to-repo>` to drop `.prettierrc.json`. Commit config + a one-time `prettier --write` sweep in the target.
3. Add caller workflows `.github/workflows/{lint,test,deploy}.yml` + an npm-only `dependabot.yml`; delete the old `ci.yml`.
4. Set `CLOUDFLARE_API_TOKEN` + `CLOUDFLARE_ACCOUNT_ID` repo secrets; create `dev`/`prod` Environments.

## Releasing: the v1 tag

`v1` is a moving major tag; consumers pick up changes on their next run.

```bash
git checkout main && git pull --ff-only
git tag -f v1 && git push -f origin v1
```

## Advisory to gate

Flip the relevant mode column in `registry.tsv`, commit, re-tag `v1`. No commit in the target repo.

## Layer B (future)

Terraform tree + `reusable-terraform.yml` (fmt, plan, apply) with existing infra imported. Not built yet.
