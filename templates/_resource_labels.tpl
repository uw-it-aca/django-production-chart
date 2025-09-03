{{/*
Adds the shared set of resource labels.
*/}}
{{- define "django-production-chart.resourceLabels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ include "django-production-chart.chart" . | quote }}
{{- if .Values.securityPolicy.enabled }}
axdd.s.uw.edu/security-policy: applied
{{- end -}}
{{- end -}}
