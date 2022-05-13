{{/*
Pod scheduling config
*/}}
{{- define "django-production-chart.specControllerScheduling" }}
{{- with .Values.nodeSelector }}
nodeSelector:
{{ toYaml . | trim | nindent 2}}
{{- end }}
{{- with .Values.tolerations }}
tolerations:
{{ toYaml . | trim | nindent 2}}
{{- end }}
{{- with .Values.affinity }}
affinity:
{{- if .podsSpanNodes }}
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchExpressions:
              - key: "app.kubernetes.io/name"
                operator: In
                values:
                  - "{{ include "django-production-chart.releaseIdentifier" $ }}"
          topologyKey: kubernetes.io/hostname
{{- else }}
{{ toYaml . | trim | indent 2}}
{{- end }}
{{- end }}
{{- end -}}
