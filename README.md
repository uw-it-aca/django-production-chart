# django-production-chart

This is a Helm chart for deploying UWIT SETS Django-based applications to Kubernetes. Note: this is done by invoking  `helm --template` and writing the resultant manifests to a deploy repo watched by FluxCD. Consuming application repositories do not fork or copy this chart; instead their GitHub Actions deploy workflows pull this chart (by git ref / tag) and render it with an app-specific values file — typically `docker/test-values.yml` for the test cluster and `docker/prod-values.yml` for production.

This README describes how the chart is structured, the conventions those values files follow, and how to validate changes to the chart itself (or to an app's values file) before merging.

## How this chart is used

This chart is **not** deployed directly. A consuming app repo's CI/CD pipeline uses the shared [`uw-it-aca/actions/cicd-deploy`](https://github.com/uw-it-aca/actions/blob/main/cicd-deploy/action.yml) GitHub Action, which clones this chart at a pinned ref and renders it with:

```sh
helm template ${APP_NAME} /chart --set-string "${VALUES}" -f $HELM_CHART_VALUES > ${LOCAL_MANIFEST}
```

Where `$HELM_CHART_VALUES` is `docker/${app_instance}-values.yml` in the app repo (`test-values.yml` for the test cluster, `prod-values.yml` for production), and `${VALUES}` is a single comma-separated `--set-string` list built up by the action:

- `image.tag=<commit_hash>` — always set, to the built container's tag (a commit SHA or short SHA).
- `chartVersion=<chart short SHA>` — the 7-char SHA of the cloned chart ref, used in the `app.kubernetes.io/version`/chart label (see `django-production-chart.chart` in `_helpers.tpl`); overrides the chart's own `Chart.yaml` version for that label.
- `image.repository=<registry>/<path>/<release_name>` — set whenever the action has a registry configured (either an explicit `registry_name` input, or computed from `registry_hostname`/`registry_project_id`/`registry_path`), so the app values file does **not** need to (and normally shouldn't) hardcode `image.repository` — see [Image configuration](#image-configuration).

The action then validates the rendered manifest with `kubeconform` before opening a flux deploy PR — see [Validating rendered output](#validating-rendered-output).

Every object this chart can render is gated behind a feature flag (usually `<feature>.enabled`) in `values.yaml`, so an app's values file only needs to turn on and configure the pieces it actually uses. Everything else stays off by default.

### Values precedence

Three layers feed every `helm template` render, in increasing order of precedence (each layer only needs to set the keys it cares about — anything it doesn't set falls through to the layer below):

```
  lowest precedence                                               highest precedence

+------------------------+   +------------------------+   +------------------------+
| Chart defaults         |-f>| App values file        |-->| CI --set-string        |
| (values.yaml)          |   | (test-values.yml /     |   | (cicd-deploy action)   |
|                        |   |  prod-values.yml)      |   |                        |
| resources, feature     |   |                        |   | image.tag=             |
| flags, image.repo/     |   | enabled features,      |   |   <commit hash>        |
| tag placeholder,       |   | replicas, secrets,     |   | chartVersion=          |
| cronjob.workerTypes    |   | workerType + job       |   |   <chart sha>          |
| presets, ...           |   | resources, ...         |   | image.repository=      |
|                        |   |                        |   |   <registry>/...       |
|                        |   |                        |   |   (if configured)      |
+------------------------+   +------------------------+   +------------------------+

-f  = helm "-f <values-file>"      -->  = CI --set-string "key=val,..." (applied last, highest precedence)

             |                            |                            |
             +----------------------------+----------------------------+
                                          |
                                          v
                       helm template merges all three layers
                      (highest-precedence layer wins per key)
                                          |
                                          v
                            rendered Kubernetes manifest
```

In practice this means: an app values file can set `image.repository` itself for local rendering (see examples in this README), but in the real `cicd-deploy` pipeline CI's `--set-string image.repository=...` will win and override it — so don't rely on an app's committed `image.repository` actually being what gets deployed. The one exception to this merge order is a **container's own `image` key** (e.g. a specific cronjob job or sidecar) — that's a template-level `default()` fallback inside the chart (see [Image configuration](#image-configuration)), not a values-merge layer, and it always wins over `image.repository`/`image.tag` regardless of which layer set them.

## Repository layout

```
Chart.yaml           # chart name/version
values.yaml           # full set of defaults and documented, commented-out examples
templates/
  deployment.yaml      # main app Deployment (Values.deployment.enabled)
  deploy.yaml          # pre-deploy Job, e.g. migrations (deployment + deploymentInitialization)
  statefulset.yaml      # alternative to deployment.yaml (Values.statefulset.enabled)
  daemon.yaml           # long-running management-command workers (Values.daemon.enabled)
  cronjob.yaml          # scheduled management-command jobs (Values.cronjob.enabled)
  autoscaler.yaml        # HorizontalPodAutoscaler (deployment + autoscaling.enabled)
  service.yaml / services.yaml   # ClusterIP/other Services for the app
  external-service.yaml  # Service+Endpoints pointing at a resource outside the cluster
  external-secret.yaml    # ExternalSecret objects (externalSecrets.enabled)
  gateway.yaml          # Gateway API HTTPRoute/Gateway/ListenerSet (gateway.enabled)
  ingress.yaml          # legacy Ingress (deprecated in favor of gateway.yaml)
  memcached.yaml        # memcached StatefulSet + Service (memcached.enabled)
  namespace.yaml        # optional Namespace object (namespace.enabled)
  network-policy.yaml, _network-policy.yaml   # NetworkPolicies (securityPolicy.network.enabled)
  nfs_server.yaml         # NFS server + supporting PV/PVC (nfsServer.enabled)
  pushgateway.yaml        # Prometheus Pushgateway for cronjobs (cronjob + metrics.enabled)
  pvc.yaml, configmap.yaml, service-monitor.yaml  # supporting objects
  _*.tpl                  # shared named templates (container spec, scheduling, labels, etc.)
```

`values.yaml` is the source of truth for every option: each section is heavily commented with a description and a commented-out example. Start there when you need to know what a key does or what shape it expects.

## Key conventions

- **Release naming**: `repo` + `instance` (e.g. `repo: uw-person-datastore`, `instance: test`) combine to form resource names and the default namespace (see `django-production-chart.releaseIdentifier` in `_helpers.tpl`). Set `namespace.enabled: true` to deploy into a dedicated, app-owned namespace instead of the release namespace.
- **Image configuration**: `image.repository`/`image.tag` in `values.yaml` is only a **fallback default** — it's a placeholder, not meant to be pulled. Any container-specific `image` (a cronjob job, a daemon, a sidecar) always takes precedence. In practice, the `cicd-deploy` action sets both `image.repository` (computed from the registry inputs) and `image.tag` (the commit hash) at deploy time via `--set-string`, so an app values file normally doesn't need to set either — only set `image.repository` yourself locally when rendering outside that pipeline (e.g. the examples in this README).
- **Workloads**: use `deployment` for the main web/app process (optionally paired with `autoscaling` and a pre-deploy `deploymentInitialization` job for migrations), `daemon` for long-running management commands, and `cronjob` for scheduled management commands. `statefulset` is an alternative to `deployment` for apps that need stable identity/storage.
- **Resources**: set a chart-wide default under the top-level `resources` key, and/or override per cronjob job / daemon entry with its own `resources` key. For cronjob jobs using `workerType` (see below), the precedence is: job-level `resources` > preset's `resources` > chart-wide `resources`.
- **Tainted/large node pools for cronjobs**: some cronjobs need far more CPU/memory than our normal node pool allows. `cronjob.workerTypes` in `values.yaml` defines named presets (tolerations/affinity/nodeSelector, plus fallback resources) for our oversized, autoscaled (min size 0) node pools. Reference one from a job with `workerType: "<preset-name>"`. Because these pools scale from 0, expect a cold-start delay when a job lands on them.
- **Secrets**: `externalSecrets.secrets` declares `ExternalSecret` objects backed by our Vault-based `ClusterSecretStore`; `mountedSecrets` and `certs`/`gcsCredentials` project existing Kubernetes Secrets into the pod as files.
- **Sidecars**: `sidecarContainers` defines native Kubernetes sidecars (rendered as `initContainers` with `restartPolicy: Always`). See the commented example in `values.yaml` for image-inheritance rules.
- **Gateway vs Ingress**: `gateway` (Gateway API) is the current way to expose a hostname; `ingress` is deprecated and kept only for backward compatibility.

## Local development

You'll need `helm` (v3) installed locally; no cluster connection is required for template rendering.

```sh
# From the chart directory:
cd django-production-chart

# Render with only the chart's own defaults (sanity check: should
# produce something, even if it's not meant to be deployed as-is):
helm template test-release . --set-string image.tag=dev

# Render exactly as the cicd-deploy action would, using an app's
# actual values file and the same comma-separated --set-string list
# (image.repository + chartVersion are normally set by CI, not the
# values file itself — see "Image configuration" above):
helm template test-release . \
  --set-string "image.tag=12345,chartVersion=abc1234,image.repository=us-docker.pkg.dev/uwit-mci-axdd/containers/<release_name>" \
  -f /path/to/app-repo/docker/test-values.yml

# Render only one resource kind while iterating (fast feedback loop):
helm template test-release . -f values-overlay.yml \
  --show-only templates/cronjob.yaml

# Lint the chart (catches template errors chart structure issues):
helm lint . -f /path/to/app-repo/docker/test-values.yml
```

Useful flags while developing:
- `--show-only templates/<file>.yaml` — render a single template.
- `--debug` — show the computed values and keep rendering even if the output YAML would otherwise be suppressed on error.
- `-f file1.yml -f file2.yml` — layer multiple values files (later files win); handy for combining a real app's values file with a small local overlay while testing a new chart feature.

When testing a new feature (such as a new `values.yaml` key), add a small, focused values overlay file (don't hand-edit an app's real
`test-values.yml`/`prod-values.yml` and leave it changed) and delete it when you're done unless it's useful as a permanent example.

## Validating rendered output

Rendering with `helm template` only confirms the Go templates execute and produce syntactically valid YAML — it does **not** confirm the result is a valid, schema-conformant Kubernetes manifest. Validate with one or more of the following before merging a template change:

### Option 1: `kubeconform` (same tool the real deploy pipeline uses, no cluster required)

This is what the `cicd-deploy` action's "Validate Manifest" step runs for every real app deploy, via `docker run ghcr.io/yannh/kubeconform:latest -strict -verbose -ignore-missing-schemas`. To reproduce locally:

```sh
# install kubeconform once
curl -fsSL -o /tmp/kubeconform.tar.gz \
  https://github.com/yannh/kubeconform/releases/latest/download/kubeconform-linux-amd64.tar.gz
tar xzf /tmp/kubeconform.tar.gz -C /tmp kubeconform

# render exactly as the cicd-deploy action would (see "How this chart
# is used" above for what belongs in the --set-string list), then validate
cd /path/to/django-production-chart
helm template test-release . \
  --set-string "image.tag=12345,chartVersion=abc1234,image.repository=us-docker.pkg.dev/uwit-mci-axdd/containers/<release_name>" \
  -f /path/to/app-repo/docker/test-values.yml > /tmp/manifest.yaml

/tmp/kubeconform -strict -verbose -ignore-missing-schemas /tmp/manifest.yaml
```

`-ignore-missing-schemas` skips (rather than fails) kinds with no published schema — in this chart that's `ExternalSecret` and `ServiceMonitor` CRDs. Prefer this option when checking a change the same way it will actually be validated before a real deploy.

### Option 2: `kubeval` (what the chart's own CI uses to test the chart in isolation)

`.github/workflows/cicd.yml` in this repo (distinct from the `cicd-deploy` action above) uses the older `kubeval` tool to sanity-check the chart against both its bare defaults and a real app's `prod-values.yml` on every push/PR. To reproduce locally:

```sh
# install kubeval once
mkdir -p /tmp/kubeval && cd /tmp/kubeval
wget https://github.com/instrumenta/kubeval/releases/latest/download/kubeval-linux-amd64.tar.gz
tar xzf kubeval-linux-amd64.tar.gz

# render, then validate
cd /path/to/django-production-chart
helm template test-release . --set-string "image.tag=12345,chartVersion=abc1234,image.repository=us-docker.pkg.dev/uwit-mci-axdd/containers/<release_name>" \
  -f /path/to/app-repo/docker/test-values.yml > /tmp/manifest.yaml

/tmp/kubeval/kubeval /tmp/manifest.yaml \
  --schema-location "https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master" \
  --strict \
  --skip-kinds "ExternalSecret,ServiceMonitor,HTTPRoute,ListenerSet,TrafficPolicy"
```

The `--skip-kinds` list matches `KUBEVAL_SKIP_KINDS` in the CI workflow — those kinds are CRDs (`ExternalSecret`, `ServiceMonitor`, vendor Gateway API types) with no schema available at the configured schema location. Keep this list in sync with `.github/workflows/cicd.yml` if either changes.

### Option 3: `kubectl apply --dry-run=server`

Useful when you have access to a real (or kind/minikube) cluster and want a true server-side validation (admission webhooks, CRDs actually installed, etc.), which `kubeval` cannot check:

```sh
helm template test-release . ---set-string "image.tag=12345,chartVersion=abc1234,image.repository=us-docker.pkg.dev/uwit-mci-axdd/containers/<release_name>" \
  -f /path/to/app-repo/docker/test-values.yml \
  | kubectl apply --dry-run=server -f -
```

This requires a `kubectl` context pointed at a cluster with the same CRDs installed as production (ExternalSecrets operator, Prometheus
Operator for `ServiceMonitor`, Gateway API, etc.) — the test cluster is the natural target. It will catch issues `kubeval` can't, such as
referencing a CRD version that isn't actually installed, or namespace admission policy violations, but it does **not** check `--strict` schema issues like unknown fields the same way `kubeval` does.

### CI

There are two separate CI entry points that touch this chart — keep both in mind when changing templates or `values.yaml`:

1. **This chart's own `.github/workflows/cicd.yml`**, which runs on every push/PR to `main`/`develop` and only exercises the chart in isolation (it doesn't deploy anything):
   - Renders the chart with only its own `values.yaml` defaults and validates with `kubeval --strict`.
   - Fetches a real app's `prod-values.yml` (currently `uw-it-aca/myuw`'s `docker/prod-values.yml`) from GitHub, renders the chart against it, and validates that output with `kubeval --strict` too.
2. **The `cicd-deploy` GitHub Action** (in `uw-it-aca/actions`), which every consuming app's own pipeline calls for real test/prod deploys. It clones this chart at a pinned ref, renders it with the app's own values file plus the `--set-string` overrides described in [How this chart is used](#how-this-chart-is-used), and validates the result with `kubeconform -strict -verbose -ignore-missing-schemas` before opening a flux deploy PR.

If you add a new template or `values.yaml` key, make sure it renders cleanly both with the chart's bare defaults and with a realistic app values file, and that it validates under both `kubeval` (path 1) and `kubeconform` (path 2) — a field one tool accepts can still trip the other.

## Making chart changes

- Bump `version` in `Chart.yaml` for any functional change to templates or `values.yaml` defaults (consuming repos typically pin a chart version/ref, so this is how they know a new release is available).
- Document new `values.yaml` keys with a comment above them, following the existing style (purpose, default behavior, and a commented-out example if the shape isn't obvious).
- Prefer adding a new, narrowly-scoped `_*.tpl` named template over growing an existing one, when a template's logic becomes non-trivial (see `_cronjob_worker_type.tpl` for an example).
- Validate with `helm lint`, then `helm template` + `kubeconform` (and `kubeval`, and `kubectl apply --dry-run=server` if the change affects CRDs/validating webhooks), against both the bare chart defaults and a real app values file, before opening a PR.
