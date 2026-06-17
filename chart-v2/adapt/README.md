# adapt

Helm chart for the Quadient Inspire **Adapt** License Server, with
optional integration into the Inspire Scaler workflow via a Kustomize
post-renderer overlay.

## What this chart deploys

- **License Server** — single-replica Deployment of the Adapt LS daemon
  on TCP port 5000, with a chart-managed `cdplicser.cfg` ConfigMap and
  (optionally) a chart-managed license Secret.
- **Inspire subchart** (when `inspire.enabled: true`, default) — the
  upstream Inspire chart at version 1.0.0, pulled from
  `oci://ghcr.io/robertwtucker/charts/inspire`, deploying ICM,
  Interactive, and Scaler workloads under the same release.
- **Scaler-side UA injection** (when `inspire.enabled: true` AND the
  post-renderer is used) — a `deploy-ua` initContainer + `ua-share`
  emptyDir volume + `/opt/adapt/ua` volumeMount injected into every
  Inspire Scaler Pod via Kustomize SMP, so Scaler can exec Adapt UA
  binaries during job orchestration.

## Prerequisites

- **helm** 3.x or 4.x
- **kubectl** ≥ 1.21 (the post-renderer uses the bundled `kubectl
  kustomize` subcommand — no separate kustomize install required)
- A pull secret for `registry.sptcloud.com` in the target namespace
  (image references are configurable via `image.registry`)
- For integrated installs: required Inspire Secrets (`spt-secrets`,
  `postgresql`) and a shared-storage PVC — see
  `values-examples/integrated-with-inspire.yaml` for the full list

### One-time post-renderer plugin install

The Scaler-side UA injection ships as a Helm plugin
(`adapt-scaler-inject`), required for integrated installs. Install
once per machine:

```sh
helm plugin install ./chart-v2/adapt/post-renderer
```

This copies `post-renderer/` (plugin manifest, `kustomize-post.sh`,
and the kustomize overlay) into `$HELM_PLUGINS/adapt-scaler-inject/`.
You then reference the plugin by name with `--post-renderer
adapt-scaler-inject` in install commands. The plugin is Helm 4-native;
Helm 3 users can alternatively skip the install and use the legacy
path form (`--post-renderer ./chart-v2/adapt/post-renderer/kustomize-post.sh`).

## Quick install (canonical demo)

```sh
# One-time: pull the Inspire subchart locally
helm dependency build ./chart-v2/adapt

# One-time plugin install (if not already done — see Prerequisites)
helm plugin install ./chart-v2/adapt/post-renderer

# Demo install: Adapt LS + Inspire + Scaler-side UA injection
# License files are binary; base64-encode before passing to Helm.
helm install adapt ./chart-v2/adapt \
  --values ./chart-v2/adapt/values-examples/integrated-with-inspire.yaml \
  --set licenseServer.license=$(base64 -i ./LicSer.lic | tr -d '\n') \
  --set ua.license=$(base64 -i ./adeptua.lic | tr -d '\n') \
  --post-renderer adapt-scaler-inject
```

## Install scenarios

### LS-only (no Inspire)

```sh
helm install adapt ./chart-v2/adapt \
  --values ./chart-v2/adapt/values-examples/ls-only-no-inspire.yaml \
  --set licenseServer.license=$(base64 -i ./LicSer.lic | tr -d '\n')
```

The `--post-renderer` flag is safe to include or omit in this mode —
the post-renderer's safety check detects no `inspire-scaler` Deployment
and passes through unchanged.

### Integrated (Adapt + Inspire + Scaler injection)

See the [Quick install](#quick-install-canonical-demo) above. The
canonical case.

### Expert path (consumer controls `/opt/adapt/etc/`)

```sh
helm install adapt ./chart-v2/adapt \
  --values ./chart-v2/adapt/values-examples/expert-etc-override.yaml
```

The consumer brings their own Secret/ConfigMap/PVC mounted at
`/opt/adapt/etc/`, superseding the chart-managed Secret + ConfigMap.
See `values-examples/expert-etc-override.yaml` for the values shape.

## How LS license delivery works

Two coexisting modes, both opt-in:

**Demo path (default).** The Adapt license file is a binary
(encrypted/signed Quadient payload), so the value must be
**base64-encoded** before passing to Helm. The chart's Secret template
uses `data:` (K8s-native base64) — it embeds the encoded value
unchanged and K8s decodes losslessly when mounting into the Pod.
Provide via:

```sh
--set licenseServer.license=$(base64 -i ./LicSer.lic | tr -d '\n')
```

The `| tr -d '\n'` strips the line-wrapping that `base64` adds by
default on macOS — gives a single-line value that Helm's `--set`
parser handles cleanly. The chart auto-mounts the rendered Secret at
`licenseServer.licenseFile` (`/opt/adapt/etc/LicSer.lic` by default)
as a `subPath` (file-level) mount.

**Expert path.** Leave `licenseServer.license` empty. Set
`licenseServer.volumes` + `licenseServer.volumeMounts` to mount a
parent directory (`/opt/adapt/etc/`) from a Secret/ConfigMap/PVC of
your choice. Kubelet's mount resolution gives directory mounts
precedence — your tree supersedes the chart-managed file mounts.

The chart does **not** detect collisions between the two modes. If
you set both, kubelet picks the directory mount and the chart-managed
Secret becomes dead config.

## How UA license delivery works

UA deploys only as an initContainer in the Inspire Scaler Pod (via the
Kustomize overlay), so UA license delivery only matters when
`inspire.enabled: true` AND `--post-renderer` is used.

**Demo path.** As with the LS license, the UA license file is binary
and must be **base64-encoded** before passing to Helm. The chart
renders an `Opaque` Secret named `adapt-ua-license` with the encoded
value in `data.adeptua.lic`. Provide via:

```sh
--set ua.license=$(base64 -i ./adeptua.lic | tr -d '\n')
```

The Kustomize overlay mounts this Secret on the `deploy-ua`
initContainer at `ua.licenseFile` (`/opt/adapt/etc/adeptua.lic` by
default) as a `subPath` (file-level) mount — leaving the image's
other baked-in `etc/` files (`adeptua.ini`, `ads.ini`,
`GenericStartup.ini`, etc.) visible.

**No expert path for UA in v1.0.0.** Per the SPT opinionated-fork
philosophy, directory-level `/opt/adapt/etc/` override for UA would
require the chart to bake all six ini files into a chart-managed
Secret (because a directory mount masks the image's etc/ tree); not
warranted until a concrete demo requirement surfaces. Fork the chart
if you need full UA etc/ control.

**Constraint: one Adapt release per namespace** when using the UA
demo path. The chart-managed Secret name is `adapt-ua-license` (not
release-prefixed) to match the Kustomize overlay's hard-coded
reference. The overlay marks the Secret reference `optional: true`,
so installs without `ua.license` set will succeed — UA will fail
license validation at runtime instead.

## Image registry configuration

The default `image.registry: registry.sptcloud.com` points at SPT's
private registry. To redirect to a mirror:

```sh
helm install adapt ./chart-v2/adapt --set image.registry=mymirror.example.com ...
```

**Important constraint**: `image.registry` only affects the
_Helm-templated_ LS Deployment. The UA image reference in the
Kustomize overlay (`kustomize/scaler-inject/initcontainer-patch.yaml`)
is **hard-coded** per the v1.0.0 design (mechanism (a) in the chart
design notes). To change the UA image, edit the overlay file and
re-release the chart — there is no values knob.

## Hostname / license pinning

The Pod spec sets `spec.hostname: sandbox` by default. The Adapt demo
license file is pinned to hostname `sandbox` (the convention from
Quadient demo Windows VMs). Override `licenseServer.hostname` if your
license is keyed to a different name.

Pod hostnames in Kubernetes are _not_ unique across the cluster (they
live in per-Pod network namespaces), so RollingUpdate during chart
upgrades is safe: two Pods can briefly coexist with the same hostname.

## How the Scaler-side injection works

When `inspire.enabled: true` and `--post-renderer adapt-scaler-inject`
is used (the plugin installed from `./chart-v2/adapt/post-renderer`),
the post-renderer:

1. Reads Helm's rendered manifests from stdin
2. Detects whether an Inspire Scaler Deployment (`metadata.name:
inspire-scaler`) is present
3. If absent: passes through unchanged
4. If present: applies a Kustomize strategic-merge patch that appends
   to the Scaler Deployment's `initContainers`, `containers[0].volumeMounts`,
   and `volumes` lists

The patch adds:

- `deploy-ua` initContainer (image: `registry.sptcloud.com/adapt/ua:2.4.1.22-HF`)
  — copies UA binaries to `/opt/adapt/share` inside its container
- `ua-share` emptyDir volume — shared between the initContainer and
  the main scaler container
- VolumeMount on the main `inspire-scaler` container at `/opt/adapt/ua`
  — same `ua-share` volume, different mount path per container
- `ua-license` volume from Secret `adapt-ua-license` (marked
  `optional: true`) — the chart-managed UA license Secret, when
  `ua.license` is set
- VolumeMount on the `deploy-ua` initContainer at `/opt/adapt/etc/adeptua.lic`
  via subPath — file-level mount so the image's baked-in etc/ ini
  files remain visible

Each Scaler Pod gets its own fresh `emptyDir`, populated independently
by its own initContainer. HPA scale-up works automatically: every new
Pod runs the same initContainer, gets its own UA binaries, and is
self-contained. See `post-renderer/kustomize/scaler-inject/initcontainer-patch.yaml`.

## Constraints (require chart fork to override)

Per the SPT charts opinionated-fork philosophy: a small set of values
are hard-coded in templates or overlays rather than parameterized. If
you need to change any of these, fork the chart.

| Setting                      | Hard-coded value                             | Lives in                                                              |
| ---------------------------- | -------------------------------------------- | --------------------------------------------------------------------- |
| UA image reference           | `registry.sptcloud.com/adapt/ua:2.4.1.22-HF` | `post-renderer/kustomize/scaler-inject/initcontainer-patch.yaml`      |
| Scaler injection target name | `inspire-scaler`                             | overlay + `post-renderer/kustomize-post.sh` safety check              |
| UA license Secret name       | `adapt-ua-license`                           | overlay + `templates/ua-license-secret.yaml`                          |
| LS replica count             | `1`                                          | `templates/ls-deployment.yaml`                                        |
| LS container internal port   | `5000`                                       | `templates/ls-deployment.yaml`, `templates/ls-configmap.yaml`         |
| cdplicser.cfg mount path     | `/opt/adapt/etc/cdplicser.cfg`               | `templates/ls-deployment.yaml`                                        |

The remaining knobs (image registry, image tag, hostname, license
content, probe configs, security context, resources, ingress
absence — yes, intentionally no ingress for LS) are all values-driven.

## Smoke testing locally

```sh
# Render only (no install) — pipe form works on all Helm versions
# without needing the plugin installed
helm template adapt ./chart-v2/adapt \
  --values ./chart-v2/adapt/values-examples/integrated-with-inspire.yaml \
  --set licenseServer.license=$(base64 -i ./LicSer.lic | tr -d '\n') \
  --set ua.license=$(base64 -i ./adeptua.lic | tr -d '\n') \
  | ./chart-v2/adapt/post-renderer/kustomize-post.sh \
  > /tmp/adapt-rendered.yaml

# Validate against K8s schemas
kubeconform -strict -summary /tmp/adapt-rendered.yaml
```

A passing smoke test gives high confidence the chart will install
cleanly; it does **not** validate that the rendered workloads actually
run (image pulls, license validation, network reachability between
Scaler and LS, etc. all happen at runtime).
