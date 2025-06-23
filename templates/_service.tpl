{{/*
Application service template
*/}}
{{- define "django-production-chart.service" -}}
apiVersion: v1
kind: Service
metadata:
  name: {{ .name }}
  namespace: {{ .root.Values.namespaceIdentifier  }}
  labels:
    app.kubernetes.io/name: {{ include "django-production-chart.releaseIdentifier" .root }}
    app.kubernetes.io/instance: {{ include "django-production-chart.instanceIdentifier" .root }}
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
    app.kubernetes.io/name: {{ .root.Values.releaseIdentifier }}
    app.kubernetes.io/instance: {{ .root.Values.instanceIdentifier }}
{{- end }}
