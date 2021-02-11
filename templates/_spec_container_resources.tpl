{{/*
Application container base spec resources
*/}}
{{- define "django-production-chart.specContainerResources" -}}
resources:
{{ toYaml . | indent 2 }}
{{- end -}}
