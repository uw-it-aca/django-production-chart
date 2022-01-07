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
    app.kubernetes.io/name: {{ include "django-production-chart.name" .root }}
    helm.sh/chart: {{ include "django-production-chart.chart" .root }}
    app.kubernetes.io/instance: {{ .root.Release.Name }}
    app.kubernetes.io/managed-by: {{ .root.Release.Service }}
spec:
  type: {{ default "ClusterIP" .service.type }}
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
