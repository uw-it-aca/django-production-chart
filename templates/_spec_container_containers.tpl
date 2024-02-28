{{/*
Application initialization containers
*/}}
{{ define "django-production-chart.specContainerContainers" }}
{{- $root := .root }}
{{- if (and $.type .containers) }}
{{ $.type }}:
{{- end }}
{{- range $podName, $container := .containers }}
  - name: {{ $podName | quote }}
{{- if $container.image }}
    image: {{ $container.image | quote }}
{{- end }}
{{- if $container.securityContext }}
    securityContext:
{{ toYaml $container.securityContext | indent 6}}
{{- end }}
{{- if $container.command }}
    command:
{{ toYaml $container.command | indent 6}}
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
{{- if $root.Values.certs.mounted }}
      - name: certs-volume
        readOnly: true
        mountPath: "/certs"
{{- end }}
{{- if $root.Values.gcsCredentials.mounted }}
      - name: gcs-volume
        readOnly: true
        mountPath: "/gcs"
{{- end }}
{{- range $name, $map := $root.Values.podVolumes }}
{{- if and ( hasKey $map "mount" ) ( has $podName $map.containers ) }}
{{ include "django-production-chart.volumeMount" ( dict "root" $root "name" $name "map" $map ) | indent 6}}
{{- end }}
{{- end }}
{{- if hasKey $container "ports" }}
    ports:
{{ toYaml $container.ports | indent 6 }}
{{- end }}
    env:
{{- if $container.environmentVariables }}
{{ toYaml $container.environmentVariables | indent 6 }}
{{- end }}
{{- end }}
{{- end -}}
