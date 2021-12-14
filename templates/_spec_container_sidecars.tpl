{{/*
Application sidecar containers
*/}}
{{- define "django-production-chart.specContainerSidecars" -}}
{{- range $name, $container := .Values.sidecarContainers }}
  - name: {{ $name | quote }}
{{ toYaml $container | indent 4 }}
{{- end }}
{{- end -}}
