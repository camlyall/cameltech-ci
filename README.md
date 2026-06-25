# cameltech-ci

Generic, reusable CI + Cloudflare deploy workflows for Cameron's webdev sites. Public by necessity (GitHub Free cannot share reusable workflows from a private repo), so it is kept deliberately generic: it holds no client roster and no secrets. Each private caller repo supplies its own per-repo settings (lint/test mode, deploy target) as workflow inputs. Callers pin `camlyall/cameltech-ci/.github/workflows/<wf>.yml@v1`.

## Reusable workflows

- `reusable-lint.yml`: `astro check` + `prettier --check`. Inputs: `language` (default `astro`), `lint_mode` (none|advisory|gate, default `advisory`).
- `reusable-test.yml`: `vitest`/`npm test`. Inputs: `language` (default `astro`), `test_mode` (none|advisory|gate, default `none`; `none` skips tests).
- `reusable-deploy.yml`: Cloudflare deploy. Inputs: `deploy_kind` (pages|worker), `project_name`, `environment` (dev|prod), `site_url`, `build_command`, `wrangler_config`. Secrets: `CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ACCOUNT_ID`.

## Modes (advisory / gate)

A tier runs in `advisory` (findings reported, non-blocking) or `gate` (findings block). Infra errors fail loud in every mode (advisory never masks a broken toolchain). The mode is NOT stored centrally; each caller declares it in its own workflow via `lint_mode` / `test_mode`. There is no `registry.tsv`, so nothing client-identifying lives in this public repo.

## Onboard a site

1. In the target repo install `prettier`, `prettier-plugin-astro`, and `prettier-plugin-tailwindcss` as devDeps, and add a `.prettierignore` (build output, `docs/`, the generated `src/env.d.ts`, plus any files prettier-plugin-astro cannot parse). Run a one-time sweep against the canonical config: `prettier --write . --config <cameltech-ci>/configs/prettierrc.json` and commit. Repos carry **no** `.prettierrc.json` — CI lints against the central config directly.
2. Add caller workflows `.github/workflows/{lint,test,deploy}.yml` (set `lint_mode` / `test_mode` / deploy inputs) + an npm-only `dependabot.yml`; delete the old `ci.yml`.
3. Set `CLOUDFLARE_API_TOKEN` + `CLOUDFLARE_ACCOUNT_ID` repo secrets; create `dev`/`prod` Environments.

## Releasing: the v1 tag

`v1` is a moving major tag; consumers pick up changes on their next run.

```bash
git checkout main && git pull --ff-only
git tag -f v1 && git push -f origin v1
```

## Advisory to gate

Bump `lint_mode` (or `test_mode`) from `advisory` to `gate` in the caller repo's own workflow once its backlog is clean. One-line edit, per repo.

## Layer B (future)

Terraform tree + `reusable-terraform.yml` (fmt, plan, apply) with existing infra imported. Not built yet.
