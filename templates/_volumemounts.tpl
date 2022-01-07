{{/*
volumeMount helper template
*/}}
{{- define "django-production-chart.volumeMount" -}}
{{- if or ( hasKey .map.volume "claimTemplate" ) ( hasKey .map.volume "claim" ) -}}
- name: {{ printf "%s-pvc-%s" ( include "django-production-chart.releaseIdentifier" .root ) .name }}
{{- else -}}
- name: {{ .name }}
{{- end }}
{{ toYaml .map.mount | indent 2 }}
{{- end -}}