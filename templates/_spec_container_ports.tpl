{{/*
Application container base spec ports definition
*/}}
{{- define "django-production-chart.specContainerPorts" -}}
ports:
{{- if .Values.containerPorts.enabled }}
{{- range .Values.containerPorts.ports }}
  - containerPort: {{ .containerPort }}
    name: {{ .name }}
    protocol: {{ .protocol }}
{{- if ( and .name ( or ( not eq .name "http" ) ( not ( and .Values.proxyServer .Values.proxyServer.enabled ) ) ) ) }}
    name: {{ .name }}
{{- end }}
{{- end }}
{{- else }}
  - containerPort: {{ .Values.containerPort }}
    protocol: TCP
{{- if not (and .Values.proxyServer .Values.proxyServer.enabled ) }}
    name: http
{{- end }}
{{- end }}
{{- end }}
