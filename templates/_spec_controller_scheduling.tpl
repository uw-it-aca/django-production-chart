{{/*
Pod scheduling config
*/}}
{{- define "django-production-chart.specControllerScheduling" -}}
{{- $dot := . -}}
{{- with .Values.nodeSelector }}
nodeSelector:
{{ toYaml . | trim | indent 2}}
{{- end }}
{{- with .Values.tolerations }}
tolerations:
{{ toYaml . | trim | indent 2}}
{{- end }}
{{- with .Values.affinity }}
affinity:
{{- if .podsSpanNodes }}
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchExpressions:
            - key: "app.kubernetes.io/name"
              operator: In
              values:
              - "{{ include "django-production-chart.releaseIdentifier" $dot }}"
        topologyKey: "kubernetes.io/hostname"
{{- else }}
{{ toYaml . | trim | indent 2}}
{{- end }}
{{- end }}
{{- end -}}
