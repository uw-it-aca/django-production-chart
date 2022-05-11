{{/*
Resource labels
*/}}
{{- define "django-production-chart.resourceLabels" -}}
{{- $labelPrefix := "axdd.s.uw.edu" -}}
{{- $billingNames := dict "517" "campus-events-calendar-trumba" "522" "catalyst-tools" "554" "enterprise-portal-myuw" "629" "campus-technology-support" "740" "lecture-capture-panopto" "742" "learning-management-systems-canvas" "762" "email-lists-mailman" "785" "student-experience-applications" "786" "student-instructor-success-analytics" "787" "student-engagement-tools" "788" "training-management-system-bridge" "828" "research-technologies-teaching-learning" "830" "admissions-enrollment-management-tools" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ include "django-production-chart.chart" . }}
{{- range $key, $value := .Values.labels }}
{{ printf "%s/%s" $labelPrefix $key }}: {{ $value | quote }}
{{- if eq "billing-code" $key }}
{{ printf "%s/%s" $labelPrefix "billing-name"}}: {{ get $billingNames $value | quote }}
{{- end }}
{{- end -}}
{{- end -}}
