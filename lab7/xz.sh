kubectl expose deployment stateless-app --port=80 --type=ClusterIP --name=stateless-svc

kubectl get svc stateless-svc

# Then run this loop (from inside the node: vagrant ssh)
while true; do
  curl -s -o /dev/null -w "%{http_code}\n" http://<CLUSTER_IP>:80
  sleep 0.5
done

# Update the image — Deployment uses RollingUpdate strategy by default
kubectl set image deployment/stateless-app nginx=nginx:1.26

# Watch the rollout
kubectl rollout status deployment/stateless-app

kubectl expose statefulset stateful-app --port=80 --name=stateful-svc-ext --type=ClusterIP

# Update
kubectl set image statefulset/stateful-app nginx=nginx:1.26
kubectl rollout status statefulset/stateful-app

# Rollback
kubectl rollout undo statefulset/stateful-app

#!/bin/bash
while true; do
  POD=$(kubectl get pods --all-namespaces --no-headers \
    | grep -v "kube-system" \
    | shuf -n 1)

  NAMESPACE=$(echo $POD | awk '{print $1}')
  POD_NAME=$(echo $POD | awk '{print $2}')

  if [ -n "$POD_NAME" ]; then
    echo "$(date): Killing pod $POD_NAME in $NAMESPACE"
    kubectl delete pod "$POD_NAME" -n "$NAMESPACE" --grace-period=0 --force
  fi

  sleep 1
done