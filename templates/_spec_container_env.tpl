{{/*
Application container base spec environment variables
*/}}
{{- define "django-production-chart.specContainerEnv" -}}
env:
  - name: PORT
    value: "8080"
{{- if .Values.certs.mounted }}
  - name: CERT_PATH
    value: {{ .Values.certs.certPath | quote }}
  - name: KEY_PATH
    value: {{ .Values.certs.keyPath | quote }}
{{- end }}
  - name: DB
    value: {{ .Values.database.engine | quote }}
{{- if (ne "sqlite3" .Values.database.engine) }}
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
  - name: DATABASE_DB_NAME
    value: {{ .Values.database.name | quote }}
  - name: DATABASE_HOSTNAME
    value: {{ .Values.database.hostname | quote }}
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
