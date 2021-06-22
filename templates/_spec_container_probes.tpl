{{/*
Application container readiness, liveliness, health probe definitions
*/}}
{{- define "django-production-chart.specContainerProbes" -}}
{{- $command := .Values.readiness.command | default (list "/scripts/ready.sh") -}}
{{- if .Values.readiness.enabled -}}
readinessProbe:
{{- if .Values.readiness.httpGet -}}
  httpGet:
    path: {{ .Values.readiness.httpGet.path | default "/readiness" }}
    port: {{ default 8000 .Values.readiness.httpGet.port | quote }}
{{- else if .Values.readiness.tcpSocket -}}
  tcpSocket:
    port: {{ default 8000 .Values.readiness.tcpSocket.port | quote }}
{{- else }}
  exec:
{{ include "django-production-chart.specContainerCommand" (dict "command" $command "args" "") | indent 4}}
{{- end }}
  initialDelaySeconds: {{ .Values.readiness.initialDelay | default 5 }}
  periodSeconds: {{ .Values.readiness.period | default 5 }}
{{- end }}
{{- end -}}