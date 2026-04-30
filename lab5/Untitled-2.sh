KHAN_TOKEN=$(curl -k -s -X POST https://keycloak.default.svc.cluster.local:8443/realms/K8s/protocol/openid-connect/token \
  -d "grant_type=password" \
  -d "client_id=kubernetes" \
  -d "client_secret=fwVGd4DYyMKSWqqC3ar5WuslHCvgErAD" \
  -d "username=khan" \
  -d "password=Khan1996" | jq -r .access_token)

  kubectl get nodes --token=$KHAN_TOKEN

RAW_JSON=$(curl -k -s -X POST https://keycloak.default.svc.cluster.local:8443/realms/K8s/protocol/openid-connect/token \
  -d "grant_type=password" \
  -d "client_id=kubernetes" \
  -d "client_secret=fwVGd4DYyMKSWqqC3ar5WuslHCvgErAD" \
  -d "username=tatsumi_645" \
  -d "password=645Killer")

ID_TOKEN=$(echo $RAW_JSON | jq -r .access_token)

kubectl auth can-i get nodes --as=tatsumi_645 --as-group=Devs