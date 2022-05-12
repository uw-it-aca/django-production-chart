{{/*
Resource labels
*/}}
{{- define "django-production-chart.resourceLabels" -}}
{{- $labelPrefix := "axdd.s.uw.edu" -}}
{{- $billingcode := index .Values.billing.codes .Values.repo | default "" }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ include "django-production-chart.chart" . }}
{{ printf "%s/%s" $labelPrefix "billing-code"}}: {{ $billingcode | quote }}
{{ printf "%s/%s" $labelPrefix "billing-name"}}: {{ index .Values.billing.names $billingcode | quote }}
{{- range $key, $value := .Values.labels }}
{{ printf "%s/%s" $labelPrefix $key }}: {{ $value | quote }}
{{- end }}
{{- end -}}
