#!/usr/bin/env bash
# Helm post-renderer for the Adapt chart.
#
# Reads Helm's rendered manifests from stdin, applies the
# kustomize/scaler-inject overlay (which injects a deploy-ua
# initContainer + ua-share emptyDir volume + main-container volumeMount
# into Inspire's Scaler Deployment), and writes the result to stdout.
#
# When no Inspire Scaler Deployment is present in the input (e.g., the
# user installed with inspire.enabled=false), input is passed through
# unchanged — so this script is safe to use unconditionally.
#
# Usage:
#   helm install adapt /path/to/chart-v2/adapt \
#     --set-file licenseServer.license=./LicSer.lic \
#     --post-renderer /path/to/chart-v2/adapt/kustomize-post.sh
#
# Requirements:
#   kubectl >= 1.21 (uses the bundled kustomize v5.x subcommand;
#   no separate kustomize binary required).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OVERLAY_DIR="${SCRIPT_DIR}/kustomize/scaler-inject"

# Read the rendered manifests from stdin.
RENDERED="$(cat)"

# Safety: if no Inspire Scaler Deployment is present, pass through.
# This keeps `helm install --post-renderer kustomize-post.sh` working
# for LS-only installs (inspire.enabled=false) without forcing the user
# to remember to omit --post-renderer in that case.
#
# Constraint: this checks for the literal name `inspire-scaler`, which
# is what Inspire renders when global.applicationName is at its default
# "inspire". If a consumer overrides applicationName, the overlay's
# patch target no longer matches — fork the chart and update both the
# overlay's target name and this safety-check regex.
if ! grep -qE '^  name: inspire-scaler$' <<< "$RENDERED"; then
  printf '%s\n' "$RENDERED"
  exit 0
fi

# Apply the overlay.
WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

cp "${OVERLAY_DIR}/kustomization.yaml" "${WORKDIR}/"
cp "${OVERLAY_DIR}/initcontainer-patch.yaml" "${WORKDIR}/"
printf '%s\n' "$RENDERED" > "${WORKDIR}/rendered-manifests.yaml"

kubectl kustomize "${WORKDIR}"
