{{/*
Application container base spec environment variables
*/}}
{{ $_ := set .Values "releaseIdentifier" ( include "django-production-chart.releaseIdentifier" . ) }}
{{ $_ := set .Values "namespaceIdentifier" ( include "django-production-chart.namespaceIdentifier" . ) }}
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
    value: {{ .Values.releaseIdentifier }}-pushgateway
{{- end }}
{{- if .Values.memcached.enabled }}
  - name: MEMCACHED_SERVER_COUNT
    value: {{ .Values.memcached.replicaCount | quote }}
  - name: MEMCACHED_SERVER_SPEC
{{- $memcachedName := printf "%s-memcached" .Values.releaseIdentifier }}
{{- if and .Values.namespace .Values.namespace.enabled }}
{{- $memcachedName = "memcached" }}
{{- end }}
    value: {{ $memcachedName }}-{{ "{}" }}.{{ .Values.releaseIdentifier }}-memcached.{{ .Values.namespaceIdentifier }}.svc.cluster.local
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
