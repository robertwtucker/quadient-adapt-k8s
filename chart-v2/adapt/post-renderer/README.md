# adapt-scaler-inject (Helm 4 postrenderer plugin)

Kustomize-based post-renderer plugin for the Adapt Helm chart. Reads
Helm's rendered manifests from stdin, applies a strategic-merge patch
that injects the `deploy-ua` initContainer, `ua-share` emptyDir volume,
and main-container volumeMount into Inspire's Scaler Deployment so
Scaler can exec Adapt UA binaries from `/opt/adapt/ua`. When no
`inspire-scaler` Deployment is present in stdin (e.g.,
`inspire.enabled=false`), input passes through unchanged.

## Install once per machine

```sh
helm plugin install /path/to/chart-v2/adapt/post-renderer
```

## Usage

```sh
helm install adapt /path/to/chart-v2/adapt \
  --values /path/to/values.yaml \
  --post-renderer adapt-scaler-inject \
  ...
```

## Layout

- `plugin.yaml` — Helm 4 plugin manifest (`type: postrenderer/v1`)
- `kustomize-post.sh` — subprocess command; reads stdin, applies
  the Kustomize overlay, writes stdout
- `kustomize/scaler-inject/` — Kustomize overlay (kustomization.yaml +
  initcontainer-patch.yaml SMP)

## Requirements

`kubectl` ≥ 1.21 (the script uses the bundled `kubectl kustomize`
subcommand — no separate kustomize binary needed).

## Uninstall

```sh
helm plugin uninstall adapt-scaler-inject
```

If the uninstall hits errors and leaves a stale directory at
`$HELM_PLUGINS/post-renderer/`, remove it manually:

```sh
rm -rf "$(helm env HELM_PLUGINS)/post-renderer"
```
