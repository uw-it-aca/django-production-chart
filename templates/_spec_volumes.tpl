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
{{- if not ( or ( hasKey $map.volume "claim"  ) ( hasKey $map.volume "claimTemplate" ) ) }}
  - name: {{ $name }}
{{- if hasKey $map.volume "configMap" }}
    configMap:
      name: {{ printf "%s-%s" ( include "django-production-chart.releaseIdentifier" $dot ) $map.volume.configMap.name }}
{{- else }}
{{ toYaml $map.volume | indent 4 }}
{{- end }}
{{- end }}
{{- end }}
{{- end -}}