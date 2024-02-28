{{/*
Application container spec base
*/}}
{{- define "django-production-chart.specContainerBase" -}}
{{- $dot := . -}}
{{- $baseContainerName := ( include "django-production-chart.releaseIdentifier" . ) }}
{{- $containerName := default $baseContainerName .containerName }}
{{- $containerImage := default ( printf "%s:%s" .Values.image.repository .Values.image.tag ) .containerImage }}
containers:
  - name: {{ $containerName | quote }}
    image: {{ $containerImage| quote }}
    imagePullPolicy: "Always"
{{- if .Values.securityPolicy.enabled }}
    securityContext:
{{ include "django-production-chart.securityPolicyContext" .Values.securityPolicy.containerBase | indent 6 }}
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
{{- if or ( not ( hasKey $map "containers" ) ) ( and (has "base" $map.containers ) ( eq $baseContainerName  $containerName ) ) ( has $containerName $map.containers ) }}
{{ include "django-production-chart.volumeMount" ( dict "root" $dot "name" $name "map" $map ) | indent 6 }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
