{{/*
Resource labels
*/}}
{{- define "django-production-chart.specContainerLabels" -}}
{{- $labelPrefix := "axdd.s.uw.edu" -}}
{{- $billingNames := dict "786" "Student & Instructor Success Analytics" -}}
app.kubernetes.io/name: {{ include "django-production-chart.name" . }}
helm.sh/chart: {{ include "django-production-chart.chart" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- range $key, $value := .Values.labels }}
{{ printf "%s/%s" $labelPrefix $key }}: {{ $value | quote }}
{{- if eq "billing-code" $key }}
{{ printf "%s/%s" $labelPrefix "billing-name"}}: {{ get $billingNames $value | quote }}
{{- end }}
{{- end -}}
{{- end -}}
