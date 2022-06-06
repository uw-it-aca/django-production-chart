{{/*
Application container spec base
*/}}
{{- define "django-production-chart.specContainerBase" -}}
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
containers:
  - name: {{ include "django-production-chart.releaseIdentifier" . }}
    image: {{ default ( printf "%s:%s" .Values.image.repository .Values.image.tag ) .image | quote }}
    imagePullPolicy: "Always"
{{- if .Values.securityPolicy.enabled }}
{{- if .Values.securityPolicy.containerBase }}
{{- if .Values.securityPolicy.containerBase.securityContext }}
    securityContext:
{{ toYaml .Values.securityPolicy.containerBase.securityContext | indent 6 }}
{{- end }}
{{- end }}
{{- end }}
    volumeMounts:
{{- if .Values.certs.mounted }}
      - name: certs-volume
        readOnly: true
        mountPath: "/certs"
{{- end }}
{{- if .Values.gcsCredentials.mounted }}
      - name: gcs-volume
        readOnly: true
        mountPath: "/gcs"
{{- end }}
{{- if .Values.mountedSecrets.enabled }}
      - name: mounted-secrets-volume
        readOnly: true
        mountPath: {{ default "/data" .Values.mountedSecrets.mountPath | quote }}
{{- end }}
{{- range $name, $map := .Values.podVolumes }}
{{- if $map.mount }}
{{- if or ( not ( hasKey $map "containers" ) ) ( has "base" $map.containers ) }}
{{ include "django-production-chart.volumeMount" ( dict "root" $dot "name" $name "map" $map ) | indent 6 }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
