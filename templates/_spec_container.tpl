{{/*
Application container spec
*/}}
{{- define "django-production-chart.specContainer" -}}
{{- include "django-production-chart.specContainerBase" . -}}
{{- include "django-production-chart.specContainerResources" .Values.resources | nindent 4 -}}
{{- include "django-production-chart.specContainerEnv" . | nindent 4 -}}
{{- include "django-production-chart.specContainerPorts" . | nindent 4 -}}
{{- end -}}