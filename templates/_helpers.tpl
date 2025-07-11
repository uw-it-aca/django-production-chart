{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "django-production-chart.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "django-production-chart.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "django-production-chart.chart" -}}
{{- printf "%s-%s" .Chart.Name ( .Values.chartVersion | default .Chart.Version ) | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{ define "django-production-chart.releaseIdentifier" -}}
{{- if and .Values.namespace .Values.namespace.enabled -}}
{{- printf .Values.repo -}}
{{- else -}}
{{- printf "%s-prod-%s" .Values.repo .Values.instance -}}
{{- end -}}
{{- end -}}

{{ define "django-production-chart.namespaceIdentifier" -}}
{{- if and .Values.namespace .Values.namespace.enabled -}}
{{- printf "%s-%s" .Values.repo .Values.instance -}}
{{- else -}}
{{- printf (default .Release.Namespace "default") -}}
{{- end -}}
{{- end -}}

{{ define "django-production-chart.instanceIdentifier" -}}
{{- if and .Values.namespace .Values.namespace.enabled -}}
{{- printf "%s-%s" .Values.repo .Values.instance -}}
{{- else -}}
{{- printf "%s-prod-%s" .Values.repo .Values.instance -}}
{{- end -}}
{{- end -}}

{{- define "daemonset.apiVersion" -}}
{{- if semverCompare "<1.9-0" .Capabilities.KubeVersion.GitVersion -}}
{{- print "extensions/v1beta1" -}}
{{- else if semverCompare "^1.9-0" .Capabilities.KubeVersion.GitVersion -}}
{{- print "apps/v1" -}}
{{- end -}}
{{- end -}}

{{/*
Return the appropriate apiVersion for statefulset.
*/}}
{{- define "statefulset.apiVersion" -}}
{{- if semverCompare "<1.9-0" .Capabilities.KubeVersion.GitVersion -}}
{{- print "extensions/v1beta1" -}}
{{- else if semverCompare "^1.9-0" .Capabilities.KubeVersion.GitVersion -}}
{{- print "apps/v1" -}}
{{- end -}}
{{- end -}}
