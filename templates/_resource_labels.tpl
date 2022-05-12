{{/*
Resource labels
*/}}
{{- define "django-production-chart.resourceLabels" -}}
{{- $labelPrefix := "axdd.s.uw.edu" -}}
{{- $appname := .Release.Name | trimSuffix "-prod-test" | trimSuffix "-prod-prod" -}}
{{- $billingcode := index .Values.billing.codes $appname -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ include "django-production-chart.chart" . }}
{{ printf "%s/%s" $labelPrefix "billing-code"}}: {{ $billingcode | quote }}
{{ printf "%s/%s" $labelPrefix "billing-name"}}: {{ index .Values.billing.names $billingcode | quote }}
{{- range $key, $value := .Values.labels }}
{{ printf "%s/%s" $labelPrefix $key }}: {{ $value | quote }}
{{- end }}
{{- end -}}
