{{/*
Persistent Volume Claim template
*/}}
{{- define "django-production-chart.pvcBase" }}
  name: {{ printf "%s-pvc-%s" ( include "django-production-chart.releaseIdentifier" .root ) .name }}
  namespace: {{ include "django-production-chart.namespaceIdentifier" .root }}
spec:
  accessModes:
{{- if .claim.accessModes }}
{{- range .claim.accessModes }}
    - {{ . | quote }}
{{- end }}
{{- else }}
    - ReadWriteMany
{{- end }}
{{- if .claim.volumeMode }}
  volumeMode: {{ .claim.volumeMode | quote }}
{{- end }}
  storageClassName: {{ default "default" .claim.storageClassName | quote }}
  resources:
    requests:
      storage: {{ .claim.storageSize | quote }}
{{- if .claim.selector }}
  selector:
{{- if .claim.selector.matchLabels }}
    matchLabels:
{{ toYaml .claim.selector.matchLabels | indent 6 }}
      release: "stable"
{{- end }}
{{- if .claim.selector.matchExpressions }}
    matchExpressions:
{{ toYaml .claim.selector.matchExpressions | indent 6 }}
{{- end }}
{{- end }}
{{ end -}}
