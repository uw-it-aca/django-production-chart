{{/*
Adds the shared set of resource labels.
*/}}
{{- define "django-production-chart.resourceLabels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ include "django-production-chart.chart" . | quote }}
{{- range .Values.billingCodes }}
{{- if has $.Values.repo .releaseNames }}
axdd.s.uw.edu/billing-code: {{ .code | quote }}
axdd.s.uw.edu/billing-name: {{ .name | quote }}
{{- end -}}
{{- end -}}
{{- end -}}
