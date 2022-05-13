{{/*
Application container base spec ports definition
*/}}
{{- define "django-production-chart.specContainerPorts" -}}
ports:
{{- if .Values.containerPorts.enabled }}
{{- range .Values.containerPorts.ports }}
  - name: {{ .name }}
    containerPort: {{ .containerPort }}
    protocol: {{ .protocol }}
{{- end }}
{{- else }}
  - name: http
    containerPort: {{ .Values.containerPort }}
    protocol: TCP
{{- end }}
{{- end }}
