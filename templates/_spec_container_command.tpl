{{/*
Application container base spec command
*/}}
{{- define "django-production-chart.specContainerCommand" -}}
{{ if .command -}}
command:
{{- range .command }}
  - {{ . }}
{{- end -}}
{{- end -}}
{{ if .args -}}
args:
{{- range .args }}
  - {{ . }}
{{- end -}}
{{- end -}}
{{- end -}}
