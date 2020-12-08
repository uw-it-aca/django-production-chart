{{/*
Application container base spec ports definition
*/}}
{{- define "django-production-chart.specContainerPorts" -}}
ports:
  - name: http
    containerPort: {{ .Values.containerPort }}
    protocol: TCP
{{- end -}}