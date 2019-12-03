{{/*
Application container spec base
*/}}
{{- define "django-production-chart.specContainerBase" -}}
{{- if .Values.certs.mounted }}
volumes:
  - name: certs-volume
    secret:
      secretName: {{ .Values.certs.secretName | quote }}
{{- end }}
containers:
  - name: {{ include "django-production-chart.releaseIdentifier" . }}
    image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
    imagePullPolicy: "Always"
{{- if .Values.certs.mounted }}
    volumeMounts:
      - name: certs-volume
        readOnly: true
        mountPath: "/certs"
{{- end }}
{{- end -}}
