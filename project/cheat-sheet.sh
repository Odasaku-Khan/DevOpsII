kubectl patch svc authentik -n authentik --type='json' -p='[
  {
    "op": "replace",
    "path": "/spec/selector",
    "value": {
      "app.kubernetes.io/name": "authentik",
      "app.kubernetes.io/component": "server",
      "app.kubernetes.io/instance": "authentik-green"
    }
  }
]'


kubectl scale deployment authentik-blue-server -n authentik --replicas=0
kubectl scale deployment authentik-blue-worker -n authentik --replicas=0
kubectl scale deployment authentik-green-server -n authentik --replicas=1
kubectl scale deployment authentik-green-worker -n authentik --replicas=1
kubectl get endpoints authentik -n authentik

kubectl patch svc authentik -n authentik --type='json' -p='[
  {
    "op": "replace",
    "path": "/spec/selector",
    "value": {
      "app.kubernetes.io/name": "authentik",
      "app.kubernetes.io/component": "server",
      "app.kubernetes.io/instance": "authentik-blue"
    }
  }
]'


kubectl scale deployment authentik-blue-server -n authentik --replicas=1
kubectl scale deployment authentik-blue-worker -n authentik --replicas=1
kubectl scale deployment authentik-green-server -n authentik --replicas=0
kubectl scale deployment authentik-green-worker -n authentik --replicas=0

kubectl get endpoints authentik -n authentik