kubectl set env daemonset/calico-node -n kube-system IP_AUTODETECTION_METHOD=can-reach=8.8.8.8
kubectl delete -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.2/manifests/calico.yaml
sudo rm -rf /etc/cni/net.d/
sudo rm -rf /var/lib/calico/
 curl -L https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml -o kube-flannel.yml
sed -i 's/10.244.0.0\/16/192.168.0.0\/16/g' kube-flannel.yml
kubectl apply -f kube-flannel.yml
sudo rm -f /run/flannel/subnet.env
sudo rm -f /etc/cni/net.d/10-flannel.conflist
sudo ip link delete flannel.1 || true
kubectl get cm -n kube-flannel kube-flannel-cfg -o yaml
kubectl delete pod -n kube-flannel -l app=flannel

sudo rm -rf /var/lib/cni/networks/cbr0/*
sudo rm -rf /var/lib/cni/cache/*

sudo systemctl restart containerd
sudo systemctl restart kubelet

kubectl scale statefulset keycloak -n keycloak --replicas=1

kubectl port-forward -n keycloak svc/keycloak 8080:8080 --address 0.0.0.0
kubectl port-forward -n keycloak svc/keycloak 8080:8080 --address 0.0.0.0
kubectl port-forward -n keycloak svc/keycloak 8080:8080 --address 0.0.0.0
kubectl port-forward -n keycloak svc/keycloak 8080:8080 --address 0.0.0.0

GWdO8nnAX5sNf1C7CjxmqEjNN8PNuvDG
Khan Admins
Khan1996
tatsumi_645 Devs
645Killer

sudo nano /etc/kubernetes/manifests/kube-apiserver.yaml

cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: oidc-admin-binding
subjects:
- kind: Group
  name: Admins
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io
EOF

cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: keycloak-admin-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: Group
  name: Admins
  apiGroup: rbac.authorization.k8s.io
EOF

kubectl patch svc keycloak -n keycloak -p '{"spec": {"type": "NodePort"}}'
kubectl get svc -n keycloak keycloak

curl -I http://10.0.2.15:32642/realms/K8s/.well-known/openid-configuration

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key -out tls.crt \
  -subj "/CN=10.0.2.15" \
  -addext "subjectAltName = IP:10.0.2.15,IP:10.96.92.248"

sudo mkdir -p /etc/kubernetes/pki/oidc
sudo cp tls.crt /etc/kubernetes/pki/oidc/keycloak.crt

kubectl create secret tls keycloak-tls-secret \
  --cert=tls.crt \
  --key=tls.key \
  -n keycloak

kubectl edit statefulset keycloak -n keycloak
volumeMounts:
        - name: certs
          mountPath: /etc/x509/https
          readOnly: true

volumes:
      - name: certs
        secret:
          secretName: keycloak-tls-secret

containerPort: 8443 
          name: https

kubectl patch svc keycloak -n keycloak --type='json' -p='[{"op": "replace", "path": "/spec/ports/0/targetPort", "value": 8443}]'
kubectl patch svc keycloak -n keycloak --type='json' -p='[{"op": "replace", "path": "/spec/ports/0/targetPort", "value": 8443}]'

kubectl patch svc keycloak -n keycloak --type='json' -p='[{"op": "replace", "path": "/spec/ports", "value": [{"name": "https", "port": 8443, "targetPort": 8443, "nodePort": 32642}]}]'

kubectl patch sts keycloak -n keycloak --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/readinessProbe/httpGet/scheme", "value": "HTTPS"},
  {"op": "replace", "path": "/spec/template/spec/containers/0/livenessProbe/httpGet/scheme", "value": "HTTPS"},
  {"op": "replace", "path": "/spec/template/spec/containers/0/startupProbe/httpGet/scheme", "value": "HTTPS"}
]'

kubectl patch sts keycloak -n keycloak --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/readinessProbe/httpGet/scheme", "value": "HTTPS"},
  {"op": "replace", "path": "/spec/template/spec/containers/0/livenessProbe/httpGet/scheme", "value": "HTTPS"},
  {"op": "replace", "path": "/spec/template/spec/containers/0/startupProbe/httpGet/scheme", "value": "HTTPS"}
]'

sudo mkdir -p /etc/kubernetes/pki/oidc
sudo cp tls.crt /etc/kubernetes/pki/oidc/keycloak.crt

POD_NAME=$(kubectl get pods -n keycloak -l app=keycloak -o jsonpath='{.items[0].metadata.name}')

cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: oidc-admin-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: User
  name: khan
  apiGroup: rbac.authorization.k8s.io
EOF

http://keycloak.10.0.2.15.nip.io/admin