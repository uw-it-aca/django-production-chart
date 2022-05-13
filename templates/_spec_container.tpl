{{/*
Application container spec
*/}}
{{- define "django-production-chart.specContainer" -}}
{{ include "django-production-chart.specContainerBase" . }}
{{ include "django-production-chart.specContainerResources" .Values.resources | indent 4 }}
{{ include "django-production-chart.specContainerEnv" . | indent 4 }}
{{ include "django-production-chart.specContainerPorts" . | indent 4 }}
{{- end -}}
