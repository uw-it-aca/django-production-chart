{{/*
Application container base spec ports definition
*/}}
{{- define "django-production-chart.specContainerPorts" -}}
ports:
  - name: http
    containerPort: 8080
    protocol: TCP
{{- end -}}