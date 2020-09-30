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
{{- if .Values.memcached.enabled }}
{{- if .Values.memcached.mcrouter.enabled }}
  - name: MEMCACHED_SERVER_COUNT
    value: "1"
  - name: MEMCACHED_SERVER_SPEC
    value: {{ ( include "django-production-chart.releaseIdentifier" . ) }}-mcrouter.{{ .Release.Namespace }}.svc.cluster.local:{{ default 5000 .Values.memcached.mcrouter.params.port }}
{{- else }}
  - name: MEMCACHED_SERVER_COUNT
    value: {{ .Values.memcached.replicaCount | quote }}
  - name: MEMCACHED_SERVER_SPEC
    value: {{ ( include "django-production-chart.releaseIdentifier" . ) }}-memcached-{{ "{}" }}.{{ ( include "django-production-chart.releaseIdentifier" .) }}-memcached.{{ .Release.Namespace }}.svc.cluster.local
{{- end }}
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
