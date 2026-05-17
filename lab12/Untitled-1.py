import json
import ssl
import time
import urllib.request
import urllib.error

API = "https://kubernetes.default.svc"
TOKEN_PATH = "/var/run/secrets/kubernetes.io/serviceaccount/token"
CA_PATH = "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"

SYSTEM_NS = {"default", "kube-system", "kube-public", "kube-node-lease"}

with open(TOKEN_PATH, "r") as f:
    TOKEN = f.read().strip()

CTX = ssl.create_default_context(cafile=CA_PATH)

def log(msg):
    print(msg, flush=True)

def request(method, path, body=None, content_type="application/json"):
    data = None
    headers = {"Authorization": "Bearer " + TOKEN}

    if body is not None:
        data = json.dumps(body).encode("utf-8")
        headers["Content-Type"] = content_type

    req = urllib.request.Request(
        API + path,
        data=data,
        headers=headers,
        method=method,
    )

    try:
        with urllib.request.urlopen(req, context=CTX, timeout=10) as resp:
            raw = resp.read().decode("utf-8")
            return resp.status, json.loads(raw) if raw else {}
    except urllib.error.HTTPError as e:
        raw = e.read().decode("utf-8")
        try:
            parsed = json.loads(raw) if raw else {}
        except Exception:
            parsed = {"raw": raw}
        return e.code, parsed

def create_or_patch(path, name, body):
    status, resp = request("POST", path, body)

    if status in [200, 201]:
        log("created " + name)
        return

    if status == 409:
        patch_path = path + "/" + body["metadata"]["name"]
        status, resp = request(
            "PATCH",
            patch_path,
            body,
            content_type="application/merge-patch+json",
        )
        if status in [200, 201]:
            log("patched " + name)
            return

    log("ERROR create_or_patch " + name + ": " + str(status) + " " + str(resp))

def ensure_namespace(ns):
    if ns in SYSTEM_NS:
        return

    role_path = f"/apis/rbac.authorization.k8s.io/v1/namespaces/{ns}/roles"
    rb_path = f"/apis/rbac.authorization.k8s.io/v1/namespaces/{ns}/rolebindings"

    view_rules = [{
        "apiGroups": ["", "apps", "batch"],
        "resources": ["pods", "pods/log", "services", "configmaps", "deployments", "replicasets", "jobs", "cronjobs"],
        "verbs": ["get", "list", "watch"]
    }]

    edit_rules = [{
        "apiGroups": ["", "apps", "batch"],
        "resources": ["pods", "pods/log", "services", "configmaps", "deployments", "replicasets", "jobs", "cronjobs"],
        "verbs": ["get", "list", "watch", "create", "update", "patch", "delete"]
    }]

    admin_rules = [{
        "apiGroups": ["*"],
        "resources": ["*"],
        "verbs": ["*"]
    }]

    roles = [
        ("namespace-view", view_rules),
        ("namespace-edit", edit_rules),
        ("namespace-admin", admin_rules),
    ]

    for role_name, rules in roles:
        create_or_patch(
            role_path,
            f"role {ns}/{role_name}",
            {
                "apiVersion": "rbac.authorization.k8s.io/v1",
                "kind": "Role",
                "metadata": {
                    "name": role_name,
                    "namespace": ns,
                    "labels": {"managed-by": "namespace-operator"}
                },
                "rules": rules
            }
        )

    bindings = [
        (f"{ns}-viewers", "namespace-view", f"{ns}:viewers"),
        (f"{ns}-editors", "namespace-edit", f"{ns}:editors"),
        (f"{ns}-admins", "namespace-admin", f"{ns}:admins"),
    ]

    for rb_name, role_name, group_name in bindings:
        create_or_patch(
            rb_path,
            f"rolebinding {ns}/{rb_name}",
            {
                "apiVersion": "rbac.authorization.k8s.io/v1",
                "kind": "RoleBinding",
                "metadata": {
                    "name": rb_name,
                    "namespace": ns,
                    "labels": {"managed-by": "namespace-operator"}
                },
                "subjects": [{
                    "kind": "Group",
                    "name": group_name,
                    "apiGroup": "rbac.authorization.k8s.io"
                }],
                "roleRef": {
                    "kind": "Role",
                    "name": role_name,
                    "apiGroup": "rbac.authorization.k8s.io"
                }
            }
        )

def pod_missing_resources(container):
    resources = container.get("resources") or {}
    requests = resources.get("requests") or {}
    limits = resources.get("limits") or {}

    return not (
        requests.get("cpu")
        and requests.get("memory")
        and limits.get("cpu")
        and limits.get("memory")
    )

def patch_pod(ns, name, metadata):
    path = f"/api/v1/namespaces/{ns}/pods/{name}"
    status, resp = request(
        "PATCH",
        path,
        {"metadata": metadata},
        content_type="application/merge-patch+json",
    )

    if status not in [200, 201]:
        log("ERROR patch pod " + ns + "/" + name + ": " + str(status) + " " + str(resp))

def ensure_pod_warning(pod):
    meta = pod.get("metadata") or {}
    spec = pod.get("spec") or {}

    ns = meta.get("namespace")
    name = meta.get("name")

    if ns in SYSTEM_NS:
        return

    containers = spec.get("containers") or []
    missing = [c.get("name", "unknown") for c in containers if pod_missing_resources(c)]

    if not missing:
        return

    annotations = meta.get("annotations") or {}

    if "operator/resource-warning" in annotations:
        return

    msg = "Missing CPU/memory requests or limits for containers: " + ", ".join(missing)

    patch_pod(ns, name, {
        "annotations": {
            "operator/resource-warning": msg
        }
    })

    log("annotated pod " + ns + "/" + name)

def debug_enabled(pod):
    meta = pod.get("metadata") or {}
    annotations = meta.get("annotations") or {}
    value = str(annotations.get("debug", "")).lower()
    return value in ["true", "yes", "1", "enabled"]

def first_port(pod):
    spec = pod.get("spec") or {}
    containers = spec.get("containers") or []

    for c in containers:
        for p in c.get("ports") or []:
            if p.get("containerPort"):
                return int(p.get("containerPort"))

    return 80

def ensure_debug_service(pod):
    meta = pod.get("metadata") or {}

    ns = meta.get("namespace")
    name = meta.get("name")

    if ns in SYSTEM_NS:
        return

    if not debug_enabled(pod):
        return

    svc_name = "debug-" + name
    port = first_port(pod)

    patch_pod(ns, name, {
        "labels": {
            "lab12-debug": name
        },
        "annotations": {
            "operator/debug-service": svc_name
        }
    })

    svc_path = f"/api/v1/namespaces/{ns}/services"

    service = {
        "apiVersion": "v1",
        "kind": "Service",
        "metadata": {
            "name": svc_name,
            "namespace": ns,
            "labels": {"managed-by": "namespace-operator"}
        },
        "spec": {
            "type": "NodePort",
            "selector": {
                "lab12-debug": name
            },
            "ports": [{
                "name": "debug",
                "protocol": "TCP",
                "port": port,
                "targetPort": port
            }]
        }
    }

    status, resp = request("POST", svc_path, service)

    if status in [200, 201]:
        log("created service " + ns + "/" + svc_name)
    elif status != 409:
        log("ERROR create service " + ns + "/" + svc_name + ": " + str(status) + " " + str(resp))

def reconcile():
    status, namespaces = request("GET", "/api/v1/namespaces")

    if status == 200:
        for ns_obj in namespaces.get("items", []):
            meta = ns_obj.get("metadata") or {}
            if not meta.get("deletionTimestamp"):
                ensure_namespace(meta.get("name"))

    status, pods = request("GET", "/api/v1/pods")

    if status == 200:
        for pod in pods.get("items", []):
            meta = pod.get("metadata") or {}
            if not meta.get("deletionTimestamp"):
                ensure_pod_warning(pod)
                ensure_debug_service(pod)

log("raw namespace controller started")

while True:
    try:
        reconcile()
    except Exception as e:
        log("ERROR loop: " + str(e))
    time.sleep(5)
