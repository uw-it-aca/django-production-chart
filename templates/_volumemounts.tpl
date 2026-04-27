{{/*
volumeMount helper template
*/}}
{{- define "django-production-chart.volumeMount" -}}
{{- if ( hasKey .map "claimName" ) -}}
- name: {{ .map.claimName }}
{{- else -}}
{{- if and ( hasKey .map "volume" ) ( or ( hasKey .map.volume "claimTemplate" ) ( hasKey .map.volume "claim" ) ) -}}
- name: {{ include "django-production-chart.pvcName" (dict "root" .root "name" .name ) }}
{{- else -}}
- name: {{ .name }}
{{- end }}
{{- end }}
{{ toYaml .map.mount | indent 2 }}
{{- end -}}