{{/* Helper definitions to inject HTTP proxy server and config with default nginx. */}}

{{- define "django-production-chart.proxyServerConfigMapName" -}}
proxy-server
{{- end -}}

{{- define "django-production-chart.injectProxyServerSidecar" -}}
{{/*
Inject proxy server container into containerContainers
*/}}
{{ $sidecars := merge ( $.Values.sidecarContainers | default dict ) ( fromYaml ( include "django-production-chart.proxyServerSidecar" . ) ) }}
{{ $_ := set $.Values "sidecarContainers" $sidecars }}
{{/*
Inject proxy server volume mounts into podVolumes
*/}}
{{ $podvolumes := merge ( .Values.podVolumes | default dict ) ( fromYaml ( include "django-production-chart.proxyServerPodVolume" . ) ) }}
{{ $_ := set $.Values "podVolumes" $podvolumes }}
{{- end -}}

{{- define "django-production-chart.proxyDefaultConfigMap" -}}
nginx.conf: |
  worker_processes 1;
  error_log  /dev/stderr notice;
  pid /tmp/nginx.pid;
  events {
    worker_connections 5000;
    accept_mutex off; # set to 'on' if nginx worker_processes > 1
  }
  http {
    proxy_temp_path /tmp/proxy_temp;
    client_body_temp_path /tmp/client_temp;
    fastcgi_temp_path /tmp/fastcgi_temp;
    uwsgi_temp_path /tmp/uwsgi_temp;
    scgi_temp_path /tmp/scgi_temp;
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';
    access_log /dev/stdout main;
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    sendfile on;
    upstream app_server {
      server unix:/var/run/gunicorn/gunicorn.sock fail_timeout=0;
    }
    map $http_x_forwarded_proto $xfproto {
      default $http_x_forwarded_proto;
      ''      $scheme;
    }
    server {
      listen {{ $.Values.proxyServer.servicePort }} default_server;
      charset utf-8;
      underscores_in_headers on;
      port_in_redirect off;
      client_max_body_size 4G;
      location = /favicon.ico {
          return 204;
      }
      location {{ $.Values.proxyServer.serviceProbePath }} {
        return 200;
      }
      # include for app-specific location config
      location /media  {
        alias /common/media;
      }
      location /static {
        alias /common/static;
        access_log off;
        expires 30d;
      }
      location / {
        # checks for static file, if not found proxy to app
        try_files $uri @proxy_to_app;
      }
      location @proxy_to_app {
        proxy_pass_request_headers on;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $xfproto;
        proxy_set_header Host $http_host;
        proxy_redirect off;
        proxy_pass http://app_server;
      }
    }
  }
{{- end -}}

{{/*
Proxy server sidecar container settings
*/}}
{{- define "django-production-chart.proxyServerSidecar" -}}
{{- if .Values.proxyServer.sidecar }}
{{ toYaml .Values.proxyServer.sidecar }}
{{- else }}
proxy-server-statics:
  image: {{ printf "%s:%s" $.Values.image.repository $.Values.image.tag }}
  imagePullPolicy: Always
  restartPolicy: Never
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
  command:
    - "sh"
    - "-c"
    - |
      if [ -d /statics ] ; then
        cp -r /statics/. /common/static
      fi
      if [ -d /media ] ; then
        cp -r /media/. /common/media
      fi
proxy-server:
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
{{- end }}
{{- end -}}

{{/*
Default proxy server sidecar container definition
*/}}
{{- define "django-production-chart.proxyServerSidecarDefault" -}}
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
    mountPath: /etc/nginx/nginx.conf
    subPath: nginx.conf
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
    mountPath: /common/static
  containers: [ base, proxy-server, proxy-server-statics ]
proxy-server-media:
  volume:
    emptyDir: {}
  mount:
    mountPath: /common/media
  containers: [ base, proxy-server, proxy-server-statics ]
{{- end -}}
