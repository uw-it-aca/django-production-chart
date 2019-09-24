{{/*
Application container base spec environment variables
*/}}
{{- define "django-production-chart.specContainerEnv" -}}
env:
{{- if .Values.certs.mounted }}
  - name: CERT_PATH
    value: {{ .Values.certs.certPath | quote }}
  - name: KEY_PATH
    value: {{ .Values.certs.keyPath | quote }}
{{- end }}
  - name: DB
    value: {{ .Values.database.engine | quote }}
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
  - name: ENV
    value: "prod"
  - name: PORT
    value: "8080"
  - name: DATABASE_DB_NAME
    value: {{ .Values.database.name | quote }}
  - name: DATABASE_HOSTNAME
    value: {{ .Values.database.hostname | quote }}
{{- range .Values.environmentVariablesSecrets }}
  - name: {{ .name }}
    valueFrom:
      secretKeyRef: 
        name: {{ .secretName }}
        key: {{ .secretKey }}
{{- end }}
{{ toYaml .Values.environmentVariables | indent 2 }}
{{- end -}}
