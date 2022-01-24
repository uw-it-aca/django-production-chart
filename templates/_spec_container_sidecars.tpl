{{/*
Application sidecar containers
*/}}
{{- define "django-production-chart.specContainerSidecars" -}}
{{ $dot := . }}
{{- range $podName, $container := .Values.sidecarContainers }}
  - name: {{ $podName | quote }}
{{ toYaml $container | indent 4 }}
    volumeMounts:
{{- if $dot.Values.certs.mounted }}
      - name: certs-volume
        readOnly: true
        mountPath: "/certs"
{{- end }}
{{- range $name, $map := $dot.Values.podVolumes }}
{{- if and ( hasKey $map "mount" ) ( has $podName $map.containers ) }}
{{ include "django-production-chart.volumeMount" ( dict "root" $dot "name" $name "map" $map ) | indent 6}}
{{- end }}
{{- end }}
{{- end }}
{{- end -}}
