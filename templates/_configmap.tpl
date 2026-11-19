{{/*
Create a configmap object
*/}}
{{- define "django-production-chart.configmap" -}}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .root.Values.releaseIdentifier }}-{{ .map_name }}
  namespace: {{ .root.Values.namespaceIdentifier }}
data:
{{ .map_data | indent 2 }}
{{- end -}}
