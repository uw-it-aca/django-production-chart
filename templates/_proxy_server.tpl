{{/* Defines default nginx config */}}

{{- define "django-production-chart.proxyServerConfigMapName" -}}
proxy-server
{{- end -}}

{{- define "django-production-chart.proxyDefaultConfigMap" -}}
nginx.conf: |
  upstream app_server {
    server unix:/var/run/gunicorn/gunicorn.sock;
  }
  map $http_x_forwarded_proto $xfproto {
    default $http_x_forwarded_proto;
    ''      $scheme;
  }
  server {
      listen 8080;
      charset utf-8;
      underscores_in_headers on;
      port_in_redirect off;
      client_max_body_size 4G;
      access_log /dev/stdout main;
      error_log  /dev/stderr notice;
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
          location {{ $.Values.proxyServer.serviceProbePath }} {
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
Proxy server sidecar container settings
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
Default proxy server sidecar container definition
*/}}
{{- define "django-production-chart.proxyServerSidecarDefault" -}}
image: nginx/nginx-unprivileged:stable
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
  runAsNonRoot: true
  runAsUser: 1000
  runAsGroup: 1000
  allowPrivilegeEscalation: false
  capabilities:
    drop:
      - ALL
ports:
  - containerPort: {{ $.Values.proxyServer.servicePort }}
    protocol: TCP
    name: http
liveness:
  enabled: true
  httpGet:
    path: {{ $.Values.proxyServer.serviceProbePath }}
    port: http
readiness:
  enabled: true
  httpGet:
    path: {{ $.Values.proxyServer.serviceProbePath }}
    port: http
  initialDelaySeconds: 2
{{- end -}}

{{/*
Proxy server podVolumes for nginx configmap and /static volume from app container
*/}}
{{- define "django-production-chart.proxyServerPodVolume" -}}
proxy-server-config:
  volume:
    configMap:
      name: {{ include "django-production-chart.proxyServerConfigMapName" . }}
  mount:
    mountPath: /etc/nginx/conf.d
  containers: [ proxy-server ]
proxy-server-socket:
  volume:
    emptyDir: {}
  mount:
    mountPath: /var/run/gunicorn
  containers: [ base, proxy-server ]
proxy-server-statics:
  volume:
    emptyDir: {}
  mount:
    mountPath: /static
    readOnly: true
  containers: [ base, proxy-server ]
proxy-server-media:
  volume:
    emptyDir: {}
  mount:
    mountPath: /media
    readOnly: true
  containers: [ base, proxy-server ]
{{- end -}}
