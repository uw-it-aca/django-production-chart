{{/* Helper definitions to inject HTTP proxy server and config with default nginx. */}}

{{- define "django-production-chart.proxyServerConfigMapName" -}}
proxy-server
{{- end -}}

{{/*
Values to overlay on a copy of the root Values for the main workload (deployment
or statefulset): sidecarContainers and podVolumes with the proxy-server
components merged in. User-supplied entries win. Never mutates .Values, so other
workloads (release job, cronjobs, daemons) are unaffected.

Usage (see deployment.yaml, statefulset.yaml): overlay this onto a deepCopy of
.Values, build a local context from it, and pass that context instead of . to
the spec includes.
*/}}
{{- define "django-production-chart.proxyServerValues" -}}
sidecarContainers:
{{ merge ( deepCopy ( $.Values.sidecarContainers | default dict ) ) ( fromYaml ( include "django-production-chart.proxyServerSidecar" . ) ) | toYaml | indent 2 }}
podVolumes:
{{ merge ( deepCopy ( $.Values.podVolumes | default dict ) ) ( fromYaml ( include "django-production-chart.proxyServerPodVolume" . ) ) | toYaml | indent 2 }}
{{- end -}}

{{/*
App-specific nginx locations, included in the server block. Defaults to serving
the app image's /static.
*/}}
{{- define "django-production-chart.proxyServerLocations" -}}
{{- if $.Values.proxyServer.locations -}}
{{ $.Values.proxyServer.locations }}
{{- else -}}
location /static {
  alias /static;
  access_log off;
  expires 30d;
}
{{- end -}}
{{- end -}}

{{/*
Define nginx.conf appropriate for default proxy-sidecar
*/}}
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
      # readiness: passes through to the app over the socket. Any answer below
      # 500 means gunicorn is serving; 5xx, including nginx's own 502 while the
      # socket is missing, is not intercepted and fails the probe.
      location = {{ $.Values.proxyServer.readinessPath }} {
        access_log off;
        proxy_set_header Host $http_host;
        proxy_pass http://app_server{{ $.Values.proxyServer.readinessAppPath }};
        proxy_intercept_errors on;
        error_page 300 301 302 303 304 307 308 400 401 402 403 404 405 406 408 409 410 411 412 413 414 415 416 417 418 421 422 423 424 425 426 428 429 431 451 =200 @ready_ok;
      }
      location @ready_ok {
        return 200;
      }
{{ include "django-production-chart.proxyServerLocations" . | indent 6 }}
      location / {
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
Proxy server sidecar container settings.
By default, defines an nginx proxy sidecar. The app image's /static is mounted
read-only into it as an image volume (no copy).
*/}}
{{- define "django-production-chart.proxyServerSidecar" -}}
{{- if .Values.proxyServer.sidecar }}
{{ toYaml .Values.proxyServer.sidecar }}
{{- else }}
proxy-server:
  image: nginx/nginx-unprivileged:stable
  imagePullPolicy: Always
  restartPolicy: Always
  resources:
{{ toYaml $.Values.proxyServer.resources | indent 4 }}
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
      path: {{ $.Values.proxyServer.readinessPath }}
      port: http
    initialDelay: 2
{{- end }}
{{- end -}}

{{/*
Default proxy server sidecar container definition
*/}}
{{- define "django-production-chart.proxyServerSidecarDefault" -}}
{{- end -}}

{{/*
Proxy server podVolumes: nginx configmap, gunicorn socket, paths from the app image
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
{{- range $i, $p := $.Values.proxyServer.appImagePaths }}
proxy-server-image-{{ $i }}:
  volume:
    image:
      reference: {{ printf "%s:%s" $.Values.image.repository $.Values.image.tag }}
      pullPolicy: IfNotPresent
  mount:
    mountPath: {{ $p.mountPath }}
    subPath: {{ $p.path }}
    readOnly: true
  containers: [ proxy-server ]
{{- end }}
{{- end -}}
