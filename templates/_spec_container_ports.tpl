{{/*
Application container base spec ports definition
*/}}
{{- define "django-production-chart.specContainerPorts" -}}
{{- $proxy := and .Values.proxyServer .Values.proxyServer.enabled -}}
ports:
{{- if .Values.containerPorts.enabled }}
{{- range .Values.containerPorts.ports }}
  - containerPort: {{ .containerPort }}
    protocol: {{ .protocol | default "TCP" }}
{{- /* the proxy sidecar owns the "http" port name the Service targets */}}
{{- if and .name (not (and $proxy (eq .name "http"))) }}
    name: {{ .name }}
{{- end }}
{{- end }}
{{- else }}
  - containerPort: {{ .Values.containerPort }}
    protocol: TCP
{{- if not $proxy }}
    name: http
{{- end }}
{{- end }}
{{- end }}
