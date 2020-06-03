{{/*
Application container base spec command
*/}}
{{- define "django-production-chart.specContainerCommand" -}}
{{ if .command -}}
command:
{{- range .command }}
  - {{ . | quote }}
{{- end -}}
{{- end -}}
{{ if .args -}}
args:
{{- range .args }}
  - {{ . | quote }}
{{- end -}}
{{- end -}}
{{- end -}}
