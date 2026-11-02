# AGENTS.md

Operational guidance for coding agents working in this repo. Read `README.md`
first: it is the single source of truth for what the chart is, how CI
consumes it, its conventions, and how to validate it. This file only adds the
rules and pitfalls an agent needs while editing, and links to the README
rather than repeating it. If you find a fact that belongs in both places, put
it in the README and link to it from here.

## Scope: what does and doesn't belong in this repo

This chart only renders manifests. The app's source, `Dockerfile`, base
image, CI workflow, and secret values all live in other repos or systems (see
`README.md` → intro and [How this chart is used](README.md#how-this-chart-is-used)).
Don't go looking for them in this checkout, and don't try to fix problems
there by changing templates here:

- If a task seems to require editing an app's `Dockerfile`, the
  `django-container` base image, or a CI workflow, that work belongs in
  another repo.
- If a deploy fails because a secret or shared config value is missing or
  malformed, the fix is almost always in Vault or the flux repo, not in this
  chart.

## Before editing

- There is no way to "run the app" here. Correctness is judged entirely by
  rendered manifest output plus schema validation, and many app repos consume
  this chart at a pinned git ref. Treat every change to templates or
  `values.yaml` as a public API change to those consumers.
- Never hand-edit an app's real `test-values.yml`/`prod-values.yml` to test
  something. Use a throwaway overlay *outside* the chart directory (e.g.
  `/tmp/<feature>-test-values.yml`) and pass it with an extra `-f`.

## Required validation after any template/values change

Run every step in [Validating rendered output](README.md#validating-rendered-output)
before considering a change done: `helm lint`, a render with bare chart
defaults, a render with a realistic app values file using the CI
`--set-string` shape, and then **both** `kubeconform` and `kubeval` against
that render ([CI](README.md#ci) explains why both are required). The README
has copy-pasteable commands, including how to install the validators.

On top of that:

- **Look at the raw rendered output** (`--show-only templates/<file>.yaml`)
  for any whitespace-sensitive change. The validators check schema
  conformance, not formatting, so they won't catch stray blank lines or bad
  indentation.
- **For anything touching `cronjob.yaml` or `workerType` logic**, render
  with values that exercise both a job with `workerType` *and* its own
  `resources`, and a job with `workerType` and *no* `resources`. These take
  different code paths.

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
- **Cronjob `resources` precedence and `workerType` scheduling are separate
  concerns.** `(or .resources $workerType.resources $.Values.resources)` in
  `templates/cronjob.yaml` is intentional, and the preset's scheduling
  constraints apply regardless of which `resources` wins. Don't couple them.
  See [Key conventions](README.md#key-conventions).
- **`image.repository`/`image.tag` is a `default()` fallback**, not string
  concatenation glue, and CI overrides it at deploy time. Don't
  "fix" image handling by hardcoding a repository in `values.yaml` or an app
  values file. See [Key conventions](README.md#key-conventions) →
  Image configuration.
- **Don't add a `chartVersion` default to `values.yaml`.** CI sets it, and a
  default would mask the fallback to `Chart.yaml`'s `version`. See
  [How this chart is used](README.md#how-this-chart-is-used).

## Commit/PR conventions

- No enforced line-length limit on Markdown/docs in this repo.
- Follow [Making chart changes](README.md#making-chart-changes) for
  `values.yaml` comment style, `Chart.yaml` versioning, and when to split
  logic into a new `_*.tpl`.
