{{/*
securityPolicy security spec
*/}}
{{- define "django-production-chart.securityPolicySpec" -}}
{{- if (hasKey . "spec") }}
# securityPolicy specification values
{{ toYaml .spec }}
{{- end }}
{{- end -}}