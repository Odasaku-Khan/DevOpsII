kubectl patch svc authentik -n authentik --type=merge \
  -p '{"spec":{"selector":{"app.kubernetes.io/name":"authentik","app.kubernetes.io/component":"server","version":"green"}}}'

kubectl get endpoints authentik -n authentik

kubectl patch svc authentik -n authentik --type=merge \
  -p '{"spec":{"selector":{"app.kubernetes.io/name":"authentik","app.kubernetes.io/component":"server","version":"blue"}}}'

kubectl get endpoints authentik -n authentik