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
{{- if or ( hasKey $map.volume "claimTemplate" ) ( hasKey $map.volume "claim" ) }}
      - name: {{ printf "%s-pvc-%s" ( include "django-production-chart.releaseIdentifier" $dot ) $name }}
{{- else }}
      - name: {{ $name }}
{{- end }}
{{ toYaml $map.mount | indent 8 }}
{{- end }}
{{- end }}

{{- end }}
{{- end -}}
