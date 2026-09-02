resource "helm_release" "ingress_nginx" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true

  values = [yamlencode({
    controller = {
      replicaCount = 2
      service = {
        type = "LoadBalancer"
        annotations = {
          "service.beta.kubernetes.io/azure-load-balancer-health-probe-request-path" = "/healthz"
        }
      }
    }
  })]

  depends_on = [azurerm_kubernetes_cluster.main]
}

resource "helm_release" "external_secrets" {
  name             = "external-secrets"
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  namespace        = "external-secrets"
  create_namespace = true
  depends_on       = [azurerm_kubernetes_cluster.main]
}

resource "kubectl_manifest" "cluster_secret_store" {
  yaml_body = <<-YAML
    apiVersion: external-secrets.io/v1beta1
    kind: ClusterSecretStore
    metadata:
      name: azure-keyvault-store
    spec:
      provider:
        azurekv:
          tenantId: "${data.azurerm_client_config.current.tenant_id}"
          vaultUrl: "${azurerm_key_vault.main.vault_uri}"
          authType: WorkloadIdentity
          serviceAccountRef:
            name: external-secrets-sa
            namespace: external-secrets
  YAML

  depends_on = [helm_release.external_secrets, azurerm_key_vault.main]
}
