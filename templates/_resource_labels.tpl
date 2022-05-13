{{/*
Adds the shared set of resource labels.
*/}}
{{- define "django-production-chart.resourceLabels" -}}
{{- $billingcode := index .Values.billing.codes .Values.repo | default "" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ include "django-production-chart.chart" . | quote }}
axdd.s.uw.edu/billing-code: {{ $billingcode | quote }}
axdd.s.uw.edu/billing-name: {{ index .Values.billing.names $billingcode | quote }}
{{- end -}}