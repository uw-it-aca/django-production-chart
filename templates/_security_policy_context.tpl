{{/*
securityPolicy context
*/}}
{{- define "django-production-chart.securityPolicyContext" -}}
{{- if (hasKey . "securityContext") }}
# securityPolicyContext values
{{ toYaml .securityContext }}
{{- end }}
{{- end -}}