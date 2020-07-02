{{/*
Application container base spec resources
*/}}
{{- define "django-production-chart.specContainerResources" -}}
resources:
{{ toYaml .Values.resources | indent 6 }}
{{- end -}}
