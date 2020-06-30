{{/*
Application container contaienr lifecycle directives
*/}}
{{- define "django-production-chart.specContainerLifecycle" -}}
{{- if .Values.lifecycle.enabled -}}
lifecycle:
{{- if .Values.lifecycle.preStop.enabled }}
{{- $command := .Values.lifecycle.preStop.command | default (list "/bin/sleep" "20") }}
  preStop:
    exec:
{{ include "django-production-chart.specContainerCommand" (dict "command" $command "args" "") | indent 6}}
{{- end }}
{{- end }}
{{- end -}}
