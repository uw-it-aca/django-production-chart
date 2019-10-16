{{/*
Application container base spec environment variables
*/}}
{{- define "django-production-chart.specContainerCommand" -}}
command: {{ .command }}
{{ if .args -}}
args: {{ .args }}
{{- end -}}
{{- end -}}
