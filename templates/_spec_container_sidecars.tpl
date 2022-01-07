{{/*
Application sidecar containers
*/}}
{{- define "django-production-chart.specContainerSidecars" -}}
{{ $dot := . }}
{{- range $podName, $container := .Values.sidecarContainers }}
  - name: {{ $podName | quote }}
{{ toYaml $container | indent 4 }}
{{- $i := 0 }}
{{- range $name, $map := $dot.Values.podVolumes }}
{{- if and ( hasKey $map "mount" ) ( has $podName $map.containers ) }}
{{- if eq $i 0 }}
    volumeMounts:
{{- end }}
{{- $i = add1 $i }}
{{- end }}
{{- end }}
{{- range $name, $map := $dot.Values.podVolumes }}
{{- if and ( hasKey $map "mount" ) ( has $podName $map.containers ) }}
{{ include "django-production-chart.volumeMount" ( dict "root" $dot "name" $name "map" $map ) | indent 6}}
{{- end }}
{{- end }}
{{- end }}
{{- end -}}
