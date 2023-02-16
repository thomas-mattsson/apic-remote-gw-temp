provider "kustomization" {
  kubeconfig_raw = var.kubeconfig
}

data "kustomization_build" "cert-manager" {
  path = "../components/cert-manager/base"
}

# Ensure namespace is created first
resource "kustomization_resource" "certmanager-namespace" {
  for_each = { for id in data.kustomization_build.cert-manager.ids: id => id if length(regexall("/Namespace/", id)) > 0 }

  manifest = data.kustomization_build.cert-manager.manifests[each.value]
}

resource "kustomization_resource" "cert-manager" {
  depends_on = [
    kustomization_resource.certmanager-namespace
  ]

  for_each = { for id in data.kustomization_build.cert-manager.ids: id => id if length(regexall("/Namespace/", id)) == 0 }

  manifest = data.kustomization_build.cert-manager.manifests[each.value]
  wait = true
}

resource "random_password" "password" {
  length = 16
  special = true
  override_special = "_%@"
}

data "kustomization_overlay" "api-connect-operator" {
  resources = [
    "../components/api-connect-operator/base"
  ]

  # Disable webhooks to allow dry-runs
  patches {
    target {
      kind = "ValidatingWebhookConfiguration"
      name = "ibm-apiconnect-validating-webhook-configuration"
    }
    patch = <<-EOF
      - op: replace
        path: /webhooks/0/failurePolicy
        value: Ignore
      - op: replace
        path: /webhooks/2/failurePolicy
        value: Ignore
    EOF
  }

  patches {
    target {
      kind = "MutatingWebhookConfiguration"
      name = "ibm-apiconnect-mutating-webhook-configuration"
    }
    patch = <<-EOF
      - op: replace
        path: /webhooks/0/failurePolicy
        value: Ignore
      - op: replace
        path: /webhooks/1/failurePolicy
        value: Ignore
    EOF
  }

  namespace = var.namespace
}

resource "kustomization_resource" "namespace" {
  for_each = { for id in data.kustomization_overlay.api-connect-operator.ids: id => id if length(regexall("/Namespace/", id)) > 0 }

  manifest =  data.kustomization_overlay.api-connect-operator.manifests[each.value]
}

resource "kustomization_resource" "admin-secret" {
  depends_on = [
    kustomization_resource.namespace
  ]

  manifest = jsonencode({
    apiVersion = "v1"
    kind = "Secret"
    metadata = {
      name = "admin-credentials"
      namespace = var.namespace
    }
    data = {
      password = base64encode(random_password.password.result)
    }
  })
}

resource "kustomization_resource" "apimanager-ca" {
  depends_on = [
    kustomization_resource.namespace
  ]

  manifest = jsonencode({
    apiVersion = "v1"
    kind = "Secret"
    metadata = {
      name = "apimanager-ca"
      namespace = var.namespace
    }
    data = {
      "apimanager.crt"=sensitive(base64encode(file(var.apimanager-ca-file)))
    }
  })
}

resource "kustomization_resource" "entitlement-key" {
  depends_on = [
    kustomization_resource.namespace
  ]

  manifest = jsonencode({
    apiVersion = "v1"
    kind = "Secret"
    metadata = {
      name = "ibm-entitlement-key"
      namespace = var.namespace
    }
    type = "kubernetes.io/dockerconfigjson"
    data = {
      ".dockerconfigjson" = base64encode(jsonencode({
        auths = {
          "cp.icr.io" = {
            username = "cp"
            password = var.entitlement-key
            email    = ""
            auth     = base64encode("cp:${var.entitlement-key}")
          }
        }
      }))
    }
  })
}

resource "kustomization_resource" "api-connect-operator" {
  depends_on = [
    kustomization_resource.cert-manager,
    kustomization_resource.admin-secret,
    kustomization_resource.entitlement-key,
    kustomization_resource.apimanager-ca
  ]

  for_each = { for id in data.kustomization_overlay.api-connect-operator.ids: id => id if length(regexall("/Namespace/", id)) == 0 }

  manifest =  data.kustomization_overlay.api-connect-operator.manifests[each.value]

  wait = true
}

data "kustomization_overlay" "api-connect-operands" {
  resources = [
    "../env/${var.cloudprovider}/nonprod/gatewaycluster",
    "../env/${var.cloudprovider}/nonprod/analyticscluster"
  ]

  patches {
    target {
      kind = "AnalyticsCluster"
      name = "analytics"
    }
    patch = <<-EOF
      - op: replace
        path: /spec/ingestion/endpoint/hosts/0/name
        value: "ai.${var.ingress-subdomain}"
    EOF
  }

  patches {
    target {
      kind = "GatewayCluster"
      name = "gateway-cluster"
    }
    patch = <<-EOF
      - op: replace
        path: /spec/gatewayEndpoint/hosts/0/name
        value: "gw.${var.ingress-subdomain}"
      - op: replace
        path: /spec/gatewayManagerEndpoint/hosts/0/name
        value: "gwd.${var.ingress-subdomain}"
    EOF
  }

  namespace = var.namespace
}

resource "kustomization_resource" "api-connect-operands" {
  depends_on = [
    kustomization_resource.api-connect-operator
  ]

  for_each = toset([
    "_/ConfigMap/${var.namespace}/gwd-add-apimgmt-ca",
    "gateway.apiconnect.ibm.com/GatewayCluster/${var.namespace}/gateway-cluster",
    "analytics.apiconnect.ibm.com/AnalyticsCluster/${var.namespace}/analytics"
  ])

  manifest = data.kustomization_overlay.api-connect-operands.manifests[each.value]
}
