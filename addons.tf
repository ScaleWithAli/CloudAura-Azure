resource "helm_release" "argo_cd" {
  name             = "argo-cd"
  chart            = "argo-cd"
  repository       = "https://argoproj.github.io/argo-helm"
  namespace        = "argocd"
  create_namespace = true
  values           = [yamlencode(local.app_values.argocd)]
  depends_on       = [helm_release.ingress_nginx]
}

resource "helm_release" "argo_rollouts" {
  name       = "argo-rollouts"
  chart      = "argo-rollouts"
  repository = "https://argoproj.github.io/argo-helm"
  namespace  = "argocd"
  values     = [yamlencode(local.app_values.argo_rollouts)]
  depends_on = [helm_release.argo_cd]
}

resource "helm_release" "kube_prometheus_stack" {
  name             = "kube-prometheus-stack"
  chart            = "kube-prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  namespace        = "kube-prometheus-stack"
  create_namespace = true
  values           = [yamlencode(local.app_values.prometheus)]
  depends_on       = [helm_release.ingress_nginx]
}

resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = "v1.17.2"
  namespace        = "cert-manager"
  create_namespace = true
  timeout          = 600
  values = [yamlencode({
    crds = { enabled = true }
  })]
  depends_on = [azurerm_kubernetes_cluster.main]
}

resource "kubectl_manifest" "cluster_issuer" {
  yaml_body = <<-YAML
    apiVersion: cert-manager.io/v1
    kind: ClusterIssuer
    metadata:
      name: letsencrypt-prod
    spec:
      acme:
        server: https://acme-v02.api.letsencrypt.org/directory
        email: m.ali.hassan.devops@gmail.com
        privateKeySecretRef:
          name: letsencrypt-prod
        solvers:
        - http01:
            ingress:
              class: nginx
  YAML
  depends_on = [helm_release.cert_manager]
}

resource "helm_release" "argocd_image_updater" {
  name             = "argocd-image-updater"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argocd-image-updater"
  namespace        = "argocd"
  create_namespace = false

  values = [yamlencode({
    serviceAccount = {
      create = true
      name   = "argocd-image-updater-sa"
      annotations = {
        "azure.workload.identity/client-id" = azurerm_user_assigned_identity.image_updater.client_id
      }
    }
    config = {
      registries = [{
        name    = "ACR"
        api_url = "https://cloudaura.azurecr.io"
        prefix  = "cloudaura.azurecr.io"
        ping    = true
        default = true
      }]
    }
    authScripts = {
      enabled = true
      scripts = {
        "acr-login.sh" = <<-EOF
          #!/bin/sh
          TOKEN=$(az acr login --name cloudaura --expose-token --output tsv --query accessToken)
          echo "00000000-0000-0000-0000-000000000000:$TOKEN"
        EOF
      }
    }
  })]

  depends_on = [helm_release.argo_cd, azurerm_federated_identity_credential.image_updater]
}

resource "helm_release" "istio_base" {
  name             = "istio-base"
  repository       = "https://istio-release.storage.googleapis.com/charts"
  chart            = "base"
  namespace        = "istio-system"
  create_namespace = true
  depends_on       = [azurerm_kubernetes_cluster.main]
}

resource "helm_release" "istiod" {
  name       = "istiod"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "istiod"
  namespace  = "istio-system"
  values = [yamlencode({
    meshConfig = {
      defaultConfig = {
        holdApplicationUntilProxyStarts = true
      }
    }
  })]
  depends_on = [helm_release.istio_base]
}
