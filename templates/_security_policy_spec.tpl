{{/*
securityPolicy security spec
*/}}
{{- define "django-production-chart.securityPolicySpec" -}}
{{- if (hasKey . "spec") }}
{{ toYaml .spec }}
{{- end }}
{{- end -}}