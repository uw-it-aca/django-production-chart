{{/*
Application service template
*/}}
{{- define "django-production-chart.service" -}}
apiVersion: v1
kind: Service
metadata:
  name: {{ .name }}
  namespace: {{ include "django-production-chart.namespaceIdentifier" .root }}
  labels:
    app.kubernetes.io/name: {{ include "django-production-chart.releaseIdentifier" .root }}
    app.kubernetes.io/instance: {{ .root.Release.Name }}
{{- include "django-production-chart.resourceLabels" .root | nindent 4 }}
spec:
{{- if or ( not .type ) ( has .type (list "ClusterIP" "NodePort" "LoadBalancer" "ExternalName")) }}
  type: {{ default "ClusterIP" .type }}
{{- end }}
  ports:
{{- if .service.ports }}
{{- range .service.ports }}
    - port: {{ .port }}
      targetPort: {{ .targetPort }}
      protocol: {{ default "TCP" .protocol }}
{{- if .name }}
      name: {{ .name }}
{{- end }}
{{- end }}
{{- else }}
    - port: {{ default 80 .service.port }}
      targetPort: http
      protocol: TCP
      name: http
{{- end }}
  selector:
    app.kubernetes.io/name: {{ include "django-production-chart.releaseIdentifier" .root }}
    app.kubernetes.io/instance: {{ .root.Release.Name }}
{{- end }}
