{{/*
Application container volumes
*/}}
{{- define "django-production-chart.specVolumes" -}}
{{- $dot := . -}}
volumes:
{{- if .Values.certs.mounted }}
  - name: certs-volume
    secret:
      secretName: {{ .Values.certs.secretName | quote }}
{{- end }}
{{- if .Values.gcsCredentials.mounted }}
  - name: gcs-volume
    secret:
      secretName: {{ .Values.gcsCredentials.secretName | quote }}
{{- end }}
{{- if .Values.mountedSecrets.enabled }}
  - name: mounted-secrets-volume
    secret:
      secretName: {{ .Values.mountedSecrets.secretName | quote }}
{{- if .Values.mountedSecrets.items }}
      items:
{{- range .Values.mountedSecrets.items }}
        - key: {{ .key | quote }}
          path: {{ .path | quote }}
{{- end }}
{{- end }}
{{- end }}
{{- range $name, $map := .Values.podVolumes }}
{{- if hasKey $map "volume" }}
{{- if hasKey $map.volume "configMap" }}
  - name: {{ $name }}
    configMap:
      name: {{ printf "%s-%s" ( include "django-production-chart.releaseIdentifier" $dot ) $map.volume.configMap.name }}
{{- end }}
{{- if hasKey $map.volume "claim" }}
{{ toYaml $map.volume | indent 4 }}
{{- end }}
{{- else }}
{{- if hasKey $map "persistentVolumeClaim" }}
  - name: {{ include "django-production-chart.pvcName" ( dict "root" $ "name" $name ) }}
    persistentVolumeClaim:
{{ toYaml $map.persistentVolumeClaim | indent 6 }}
{{- end }}
{{- end }}
{{- end }}
{{- end -}}