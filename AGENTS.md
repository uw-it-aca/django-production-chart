# AGENTS.md

Operational guidance for coding agents working in this repo. See `README.md`
first for what the chart is and how it's used/structured — this file only
covers things an agent needs to get right while editing, that aren't obvious
from reading a single template in isolation.

## Before editing

- This chart is consumed by many separate Django app repos via pinned git
  ref/tag (see `README.md` → "How this chart is used"). There is no way to
  "run the app" here — correctness is judged entirely by rendered manifest
  output (`helm template`) plus schema validation. Treat every change as a
  public API change to those consumers.
- Don't hand-edit `/work/test-values.yml` (or any other app's real
  `test-values.yml`/`prod-values.yml`) to "just test something" and leave it
  changed — it's someone else's working file, not test fixture for this repo.
  Create a small, throwaway values overlay instead (e.g.
  `/tmp/<feature>-test-values.yml` if ephemeral files are acceptable in this
  environment, otherwise a persistent file *outside* the chart directory) and
  pass it with an extra `-f`.

## Required validation after any template/values change

Run all of these from the chart directory before considering a change done.
`helm` and (optionally) `kubeconform`/`kubeval` may need installing first —
see commands below and the full versions in `README.md` → "Validating
rendered output".

```sh
# 1. Lint
helm lint . -f <some-values-file>.yml

# 2. Render with bare chart defaults (must not error)
helm template test-release . --set-string image.tag=dev

# 3. Render with a realistic app values file, using the same --set-string
#    shape the real cicd-deploy action uses (see README for exact keys)
helm template test-release . \
  --set-string "image.tag=12345,chartVersion=abc1234,image.repository=example/repo" \
  -f <some-values-file>.yml > /tmp/manifest.yaml

# 4. Schema-validate that render (install kubeconform if not present:
#    curl -fsSL -o /tmp/kubeconform.tar.gz \
#      https://github.com/yannh/kubeconform/releases/latest/download/kubeconform-linux-amd64.tar.gz
#    tar xzf /tmp/kubeconform.tar.gz -C /tmp kubeconform)
/tmp/kubeconform -strict -verbose -ignore-missing-schemas /tmp/manifest.yaml
```

For whitespace-sensitive template changes, also eyeball the raw rendered
output (`cat /tmp/manifest.yaml`, or `--show-only templates/<file>.yaml`) for
stray blank lines or bad indentation — `kubeconform`/`kubeval` validate
schema conformance, not cosmetic formatting, so they will not catch this
class of bug.

If a change touches `cronjob.yaml` or any `workerType` logic specifically,
confirm with a values file that exercises **both** states: a job with
`workerType` set and its own `resources`, and a job with `workerType` set and
no `resources` — these take different code paths (see "Gotchas" below).

## Gotchas learned the hard way

- **Go template whitespace trimming is positional, not conditional.**
  `{{-`/`-}}` trim whitespace in the literal template text at parse time,
  regardless of which branch of an `if`/`with` actually executes. A common
  bug: a literal line like `tolerations:` followed by a newline then
  `{{ toYaml ... | nindent 2 }}` (no leading `{{-`) produces a blank line,
  because the literal newline survives *and* `nindent` prepends its own. Fix
  by trimming the preceding newline (`{{- toYaml ... | trim | nindent N }}`)
  so `nindent`'s own newline is the only separator. After any such change,
  actually look at rendered output — don't just trust that `helm lint`
  passed.
- **Resource precedence for cronjobs is intentionally**
  `(or .resources $workerType.resources $.Values.resources)` in
  `templates/cronjob.yaml` — a job's own `resources` always wins over its
  `workerType` preset's `resources`, which in turn falls back to the
  chart-wide default. Tolerations/affinity/nodeSelector from the preset are
  *always* applied when `workerType` is set, independent of which
  `resources` value is chosen. Don't conflate these two concerns.
- **`image.repository`/`image.tag` in `values.yaml` is a `default()`
  fallback, not string concatenation glue.** It's consumed via
  `default (printf "%s:%s" .Values.image.repository .Values.image.tag)
  .containerImage` in `_spec_container_base.tpl`/`_spec_containers.tpl`. Any
  per-container `image` key always wins. In real deploys this fallback is
  populated by the `cicd-deploy` action's `--set-string` overrides (commit
  hash + computed registry path), not by the app's values file — see
  `README.md` → "How this chart is used" for the exact composition.
- **There are two independent validation/CI paths that must both keep
  passing**, and a change that satisfies one can still break the other:
  `kubeval` (this repo's own `.github/workflows/cicd.yml`, tests the chart
  in isolation) and `kubeconform` (the `cicd-deploy` action in the separate
  `uw-it-aca/actions` repo, used for every real app deploy). See
  `README.md` → "Validating rendered output" and "CI" for exact commands.
- **Bump `version` in `Chart.yaml`** for any functional template/values
  change — consuming repos pin a chart ref/version, so this is the only
  signal they have that something changed. Current version at time of
  writing: `0.1.1`.
- **`chartVersion`** (a top-level `values.yaml` key, separate from
  `Chart.yaml`'s `version`) feeds the `app.kubernetes.io/version`/chart
  label via `django-production-chart.chart` in `_helpers.tpl`, and is
  normally overridden by CI with the chart's own git short-SHA. Don't
  confuse it with `Chart.yaml`'s `version`.
- **`workertype-test-values.yml` and `feature_tolerate-tainted-nodes.md`
  live in `/work/`, not inside this chart repo** — they're scratch
  artifacts from feature development, not chart files. Don't assume
  everything referenced during a session lives under this chart's git root.

## Commit/PR conventions

- No enforced line-length limit on Markdown/docs in this repo.
- Follow the existing `values.yaml` comment style when adding new keys:
  purpose, default behavior, and a commented-out example if the shape isn't
  obvious.
- Prefer a new, narrowly-scoped `_*.tpl` named template over growing an
  existing one once its logic becomes non-trivial (see
  `_cronjob_worker_type.tpl` for precedent).
