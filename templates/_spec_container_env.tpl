{{/*
Application container base spec environment variables
*/}}
{{- define "django-production-chart.specContainerEnv" -}}
env:
  - name: PORT
    value: {{ default 8000 .Values.containerPort | quote }}
  - name: RELEASE_ID
    value: {{ include "django-production-chart.releaseIdentifier" . }}
{{- if .Values.certs.mounted }}
  - name: CERT_PATH
    value: {{ .Values.certs.certPath | quote }}
  - name: KEY_PATH
    value: {{ .Values.certs.keyPath | quote }}
{{- end }}
{{- if .Values.database.engine }}
  - name: DB
    value: {{ .Values.database.engine | quote }}
{{- end }}
{{- if .Values.database.secretName }}
  - name: DATABASE_USERNAME
    valueFrom:
      secretKeyRef:
        name: {{ .Values.database.secretName }}
        key: username
  - name: DATABASE_PASSWORD
    valueFrom:
      secretKeyRef:
        name: {{ .Values.database.secretName }}
        key: password
{{- end }}
{{- if .Values.database.name }}
  - name: DATABASE_DB_NAME
    value: {{ .Values.database.name | quote }}
{{- end }}
{{- if .Values.database.hostname }}
  - name: DATABASE_HOSTNAME
    value: {{ .Values.database.hostname | quote }}
{{- end }}
{{- if and .Values.cronjob.enabled .Values.metrics.enabled }}
  - name: PUSHGATEWAY
    value: {{ printf "%s-pushgateway" ( include "django-production-chart.releaseIdentifier" . ) }}
{{- end }}
{{- if .Values.memcached.enabled }}
  - name: MEMCACHED_SERVER_COUNT
    value: {{ .Values.memcached.replicaCount | quote }}
  - name: MEMCACHED_SERVER_SPEC
    value: {{ ( include "django-production-chart.releaseIdentifier" . ) }}-memcached-{{ "{}" }}.{{ ( include "django-production-chart.releaseIdentifier" .) }}-memcached.{{ .Release.Namespace }}.svc.cluster.local
{{- end }}
{{- range .Values.environmentVariablesSecrets }}
  - name: {{ .name }}
    valueFrom:
      secretKeyRef:
        name: {{ .secretName }}
        key: {{ .secretKey }}
{{- end }}
{{ toYaml .Values.environmentVariables | indent 2 }}
{{- end -}}
