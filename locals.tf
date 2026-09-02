locals {
  common_tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  system_scheduling = {
    nodeSelector = { role = "system" }
    tolerations = [{
      key      = "CriticalAddonsOnly"
      operator = "Equal"
      value    = "true"
      effect   = "NoSchedule"
    }]
  }

  app_values = {
    argocd = {
      global = {
        nodeSelector = {}
        tolerations  = []
      }
      server = {
        metrics = {
          enabled = true
          serviceMonitor = {
            enabled          = true
            namespace        = "kube-prometheus-stack"
            additionalLabels = {
              release = "kube-prometheus-stack"
            }
          }
        }
        ingress = {
          enabled          = true
          ingressClassName = "nginx"
          hostname         = "argocd.cloudaura.online"
          tls              = true
          annotations = {
            "cert-manager.io/cluster-issuer"               = "letsencrypt-prod"
            "nginx.ingress.kubernetes.io/backend-protocol" = "HTTPS"
            "nginx.ingress.kubernetes.io/ssl-redirect"     = "true"
          }
        }
      }
      controller = {
        metrics = {
          enabled = true
          serviceMonitor = {
            enabled          = true
            namespace        = "kube-prometheus-stack"
            additionalLabels = {
              release = "kube-prometheus-stack"
            }
          }
        }
      }
      repoServer = {
        metrics = {
          enabled = true
          serviceMonitor = {
            enabled          = true
            namespace        = "kube-prometheus-stack"
            additionalLabels = {
              release = "kube-prometheus-stack"
            }
          }
        }
      }
      applicationSet = {}
      redis          = {}
    }

    argo_rollouts = {
      controller = {
        metrics = {
          enabled = true
        }
      }
      dashboard = {}
    }

    prometheus = {
      prometheus = {
        prometheusSpec = {}
      }
      grafana = {
        assertNoLeakedSecrets = false
        ingress = {
          enabled          = true
          ingressClassName = "nginx"
          hosts            = ["grafana.cloudaura.online"]
          tls = [{
            secretName = "grafana-tls"
            hosts      = ["grafana.cloudaura.online"]
          }]
          annotations = {
            "cert-manager.io/cluster-issuer"           = "letsencrypt-prod"
            "nginx.ingress.kubernetes.io/ssl-redirect" = "true"
          }
        }
      }
      kube-state-metrics = {
        enabled = true
      }
      alertmanager = {
        alertmanagerSpec = {}
      }
      prometheusOperator = {
        admissionWebhooks = {
          patch = {}
        }
      }
    }
  }
}
