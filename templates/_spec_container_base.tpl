{{/*
Application container spec base
*/}}
{{- define "django-production-chart.specContainerBase" -}}
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
containers:
  - name: {{ include "django-production-chart.releaseIdentifier" . }}
    image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
    imagePullPolicy: "Always"
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
{{- end -}}
