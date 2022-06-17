{{/*
Application sidecar containers
*/}}
{{ define "django-production-chart.specContainerSidecars" }}
{{- range $podName, $container := .Values.sidecarContainers }}
  - name: {{ $podName | quote }}
{{- if $container.image }}
    image: {{ $container.image | quote }}
{{- end }}
{{- if $container.cmd }}
    cmd: {{ toYaml $container.cmd }}
{{- end }}
{{- if $container.args }}
    args:
{{ toYaml $container.args | indent 6 }}
{{- end }}
{{- if $container.resources }}
    resources:
{{ toYaml $container.resources | indent 6 }}
{{- end }}
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
    env:
{{- if $container.environmentVariables }}
{{ toYaml $container.environmentVariables | indent 6 }}
{{- end }}
{{- if $.Values.metrics.enabled }}
      - name: PUSHGATEWAY
        value: {{ printf "%s-pushgateway" ( include "django-production-chart.releaseIdentifier" $ ) }}
{{- end }}
{{- end }}
{{- end -}}
