{{/*
Application container base spec resources
*/}}
{{- define "django-production-chart.specContainerResources" -}}
resources:
{{ toYaml .Values.resources | indent 6 }}
{{- if .Values.nodeSelector }}
nodeSelector:
{{- with .Values.nodeSelector -}}
{{- toYaml . | nindent 2 }}
{{- end -}}
{{- end }}
{{- if .Values.affinity }}
affinity:
{{- with .Values.affinity -}}
{{- toYaml . | nindent 2 }}
{{- end -}}
{{- end }}
{{- if .Values.tolerations }}
tolerations:
{{- with .Values.tolerations -}}
{{- toYaml . | nindent 2 }}
{{- end -}}
{{- end }}
{{- end }}
