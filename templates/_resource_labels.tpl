{{/*
Adds the shared set of resource labels.
*/}}
{{- define "django-production-chart.resourceLabels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ include "django-production-chart.chart" . | quote }}
{{- if .Values.securityPolicy.enabled }}
axdd.s.uw.edu/security-policy: applied
{{- end -}}
{{- range .Values.billingCodes }}
{{- if has $.Values.repo .releaseNames }}
axdd.s.uw.edu/billing-code: {{ .code | quote }}
axdd.s.uw.edu/billing-name: {{ .name | quote }}
{{- end -}}
{{- end -}}
{{- end -}}
