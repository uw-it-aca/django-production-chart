{{/*
securityPolicy annotations
*/}}
{{- define "django-production-chart.securityPolicyAnnotations" -}}
{{- if (hasKey . "skipCheck") }}
# checkov securityPolicy exception supression
{{- range $index, $value:= .skipCheck }}
checkov.io/skip{{ add $index 1 }}: {{ $value | quote }}
{{- end }}
{{- end }}
{{- end -}}