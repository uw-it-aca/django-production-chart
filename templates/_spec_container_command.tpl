{{/*
Application container base spec environment variables
*/}}
{{- define "django-production-chart.specContainerCommand" -}}
command: {{ .command }}
args: {{ .args }}
{{- end -}}
