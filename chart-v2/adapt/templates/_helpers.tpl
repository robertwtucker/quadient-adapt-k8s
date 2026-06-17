{{/*
Expand the name of the chart.
*/}}
{{- define "adapt.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to
this (by the DNS naming spec). If release name contains chart name, it will
be used as a full name.
*/}}
{{- define "adapt.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "adapt.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "adapt.labels" -}}
helm.sh/chart: {{ include "adapt.chart" . }}
{{ include "adapt.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: adapt
{{- end }}

{{/*
Selector labels
*/}}
{{- define "adapt.selectorLabels" -}}
app.kubernetes.io/name: {{ include "adapt.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
License Server-specific labels — extend common labels with a component tag.
*/}}
{{- define "adapt.licenseServer.labels" -}}
{{ include "adapt.labels" . }}
app.kubernetes.io/component: license-server
{{- end }}

{{/*
License Server selector labels.
*/}}
{{- define "adapt.licenseServer.selectorLabels" -}}
{{ include "adapt.selectorLabels" . }}
app.kubernetes.io/component: license-server
{{- end }}

{{/*
Resource name for the License Server workload.
*/}}
{{- define "adapt.licenseServer.fullname" -}}
{{- printf "%s-ls" (include "adapt.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create the name of the service account to use.
*/}}
{{- define "adapt.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "adapt.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Fully-qualified License Server image reference (registry/repository:tag).
Tag defaults to .Chart.AppVersion when .Values.licenseServer.image.tag is empty.
*/}}
{{- define "adapt.licenseServer.image" -}}
{{- $registry := .Values.image.registry -}}
{{- $repository := .Values.licenseServer.image.repository -}}
{{- $tag := default .Chart.AppVersion .Values.licenseServer.image.tag -}}
{{- printf "%s/%s:%s" $registry $repository $tag -}}
{{- end }}

{{/*
Name of the chart-managed License Server license Secret.
*/}}
{{- define "adapt.licenseServer.licenseSecretName" -}}
{{- printf "%s-license" (include "adapt.licenseServer.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Name of the chart-managed cdplicser.cfg ConfigMap.
*/}}
{{- define "adapt.licenseServer.configMapName" -}}
{{- printf "%s-config" (include "adapt.licenseServer.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Name of the chart-managed UA license Secret.
HARD-CODED (not release-prefixed) because the Kustomize overlay
references this name as a constant. See
kustomize/scaler-inject/initcontainer-patch.yaml. Constraint: only
one Adapt release per namespace can use the demo path when
.Values.ua.license is set.
*/}}
{{- define "adapt.ua.licenseSecretName" -}}
adapt-ua-license
{{- end }}
