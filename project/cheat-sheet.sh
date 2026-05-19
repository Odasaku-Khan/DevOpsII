Blue active:

kubectl patch svc authentik -n authentik --type='merge' -p='
{"spec":{"selector":{
  "app.kubernetes.io/name":"authentik",
  "app.kubernetes.io/component":"server",
  "app.kubernetes.io/instance":"authentik-blue"
}}}'
kubectl -n demo-app patch svc protected-portal \
  -p '{"spec":{"selector":{"app":"protected-portal","version":"blue"}}}'

Green active:

kubectl patch svc authentik -n authentik --type='merge' -p='
{"spec":{"selector":{
  "app.kubernetes.io/name":"authentik",
  "app.kubernetes.io/component":"server",
  "app.kubernetes.io/instance":"authentik-green"
}}}'

kubectl -n demo-app patch svc protected-portal \
  -p '{"spec":{"selector":{"app":"protected-portal","version":"green"}}}'