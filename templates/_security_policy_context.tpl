{{/*
securityPolicy context
*/}}
{{- define "django-production-chart.securityPolicyContext" -}}
{{- if (hasKey . "securityContext") }}
{{ toYaml .securityContext }}
{{- end }}
{{- end -}}