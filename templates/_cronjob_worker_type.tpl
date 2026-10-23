{{/*
Resolves a cronjob job's "workerType" key (if set) to its preset defined in
.Values.cronjob.workerTypes. Fails with a clear error if the referenced
preset does not exist. Returns an empty dict if "workerType" is unset.
*/}}
{{- define "django-production-chart.cronjobWorkerType" -}}
{{- $root := .root -}}
{{- $job := .job -}}
{{- if $job.workerType -}}
{{- $workerType := index $root.Values.cronjob.workerTypes $job.workerType -}}
{{- if not $workerType -}}
{{- fail (printf "cronjob job %q references unknown workerType %q" $job.name $job.workerType) -}}
{{- end -}}
{{- $workerType | toYaml -}}
{{- else -}}
{{- dict | toYaml -}}
{{- end -}}
{{- end -}}

{{/*
Renders the pod-level scheduling fields (nodeSelector/tolerations/affinity)
from a resolved workerType preset.
*/}}
{{- define "django-production-chart.cronjobWorkerTypeScheduling" -}}
{{- with .nodeSelector -}}
nodeSelector:
{{- toYaml . | trim | nindent 2 }}
{{ end -}}
{{- with .tolerations -}}
tolerations:
{{- toYaml . | trim | nindent 2 }}
{{ end -}}
{{- with .affinity -}}
affinity:
{{- toYaml . | trim | nindent 2 }}
{{ end -}}
{{- end -}}
