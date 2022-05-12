{{/*
Resource labels
*/}}
{{- define "django-production-chart.resourceLabels" -}}
{{- $labelPrefix := "axdd.s.uw.edu" -}}
{{- $billingCodes := dict "admissions-cohort-manager" "830" "axdd-components" "629" "bridge" "788" "canvas" "742" "canvas-analytics" "786" "canvas-login-statics" "742" "catalyst" "522"  "coda" "787" "compass" "786" "course-roster" "742" "course-users" "742" "dawgpath" "786" "eventcal" "517" "github-inventory" "629" "gradepage" "787" "grading-standards" "742" "infohub" "742" "interview-db" "787" "jira-webhook" "629" "libguides" "742" "linkbot" "629" "mailman-core" "762" "mailman-web" "762" "mdot" "629" "mdot-rest" "629" "myuw" "554" "prt" "629" "retention-dashboard" "786" "retention-data-pipeline" "786" "scheduler" "740" "scout" "787" "scout-manager" "787" "spotseeker" "787" "uw-foodalert" "787" "uwperson" "786" "vax-status-listener" "830" "zoom-login-statics" "629" -}}
{{- $billingNames := dict "517" "campus-events-calendar-trumba" "522" "catalyst-tools" "554" "enterprise-portal-myuw" "629" "campus-technology-support" "740" "lecture-capture-panopto" "742" "learning-management-systems-canvas" "762" "email-lists-mailman" "785" "student-experience-applications" "786" "student-instructor-success-analytics" "787" "student-engagement-tools" "788" "training-management-system-bridge" "828" "research-technologies-teaching-learning" "830" "admissions-enrollment-management-tools" -}}
{{- $code := get $billingCodes .Release.Name -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ include "django-production-chart.chart" . }}
{{ printf "%s/%s" $labelPrefix "billing-code"}}: {{ $code | quote }}
{{ printf "%s/%s" $labelPrefix "billing-name"}}: {{ get $billingNames $code | quote }}
{{- range $key, $value := .Values.labels }}
{{ printf "%s/%s" $labelPrefix $key }}: {{ $value | quote }}
{{- end }}
{{- end -}}
