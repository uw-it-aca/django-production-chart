{{/* Defines default nginx config */}}

{{- define "django-production-chart.proxyServerConfigMapName" -}}
proxy-server
{{- end -}}

{{- define "django-production-chart.proxyDefaultConfigMap" -}}
nginx.conf: |
  include /etc/nginx/mime.types;
  default_type application/octet-stream;
  sendfile on;
  upstream app_server {
      # All containers in the same pod are reachable with 127.0.0.1
      server 127.0.0.1:{{ .Values.proxyServer.appPort }} fail_timeout=0;
  }
  map $http_x_forwarded_proto $xfproto {
    default $http_x_forwarded_proto;
    ''      $scheme;
  }
  server {
      listen 80;
      charset utf-8;
      underscores_in_headers on;
      port_in_redirect off;
      client_max_body_size 4G;
      access_log stdout;
      error_log  stderr;
      location = /favicon.ico {
          return 204;
      }
      location /media  {
        alias /media;
      }
      location /static {
        alias /static;
        access_log off;
        expires 30d;
      }
      location / {
          location /static {
              add_header Access-Control-Allow-Origin *;
              add_header Access-Control-Max-Age 3600;
              add_header Access-Control-Expose-Headers Content-Length;
              add_header Access-Control-Allow-Headers Range;
              if ($request_method = OPTIONS) {
                  return 204;
              }
              try_files /$uri @django;
          }
          location /nghealth {
              return 200;
          }
          try_files $uri @django;
      }
      location @django {
          proxy_pass_request_headers on;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $xfproto;
          proxy_set_header Host $http_host;
          proxy_redirect off;
          proxy_pass http://app_server;
      }
  }
{{- end -}}

{{/*
Supply proxy server sidecar container settings
*/}}
{{- define "django-production-chart.proxyServerSidecar" -}}
proxy-server:
{{- if .Values.proxyServer.sidecar }}
{{ toYaml .Values.proxyServer.sidecar | indent 2}}
{{- else }}
{{ include "django-production-chart.proxyServerSidecarDefault" . | indent 2 }}
{{- end }}
{{- end -}}

{{/*
Default proxy server sidecar container settings
*/}}
{{- define "django-production-chart.proxyServerSidecarDefault" -}}
image: nginx:stable
imagePullPolicy: Always
restartPolicy: Always
resources:
  limits:
    cpu: 500m
    memory: 768Mi
  requests:
    cpu: 100m
    memory: 512Mi
securityContext:
  privileged: false
  allowPrivilegeEscalation: false
  capabilities:
    drop:
      - ALL
ports:
  - name: http
    containerPort: {{ $.Values.containerPort }}
    protocol: TCP
{{- end -}}

{{/*
Supply proxy server sidecar container settings
*/}}
{{- define "django-production-chart.proxyServerPodVolume" -}}
proxy-server:
  volume:
    configMap:
      name: {{ include "django-production-chart.proxyServerConfigMapName" . }}
  mount:
    mountPath: /etc/nginx/conf.d
  containers: [ proxy-server ]
{{- end -}}
