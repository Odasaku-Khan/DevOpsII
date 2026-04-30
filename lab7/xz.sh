kubectl expose deployment nginx-deployment --port=80 --type=ClusterIP --name=nginx-svc
NGINX_IP=$(kubectl get svc nginx-svc -o jsonpath='{.spec.clusterIP}')

while true; do
  curl -s -o /dev/null -w "%{http_code}\n" http://$NGINX_IP:80
  sleep 0.5
done

kubectl set image deployment/nginx-deployment nginx=nginx:1.24
kubectl rollout status deployment/nginx-deployment

kubectl rollout undo deployment/nginx-deployment
kubectl rollout history deployment/nginx-deployment


kubectl set image statefulset/redis-statefulset redis=redis:7.2
kubectl rollout status statefulset/redis-statefulset
kubectl rollout undo statefulset/redis-statefulset

#!/bin/bash
while true; do
  POD_INFO=$(kubectl get pods --all-namespaces --no-headers \
    | grep -v "kube-system" | shuf -n 1)

  NS=$(echo $POD_INFO | awk '{print $1}')
  POD=$(echo $POD_INFO | awk '{print $2}')

  if [ -n "$POD" ]; then
    echo "$(date): Deleting $POD in $NS"
    kubectl delete pod "$POD" -n "$NS" --grace-period=0 --force 2>/dev/null
  fi

  sleep 1
done
kubectl expose daemonset node-exporter-daemonset --port=9100 --type=ClusterIP --name=node-exporter-svc