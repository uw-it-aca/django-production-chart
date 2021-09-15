{{/*
Resource labels
*/}}
{{- define "django-production-chart.resourceLabels" -}}
{{- $labelPrefix := "axdd.s.uw.edu" -}}
{{- $billingNames := dict "517" "Campus Events Calendar (Trumba)" "554" "Enterprise Portal (MyUW)" "740" "Lecture Capture (Panopto)" "742" "Learning Management Systems (Canvas)" "762" "Email Lists (Mailman)" "785" "Student Experience Applications" "786" "Student & Instructor Success Analytics" "787" "Student Engagement Tools" "788" "Training Management System (Bridge)" "830" "Admissions & Enrollment Management Tools" -}}
app.kubernetes.io/name: {{ include "django-production-chart.name" . }}
app.kubernetes.io/instance: {{ .Release.Name | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service | quote }}
helm.sh/chart: {{ include "django-production-chart.chart" . }}
{{- range $key, $value := .Values.labels }}
{{ printf "%s/%s" $labelPrefix $key }}: {{ $value | quote }}
{{- if eq "billing-code" $key }}
{{ printf "%s/%s" $labelPrefix "billing-name"}}: {{ get $billingNames $value | quote }}
{{- end }}
{{- end -}}
{{- end -}}
