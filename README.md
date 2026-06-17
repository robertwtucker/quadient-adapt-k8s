# adapt-k8s

> Container image builds for Quadient Inspire Adapt (UA + License Server)

This repository defines the **container images** for Quadient Inspire Adapt:
the User Agent (UA) and the License Server (LS). Both images are built on
Red Hat UBI 9 and bundle the proprietary Adapt distribution tarballs sourced
from Quadient.

The **Helm chart** for deploying these images on Kubernetes lives in
[`spt-charts`](https://github.com/robertwtucker/spt-charts) at
`adapt/` — see that repo for install instructions and the
Kustomize-based Scaler injection.

## Repo layout

```
container/
  ua/                 UA container build context
    Dockerfile        UBI 9 base + adeptua tarball + entrypoint
    entrypoint.sh     `share` mode: copy UA binaries to /opt/adapt/share
    etc/              baked config (adeptua.ini, ads.ini, GenericStartup.ini, etc.)
                      + 0-byte adeptua.lic placeholder (real license mounted at runtime)
    Makefile          per-container build/push targets
    InspireAdapt_adeptua_*.tar  source tarball from Quadient (not in git)
  license-server/     LS container build context
    Dockerfile        UBI 9 base + cdp_licser64 tarball + entrypoint
    entrypoint.sh     starts the cdplicser daemon on TCP 5000
    etc/              baked config (cdplicser.cfg) + 0-byte LicSer.lic placeholder
    Makefile
    cdp_licser64_*.tar
  make/
    Makefile.mk       shared Make targets (build/push/release based on Xebia pattern)
    .make-release-support  versioning helper script
```

## Prerequisites

- **Docker** (or Podman with `docker` alias)
- **Source tarballs from Quadient** placed in each container's build context:
  - UA: `container/ua/InspireAdapt_adeptua_<version>_<api>_RedHat(Ootpa)-64.tar`
  - LS: `container/license-server/cdp_licser64_<version>_RedHat(Ootpa).tar`
- **Credentials** for `registry.sptcloud.com` (`docker login registry.sptcloud.com`)

## Building images

Each container subdirectory has its own Makefile that includes `../make/Makefile.mk`.

```sh
cd container/ua
make build      # docker build → registry.sptcloud.com/adapt/ua:<version>
make push       # docker push to registry.sptcloud.com
make snapshot   # build + push in one step
make release    # check status + build + push (gated on tagged version)
```

Same targets in `container/license-server/`.

The version comes from each container's `.release` file (`release=...` line),
managed by the Xebia release-support pattern. Use `make patch-release`,
`make minor-release`, or `make major-release` to bump and tag.

## Image versioning convention

Image tags reflect the **product version** (the version of the Adapt component
inside the tarball), not a refarch SemVer. Current cuts:

- `registry.sptcloud.com/adapt/license-server:1.21.0.458-HF`
- `registry.sptcloud.com/adapt/ua:2.4.1.22-HF`

The matching Helm chart in `spt-charts/adapt/` carries these versions
in its `Chart.yaml` annotations
(`com.quadient.spt.refarch.adapt-{ls,ua}-version`) and references them in the
templated LS Deployment + the Kustomize overlay's UA initContainer. Bumping
product versions in this repo's `.release` files requires a corresponding
chart annotation update in `spt-charts`.

## Why the chart lives elsewhere

The chart slice migrated to `spt-charts` so that all SPT-maintained Helm
charts (Inspire mirror, Adapt, future additions) live in a single OCI-
publishing repo with shared CI (lint + template + kubeconform + KinD
dry-run on PR; tag-triggered GHCR push + cosign sign on release). This repo
retains the **image-build definition** — Dockerfiles, entrypoints,
proprietary tarballs, build automation — which has different cadence and
trust requirements (private registry, no public CI).

Design context — chart-shape decision, mirror policy, ownership framing
between SPT (refarch / image builds / chart packaging) and the Adapt team
(productization, if/when) — lives in private project notes.
