{{/*
Application container readiness, liveliness, health probe definitions
*/}}

{{ define "django-production-chart.specContainerProbesBlock" -}}
{{- if .httpGet }}
httpGet:
  path: {{ .httpGet.path | default "/readiness" }}
  port: {{ default 8000 .httpGet.port | quote }}
{{- else if .tcpSocket }}
tcpSocket:
  port: {{ default 8000 .tcpSocket.port | quote }}
{{- else }}
exec:
{{- $command := .command | default (list "/scripts/ready.sh") }}
{{ include "django-production-chart.specContainerCommand" (dict "command" $command "args" "") | indent 2 }}
{{- end }}
initialDelaySeconds: {{ .initialDelay | default 5 }}
periodSeconds: {{ .period | default 5 }}
{{- end -}}

{{ define "django-production-chart.specContainerProbes" -}}
{{- if (and .readiness .readiness.enabled ) }}
readinessProbe:
{{ include "django-production-chart.specContainerProbesBlock" .readiness | indent 2 }}
{{- end }}
{{- if (and .liveness .liveness.enabled ) }}
livenessProbe:
{{ include "django-production-chart.specContainerProbesBlock" .liveness | indent 2 }}
{{- end }}
{{- end -}}
