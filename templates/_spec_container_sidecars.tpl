{{/*
Application sidecar containers
*/}}
{{ define "django-production-chart.specContainerSidecars" }}
{{- range $podName, $container := .Values.sidecarContainers }}
  - name: {{ $podName | quote }}
{{ toYaml $container | indent 4 }}
    volumeMounts:
{{- if $.Values.certs.mounted }}
      - name: certs-volume
        readOnly: true
        mountPath: "/certs"
{{- end }}
{{- if $.Values.gcsCredentials.mounted }}
      - name: gcs-volume
        readOnly: true
        mountPath: "/gcs"
{{- end }}
{{- range $name, $map := $.Values.podVolumes }}
{{- if and ( hasKey $map "mount" ) ( has $podName $map.containers ) }}
{{ include "django-production-chart.volumeMount" ( dict "root" $ "name" $name "map" $map ) | indent 6}}
{{- end }}
{{- end }}
{{- end }}
{{- end -}}
